//
//  HXPhotoEditingView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/29.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditingView.h"
#import "HXPhotoClippingView.h"
#import "HXPhotoEditGridView.h"
#import "HXPhotoDefine.h"
#import "UIView+HXExtension.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoEditImageView.h"
#import "HXMECancelBlock.h"
#import "HXPhotoEditConfiguration.h"

#import <AVFoundation/AVFoundation.h>

#define HXMaxZoomScale 2.5f

#define HXClipZoom_margin 20.f
CGFloat const hx_editingView_splashWidth = 50.f;

typedef NS_ENUM(NSUInteger, HXPhotoEditingViewOperation) {
    HXPhotoEditingViewOperationNone = 0,
    HXPhotoEditingViewOperationDragging = 1 << 0,
    HXPhotoEditingViewOperationZooming = 1 << 1,
    HXPhotoEditingViewOperationGridResizing = 1 << 2,
};

NSString *const kHXEditingViewData = @"kHXClippingViewData";

NSString *const kHXEditingViewData_gridView_aspectRatio = @"kHXEditingViewData_gridView_aspectRatio";

NSString *const kHXEditingViewData_clippingView = @"kHXEditingViewData_clippingView";

@interface HXPhotoEditingView ()<UIScrollViewDelegate, HXPhotoClippingViewDelegate, HXPhotoEditGridViewDelegate>

@property (nonatomic, weak) HXPhotoClippingView *clippingView;
@property (nonatomic, weak) HXPhotoEditGridView *gridView;
/**  需要额外创建一层进行缩放处理，理由：UIScrollView的缩放会自动重置transform */
@property (nonatomic, weak) UIView *clipZoomView;

/** 剪裁尺寸, CGRectInset(self.bounds, 20, 50) */
@property (nonatomic, assign) CGRect clippingRect;

/** 显示图片剪裁像素 */
@property (nonatomic, weak) UILabel *imagePixel;

/** 图片像素参照坐标 */
@property (nonatomic, assign) CGSize referenceSize;

/* 底部栏高度 默认60 */
@property (nonatomic, assign) CGFloat editToolbarDefaultHeight;

@property (nonatomic, copy) hx_me_dispatch_cancelable_block_t maskViewBlock;

/** 编辑操作次数记录-有3种编辑操作 拖动、缩放、网格 并且可以同时触发任意2种，避免多次回调代理 */
@property (nonatomic, assign) HXPhotoEditingViewOperation editedOperation;

/** 默认最大化缩放 */
@property (nonatomic, assign) CGFloat defaultMaximumZoomScale;

/** 真实的图片尺寸 */
@property (nonatomic, assign) CGSize imageSize;

/** 默认长宽比例，执行一次 */
@property (nonatomic, assign) NSInteger onceDefaultAspectRatioIndex;

/** 记录剪裁前的数据 */
@property (nonatomic, assign) HXPhotoEditGridViewAspectRatioType old_aspectRatio;

@property (assign, nonatomic) BOOL firstShow;
@end

@implementation HXPhotoEditingView

@synthesize image = _image;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)setup {
    self.firstShow = YES;
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
    self.delegate = self;
    self.clipsToBounds = YES;
    /** 缩放 */
    self.maximumZoomScale = HXMaxZoomScale;
    self.minimumZoomScale = 1.0;
    _editToolbarDefaultHeight = 110.f;
    _defaultMaximumZoomScale = HXMaxZoomScale;
    
    /** 创建缩放层，避免直接缩放LFClippingView，会改变其transform */
    UIView *clipZoomView = [[UIView alloc] initWithFrame:self.bounds];
    clipZoomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    clipZoomView.backgroundColor = [UIColor clearColor];
    [self addSubview:clipZoomView];
    self.clipZoomView = clipZoomView;
    
    /** 创建剪裁层 */
    HXPhotoClippingView *clippingView = [[HXPhotoClippingView alloc] initWithFrame:self.bounds];
    clippingView.clippingDelegate = self;
    [self.clipZoomView addSubview:clippingView];
    self.clippingView = clippingView;
    
    HXPhotoEditGridView *gridView = [[HXPhotoEditGridView alloc] initWithFrame:self.bounds];
    gridView.delegate = self;
    /** 先隐藏剪裁网格 */
    gridView.alpha = 0.f;
    [self addSubview:gridView];
    self.gridView = gridView;
    
    self.clippingMinSize = CGSizeMake(80, 80);
    self.clippingMaxRect = [self refer_clippingRect];
    
    /** 创建显示图片像素控件 */
    UILabel *imagePixel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.hx_w - 40, 30)];
    imagePixel.numberOfLines = 1;
    imagePixel.textAlignment = NSTextAlignmentCenter;
    imagePixel.font = [UIFont boldSystemFontOfSize:13.f];
    imagePixel.textColor = [UIColor whiteColor];
    imagePixel.highlighted = YES;
    imagePixel.highlightedTextColor = [UIColor whiteColor];
    imagePixel.layer.shadowColor = [UIColor blackColor].CGColor;
    imagePixel.layer.shadowOpacity = 1.f;
    imagePixel.layer.shadowOffset = CGSizeMake(0, 0);
    imagePixel.layer.shadowRadius = 8;
    imagePixel.alpha = 0.f;
    [self addSubview:imagePixel];
    self.imagePixel = imagePixel;
     
    [self setSubViewData];
}

- (void)changeSubviewFrame {
    self.clipZoomView.frame = self.bounds;
    self.clippingView.frame = self.bounds;
    [self.clippingView changeSubviewFrame];
    self.gridView.frame = self.bounds;
    self.clippingMaxRect = [self refer_clippingRect];
    self.imagePixel.hx_w = self.hx_w - 40;
    [self setSubViewData];
}
- (void)clearCoverage {
    [self.clippingView clearCoverage];
}
- (void)setOnlyCliping:(BOOL)onlyCliping {
    _onlyCliping = onlyCliping;
    if (onlyCliping) {
        self.gridView.hidden = YES;
        self.imagePixel.hidden = YES;
    }
}
- (void)setConfiguration:(HXPhotoEditConfiguration *)configuration {
    _configuration = configuration;
    if (configuration.onlyCliping && configuration.aspectRatio == HXPhotoEditAspectRatioType_1x1) {
        if (configuration.isRoundCliping) {
            [self.imagePixel removeFromSuperview];
        }
        self.gridView.isRound = configuration.isRoundCliping;
    }
    self.clippingView.configuration = configuration;
}
- (UIEdgeInsets)refer_clippingInsets {
    CGFloat top = HXClipZoom_margin + hxTopMargin;
    CGFloat left = HXClipZoom_margin;
    CGFloat bottom = self.editToolbarDefaultHeight + hxBottomMargin + 20;
    CGFloat right = HXClipZoom_margin;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        top = HXClipZoom_margin + 15;
        left = HXClipZoom_margin + hxTopMargin;
        bottom = self.editToolbarDefaultHeight + HXClipZoom_margin + 15;
        right = left;
    }
    return UIEdgeInsetsMake(top, left, bottom, right);
}

- (CGRect)refer_clippingRect {
    UIEdgeInsets insets = [self refer_clippingInsets];
    
    CGRect referRect = self.bounds;
    referRect.origin.x += insets.left;
    referRect.origin.y += insets.top;
    referRect.size.width -= (insets.left+insets.right);
    referRect.size.height -= (insets.top+insets.bottom);
    
    return referRect;
}

- (void)setImage:(UIImage *)image {
    _image = image;
    if (image) {
        _imageSize = image.size;
        CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(self.imageSize, self.bounds);
        
        /** 参数取整，否则可能会出现1像素偏差 */
//        cropRect = HXMediaEditProundRect(cropRect);
        
        self.gridView.controlSize = cropRect.size;
        self.gridView.gridRect = cropRect;
        self.gridView.aspectRatioHorizontally = (self.imageSize.width > self.imageSize.height);
        self.imagePixel.center = CGPointMake(CGRectGetMidX(cropRect), CGRectGetMidY(cropRect));
        /** 调整最大缩放比例 */
        {
            if (cropRect.size.width < cropRect.size.height) {
                self.defaultMaximumZoomScale = self.frame.size.width * HXMaxZoomScale / cropRect.size.width;
            } else {
                self.defaultMaximumZoomScale = self.frame.size.height * HXMaxZoomScale / cropRect.size.height;
            }
            self.maximumZoomScale = self.defaultMaximumZoomScale;
        }
        self.clippingView.frame = cropRect;
    }
    [self.clippingView setImage:image];
    
    /** 计算图片像素参照坐标 */
    self.referenceSize = AVMakeRectWithAspectRatioInsideRect(self.clippingView.hx_size, self.clippingMaxRect).size;
    
    /** 针对长图的展示 */
    [self fixedLongImage];
}

- (void)setClippingRect:(CGRect)clippingRect {
    if (self.isClipping) {
        CGFloat clippingMinY = CGRectGetMinY(self.clippingMaxRect);
        if (clippingRect.origin.y < clippingMinY) {
            clippingRect.origin.y = clippingMinY;
        }
        CGFloat clippingMaxY = CGRectGetMaxY(self.clippingMaxRect);
        if (CGRectGetMaxY(clippingRect) > clippingMaxY) {
            clippingRect.size.height = self.clippingMaxRect.size.height;
        }
        CGFloat clippingMinX = CGRectGetMinX(self.clippingMaxRect);
        if (clippingRect.origin.x < clippingMinX) {
            clippingRect.origin.x = clippingMinX;
        }
        CGFloat clippingMaxX = CGRectGetMaxX(self.clippingMaxRect);
        if (CGRectGetMaxX(clippingRect) > clippingMaxX) {
            clippingRect.size.width = self.clippingMaxRect.size.width;
        }
        
        /** 调整最小尺寸 */
        CGSize clippingMinSize = self.clippingMinSize;
        if (clippingMinSize.width > clippingRect.size.width) {
            clippingMinSize.width = clippingRect.size.width;
        }
        if (clippingMinSize.height > clippingRect.size.height) {
            clippingMinSize.height = clippingRect.size.height;
        }
        self.clippingMinSize = clippingMinSize;
    }
    _clippingRect = clippingRect;
    self.gridView.gridRect = clippingRect;
    UIEdgeInsets insets = [self refer_clippingInsets];
    /** 计算clippingView与父界面的中心偏差坐标 */
    self.clippingView.offsetSuperCenter = self.isClipping ? CGPointMake(insets.right-insets.left, insets.bottom-insets.top) : CGPointZero;
    self.clippingView.cropRect = clippingRect;
    self.imagePixel.center = CGPointMake(CGRectGetMidX(self.gridView.gridRect), CGRectGetMidY(self.gridView.gridRect));
}

- (void)setClippingMinSize:(CGSize)clippingMinSize {
    if (CGSizeEqualToSize(CGSizeZero, _clippingMinSize) || (clippingMinSize.width < CGRectGetWidth(_clippingMaxRect) && clippingMinSize.height < CGRectGetHeight(_clippingMaxRect))) {
        
        CGSize normalClippingMinSize = AVMakeRectWithAspectRatioInsideRect(self.clippingView.hx_size, [self refer_clippingRect]).size;
        /** 需要考虑到旋转后到尺寸可能会更加小，取最小值 */
        CGSize rotateClippingMinSize = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(self.clippingView.hx_size.height, self.clippingView.hx_size.width), [self refer_clippingRect]).size;
        
        CGSize newClippingMinSize = CGSizeMake(MIN(normalClippingMinSize.width, rotateClippingMinSize.width), MIN(normalClippingMinSize.height, rotateClippingMinSize.height));
        {
            if (clippingMinSize.width > newClippingMinSize.width) {
                clippingMinSize.width = newClippingMinSize.width;
            }
            if (clippingMinSize.height > newClippingMinSize.height) {
                clippingMinSize.height = newClippingMinSize.height;
            }
        }
        
        _clippingMinSize = clippingMinSize;
        self.gridView.controlMinSize = clippingMinSize;
    }
}

- (void)setClippingMaxRect:(CGRect)clippingMaxRect {
    if (CGRectEqualToRect(CGRectZero, _clippingMaxRect) || (CGRectGetWidth(clippingMaxRect) > _clippingMinSize.width && CGRectGetHeight(clippingMaxRect) > _clippingMinSize.height)) {
        
        CGRect newClippingMaxRect = [self refer_clippingRect];
        
        if (clippingMaxRect.origin.y < newClippingMaxRect.origin.y) {
            clippingMaxRect.origin.y = newClippingMaxRect.origin.y;
        }
        if (clippingMaxRect.origin.x < newClippingMaxRect.origin.x) {
            clippingMaxRect.origin.x = newClippingMaxRect.origin.x;
        }
        if (CGRectGetMaxY(clippingMaxRect) > CGRectGetMaxY(newClippingMaxRect)) {
            clippingMaxRect.size.height = newClippingMaxRect.size.height;
        }
        if (CGRectGetMaxX(clippingMaxRect) > CGRectGetMaxX(newClippingMaxRect)) {
            clippingMaxRect.size.width = newClippingMaxRect.size.width;
        }
        
        _clippingMaxRect = clippingMaxRect;
        self.gridView.controlMaxRect = clippingMaxRect;
        self.clippingView.editRect = clippingMaxRect;
        /** 计算缩放剪裁尺寸 */
        self.referenceSize = AVMakeRectWithAspectRatioInsideRect(self.clippingView.hx_size, self.clippingMaxRect).size;
    }
}

- (void)setClipping:(BOOL)clipping {
    [self setClipping:clipping animated:NO];
}
- (void)setClipping:(BOOL)clipping animated:(BOOL)animated {
    [self setClipping:clipping animated:animated completion:nil];
}
- (void)setClipping:(BOOL)clipping animated:(BOOL)animated completion:(void (^)(void))completion {
    if (!self.image) {
        /** 没有图片禁止开启编辑模式 */
        if (completion) {
            completion();
        }
        return;
    }
    self.editedOperation = HXPhotoEditingViewOperationNone;
    _clipping = clipping;
    self.clippingView.useGesture = clipping;
    
    self.old_aspectRatio = self.gridView.aspectRatio;
    if (self.onceDefaultAspectRatioIndex && clipping) {
        self.old_aspectRatio = self.onceDefaultAspectRatioIndex;
    }
    if (clipping) {
        if ([self.clippingDelegate respondsToSelector:@selector(editingViewWillAppearClip:)]) {
            [self.clippingDelegate editingViewWillAppearClip:self];
        }
    } else {
        [self.clippingView setContentOffset:self.clippingView.contentOffset animated:NO];
        if ([self.clippingDelegate respondsToSelector:@selector(editingViewWillDisappearClip:)]) {
            [self.clippingDelegate editingViewWillDisappearClip:self];
        }
    }
    if (clipping) {
        [UIView animateWithDuration:(animated ? 0.125f : 0) animations:^{
            [self setZoomScale:self.minimumZoomScale];
            /** 关闭缩放 */
            self.maximumZoomScale = self.minimumZoomScale;
            /** 重置contentSize */
            [self resetContentSize:NO];
        }];
    } else {
        self.maximumZoomScale = MIN(MAX(self.minimumZoomScale + self.defaultMaximumZoomScale - self.defaultMaximumZoomScale * (self.clippingView.zoomScale/self.clippingView.maximumZoomScale), self.minimumZoomScale), self.defaultMaximumZoomScale);
    }
    
    if (clipping) {
        /** 动画切换 */
        if (animated) {

            __block BOOL hasOnceIndex = NO;
            [UIView animateWithDuration:0.2f animations:^{
                self.clippingRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.hx_size, [self refer_clippingRect]);
                
            } completion:^(BOOL finished) {
                if (!self.firstShow) {
                    self.gridView.alpha = 1.f;
                }

                /** 显示多余部分 */
                self.clippingView.clipsToBounds = NO;
                if (self.onceDefaultAspectRatioIndex) {
                    /** 代理优先执行，下面可能是编辑操作，gridView.gridRect会发生改变，影响计算结果 */
                    if ([self.clippingDelegate respondsToSelector:@selector(editingViewDidAppearClip:)]) {
                        [self.clippingDelegate editingViewDidAppearClip:self];
                    }
                    [self.gridView setAspectRatio:self.onceDefaultAspectRatioIndex animated:YES];
                    self.onceDefaultAspectRatioIndex = 0;
                    self.gridView.maskColor = [[UIColor blackColor] colorWithAlphaComponent:0.6].CGColor;
                    hasOnceIndex = YES;
                }else {
                    self.gridView.maskColor = [[UIColor blackColor] colorWithAlphaComponent:0.6].CGColor;
                }
                self.gridView.gridLayer.gridColor = [UIColor whiteColor];
                [self.gridView.gridLayer setGridRect:self.gridView.gridRect animated:YES];
                [UIView animateWithDuration:0.25f animations:^{
                    if (!self.firstShow) {
                        self.imagePixel.alpha = 1.f;
                    }
                    
                    if (!self.onceDefaultAspectRatioIndex && !hasOnceIndex) {
                        /** 处理缩放比例 */
                        [self gridViewDidAspectRatio:self.gridView];
                        /** 代理延迟执行，因为gridView.gridRect并没有发生改变，等待clippingView的大小调整后触发 */
                        if ([self.clippingDelegate respondsToSelector:@selector(editingViewDidAppearClip:)]) {
                            [self.clippingDelegate editingViewDidAppearClip:self];
                        }
                    }else {
                        if (self.firstShow && self.fixedAspectRatio) {
                            /** 处理缩放比例 */
                            [self gridViewDidAspectRatio:self.gridView];
                        }
                    }
                } completion:^(BOOL finished) {
                    if (completion) {
                        completion();
                    }
                }];
            }];
        } else {
            self.clippingRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.hx_size, [self refer_clippingRect]);
            self.gridView.alpha = 1.f;
            self.imagePixel.alpha = 1.f;
            self.gridView.maskColor = [[UIColor blackColor] colorWithAlphaComponent:0.6].CGColor;
            self.gridView.gridLayer.gridColor = [UIColor whiteColor];
            [self.gridView.gridLayer setGridRect:self.gridView.gridRect animated:NO];
            /** 显示多余部分 */
            self.clippingView.clipsToBounds = NO;
            
            if (self.onceDefaultAspectRatioIndex) {
                if ([self.clippingDelegate respondsToSelector:@selector(editingViewDidAppearClip:)]) {
                    [self.clippingDelegate editingViewDidAppearClip:self];
                }
                [self.gridView setAspectRatio:self.onceDefaultAspectRatioIndex animated:YES];
                self.onceDefaultAspectRatioIndex = 0;
            } else {
                /** 处理缩放比例 */
                [self gridViewDidAspectRatio:self.gridView];
                if ([self.clippingDelegate respondsToSelector:@selector(editingViewDidAppearClip:)]) {
                    [self.clippingDelegate editingViewDidAppearClip:self];
                }
            }
            if (completion) {
                completion();
            }
        }
        [self updateImagePixelText];
    } else {
        /** 重置最大缩放 */
        if (animated) {
            /** 剪裁多余部分 */
            self.clippingView.clipsToBounds = YES;
            [UIView animateWithDuration:0.1f animations:^{
                self.gridView.alpha = 0.f;
                self.imagePixel.alpha = 0.f;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.25f animations:^{
                    CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.hx_size, self.bounds);
                    self.clippingRect = cropRect;
                }];
                
                [UIView animateWithDuration:0.125f delay:0.125f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    /** 针对长图的展示 */
                    [self fixedLongImage];
                } completion:^(BOOL finished) {
                    self.gridView.maskColor = [UIColor blackColor].CGColor;
                    self.gridView.gridLayer.gridColor = [UIColor clearColor];
                    if ([self.clippingDelegate respondsToSelector:@selector(editingViewDidDisappearClip:)]) {
                        [self.clippingDelegate editingViewDidDisappearClip:self];
                    }
                    self.clippingView.imageView.stickerView.angle = self.clippingView.angle;
                    self.clippingView.imageView.stickerView.mirrorType = self.clippingView.mirrorType;
                    if (completion) {
                        completion();
                    }
                }];
                
            }];
        } else {
            /** 剪裁多余部分 */
            self.clippingView.clipsToBounds = YES;
            self.gridView.alpha = 0.f;
            self.imagePixel.alpha = 0.f;
            CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.hx_size, self.bounds);
            self.clippingRect = cropRect;
            /** 针对长图的展示 */
            [self fixedLongImage];
            if ([self.clippingDelegate respondsToSelector:@selector(editingViewDidDisappearClip:)]) {
                [self.clippingDelegate editingViewDidDisappearClip:self];
            }
            self.clippingView.imageView.stickerView.angle = self.clippingView.angle;
            self.clippingView.imageView.stickerView.mirrorType = self.clippingView.mirrorType;
            if (completion) {
                completion();
            }
        }
    }
}

/** 取消剪裁 */
- (void)cancelClipping:(BOOL)animated {
    [self.clippingView setContentOffset:self.clippingView.contentOffset animated:NO];
    self.editedOperation = HXPhotoEditingViewOperationNone;
    _clipping = NO;
    self.clippingView.useGesture = _clipping;
    if ([self.clippingDelegate respondsToSelector:@selector(editingViewWillDisappearClip:)]) {
        [self.clippingDelegate editingViewWillDisappearClip:self];
    }
    
    /** 剪裁多余部分 */
    if (animated) {
        self.clippingView.clipsToBounds = YES;
        [UIView animateWithDuration:0.1f animations:^{
            self.imagePixel.alpha = 0.f;
            self.gridView.alpha = 0.f;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15f animations:^{
                [self cancel];
            }];
            [UIView animateWithDuration:0.15f delay:0.1f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                /** 针对长图的展示 */
                [self fixedLongImage];
            } completion:^(BOOL finished) {
                self.gridView.maskColor = [UIColor blackColor].CGColor;
                self.gridView.gridLayer.gridColor = [UIColor clearColor];
                if ([self.clippingDelegate respondsToSelector:@selector(editingViewDidDisappearClip:)]) {
                    [self.clippingDelegate editingViewDidDisappearClip:self];
                }
                self.clippingView.imageView.stickerView.angle = self.clippingView.angle;
                self.clippingView.imageView.stickerView.mirrorType = self.clippingView.mirrorType;
            }];
        }];
    } else {
        self.clippingView.clipsToBounds = YES;
        self.imagePixel.alpha = 0.f;
        self.gridView.alpha = 0.f;
        self.gridView.maskColor = [UIColor blackColor].CGColor;
        self.gridView.gridLayer.gridColor = [UIColor clearColor];
        [self cancel];
        /** 针对长图的展示 */
        [self fixedLongImage];
        if ([self.clippingDelegate respondsToSelector:@selector(editingViewDidDisappearClip:)]) {
            [self.clippingDelegate editingViewDidDisappearClip:self];
        }
        self.clippingView.imageView.stickerView.angle = self.clippingView.angle;
        self.clippingView.imageView.stickerView.mirrorType = self.clippingView.mirrorType;
    }
}

- (void)cancel {
    [self.clippingView cancel];
    _clippingRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.hx_size, self.bounds);
    UIEdgeInsets insets = [self refer_clippingInsets];
    /** 计算clippingView与父界面的中心偏差坐标 */
    self.clippingView.offsetSuperCenter = self.isClipping ? CGPointMake(insets.right-insets.left, insets.bottom-insets.top) : CGPointZero;
    
    self.gridView.gridRect = self.clippingView.frame;
    [self.gridView setAspectRatioWithoutDelegate:self.old_aspectRatio];
    self.imagePixel.center = CGPointMake(CGRectGetMidX(self.gridView.gridRect), CGRectGetMidY(self.gridView.gridRect));
    
    CGFloat max = MAX(self.minimumZoomScale + self.defaultMaximumZoomScale - self.defaultMaximumZoomScale * (self.clippingView.zoomScale / self.clippingView.maximumZoomScale), self.minimumZoomScale);
    self.maximumZoomScale = MIN(max, self.defaultMaximumZoomScale);
}
- (void)resetToRridRectWithAspectRatioIndex:(NSInteger)aspectRatioIndex {
    CGRect oldGridRect = self.gridView.gridRect;
    self.onceDefaultAspectRatioIndex = 0;
    [self.gridView setupAspectRatio:(HXPhotoEditGridViewAspectRatioType)aspectRatioIndex];
    CGRect newGridRect = self.gridView.gridRect;
    BOOL isSame = CGRectEqualToRect(oldGridRect, newGridRect);
    if (!isSame && aspectRatioIndex != 0) {
        self.gridView.showMaskLayer = NO;
        [UIView animateWithDuration:0.25 animations:^{
            /** 放大 */
            [self.clippingView zoomInToRect:self.gridView.gridRect];
            /** 图片像素 */
            [self updateImagePixelText];
            /** 缩小 */
            [self.clippingView zoomOutToRect:self.gridView.gridRect];
        }];
    }
}
/** 还原 */
- (void)reset {
    if (self.isClipping) {
        /** 若可以调整长宽比例，则重置它，否则保留默认值 */
        [self setAspectRatioIndex:0];
        if (self.fixedAspectRatio) {
            [self.clippingView resetToRect:self.gridView.gridRect];
        } else {
            [self.clippingView reset];
        }
    }
}
- (void)resetRotateAngle {
    [self.clippingView resetRotateAngle];
}
- (BOOL)canReset {
    if (self.isClipping) {
        if (self.fixedAspectRatio) {
            return [self.clippingView canResetWithRect:self.gridView.gridRect];
        } else {
            return self.clippingView.canReset;
        }
    }
    return NO;
}

/** 旋转 isClipping=YES 的情况有效 */
- (void)rotate {
    if (self.isClipping) {
        [self.clippingView rotateClockwise:NO];
    }
}

/// 镜像翻转
- (void)mirrorFlip {
    if (self.isClipping) {
        [self.clippingView mirrorFlip];
    }
}

/** 默认长宽比例 */
- (void)setDefaultAspectRatioIndex:(NSUInteger)defaultAspectRatioIndex {
    _defaultAspectRatioIndex = defaultAspectRatioIndex;
    _onceDefaultAspectRatioIndex = defaultAspectRatioIndex;
}

/** 长宽比例 */
- (void)setAspectRatioIndex:(NSUInteger)aspectRatioIndex {
    [self setAspectRatioIndex:(HXPhotoEditGridViewAspectRatioType)aspectRatioIndex animated:NO];
}
- (void)setAspectRatioIndex:(NSUInteger)aspectRatioIndex animated:(BOOL)animated {
    if (self.fixedAspectRatio) return;
    self.gridView.showMaskLayer = NO;
    self.onceDefaultAspectRatioIndex = 0;
    [self.gridView setAspectRatio:(HXPhotoEditGridViewAspectRatioType)aspectRatioIndex animated:animated];
}

- (void)setCustomRatioSize:(CGSize)customRatioSize {
    _customRatioSize = customRatioSize;
    self.gridView.customRatioSize = customRatioSize;
}

- (void)setFixedAspectRatio:(BOOL)fixedAspectRatio {
    _fixedAspectRatio = fixedAspectRatio;
    self.clippingView.fixedAspectRatio = fixedAspectRatio;
}

- (NSArray <NSString *>*)aspectRatioDescs {
    if (self.fixedAspectRatio) nil;
    return [self.gridView aspectRatioDescs];
}

- (NSUInteger)aspectRatioIndex {
    if (self.fixedAspectRatio) return 0;
    HXPhotoEditGridViewAspectRatioType type = self.gridView.aspectRatio;
    return (NSUInteger)type;
}

/** 补底操作-多手势同时触发时，部分逻辑没有实时处理，当手势完全停止后补充处理 */
- (void)supplementHandle {
    if (!CGRectEqualToRect(self.gridView.gridRect, self.clippingView.frame)) {
        self.gridView.showMaskLayer = NO;
        hx_me_dispatch_cancel(self.maskViewBlock);
        [self.clippingView zoomOutToRect:self.gridView.gridRect];
    }
}

/** 创建编辑图片 */
- (void)createEditImage:(void (^)(UIImage *editImage))complete {
    CGFloat scale = self.clippingView.zoomScale;
//    CGAffineTransform trans = self.clippingView.transform;
    CGPoint contentOffset = self.clippingView.contentOffset;
//    CGSize contentSize = self.clippingView.contentSize;
    CGRect clippingRect = self.clippingView.frame;
    
    /** 参数取整，否则可能会出现1像素偏差 */
//    clippingRect = HXMediaEditProundRect(clippingRect);
    
    CGSize size = clippingRect.size;
//    CGFloat rotate = acosf(trans.a);
//    if (trans.b < 0) {
//        rotate = M_PI-asinf(trans.b);
//    }
    CGFloat rotate = M_PI * (self.clippingView.angle) / 180.0;
    if (rotate != 0) {
        rotate = 2 * M_PI + rotate;
    }
    
    /** 获取编辑图层视图 */
    UIImage *otherImage = [self.clippingView editOtherImagesInRect:clippingRect rotate:rotate];
    
    __block UIImage *editImage = self.image;
    CGRect clipViewRect = AVMakeRectWithAspectRatioInsideRect(self.imageSize, self.bounds);
    /** UIScrollView的缩放率 * 剪裁尺寸变化比例 / 图片屏幕缩放率 */
    CGFloat clipScale = scale * (clipViewRect.size.width/(self.imageSize.width*editImage.scale));
    /** 计算被剪裁的原尺寸图片位置 */
    CGRect clipRect;
    
    if (self.clippingView.angle % 180 != 0) {
        // 横向
        clipRect = CGRectMake(contentOffset.x/clipScale, contentOffset.y/clipScale, size.height/clipScale, size.width/clipScale);
    } else {
        clipRect = CGRectMake(contentOffset.x/clipScale, contentOffset.y/clipScale, size.width/clipScale, size.height/clipScale);
    }
    /** 参数取整，否则可能会出现1像素偏差 */
//    clipRect = HXMediaEditProundRect(clipRect);
    
    NSInteger angle = labs(self.clippingView.angle);
    BOOL isHorizontal = self.clippingView.mirrorType == HXPhotoClippingViewMirrorType_Horizontal;
    BOOL isRoundCliping = self.configuration.isRoundCliping;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /** 创建方法 */
        UIImage *(^ClipEditImage)(UIImage *) = ^UIImage * (UIImage *image) {
            UIImage *returnedImage = nil;
            @autoreleasepool {
                /** 剪裁图片 */
                returnedImage = [image hx_cropInRect:clipRect];
                if (isRoundCliping) {
                    returnedImage = [returnedImage hx_roundClipingImage];
                }
                if (rotate > 0 || isHorizontal) {
                    /** 调整角度 */
                    if (angle == 0 || angle == 360) {
                        if (isHorizontal) {
                            returnedImage = [returnedImage hx_rotationImage:UIImageOrientationUpMirrored];
                        }
                    }else if (angle == 90) {
                        if (!isHorizontal) {
                            returnedImage = [returnedImage hx_rotationImage:UIImageOrientationLeft];
                        }else {
                            returnedImage = [returnedImage hx_rotationImage:UIImageOrientationRightMirrored];
                        }
                    }else if (angle == 180) {
                        if (!isHorizontal) {
                            returnedImage = [returnedImage hx_rotationImage:UIImageOrientationDown];
                        }else {
                            returnedImage = [returnedImage hx_rotationImage:UIImageOrientationDownMirrored];
                        }
                    }else if (angle == 270) {
                        if (!isHorizontal) {
                            returnedImage = [returnedImage hx_rotationImage:UIImageOrientationRight];
                        }else {
                            returnedImage = [returnedImage hx_rotationImage:UIImageOrientationLeftMirrored];
                        }
                    }
                }
                if (otherImage) {
                    UIImage *scaleOtherImage = [otherImage hx_scaleToFillSize:returnedImage.size];
                    if (scaleOtherImage) {
                        /** 合并图层 */
                        NSArray *otherImages = @[scaleOtherImage];
                        returnedImage = [returnedImage hx_mergeimages:otherImages];
                    }
                }
                return returnedImage;
            }
        };
        editImage = ClipEditImage(editImage);
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *resultImage = editImage;
            
            if (!resultImage) {
                /** 合并操作有误，直接截取原始图层 */
                resultImage = [self.clipZoomView hx_captureImageAtFrame:self.clippingView.frame];
                self.clipZoomView.layer.contents = (id)nil;
            }
            
            if (complete) {
                complete(resultImage);
            }
        });
    });
}

#pragma mark - HXPhotoClippingViewDelegate
- (void (^)(CGRect))clippingViewWillBeginZooming:(HXPhotoClippingView *)clippingView {
    if (self.editedOperation == HXPhotoEditingViewOperationNone && [self.clippingDelegate respondsToSelector:@selector(editingViewWillBeginEditing:)]) {
        [self.clippingDelegate editingViewWillBeginEditing:self];
    }
    self.editedOperation |= HXPhotoEditingViewOperationZooming;
    
    __weak typeof(self) weakSelf = self;
    void (^block)(CGRect) = ^(CGRect rect){
        if (clippingView.isReseting || clippingView.isRotating || clippingView.isMirrorFlip) { /** 重置/旋转 需要将遮罩显示也重置 */
            [weakSelf.gridView setGridRect:rect maskLayer:YES animated:YES];
        } else if (clippingView.isZooming) { /** 缩放 */
            weakSelf.gridView.showMaskLayer = NO;
            hx_me_dispatch_cancel(weakSelf.maskViewBlock);
        } else {
            if (weakSelf.firstShow) {
                weakSelf.gridView.alpha = 0;
                weakSelf.imagePixel.alpha = 0;
                weakSelf.gridView.hidden = NO;
                weakSelf.imagePixel.hidden = NO;
                [UIView animateWithDuration:0.2 animations:^{
                    weakSelf.gridView.alpha = 1;
                    weakSelf.imagePixel.alpha = 1;
                }];
                weakSelf.firstShow = NO;
            }
            [weakSelf.gridView setGridRect:rect animated:YES];
        }
        
        /** 图片像素 */
        [weakSelf updateImagePixelText];
    };
    
    return block;
}
- (void)clippingViewDidZoom:(HXPhotoClippingView *)clippingView {
    if (clippingView.zooming) {
        [self updateImagePixelText];
    }
}
- (void)clippingViewDidEndZooming:(HXPhotoClippingView *)clippingView {
    if (self.editedOperation & HXPhotoEditingViewOperationZooming) {
        self.editedOperation ^= HXPhotoEditingViewOperationZooming;
    }
    __weak typeof(self) weakSelf = self;
    self.maskViewBlock = hx_dispatch_block_t(0.25f, ^{
        [weakSelf updateImagePixelText];
        
        if (weakSelf.editedOperation == HXPhotoEditingViewOperationNone) {
            if (!weakSelf.gridView.isDragging) {
                if ([weakSelf.clippingDelegate respondsToSelector:@selector(editingViewDidEndEditing:)]) {
                    [weakSelf.clippingDelegate editingViewDidEndEditing:weakSelf];
                }
                weakSelf.gridView.showMaskLayer = YES;
            }
        }
        
    });
}

- (void)clippingViewWillBeginDragging:(HXPhotoClippingView *)clippingView {
    if (self.editedOperation == HXPhotoEditingViewOperationNone && [self.clippingDelegate respondsToSelector:@selector(editingViewWillBeginEditing:)]) {
        [self.clippingDelegate editingViewWillBeginEditing:self];
    }
    self.editedOperation |= HXPhotoEditingViewOperationDragging;
    /** 移动开始，隐藏 */
    self.gridView.showMaskLayer = NO;
    hx_me_dispatch_cancel(self.maskViewBlock);
}
- (void)clippingViewDidEndDecelerating:(HXPhotoClippingView *)clippingView {
    /** 移动结束，显示 */
    if (!self.gridView.isDragging && !CGRectEqualToRect(self.gridView.gridRect, self.clippingView.frame)) {
        [self supplementHandle];
        if (self.editedOperation & HXPhotoEditingViewOperationDragging) {
            self.editedOperation ^= HXPhotoEditingViewOperationDragging;
        }
    } else {
        if (self.editedOperation & HXPhotoEditingViewOperationDragging) {
            self.editedOperation ^= HXPhotoEditingViewOperationDragging;
        }
        __weak typeof(self) weakSelf = self;
        self.maskViewBlock = hx_dispatch_block_t(0.25f, ^{
            if (weakSelf.editedOperation == HXPhotoEditingViewOperationNone) {
                if (!weakSelf.gridView.isDragging) {
                    if ([weakSelf.clippingDelegate respondsToSelector:@selector(editingViewDidEndEditing:)]) {
                        [weakSelf.clippingDelegate editingViewDidEndEditing:weakSelf];
                    }
                    weakSelf.gridView.showMaskLayer = YES;
                }
            }
        });
    }
}

- (void)photoEditEnable:(BOOL)enable {
    self.clippingView.imageView.drawView.enabled = enable;
    self.clippingView.imageView.stickerView.userInteractionEnabled = enable;

    if (enable) {
        self.clippingView.imageView.splashView.userInteractionEnabled = self.clippingView.imageView.splashViewEnable;
    } else {
        self.clippingView.imageView.splashViewEnable = self.clippingView.imageView.splashView.userInteractionEnabled;
        self.clippingView.imageView.splashView.userInteractionEnabled = NO;
    }
}
#pragma mark - HXPhotoEditGridViewDelegate
- (void)gridViewDidBeginResizing:(HXPhotoEditGridView *)gridView {
    if (self.editedOperation == HXPhotoEditingViewOperationNone && [self.clippingDelegate respondsToSelector:@selector(editingViewWillBeginEditing:)]) {
        [self.clippingDelegate editingViewWillBeginEditing:self];
    }
    self.editedOperation |= HXPhotoEditingViewOperationGridResizing;
    [self.clippingView setContentOffset:self.clippingView.contentOffset animated:NO];
    gridView.showMaskLayer = NO;
    hx_me_dispatch_cancel(self.maskViewBlock);
}
- (void)gridViewDidResizing:(HXPhotoEditGridView *)gridView {
    /** 放大 */
    [self.clippingView zoomInToRect:gridView.gridRect];
    
    /** 图片像素 */
    [self updateImagePixelText];
}
- (void)gridViewDidEndResizing:(HXPhotoEditGridView *)gridView {
    /** 缩小 */
    [self.clippingView zoomOutToRect:gridView.gridRect];
    if (self.editedOperation & HXPhotoEditingViewOperationGridResizing) {
        self.editedOperation ^= HXPhotoEditingViewOperationGridResizing;
    }
}
/** 调整长宽比例 */
- (void)gridViewDidAspectRatio:(HXPhotoEditGridView *)gridView {
    if (!CGRectEqualToRect(HXRoundFrameHundreds(gridView.gridRect), HXRoundFrameHundreds(self.clippingView.frame))) {
        self.editedOperation |= HXPhotoEditingViewOperationGridResizing;
        gridView.showMaskLayer = NO;
        hx_me_dispatch_cancel(self.maskViewBlock);
        if (self.firstShow && self.onlyCliping) {
            [UIView animateWithDuration:0.2 animations:^{
                /** 放大 */
                [self.clippingView zoomInToRect:gridView.gridRect];
                
                /** 图片像素 */
                [self updateImagePixelText];
                
                /** 缩小 */
                [self.clippingView zoomOutToRect:gridView.gridRect];
            }];
        }else {
            /** 放大 */
            [self.clippingView zoomInToRect:gridView.gridRect];
            
            /** 图片像素 */
            [self updateImagePixelText];
            
            /** 缩小 */
            [self.clippingView zoomOutToRect:gridView.gridRect];
        }
        if (self.editedOperation & HXPhotoEditingViewOperationGridResizing) {
            self.editedOperation ^= HXPhotoEditingViewOperationGridResizing;
        }
    }else {
        if (self.firstShow) {
            self.gridView.alpha = 0;
            self.imagePixel.alpha = 0;
            self.gridView.hidden = NO;
            self.imagePixel.hidden = NO;
            [UIView animateWithDuration:0.2 animations:^{
                self.gridView.alpha = 1;
                self.imagePixel.alpha = 1;
            }];
            self.firstShow = NO;
        }
    }
}

#pragma mark - UIScrollViewDelegate
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.clipZoomView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    self.contentInset = UIEdgeInsetsZero;
    self.scrollIndicatorInsets = UIEdgeInsetsZero;
    [self refreshImageZoomViewCenter];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    /** 重置contentSize */
    [self resetContentSize:YES];
    if ([self.clippingDelegate respondsToSelector:@selector(editingViewViewDidEndZooming:)]) {
        [self.clippingDelegate editingViewViewDidEndZooming:self];
    }
}


#pragma mark - 重写父类方法
- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    if (!([[self subviews] containsObject:view] || [[self.clipZoomView subviews] containsObject:view])) { /** 非自身子视图 */
        if (event.allTouches.count == 2) { /** 2个手指 */
            return NO;
        } else {
            /** 因为关闭了手势延迟，2指缩放时，但屏幕未能及时检测到2指，导致不会进入event.allTouches.count == 2的判断，随后屏幕检测到2指，从而重新触发hitTest:withEvent:，需要重新指派正确的手势响应对象。 */
        }
    }
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    /**
     如果返回YES:(系统默认)是允许UIScrollView，按照消息响应链向子视图传递消息的
     如果返回NO:UIScrollView,就接收不到滑动事件了。
     */
    if (!([[self subviews] containsObject:view] || [[self.clipZoomView subviews] containsObject:view])) {
        if ([self drawEnable] || [self splashEnable] || [self stickerEnable] ) {
            /**
             编辑视图正在编辑时，优先处理。
             这里不用条件判断，gestureRecognizer:shouldReceiveTouch:时已经对手势进行筛选了。
             */
        } else {
            /** 非自身子视图 */
            return NO;
        }
    }
    return [super touchesShouldCancelInContentView:view];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (!self.isClipping && (self.clippingView == view || self.clipZoomView == view)) { /** 非编辑状态，改变触发响应最顶层的scrollView */
        view = self;
    } else if (self.isClipping && (view == self || self.clipZoomView == view)) {
        view = self.clippingView;
    }
    return view;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    /** 解决部分机型在编辑期间会触发滑动导致无法编辑的情况 */
    if (self.isClipping) {
        /** 自身手势被触发、响应视图非自身、被触发手势为滑动手势 */
        return NO;
    } else if ([self drawEnable] && ![gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        /** 绘画时候，禁用滑动手势 */
        return NO;
    } else if ([self splashEnable] && ![gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        /** 模糊时候，禁用滑动手势 */
        return NO;
    } else if ([self stickerEnable] && ![gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        /** 贴图移动时候，禁用滑动手势 */
        return NO;
    }
    return YES;
}

#pragma mark - Private
- (void)refreshImageZoomViewCenter {
    CGFloat offsetX = (self.hx_w > self.contentSize.width) ? ((self.hx_w - self.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (self.hx_h > self.contentSize.height) ? ((self.hx_h - self.contentSize.height) * 0.5) : 0.0;
    self.clipZoomView.center = CGPointMake(self.contentSize.width * 0.5 + offsetX, self.contentSize.height * 0.5 + offsetY);
}

- (void)resetContentSize:(BOOL)animation {
    /** 重置contentSize */
    CGRect realClipZoomRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.hx_size, self.clipZoomView.frame);
    CGFloat width = MAX(self.frame.size.width, realClipZoomRect.size.width);
    CGFloat height = MAX(self.frame.size.height, realClipZoomRect.size.height);
    CGFloat diffWidth = (width - self.clipZoomView.frame.size.width) / 2;
    CGFloat diffHeight = (height - self.clipZoomView.frame.size.height) / 2;
    if (animation) {
        [UIView animateWithDuration:0.2 animations:^{
            self.contentInset = UIEdgeInsetsMake(diffHeight, diffWidth, 0, 0);
            self.scrollIndicatorInsets = UIEdgeInsetsMake(diffHeight, diffWidth, 0, 0);
            self.contentSize = CGSizeMake(width - diffWidth, height - diffHeight);
        }];
    }else {
        self.contentInset = UIEdgeInsetsMake(diffHeight, diffWidth, 0, 0);
        self.scrollIndicatorInsets = UIEdgeInsetsMake(diffHeight, diffWidth, 0, 0);
        self.contentSize = CGSizeMake(width - diffWidth, height - diffHeight);
    }
    
    [self setSubViewData];
}
- (void)setDrawLineWidth:(CGFloat)drawLineWidth {
    _drawLineWidth = drawLineWidth;
    self.clippingView.imageView.drawView.lineWidth = drawLineWidth;
}
- (void)setSubViewData
{
    /** 默认绘画线粗 */
    self.clippingView.imageView.drawView.lineWidth = self.drawLineWidth / self.zoomScale;
    /** 默认模糊线粗 */
//    [self setSplashLineWidth:hx_editingView_splashWidth/self.zoomScale];
    self.clippingView.screenScale = self.zoomScale * self.clippingView.zoomScale;
}

- (void)fixedLongImage {
    /** 竖图 */
//    if (self.clippingView.frame.size.width < self.frame.size.width)
    {
        /** 屏幕大小的缩放比例 */
        CGFloat zoomScale = (self.frame.size.width / self.clippingView.frame.size.width);
        [self setZoomScale:zoomScale];
        /** 保持顶部不动的放大效果 */
        CGPoint contentOffset = self.contentOffset;
        contentOffset.y = 0;
        [self setContentOffset:contentOffset];
        /** 重置contentSize */
        [self resetContentSize:NO];
        /** 滚到顶部 */
        [self setContentOffset:CGPointMake(-self.contentInset.left, -self.contentInset.top)];
    }
}

#pragma mark - 更新图片像素
- (void)updateImagePixelText {
    CGFloat scale = self.clippingView.zoomScale / self.clippingView.first_minimumZoomScale;
    CGSize realSize = CGSizeMake(CGRectGetWidth(self.gridView.gridRect) / scale, CGRectGetHeight(self.gridView.gridRect) / scale);
    CGFloat screenScale = self.image.scale;
    int pixelW = (int)((self.imageSize.width * screenScale) / self.referenceSize.width * realSize.width + 0.5);
    int pixelH = (int)((self.imageSize.height * screenScale) / self.referenceSize.height * realSize.height + 0.5);
    self.imagePixel.text = [NSString stringWithFormat:@"%dx%d", pixelW, pixelH];
    self.imagePixel.center = CGPointMake(CGRectGetMidX(self.gridView.gridRect), CGRectGetMidY(self.gridView.gridRect));
}
 

#pragma mark - 数据
- (NSDictionary *)photoEditData {
    NSMutableDictionary *data = [@{} mutableCopy];
    
    if (self.gridView.aspectRatio > 0 &&
        self.gridView.aspectRatio != HXPhotoEditGridViewAspectRatioType_Original) {
        NSDictionary *myData = @{kHXEditingViewData_gridView_aspectRatio:@(self.gridView.aspectRatio)};
        [data setObject:myData forKey:kHXEditingViewData];
    }
    
    NSDictionary *clippingViewData = self.clippingView.photoEditData;
    if (clippingViewData) [data setObject:clippingViewData forKey:kHXEditingViewData_clippingView];
    
    if (data.count) {
        return data;
    }
    return nil;
}

- (void)setPhotoEditData:(NSDictionary *)photoEditData {
    self.clippingView.photoEditData = photoEditData[kHXEditingViewData_clippingView];
    _clippingRect = self.clippingView.frame;
    self.gridView.gridRect = self.clippingRect;
    self.maximumZoomScale = MIN(MAX(self.minimumZoomScale + self.defaultMaximumZoomScale - self.defaultMaximumZoomScale * (self.clippingView.zoomScale/self.clippingView.maximumZoomScale), self.minimumZoomScale), self.defaultMaximumZoomScale);
    NSDictionary *myData = photoEditData[kHXEditingViewData];
    if (myData) {
        HXPhotoEditGridViewAspectRatioType aspectRatio = [myData[kHXEditingViewData_gridView_aspectRatio] integerValue];
        [self.gridView setAspectRatioWithoutDelegate:aspectRatio];
        self.old_aspectRatio = aspectRatio;
    }
    /** 针对长图的展示 */
    [self fixedLongImage];
}
@end
