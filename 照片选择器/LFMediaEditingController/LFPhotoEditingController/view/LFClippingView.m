//
//  LFClippingView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFClippingView.h"
#import "LFZoomingView.h"
#import "UIView+LFMEFrame.h"
#import <AVFoundation/AVFoundation.h>

#define kRound(x) (round(x*100000)/100000)

#define kRoundFrame(rect) CGRectMake(kRound(rect.origin.x), kRound(rect.origin.y), kRound(rect.size.width), kRound(rect.size.height))

#define kDefaultMaximumZoomScale 5.f

NSString *const kLFClippingViewData = @"LFClippingViewData";

NSString *const kLFClippingViewData_frame = @"LFClippingViewData_frame";
NSString *const kLFClippingViewData_zoomScale = @"LFClippingViewData_zoomScale";
NSString *const kLFClippingViewData_contentSize = @"LFClippingViewData_contentSize";
NSString *const kLFClippingViewData_contentOffset = @"LFClippingViewData_contentOffset";
NSString *const kLFClippingViewData_minimumZoomScale = @"LFClippingViewData_minimumZoomScale";
NSString *const kLFClippingViewData_maximumZoomScale = @"LFClippingViewData_maximumZoomScale";
NSString *const kLFClippingViewData_clipsToBounds = @"LFClippingViewData_clipsToBounds";
NSString *const kLFClippingViewData_transform = @"LFClippingViewData_transform";
NSString *const kLFClippingViewData_angle = @"LFClippingViewData_angle";

NSString *const kLFClippingViewData_first_minimumZoomScale = @"LFClippingViewData_first_minimumZoomScale";

NSString *const kLFClippingViewData_zoomingView = @"LFClippingViewData_zoomingView";

@interface LFClippingView () <UIScrollViewDelegate>

@property (nonatomic, weak) LFZoomingView *zoomingView;

/** 原始坐标 */
@property (nonatomic, assign) CGRect originalRect;
/** 开始的基础坐标 */
@property (nonatomic, assign) CGRect normalRect;
/** 处理完毕的基础坐标（因为可能会被父类在缩放时改变当前frame的问题，导致记录坐标不正确） */
@property (nonatomic, assign) CGRect saveRect;
/** 首次缩放后需要记录最小缩放值，否则在多次重复编辑后由于大小发生改变，导致最小缩放值不准确，还原不回实际大小 */
@property (nonatomic, assign) CGFloat first_minimumZoomScale;
/** 旋转系数 */
@property (nonatomic, assign) NSInteger angle;
/** 与父视图中心偏差坐标 */
@property (nonatomic, assign) CGPoint offsetSuperCenter;
/** 默认最大化缩放 */
@property (nonatomic, assign) CGFloat defaultMaximumZoomScale;

/** 记录剪裁前的数据 */
@property (nonatomic, assign) CGRect old_frame;
@property (nonatomic, assign) CGFloat old_zoomScale;
@property (nonatomic, assign) CGSize old_contentSize;
@property (nonatomic, assign) CGPoint old_contentOffset;
@property (nonatomic, assign) CGFloat old_minimumZoomScale;
@property (nonatomic, assign) CGFloat old_maximumZoomScale;
@property (nonatomic, assign) CGAffineTransform old_transform;

@end

@implementation LFClippingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _originalRect = frame;
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    self.delegate = self;
    self.minimumZoomScale = 1.0f;
    self.maximumZoomScale = kDefaultMaximumZoomScale;
    self.alwaysBounceHorizontal = YES;
    self.alwaysBounceVertical = YES;
    self.angle = 0;
    self.offsetSuperCenter = CGPointZero;
    
    LFZoomingView *zoomingView = [[LFZoomingView alloc] initWithFrame:self.bounds];
    __weak typeof(self) weakSelf = self;
    zoomingView.moveCenter = ^BOOL(CGRect rect) {
        /** 判断缩放后贴图是否超出边界线 */
        CGRect newRect = [weakSelf.zoomingView convertRect:rect toView:weakSelf];
        CGRect clipTransRect = CGRectApplyAffineTransform(weakSelf.frame, weakSelf.transform);
        CGRect screenRect = (CGRect){weakSelf.contentOffset, clipTransRect.size};
        return !CGRectIntersectsRect(screenRect, newRect);
    };
    [self addSubview:zoomingView];
    self.zoomingView = zoomingView;
    
    /** 默认编辑范围 */
    _editRect = self.bounds;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self setZoomScale:1.f];
    if (image) {        
        CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(image.size, self.originalRect);
        self.frame = cropRect;
        {
            if (cropRect.size.width < cropRect.size.height) {
                self.defaultMaximumZoomScale = self.originalRect.size.width * kDefaultMaximumZoomScale / cropRect.size.width;
            } else {
                self.defaultMaximumZoomScale = self.originalRect.size.height * kDefaultMaximumZoomScale / cropRect.size.height;
            }
            self.maximumZoomScale = self.defaultMaximumZoomScale;
        }
    } else {
        self.frame = _originalRect;
    }
    self.normalRect = self.frame;
    self.saveRect = self.frame;
    self.contentSize = self.size;
    [self.zoomingView setImage:image];
}

- (void)setImageViewHidden:(BOOL)imageViewHidden
{
    self.zoomingView.imageViewHidden = imageViewHidden;
}

- (BOOL)isImageViewHidden
{
    return self.zoomingView.imageViewHidden;
}

- (void)setCropRect:(CGRect)cropRect
{
    /** 记录当前数据 */
    self.old_transform = self.transform;
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
    CGFloat scaleX = MAX(contentOffset.x/(self.contentSize.width-self.width), 0);
    CGFloat scaleY = MAX(contentOffset.y/(self.contentSize.height-self.height), 0);
    /** 获取contentOffset必须在设置contentSize之前，否则重置frame 或 contentSize后contentOffset会发送变化 */
    
    CGRect oldFrame = self.frame;
    self.frame = cropRect;
    self.saveRect = self.frame;
    /** 计算与父界面的中心偏差坐标 */
    CGFloat offset_x = (CGRectGetWidth(self.superview.frame)-CGRectGetWidth(cropRect))/2-cropRect.origin.x;
    CGFloat offset_y = (CGRectGetHeight(self.superview.frame)-CGRectGetHeight(cropRect))/2-cropRect.origin.y;
    self.offsetSuperCenter = CGPointMake(offset_x, offset_y);
    
    
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
    self.contentSize = self.zoomingView.size;
    /** 获取当前contentOffset的最大限度，根据之前的位置比例计算实际偏移坐标 */
    contentOffset.x = isnan(scaleX) ? contentOffset.x : (scaleX > 0 ? (self.contentSize.width-self.width) * scaleX : contentOffset.x);
    contentOffset.y = isnan(scaleY) ? contentOffset.y : (scaleY > 0 ? (self.contentSize.height-self.height) * scaleY : contentOffset.y);
    /** 计算坐标偏移与保底值 */
    CGRect zoomViewRect = self.zoomingView.frame;
    CGRect selfRect = CGRectApplyAffineTransform(self.frame, self.transform);
    self.contentOffset = CGPointMake(MIN(MAX(contentOffset.x, 0),zoomViewRect.size.width-selfRect.size.width), MIN(MAX(contentOffset.y, 0),zoomViewRect.size.height-selfRect.size.height));
}

/** 取消 */
- (void)cancel
{
    if (!CGRectEqualToRect(self.old_frame, CGRectZero)) {
        self.transform = self.old_transform;
        self.angle = 0;
        self.frame = self.old_frame;
        self.saveRect = self.frame;
        self.minimumZoomScale = self.old_minimumZoomScale;
        self.maximumZoomScale = self.old_maximumZoomScale;
        self.zoomScale = self.old_zoomScale;
        self.contentSize = self.old_contentSize;
        self.contentOffset = self.old_contentOffset;
    }
}

- (void)reset
{
    if (!_isReseting) {        
        _isReseting = YES;
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.transform = CGAffineTransformIdentity;
                             self.angle = 0;
                             self.minimumZoomScale = self.first_minimumZoomScale;
                             [self setZoomScale:self.minimumZoomScale];
                             self.frame = (CGRect){CGPointZero, self.zoomingView.size};
                             self.center = CGPointMake(self.superview.center.x-self.offsetSuperCenter.x/2, self.superview.center.y-self.offsetSuperCenter.y/2);
                             self.saveRect = self.frame;
                             /** 重设contentSize */
                             self.contentSize = self.zoomingView.size;
                             /** 重置contentOffset */
                             self.contentOffset = CGPointZero;
                             if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginZooming:)]) {
                                 void (^block)(CGRect) = [self.clippingDelegate lf_clippingViewWillBeginZooming:self];
                                 if (block) block(self.frame);
                             }
                         } completion:^(BOOL finished) {
                             if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndZooming:)]) {
                                 [self.clippingDelegate lf_clippingViewDidEndZooming:self];
                             }
                             _isReseting = NO;
                         }];
    }
}

- (BOOL)canReset
{
    CGRect trueFrame = CGRectMake((CGRectGetWidth(self.superview.frame)-CGRectGetWidth(self.zoomingView.frame))/2-self.offsetSuperCenter.x
                                  , (CGRectGetHeight(self.superview.frame)-CGRectGetHeight(self.zoomingView.frame))/2-self.offsetSuperCenter.y
                                  , CGRectGetWidth(self.zoomingView.frame)
                                  , CGRectGetHeight(self.zoomingView.frame));
    
    return !(CGAffineTransformIsIdentity(self.transform)
             && kRound(self.zoomScale) == kRound(self.minimumZoomScale)
             && [self verifyRect:trueFrame]);
}

- (CGRect)cappedCropRectInImageRectWithCropRect:(CGRect)cropRect
{
    CGRect rect = [self convertRect:self.zoomingView.frame toView:self.superview];
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
- (void)zoomOutToRect:(CGRect)toRect
{
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
    if (CGRectEqualToRect(kRoundFrame(self.frame), kRoundFrame(rect)) || (kRound(self.zoomScale) == kRound(self.maximumZoomScale) && kRound(scale) > 1.f)) {
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             /** 只需要移动到中点 */
                             self.center = CGPointMake(self.superview.center.x-self.offsetSuperCenter.x/2, self.superview.center.y-self.offsetSuperCenter.y/2);
                             self.saveRect = self.frame;
                             
                             if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginZooming:)]) {
                                 void (^block)(CGRect) = [self.clippingDelegate lf_clippingViewWillBeginZooming:self];
                                 if (block) block(self.frame);
                             }
                         } completion:^(BOOL finished) {
                             if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndZooming:)]) {
                                 [self.clippingDelegate lf_clippingViewDidEndZooming:self];
                             }
                         }];
        return;
    }
    
    CGFloat scaledWidth = width * scale;
    CGFloat scaledHeight = height * scale;
    /** 计算缩放比例 */
    CGFloat zoomScale = MIN(self.zoomScale * scale, self.maximumZoomScale);
    /** 特殊图片计算 比例100:1 或 1:100 的情况 */
    CGRect zoomViewRect = CGRectApplyAffineTransform(self.zoomingView.frame, self.transform);
    scaledWidth = MIN(scaledWidth, CGRectGetWidth(zoomViewRect) * (zoomScale / self.minimumZoomScale));
    scaledHeight = MIN(scaledHeight, CGRectGetHeight(zoomViewRect) * (zoomScale / self.minimumZoomScale));
    
    /** 计算实际显示坐标 */
    CGRect cropRect = CGRectMake((CGRectGetWidth(self.superview.bounds) - scaledWidth) / 2,
                                 (CGRectGetHeight(self.superview.bounds) - scaledHeight) / 2,
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
                         self.contentSize = self.zoomingView.size;
                         [self setContentOffset:contentOffset];
                         
                         /** 设置完实际大小后再次计算最小缩放系数 */
                         [self resetMinimumZoomScale];
                         [self setZoomScale:self.zoomScale];
                         
                         if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginZooming:)]) {
                             void (^block)(CGRect) = [self.clippingDelegate lf_clippingViewWillBeginZooming:self];
                             if (block) block(self.frame);
                             block = nil;
                         }
                     } completion:^(BOOL finished) {
                         if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndZooming:)]) {
                             [self.clippingDelegate lf_clippingViewDidEndZooming:self];
                         }
                     }];
}

#pragma mark 放大到指定坐标(必须大于当前坐标)
- (void)zoomInToRect:(CGRect)toRect
{
    /** 屏幕在滚动时 不触发该功能 */
    if (self.dragging || self.decelerating) {
        return;
    }
    CGRect zoomingRect = [self convertRect:self.zoomingView.frame toView:self.superview];
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
- (void)rotateClockwise:(BOOL)clockwise
{
    /** 屏幕在滚动时 不触发该功能 */
    if (self.dragging || self.decelerating) {
        return;
    }
    if (!_isRotating) {
        _isRotating = YES;
        
        NSInteger newAngle = self.angle;
        newAngle = clockwise ? newAngle + 90 : newAngle - 90;
        if (newAngle <= -360 || newAngle >= 360)
            newAngle = 0;
        
        _angle = newAngle;

        [UIView animateWithDuration:0.45f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.8f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            
            [self transformRotate:self.angle];
            
            if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginZooming:)]) {
                void (^block)(CGRect) = [self.clippingDelegate lf_clippingViewWillBeginZooming:self];
                if (block) block(self.frame);
            }
            
        } completion:^(BOOL complete) {
            _isRotating = NO;
            if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndZooming:)]) {
                [self.clippingDelegate lf_clippingViewDidEndZooming:self];
            }
        }];
        
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginDragging:)]) {
        [self.clippingDelegate lf_clippingViewWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndDecelerating:)]) {
            [self.clippingDelegate lf_clippingViewDidEndDecelerating:self];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndDecelerating:)]) {
        [self.clippingDelegate lf_clippingViewDidEndDecelerating:self];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.zoomingView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view
{
    if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginZooming:)]) {
        void (^block)(CGRect) = [self.clippingDelegate lf_clippingViewWillBeginZooming:self];
        block(self.frame);
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidZoom:)]) {
        [self.clippingDelegate lf_clippingViewDidZoom:self];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale
{
    if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndZooming:)]) {
        [self.clippingDelegate lf_clippingViewDidEndZooming:self];
    }
}

#pragma mark - 验证当前大小是否被修改
- (BOOL)verifyRect:(CGRect)r_rect
{
    /** 计算缩放率 */
    CGRect rect = CGRectApplyAffineTransform(r_rect, self.transform);
    /** 模糊匹配 */
    BOOL isEqual = CGRectEqualToRect(rect, self.frame);
    
    if (isEqual == NO) {
        /** 精准验证 */
        BOOL x = kRound(CGRectGetMinX(rect)) == kRound(CGRectGetMinX(self.frame));
        BOOL y = kRound(CGRectGetMinY(rect)) == kRound(CGRectGetMinY(self.frame));
        BOOL w = kRound(CGRectGetWidth(rect)) == kRound(CGRectGetWidth(self.frame));
        BOOL h = kRound(CGRectGetHeight(rect)) == kRound(CGRectGetHeight(self.frame));
        isEqual = x && y && w && h;
    }
    return isEqual;
}

#pragma mark - 旋转视图
- (void)transformRotate:(NSInteger)angle
{
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
    
    /** 重置变形 */
    self.transform = CGAffineTransformIdentity;
    CGRect oldRect = self.frame;
    CGFloat width = CGRectGetWidth(oldRect);
    CGFloat height = CGRectGetHeight(oldRect);
    if (angle%180 != 0) { /** 旋转基数时需要互换宽高 */
        CGFloat tempWidth = width;
        width = height;
        height = tempWidth;
    }
    /** 改变变形之前获取偏移量，变形后再计算偏移量比例移动 */
    CGPoint contentOffset = self.contentOffset;
    /** 调整变形 */
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleInRadians);
    self.transform = transform;
    
    /** 计算变形后的坐标拉伸到编辑范围 */
    self.frame = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(width, height), self.editRect);
    /** 重置最小缩放比例 */
    [self resetMinimumZoomScale];
    /** 计算缩放比例 */
    CGFloat scale = MIN(CGRectGetWidth(self.frame) / width, CGRectGetHeight(self.frame) / height);
    /** 转移缩放目标 */
    self.zoomScale *= scale;
    /** 修正旋转后到偏移量 */
    contentOffset.x *= scale;
    contentOffset.y *= scale;
    self.contentOffset = contentOffset;
}

#pragma mark - 重置最小缩放比例
- (void)resetMinimumZoomScale
{
    /** 重置最小缩放比例 */
    CGRect rotateNormalRect = CGRectApplyAffineTransform(self.normalRect, self.transform);
    CGFloat minimumZoomScale = MAX(CGRectGetWidth(self.frame) / CGRectGetWidth(rotateNormalRect), CGRectGetHeight(self.frame) / CGRectGetHeight(rotateNormalRect));
    self.minimumZoomScale = minimumZoomScale;
}

#pragma mark - 重写父类方法

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{    
//    if ([[self.zoomingView subviews] containsObject:view]) {
//        if (event.allTouches.count == 1) { /** 1个手指 */
//            return YES;
//        } else if (event.allTouches.count == 2) { /** 2个手指 */
//            return NO;
//        }
//    }
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
//    if ([[self.zoomingView subviews] containsObject:view]) {
//        return NO;
//    } else if (![[self subviews] containsObject:view]) { /** 非自身子视图 */
//        return NO;
//    }
    return [super touchesShouldCancelInContentView:view];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self.zoomingView) { /** 不触发下一层UI响应 */
        return self;
    }
    return view;
}

#pragma mark - LFEditingProtocol

- (void)setEditDelegate:(id<LFPhotoEditDelegate>)editDelegate
{
    self.zoomingView.editDelegate = editDelegate;
}

- (id<LFPhotoEditDelegate>)editDelegate
{
    return self.zoomingView.editDelegate;
}

/** 禁用其他功能 */
- (void)photoEditEnable:(BOOL)enable
{
    [self.zoomingView photoEditEnable:enable];
}

#pragma mark - 数据
- (NSDictionary *)photoEditData
{
    NSMutableDictionary *data = [@{} mutableCopy];
    
    if ([self canReset]) { /** 可还原证明已编辑过 */
//        CGRect trueFrame = CGRectApplyAffineTransform(self.frame, CGAffineTransformInvert(self.transform));
        NSDictionary *myData = @{kLFClippingViewData_frame:[NSValue valueWithCGRect:self.saveRect]
                                 , kLFClippingViewData_zoomScale:@(self.zoomScale)
                                 , kLFClippingViewData_contentSize:[NSValue valueWithCGSize:self.contentSize]
                                 , kLFClippingViewData_contentOffset:[NSValue valueWithCGPoint:self.contentOffset]
                                 , kLFClippingViewData_minimumZoomScale:@(self.minimumZoomScale)
                                 , kLFClippingViewData_maximumZoomScale:@(self.maximumZoomScale)
                                 , kLFClippingViewData_clipsToBounds:@(self.clipsToBounds)
                                 , kLFClippingViewData_first_minimumZoomScale:@(self.first_minimumZoomScale)
                                 , kLFClippingViewData_transform:[NSValue valueWithCGAffineTransform:self.transform]
                                 , kLFClippingViewData_angle:@(self.angle)};
        [data setObject:myData forKey:kLFClippingViewData];
    }
    
    NSDictionary *zoomingViewData = self.zoomingView.photoEditData;
    if (zoomingViewData) [data setObject:zoomingViewData forKey:kLFClippingViewData_zoomingView];
    
    if (data.count) {
        return data;
    }
    return nil;
}

- (void)setPhotoEditData:(NSDictionary *)photoEditData
{
    NSDictionary *myData = photoEditData[kLFClippingViewData];
    if (myData) {
        self.transform = [myData[kLFClippingViewData_transform] CGAffineTransformValue];
        self.angle = [myData[kLFClippingViewData_angle] integerValue];
        self.saveRect = [myData[kLFClippingViewData_frame] CGRectValue];
        self.frame = self.saveRect;
        self.minimumZoomScale = [myData[kLFClippingViewData_minimumZoomScale] floatValue];
        self.maximumZoomScale = [myData[kLFClippingViewData_maximumZoomScale] floatValue];
        self.zoomScale = [myData[kLFClippingViewData_zoomScale] floatValue];
        self.contentSize = [myData[kLFClippingViewData_contentSize] CGSizeValue];
        self.contentOffset = [myData[kLFClippingViewData_contentOffset] CGPointValue];
        self.clipsToBounds = [myData[kLFClippingViewData_clipsToBounds] boolValue];
        self.first_minimumZoomScale = [myData[kLFClippingViewData_first_minimumZoomScale] floatValue];
    }
    
    self.zoomingView.photoEditData = photoEditData[kLFClippingViewData_zoomingView];
}

#pragma mark - 滤镜功能
/** 滤镜类型 */
- (void)changeFilterColorMatrixType:(LFColorMatrixType)cmType
{
    [self.zoomingView changeFilterColorMatrixType:cmType];
}
/** 当前使用滤镜类型 */
- (LFColorMatrixType)getFilterColorMatrixType
{
    return [self.zoomingView getFilterColorMatrixType];
}
/** 获取滤镜图片 */
- (UIImage *)getFilterImage
{
    return [self.zoomingView getFilterImage];
}

#pragma mark - 绘画功能
/** 启用绘画功能 */
- (void)setDrawEnable:(BOOL)drawEnable
{
    self.zoomingView.drawEnable = drawEnable;
}
- (BOOL)drawEnable
{
    return self.zoomingView.drawEnable;
}

- (BOOL)drawCanUndo
{
    return [self.zoomingView drawCanUndo];
}
- (void)drawUndo
{
    [self.zoomingView drawUndo];
}
/** 设置绘画颜色 */
- (void)setDrawColor:(UIColor *)color
{
    [self.zoomingView setDrawColor:color];
}

#pragma mark - 贴图功能
/** 取消激活贴图 */
- (void)stickerDeactivated
{
    [self.zoomingView stickerDeactivated];
}
- (void)activeSelectStickerView
{
    [self.zoomingView activeSelectStickerView];
}
/** 删除选中贴图 */
- (void)removeSelectStickerView
{
    [self.zoomingView removeSelectStickerView];
}
/** 获取选中贴图的内容 */
- (LFText *)getSelectStickerText
{
    return [self.zoomingView getSelectStickerText];
}
/** 更改选中贴图内容 */
- (void)changeSelectStickerText:(LFText *)text
{
    [self.zoomingView changeSelectStickerText:text];
}

/** 创建贴图 */
- (void)createStickerImage:(UIImage *)image
{
    [self.zoomingView createStickerImage:image];
}

#pragma mark - 文字功能
/** 创建文字 */
- (void)createStickerText:(LFText *)text
{
    [self.zoomingView createStickerText:text];
}

#pragma mark - 模糊功能
/** 启用模糊功能 */
- (void)setSplashEnable:(BOOL)splashEnable
{
    self.zoomingView.splashEnable = splashEnable;
}
- (BOOL)splashEnable
{
    return self.zoomingView.splashEnable;
}
/** 是否可撤销 */
- (BOOL)splashCanUndo
{
    return [self.zoomingView splashCanUndo];
}
/** 撤销模糊 */
- (void)splashUndo
{
    [self.zoomingView splashUndo];
}

- (void)setSplashState:(BOOL)splashState
{
    self.zoomingView.splashState = splashState;
}

- (BOOL)splashState
{
    return self.zoomingView.splashState;
}

@end
