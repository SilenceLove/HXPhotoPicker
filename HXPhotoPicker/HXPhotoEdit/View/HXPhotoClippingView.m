//
//  HXPhotoClippingView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/29.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoClippingView.h"
#import "HXPhotoEditImageView.h"
#import "HXPhotoEditStickerItemView.h"
#import "UIView+HXExtension.h"
#import "HXPhotoDefine.h"
#import <AVFoundation/AVFoundation.h>
#import "HXPhotoEditStickerItemContentView.h"
#import "HXMECancelBlock.h"

#define HXDefaultMaximumZoomScale 5.f

NSString *const kHXClippingViewData = @"HXClippingViewData";
NSString *const kHXStickerViewData_screenScale = @"HXStickerViewData_screenScale";
NSString *const kHXClippingViewData_frame = @"HXClippingViewData_frame";
NSString *const kHXClippingViewData_zoomScale = @"HXClippingViewData_zoomScale";
NSString *const kHXClippingViewData_contentSize = @"HXClippingViewData_contentSize";
NSString *const kHXClippingViewData_contentOffset = @"HXClippingViewData_contentOffset";
NSString *const kHXClippingViewData_minimumZoomScale = @"HXClippingViewData_minimumZoomScale";
NSString *const kHXClippingViewData_maximumZoomScale = @"HXClippingViewData_maximumZoomScale";
NSString *const kHXClippingViewData_clipsToBounds = @"HXClippingViewData_clipsToBounds";
NSString *const kHXClippingViewData_transform = @"HXClippingViewData_transform";
NSString *const kHXClippingViewData_angle = @"HXClippingViewData_angle";
NSString *const kHXClippingViewData_mirror = @"HXClippingViewData_mirror";

NSString *const kHXClippingViewData_first_minimumZoomScale = @"HXClippingViewData_first_minimumZoomScale";

NSString *const kHXClippingViewData_zoomingView = @"HXClippingViewData_zoomingView";

@interface HXPhotoClippingView ()<UIScrollViewDelegate>
@property (nonatomic, strong) HXPhotoEditImageView *imageView;
/** 开始的基础坐标 */
@property (nonatomic, assign) CGRect normalRect;
/** 处理完毕的基础坐标（因为可能会被父类在缩放时改变当前frame的问题，导致记录坐标不正确） */
@property (nonatomic, assign) CGRect saveRect;
/** 首次缩放后需要记录最小缩放值，否则在多次重复编辑后由于大小发生改变，导致最小缩放值不准确，还原不回实际大小 */
@property (nonatomic, assign) CGFloat first_minimumZoomScale;
/** 旋转系数 */
@property (nonatomic, assign) NSInteger angle;
/** 默认最大化缩放 */
@property (nonatomic, assign) CGFloat defaultMaximumZoomScale;

/** 记录剪裁前的数据 */
@property (nonatomic, assign) CGRect old_frame;
@property (nonatomic, assign) NSInteger old_angle;
@property (nonatomic, assign) BOOL old_mirrorHorizontally;
@property (nonatomic, assign) HXPhotoClippingViewMirrorType old_mirrorType;
@property (nonatomic, assign) CGFloat old_zoomScale;
@property (nonatomic, assign) CGSize old_contentSize;
@property (nonatomic, assign) CGPoint old_contentOffset;
@property (nonatomic, assign) CGFloat old_minimumZoomScale;
@property (nonatomic, assign) CGFloat old_maximumZoomScale;
@property (nonatomic, assign) CGAffineTransform old_transform;
@end

@implementation HXPhotoClippingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)setup {
    
    self.scrollsToTop = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    if (@available(iOS 11.0, *)){
        [self setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }
    
    if (@available(iOS 13.0, *)) {
        self.automaticallyAdjustsScrollIndicatorInsets = NO;
    }
    
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    self.delegate = self;
    self.minimumZoomScale = 1.0f;
    self.maximumZoomScale = HXDefaultMaximumZoomScale;
    self.defaultMaximumZoomScale = HXDefaultMaximumZoomScale;
    self.alwaysBounceHorizontal = YES;
    self.alwaysBounceVertical = YES;
    self.angle = 0;
    self.mirrorType = HXPhotoClippingViewMirrorType_None;
    self.offsetSuperCenter = CGPointZero;
    self.useGesture = NO;
    
    self.imageView = [[HXPhotoEditImageView alloc] initWithFrame:self.bounds];
    HXWeakSelf
    self.imageView.moveCenter = ^BOOL(CGRect rect) {
        /** 判断缩放后贴图是否超出边界线 */
        CGRect newRect = [weakSelf.imageView convertRect:rect toView:weakSelf];
        CGRect clipTransRect = CGRectApplyAffineTransform(weakSelf.frame, weakSelf.transform);
        CGRect screenRect = (CGRect){weakSelf.contentOffset, clipTransRect.size};
        screenRect = CGRectInset(screenRect, 22, 22);
        return !CGRectIntersectsRect(screenRect, newRect);
    };
    self.imageView.getMinScale = ^CGFloat(CGSize size) {
        return MIN( 35 / size.width, 35 / size.height);
    };
    self.imageView.getMaxScale = ^CGFloat(CGSize size) {
        CGRect clipTransRect = CGRectApplyAffineTransform(weakSelf.frame, weakSelf.transform);
        CGRect screenRect = (CGRect){weakSelf.contentOffset, clipTransRect.size};
        CGFloat width = screenRect.size.width * weakSelf.screenScale;
        CGFloat height = screenRect.size.height * weakSelf.screenScale;
        if (width > HX_ScreenWidth) {
            width = HX_ScreenWidth;
        }
        if (height > HX_ScreenHeight) {
            height = HX_ScreenHeight;
        }
        CGFloat maxSize = MIN(size.width, size.height);
        return MAX( (width + 35) / maxSize, (height + 35) / maxSize);
    };
    [self addSubview:self.imageView];
    
    /** 默认编辑范围 */
    _editRect = self.bounds;
}
- (void)changeSubviewFrame {
    _editRect = self.bounds;
    self.imageView.frame = self.bounds;
    [self.imageView changeSubviewFrame];
}
- (void)clearCoverage {
    [self.imageView clearCoverage];
}
- (void)setConfiguration:(HXPhotoEditConfiguration *)configuration {
    _configuration = configuration;
    self.imageView.configuration = configuration;
}
- (void)setScreenScale:(CGFloat)screenScale {
    _screenScale = screenScale;
    self.imageView.screenScale = screenScale;
}
- (void)setImage:(UIImage *)image {
    _image = image;
    [self setZoomScale:1.f];
    if (image) {
        if (self.frame.size.width < self.frame.size.height) {
            self.defaultMaximumZoomScale = [UIScreen mainScreen].bounds.size.width * HXDefaultMaximumZoomScale / self.frame.size.width;
        } else {
            self.defaultMaximumZoomScale = [UIScreen mainScreen].bounds.size.height * HXDefaultMaximumZoomScale / self.frame.size.height;
        }
        self.maximumZoomScale = self.defaultMaximumZoomScale;
    }
    self.normalRect = self.frame;
    self.saveRect = self.frame;
    self.contentSize = self.hx_size;
    self.imageView.frame = self.bounds;
    self.imageView.image = image;
}

/** 获取除图片以外的编辑图层 */
- (UIImage *)editOtherImagesInRect:(CGRect)rect rotate:(CGFloat)rotate {
    CGRect inRect = [self.superview convertRect:rect toView:self.imageView];
    /** 参数取整，否则可能会出现1像素偏差 */
//    inRect = HXMediaEditProundRect(inRect);
    
    return [self.imageView editOtherImagesInRect:inRect rotate:rotate mirrorHorizontally:self.mirrorType == HXPhotoClippingViewMirrorType_Horizontal];
}

- (void)setCropRect:(CGRect)cropRect {
    /** 记录当前数据 */
    self.old_transform = self.transform;
    self.old_angle = self.angle;
    self.old_mirrorType = self.mirrorType;
    self.old_frame = self.frame;
    self.old_zoomScale = self.zoomScale;
    self.old_contentSize = self.contentSize;
    self.old_contentOffset = self.contentOffset;
    self.old_minimumZoomScale = self.minimumZoomScale;
    self.old_maximumZoomScale = self.maximumZoomScale;
    
    _cropRect = cropRect;
    
    /** 当前UI位置未改变时，获取contentOffset与contentSize */
    /** 计算未改变前当前视图在contentSize的位置比例 */
    CGPoint contentOffset = self.contentOffset;
    CGFloat scaleX = MAX(contentOffset.x / (self.contentSize.width - self.hx_w), 0);
    CGFloat scaleY = MAX(contentOffset.y / (self.contentSize.height - self.hx_h), 0);
    
    BOOL isHorizontal = NO;
    if (self.fixedAspectRatio) {
        if (self.angle % 180 != 0) {
            isHorizontal = YES;
            scaleX = MAX(contentOffset.x / (self.contentSize.width - self.hx_h), 0);
            scaleY = MAX(contentOffset.y / (self.contentSize.height - self.hx_w), 0);
        }
    }
    
    /** 获取contentOffset必须在设置contentSize之前，否则重置frame 或 contentSize后contentOffset会发送变化 */
    
    CGRect oldFrame = self.frame;
    self.frame = cropRect;
    self.saveRect = self.frame;
    
    CGFloat scale = self.zoomScale;
    /** 视图位移 */
    CGFloat scaleZX = CGRectGetWidth(cropRect)/(CGRectGetWidth(oldFrame)/scale);
    CGFloat scaleZY = CGRectGetHeight(cropRect)/(CGRectGetHeight(oldFrame)/scale);
    
    CGFloat zoomScale = MIN(scaleZX, scaleZY);
    
    [self resetMinimumZoomScale];
    self.maximumZoomScale = (zoomScale > self.defaultMaximumZoomScale ? zoomScale : self.defaultMaximumZoomScale);
    [self setZoomScale:zoomScale];
    
    /** 记录首次最小缩放值 */
    if (self.first_minimumZoomScale == 0) {
        self.first_minimumZoomScale = self.minimumZoomScale;
    }
    
    /** 重设contentSize */
    self.contentSize = self.imageView.hx_size;
    
    if (isHorizontal) {
        /** 获取当前contentOffset的最大限度，根据之前的位置比例计算实际偏移坐标 */
        contentOffset.x = isnan(scaleX) ? contentOffset.x : (scaleX > 0 ? (HXRound(self.contentSize.width) - HXRound(self.hx_h)) * scaleX : contentOffset.x);
        contentOffset.y = isnan(scaleY) ? contentOffset.y : (scaleY > 0 ? (HXRound(self.contentSize.height) - HXRound(self.hx_w)) * scaleY : contentOffset.y);
    }else {
        /** 获取当前contentOffset的最大限度，根据之前的位置比例计算实际偏移坐标 */
        contentOffset.x = isnan(scaleX) ? contentOffset.x : (scaleX > 0 ? (HXRound(self.contentSize.width) - HXRound(self.hx_w)) * scaleX : contentOffset.x);
        contentOffset.y = isnan(scaleY) ? contentOffset.y : (scaleY > 0 ? (HXRound(self.contentSize.height) - HXRound(self.hx_h)) * scaleY : contentOffset.y);
    }
    /** 计算坐标偏移与保底值 */
    CGRect zoomViewRect = self.imageView.frame;
    CGRect selfRect = CGRectApplyAffineTransform(self.frame, self.transform);
    
    CGFloat contentOffsetX = MIN(MAX(contentOffset.x, 0),zoomViewRect.size.width - selfRect.size.width);
    
    CGFloat contentOfssetY = MIN(MAX(contentOffset.y, 0),zoomViewRect.size.height - selfRect.size.height);
    
    self.contentOffset = CGPointMake(contentOffsetX, contentOfssetY);
}

/** 取消 */
- (void)cancel {
    if (!CGRectEqualToRect(self.old_frame, CGRectZero)) {
        self.transform = self.old_transform;
        self.angle = self.old_angle;
        self.mirrorType = self.old_mirrorType;
        self.frame = self.old_frame;
        self.saveRect = self.frame;
        self.minimumZoomScale = self.old_minimumZoomScale;
        self.maximumZoomScale = self.old_maximumZoomScale;
        self.zoomScale = self.old_zoomScale;
        self.contentSize = self.old_contentSize;
        self.contentOffset = self.old_contentOffset;
    }
}
- (void)resetRotateAngle {
    self.transform = CGAffineTransformIdentity;
    self.angle = 0;
    self.mirrorType = HXPhotoClippingViewMirrorType_None;
}
- (void)reset {
    [self resetToRect:CGRectZero];
}

- (void)resetToRect:(CGRect)rect {
    if (!_isReseting) {
        _isReseting = YES;
        self.mirrorType = HXPhotoClippingViewMirrorType_None;
        if (CGRectEqualToRect(rect, CGRectZero)) {
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 self.transform = CGAffineTransformIdentity;
                                 self.angle = 0;
                                 self.minimumZoomScale = self.first_minimumZoomScale;
                                 [self setZoomScale:self.minimumZoomScale];
                                 self.frame = (CGRect){CGPointZero, self.imageView.hx_size};
                                 self.center = CGPointMake(self.superview.center.x-self.offsetSuperCenter.x/2, self.superview.center.y-self.offsetSuperCenter.y/2);
                                 self.saveRect = self.frame;
                                 /** 重设contentSize */
                                 self.contentSize = self.imageView.hx_size;
                                 /** 重置contentOffset */
                                 self.contentOffset = CGPointZero;
                                 if ([self.clippingDelegate respondsToSelector:@selector(clippingViewWillBeginZooming:)]) {
                                     void (^block)(CGRect) = [self.clippingDelegate clippingViewWillBeginZooming:self];
                                     if (block) block(self.frame);
                                 }
                             } completion:^(BOOL finished) {
                                 if ([self.clippingDelegate respondsToSelector:@selector(clippingViewDidEndZooming:)]) {
                                     [self.clippingDelegate clippingViewDidEndZooming:self];
                                 }
                                 self->_isReseting = NO;
                             }];
        } else {
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 self.transform = CGAffineTransformIdentity;
                                 self.angle = 0;
                                 self.minimumZoomScale = self.first_minimumZoomScale;
                                 [self setZoomScale:self.minimumZoomScale];
                                 self.frame = (CGRect){CGPointZero, self.imageView.hx_size};
                                 self.center = CGPointMake(self.superview.center.x-self.offsetSuperCenter.x/2, self.superview.center.y-self.offsetSuperCenter.y/2);
                                 /** 重设contentSize */
                                 self.contentSize = self.imageView.hx_size;
                                 /** 重置contentOffset */
                                 self.contentOffset = CGPointZero;
                                 [self zoomInToRect:rect];
                                 [self zoomOutToRect:rect completion:^{
                                     self->_isReseting = NO;
                                 }];
                             } completion:nil];
        }
    }
}

- (BOOL)canReset {
    CGRect superViewRect = self.superview.bounds;
    CGFloat x = (HXRoundDecade(CGRectGetWidth(superViewRect)) - HXRoundDecade(CGRectGetWidth(self.imageView.frame))) / 2 - HXRoundDecade(self.offsetSuperCenter.x) / 2;
    CGFloat y = (HXRoundDecade(CGRectGetHeight(superViewRect)) - HXRoundDecade(CGRectGetHeight(self.imageView.frame))) / 2 - HXRoundDecade(self.offsetSuperCenter.y) / 2;
    CGRect trueFrame = CGRectMake(x ,y , HXRoundDecade(CGRectGetWidth(self.imageView.frame))
                                  , HXRoundDecade(CGRectGetHeight(self.imageView.frame)));
    return [self canResetWithRect:trueFrame];
}

- (BOOL)canResetWithRect:(CGRect)trueFrame {
    BOOL canReset = !(CGAffineTransformIsIdentity(self.transform)
    && HXRound(self.zoomScale) == HXRound(self.minimumZoomScale)
    && [self verifyRect:trueFrame]);
    if (self.fixedAspectRatio && !canReset) {
        if (fabs((fabs(HXRoundHundreds(self.contentSize.width) - HXRoundHundreds(self.hx_w)) / 2 - HXRoundHundreds(self.contentOffset.x))) >= 0.999) {
            canReset = YES;
        }else if (fabs((fabs(HXRoundHundreds(self.contentSize.height) - HXRoundHundreds(self.hx_h)) / 2 - HXRoundHundreds(self.contentOffset.y))) >= 0.999) {
            canReset = YES;
        }
    }
    return canReset;
}

- (CGRect)cappedCropRectInImageRectWithCropRect:(CGRect)cropRect {
    CGRect rect = [self convertRect:self.imageView.frame toView:self.superview];
    if (CGRectGetMinX(cropRect) < CGRectGetMinX(rect)) {
        cropRect.origin.x = CGRectGetMinX(rect);
    }
    if (CGRectGetMinY(cropRect) < CGRectGetMinY(rect)) {
        cropRect.origin.y = CGRectGetMinY(rect);
    }
    if (CGRectGetMaxX(cropRect) > CGRectGetMaxX(rect)) {
        cropRect.size.width = CGRectGetMaxX(rect) - CGRectGetMinX(cropRect);
    }
    if (CGRectGetMaxY(cropRect) > CGRectGetMaxY(rect)) {
        cropRect.size.height = CGRectGetMaxY(rect) - CGRectGetMinY(cropRect);
    }
    
    return cropRect;
}

#pragma mark 缩小到指定坐标
- (void)zoomOutToRect:(CGRect)toRect {
    [self zoomOutToRect:toRect completion:nil];
}
- (void)zoomOutToRect:(CGRect)toRect completion:(void (^)(void))completion {
    /** 屏幕在滚动时 不触发该功能 */
    if (self.dragging || self.decelerating) {
        return;
    }
    
    CGRect rect = [self cappedCropRectInImageRectWithCropRect:toRect];
    
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    
    /** 新增了放大功能：这里需要重新计算最小缩放系数 */
    [self resetMinimumZoomScale];
    [self setZoomScale:self.zoomScale];
    
    CGFloat scale = MIN(CGRectGetWidth(self.editRect) / width, CGRectGetHeight(self.editRect) / height);
    
    /** 指定位置=当前显示位置 或者 当前缩放已达到最大，并且仍然发生缩放的情况； 免去以下计算，以当前显示大小为准 */
    if (CGRectEqualToRect(HXRoundFrame(self.frame), HXRoundFrame(rect)) || (HXRound(self.zoomScale) == HXRound(self.maximumZoomScale) && HXRound(scale) > 1.f)) {
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             /** 只需要移动到中点 */
                             self.center = CGPointMake(self.superview.center.x-self.offsetSuperCenter.x/2, self.superview.center.y-self.offsetSuperCenter.y/2);
                             self.saveRect = self.frame;
                             
                             if ([self.clippingDelegate respondsToSelector:@selector(clippingViewWillBeginZooming:)]) {
                                 void (^block)(CGRect) = [self.clippingDelegate clippingViewWillBeginZooming:self];
                                 if (block) block(self.frame);
                             }
                         } completion:^(BOOL finished) {
                             if ([self.clippingDelegate respondsToSelector:@selector(clippingViewDidEndZooming:)]) {
                                 [self.clippingDelegate clippingViewDidEndZooming:self];
                             }
                             if (completion) {
                                 completion();
                             }
                         }];
        return;
    }
    
    CGFloat scaledWidth = width * scale;
    CGFloat scaledHeight = height * scale;
    /** 计算缩放比例 */
    CGFloat zoomScale = MIN(self.zoomScale * scale, self.maximumZoomScale);
    /** 特殊图片计算 比例100:1 或 1:100 的情况 */
    CGRect zoomViewRect = CGRectApplyAffineTransform(self.imageView.frame, self.transform);
    scaledWidth = MIN(scaledWidth, CGRectGetWidth(zoomViewRect) * (zoomScale / self.minimumZoomScale));
    scaledHeight = MIN(scaledHeight, CGRectGetHeight(zoomViewRect) * (zoomScale / self.minimumZoomScale));
    
    /** 计算实际显示坐标 */
    CGRect cropRect = CGRectMake((CGRectGetWidth(self.superview.bounds) - scaledWidth) / 2 - self.offsetSuperCenter.x/2,
                                 (CGRectGetHeight(self.superview.bounds) - scaledHeight) / 2  - self.offsetSuperCenter.y/2,
                                 scaledWidth,
                                 scaledHeight);
    
    /** 计算偏移值 */
    __block CGPoint contentOffset = self.contentOffset;
    if (!([self verifyRect:cropRect] && zoomScale == self.zoomScale)) { /** 实际位置与当前位置一致不做位移处理 && 缩放系数一致 */
        /** 获取相对坐标 */
        CGRect zoomRect = [self.superview convertRect:rect toView:self];
        contentOffset.x = zoomRect.origin.x * zoomScale / self.zoomScale;
        contentOffset.y = zoomRect.origin.y * zoomScale / self.zoomScale;
    }
    
    
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.frame = cropRect;
                         self.saveRect = self.frame;
                         [self setZoomScale:zoomScale];
                         /** 重新调整contentSize */
                         self.contentSize = self.imageView.hx_size;
                         [self setContentOffset:contentOffset];
                         
                         /** 设置完实际大小后再次计算最小缩放系数 */
                         [self resetMinimumZoomScale];
                         [self setZoomScale:self.zoomScale];
                         
                         if ([self.clippingDelegate respondsToSelector:@selector(clippingViewWillBeginZooming:)]) {
                             void (^block)(CGRect) = [self.clippingDelegate clippingViewWillBeginZooming:self];
                             if (block) block(self.frame);
                         }
                     } completion:^(BOOL finished) {
                         if ([self.clippingDelegate respondsToSelector:@selector(clippingViewDidEndZooming:)]) {
                             [self.clippingDelegate clippingViewDidEndZooming:self];
                         }
                         if (completion) {
                             completion();
                         }
                     }];
}

- (void)zoomToRect:(CGRect)rect {
    self.frame = rect;
    [self resetMinimumZoomScale];
    
    [self setZoomScale:self.zoomScale];
}

#pragma mark 放大到指定坐标(必须大于当前坐标)
- (void)zoomInToRect:(CGRect)toRect {
    /** 屏幕在滚动时 不触发该功能 */
    if (self.dragging || self.decelerating) {
        return;
    }
    CGRect zoomingRect = [self convertRect:self.imageView.frame toView:self.superview];
    /** 判断坐标是否超出当前坐标范围 */
    if ((CGRectGetMinX(toRect) + FLT_EPSILON) < CGRectGetMinX(zoomingRect)
        || (CGRectGetMinY(toRect) + FLT_EPSILON) < CGRectGetMinY(zoomingRect)
        || (CGRectGetMaxX(toRect) - FLT_EPSILON) > (CGRectGetMaxX(zoomingRect)+0.5) /** 兼容计算过程的误差0.几的情况 */
        || (CGRectGetMaxY(toRect) - FLT_EPSILON) > (CGRectGetMaxY(zoomingRect)+0.5)
        ) {
        
        /** 取最大值缩放 */
        CGRect myFrame = self.frame;
        myFrame.origin.x = MIN(myFrame.origin.x, toRect.origin.x);
        myFrame.origin.y = MIN(myFrame.origin.y, toRect.origin.y);
        myFrame.size.width = MAX(myFrame.size.width, toRect.size.width);
        myFrame.size.height = MAX(myFrame.size.height, toRect.size.height);
        self.frame = myFrame;
        
        [self resetMinimumZoomScale];
        [self setZoomScale:self.zoomScale];
    }
    
}

#pragma mark 旋转
- (void)rotateClockwise:(BOOL)clockwise {
    /** 屏幕在滚动时 不触发该功能 */
    if (self.dragging || self.decelerating) {
        return;
    }
    if (!_isRotating) {
        _isRotating = YES;
        if (self.mirrorType == HXPhotoClippingViewMirrorType_Horizontal) {
            clockwise = YES;
        }
        NSInteger newAngle = self.angle;
        newAngle = clockwise ? newAngle + 90 : newAngle - 90;
        if (newAngle <= -360 || newAngle >= 360)
            newAngle = 0;
        
        _angle = newAngle;
        
        [UIView animateWithDuration:0.35f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.8f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            
            [self transformRotate:self.angle];
            
            if ([self.clippingDelegate respondsToSelector:@selector(clippingViewWillBeginZooming:)]) {
                void (^block)(CGRect) = [self.clippingDelegate clippingViewWillBeginZooming:self];
                if (block) block(self.frame);
            }
            
        } completion:^(BOOL complete) {
            self->_isRotating = NO;
            if ([self.clippingDelegate respondsToSelector:@selector(clippingViewDidEndZooming:)]) {
                [self.clippingDelegate clippingViewDidEndZooming:self];
            }
        }];
        
    }
}
/// 镜像翻转
- (void)mirrorFlip {
    if (self.dragging || self.decelerating) {
        return;
    }
    if (!self.isMirrorFlip) {
        self.isMirrorFlip = YES;
        if ([self.clippingDelegate respondsToSelector:@selector(clippingViewWillBeginZooming:)]) {
            [self.clippingDelegate clippingViewWillBeginZooming:self];
        }
        CGFloat angleInRadians = 0.0f;
        switch (self.angle) {
            case 90:    angleInRadians = M_PI_2;            break;
            case -90:   angleInRadians = -M_PI_2;           break;
            case 180:   angleInRadians = M_PI;              break;
            case -180:  angleInRadians = -M_PI;             break;
            case 270:   angleInRadians = (M_PI + M_PI_2);   break;
            case -270:  angleInRadians = -(M_PI + M_PI_2);  break;
            default:                                        break;
        }
        CGAffineTransform rotateTransform = CGAffineTransformRotate(CGAffineTransformIdentity ,angleInRadians);
        [UIView animateWithDuration:0.25 animations:^{
            if (self.mirrorType == HXPhotoClippingViewMirrorType_None) {
                // 没有镜像翻转
                if (self.angle == 0) {
                    // 上
                    self.transform = CGAffineTransformScale(rotateTransform ,-1.0, 1.0);
                    self.mirrorType = HXPhotoClippingViewMirrorType_Horizontal;
                }else if (self.angle == -90 || self.angle == 90) {
                    // 左
                    self.transform = CGAffineTransformScale(rotateTransform ,1.0, -1.0);
                    self.mirrorType = HXPhotoClippingViewMirrorType_Horizontal;
                    self.angle = 270;
                }else if (self.angle == -180 || self.angle == 180) {
                    // 下
                    self.transform = CGAffineTransformScale(rotateTransform ,-1.0, 1.0);
                    self.mirrorType = HXPhotoClippingViewMirrorType_Horizontal;
                }else if (self.angle == -270 || self.angle == 270) {
                    // 右
                    self.transform = CGAffineTransformScale(CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI_2), -1, 1);
                    self.angle = 90;
                    self.mirrorType = HXPhotoClippingViewMirrorType_Horizontal;
                }
            }else if (self.mirrorType == HXPhotoClippingViewMirrorType_Horizontal){
                // 水平翻转了
                if (self.angle == 0) {
                    // 上
                    self.transform = CGAffineTransformScale(rotateTransform ,1.0, 1.0);
                    self.mirrorType = HXPhotoClippingViewMirrorType_None;
                }else if (self.angle == -90 || self.angle == 90) {
                    // 左
                    CGAffineTransform transfrom = CGAffineTransformRotate(CGAffineTransformIdentity, -(M_PI + M_PI_2));
                    self.transform = transfrom;
                    self.angle = -270;
                    self.mirrorType = HXPhotoClippingViewMirrorType_None;
                }else if (self.angle == -180 || self.angle == 180) {
                    // 下
                    self.transform = CGAffineTransformScale(rotateTransform ,1.0, 1.0);
                    self.mirrorType = HXPhotoClippingViewMirrorType_None;
                }else if (self.angle == -270 || self.angle == 270) {
                    // 右
                    self.transform = CGAffineTransformScale(CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI_2) , 1, 1);
                    self.angle = -90;
                    self.mirrorType = HXPhotoClippingViewMirrorType_None;
                }
            }
        } completion:^(BOOL finished) {
            self.isMirrorFlip = NO;
            if ([self.clippingDelegate respondsToSelector:@selector(clippingViewDidEndZooming:)]) {
                [self.clippingDelegate clippingViewDidEndZooming:self];
            }
        }];
    }
}
- (CGAffineTransform)getCurrentMirrorFlip {
    if (self.mirrorType == HXPhotoClippingViewMirrorType_Horizontal){
        // 水平翻转了
        return CGAffineTransformScale(CGAffineTransformIdentity ,-1.0, 1.0);
    }
    return CGAffineTransformIdentity;
}
#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([self.clippingDelegate respondsToSelector:@selector(clippingViewWillBeginDragging:)]) {
        [self.clippingDelegate clippingViewWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        if ([self.clippingDelegate respondsToSelector:@selector(clippingViewDidEndDecelerating:)]) {
            [self.clippingDelegate clippingViewDidEndDecelerating:self];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.clippingDelegate respondsToSelector:@selector(clippingViewDidEndDecelerating:)]) {
        [self.clippingDelegate clippingViewDidEndDecelerating:self];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view {
    if ([self.clippingDelegate respondsToSelector:@selector(clippingViewWillBeginZooming:)]) {
        void (^block)(CGRect) = [self.clippingDelegate clippingViewWillBeginZooming:self];
        block(self.frame);
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    self.contentInset = UIEdgeInsetsZero;
    self.scrollIndicatorInsets = UIEdgeInsetsZero;
    if (scrollView.isZooming || scrollView.isZoomBouncing) {
        /** 代码调整zoom，会导致居中计算错误，必须2指控制UI自动缩放时才调用 */
        [self refreshImageZoomViewCenter];
    }
    if ([self.clippingDelegate respondsToSelector:@selector(clippingViewDidZoom:)]) {
        [self.clippingDelegate clippingViewDidZoom:self];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    if ([self.clippingDelegate respondsToSelector:@selector(clippingViewDidEndZooming:)]) {
        [self.clippingDelegate clippingViewDidEndZooming:self];
    }
}

#pragma mark - Private
- (void)refreshImageZoomViewCenter {
    CGRect rect = CGRectApplyAffineTransform(self.frame, self.transform);
    
    CGFloat offsetX = (rect.size.width > self.contentSize.width) ? ((rect.size.width - self.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (rect.size.height > self.contentSize.height) ? ((rect.size.height - self.contentSize.height) * 0.5) : 0.0;
    self.imageView.center = CGPointMake(self.contentSize.width * 0.5 + offsetX, self.contentSize.height * 0.5 + offsetY);
}

#pragma mark - 验证当前大小是否被修改
- (BOOL)verifyRect:(CGRect)r_rect {
    /** 计算缩放率 */
    CGRect rect = CGRectApplyAffineTransform(r_rect, self.transform);
    /** 模糊匹配 */
    BOOL isEqual = CGRectEqualToRect(rect, self.frame);
    
    if (isEqual == NO) {
        /** 精准验证 */
        // 允许0.5f以内的误差
        if (fabs(self.hx_x - rect.origin.x) <= 0.5f) {
            rect = CGRectMake(self.frame.origin.x, rect.origin.y, rect.size.width, rect.size.height);
        }
        if (fabs(self.hx_y - rect.origin.y) <= 0.5f) {
            rect = CGRectMake(rect.origin.x, self.frame.origin.y, rect.size.width, rect.size.height);
        }
        if (fabs(self.hx_w - rect.size.width) <= 0.5f) {
            rect = CGRectMake(rect.origin.x, rect.origin.y, self.frame.size.width, rect.size.height);
        }
        if (fabs(self.hx_h - rect.size.height) <= 0.5f) {
            rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, self.frame.size.height);
        }
        
        BOOL x = HXRoundDecade(CGRectGetMinX(rect)) == HXRoundDecade(CGRectGetMinX(self.frame));
        
        BOOL y = HXRoundDecade(CGRectGetMinY(rect)) == HXRoundDecade(CGRectGetMinY(self.frame));
        BOOL w = HXRoundDecade(CGRectGetWidth(rect)) == HXRoundDecade(CGRectGetWidth(self.frame));
        BOOL h = HXRoundDecade(CGRectGetHeight(rect)) == HXRoundDecade(CGRectGetHeight(self.frame));
        isEqual = x && y && w && h;
    }
    return isEqual;
}

#pragma mark - 旋转视图
- (void)transformRotate:(NSInteger)angle {
    //Convert the new angle to radians
    CGFloat angleInRadians = 0.0f;
    switch (angle) {
        case 90:    angleInRadians = M_PI_2;            break;
        case -90:   angleInRadians = -M_PI_2;           break;
        case 180:   angleInRadians = M_PI;              break;
        case -180:  angleInRadians = -M_PI;             break;
        case 270:   angleInRadians = (M_PI + M_PI_2);   break;
        case -270:  angleInRadians = -(M_PI + M_PI_2);  break;
        default:                                        break;
    }
    
     
    /** 不用重置变形，使用center与bounds来计算原来的frame */
    CGPoint center = self.center;
    CGRect bounds = self.bounds;
    CGRect oldRect = CGRectMake(center.x-0.5*bounds.size.width, center.y-0.5*bounds.size.height, bounds.size.width, bounds.size.height);
    CGFloat width = CGRectGetWidth(oldRect);
    CGFloat height = CGRectGetHeight(oldRect);
    if (self.fixedAspectRatio) {
        if (angle%180 == 0) { /** 旋转基数时需要互换宽高 */
            CGFloat tempWidth = width;
            width = height;
            height = tempWidth;
        }
    }else {
        if (angle%180 != 0) { /** 旋转基数时需要互换宽高 */
            CGFloat tempWidth = width;
            width = height;
            height = tempWidth;
        }
    }
    /** 改变变形之前获取偏移量，变形后再计算偏移量比例移动 */
    CGPoint contentOffset = self.contentOffset;
    CGFloat marginXScale = 0.5;
    if (self.fixedAspectRatio) {
        CGFloat w = ((angle%180 == 0) ? self.hx_h : self.hx_w);
        if (self.contentSize.width - w > 0) {
            marginXScale = contentOffset.x / (self.contentSize.width - w);
            if (marginXScale == 0) {
                marginXScale = 0.5;
            }
            marginXScale = HXRound(marginXScale);
        }
    }
    CGFloat marginYScale = 0.5f;
    if (self.fixedAspectRatio) {
        CGFloat h = ((angle%180 == 0) ? self.hx_w : self.hx_h);
        if (self.contentSize.height - h > 0) {
            marginYScale = contentOffset.y / (self.contentSize.height - h);
            if (marginYScale == 0) {
                marginYScale = 0.5;
            }
            marginYScale = HXRound(marginYScale);
        }
    }
    
    /** 调整变形 */
    CGAffineTransform transform = CGAffineTransformRotate([self getCurrentMirrorFlip], angleInRadians);
    self.transform = transform;
    
    /** 计算变形后的坐标拉伸到编辑范围 */
    CGRect frame = HXRoundFrameHundreds(AVMakeRectWithAspectRatioInsideRect(CGSizeMake(width, height), self.editRect));
    self.frame = frame;
    /** 重置最小缩放比例 */
    [self resetMinimumZoomScale];
    /** 计算缩放比例 */
    CGFloat scale = MIN(CGRectGetWidth(self.frame) / width, CGRectGetHeight(self.frame) / height);
    /** 转移缩放目标 */
    self.zoomScale *= scale;
    /** 修正旋转后到偏移量 */
    if (self.fixedAspectRatio) {
        if (angle%180 != 0) { /** 旋转基数时需要互换宽高 */
            contentOffset.x = fabs(self.contentSize.width - self.hx_h) * marginXScale;
            contentOffset.y = fabs(self.contentSize.height - self.hx_w) * marginYScale;
        }else {
            contentOffset.x = fabs(self.contentSize.width - self.hx_w) * marginXScale;
            contentOffset.y = fabs(self.contentSize.height - self.hx_h) * marginYScale;
        }
    }else {
        contentOffset.x *= scale;
        contentOffset.y *= scale;
    }
    self.contentOffset = contentOffset;
}

#pragma mark - 重置最小缩放比例
- (void)resetMinimumZoomScale {
    /** 重置最小缩放比例 */
    CGRect rotateNormalRect = CGRectApplyAffineTransform(self.normalRect, self.transform);
    if (CGSizeEqualToSize(rotateNormalRect.size, CGSizeZero)) {
        /** size为0时候不能继续，否则minimumZoomScale=+Inf，会无法缩放 */
        return;
    }
    CGFloat minimumZoomScale = MAX(CGRectGetWidth(self.frame) / CGRectGetWidth(rotateNormalRect), CGRectGetHeight(self.frame) / CGRectGetHeight(rotateNormalRect));
    self.minimumZoomScale = minimumZoomScale;
}

#pragma mark - 重写父类方法

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
//    if ([[self.imageView subviews] containsObject:view]) {
//        if (event.allTouches.count == 1) { /** 1个手指 */
//            return YES;
//        } else if (event.allTouches.count == 2) { /** 2个手指 */
//            return NO;
//        }
//    }
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
//    if ([[self.imageView subviews] containsObject:view]) {
//        return NO;
//    } else if (![[self subviews] containsObject:view]) { /** 非自身子视图 */
//        return NO;
//    }
    return [super touchesShouldCancelInContentView:view];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (!view) {
        CGPoint sPoint = [self convertPoint:point toView:self.imageView.stickerView];
        if (CGRectContainsPoint(self.imageView.stickerView.selectItemView.frame, sPoint)) {
            self.imageView.stickerView.hitTestSubView = YES;
            return self.imageView.stickerView.selectItemView.contentView;
        }else {
            [self.imageView.stickerView removeSelectItem];
        }
    }
    if (view == self.imageView) { /** 不触发下一层UI响应 */
        return self;
    }
    return view;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    /** 控制自身手势 */
    return self.useGesture;
}
 
#pragma mark - 数据
- (NSDictionary *)photoEditData
{
    NSMutableDictionary *data = [@{} mutableCopy];
    
    if ([self canReset]) { /** 可还原证明已编辑过 */
        //        CGRect trueFrame = CGRectApplyAffineTransform(self.frame, CGAffineTransformInvert(self.transform));
        NSDictionary *myData = @{kHXClippingViewData_frame:[NSValue valueWithCGRect:self.saveRect]
                                 , kHXClippingViewData_zoomScale:@(self.zoomScale)
                                 , kHXClippingViewData_contentSize:[NSValue valueWithCGSize:self.contentSize]
                                 , kHXClippingViewData_contentOffset:[NSValue valueWithCGPoint:self.contentOffset]
                                 , kHXClippingViewData_minimumZoomScale:@(self.minimumZoomScale)
                                 , kHXClippingViewData_maximumZoomScale:@(self.maximumZoomScale)
                                 , kHXClippingViewData_clipsToBounds:@(self.clipsToBounds)
                                 , kHXClippingViewData_first_minimumZoomScale:@(self.first_minimumZoomScale)
                                 , kHXClippingViewData_transform:[NSValue valueWithCGAffineTransform:self.transform]
                                 , kHXClippingViewData_angle:@(self.angle)
                                 , kHXClippingViewData_mirror : @(self.mirrorType)
                                 , kHXStickerViewData_screenScale:@(self.screenScale)
        };
        [data setObject:myData forKey:kHXClippingViewData];
    }
    
    NSDictionary *imageViewData = self.imageView.photoEditData;
    if (imageViewData) [data setObject:imageViewData forKey:kHXClippingViewData_zoomingView];
    
    if (data.count) {
        return data;
    }
    return nil;
}

- (void)setPhotoEditData:(NSDictionary *)photoEditData
{
    NSDictionary *myData = photoEditData[kHXClippingViewData];
    if (myData) {
        self.transform = [myData[kHXClippingViewData_transform] CGAffineTransformValue];
        self.angle = [myData[kHXClippingViewData_angle] integerValue];
        self.mirrorType = [myData[kHXClippingViewData_mirror] integerValue];
        self.saveRect = [myData[kHXClippingViewData_frame] CGRectValue];
        self.frame = self.saveRect;
        self.minimumZoomScale = [myData[kHXClippingViewData_minimumZoomScale] floatValue];
        self.maximumZoomScale = [myData[kHXClippingViewData_maximumZoomScale] floatValue];
        self.zoomScale = [myData[kHXClippingViewData_zoomScale] floatValue];
        self.contentSize = [myData[kHXClippingViewData_contentSize] CGSizeValue];
        self.contentOffset = [myData[kHXClippingViewData_contentOffset] CGPointValue];
        self.clipsToBounds = [myData[kHXClippingViewData_clipsToBounds] boolValue];
        self.first_minimumZoomScale = [myData[kHXClippingViewData_first_minimumZoomScale] floatValue];
        self.screenScale = [myData[kHXStickerViewData_screenScale] floatValue];
    }

    self.imageView.photoEditData = photoEditData[kHXClippingViewData_zoomingView];
}

@end
