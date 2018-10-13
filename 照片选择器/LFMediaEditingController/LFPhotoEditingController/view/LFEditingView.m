//
//  LFEditingView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/10.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFEditingView.h"
#import "LFGridView.h"
#import "LFClippingView.h"

#import "UIView+LFMEFrame.h"
#import "LFMECancelBlock.h"
#import "UIView+LFMECommon.h"
#import "UIImage+LFMECommon.h"

#import <AVFoundation/AVFoundation.h>

#define kMaxZoomScale 2.5f

#define kClipZoom_margin 10.f

@interface LFEditingView () <UIScrollViewDelegate, LFClippingViewDelegate, LFGridViewDelegate>

@property (nonatomic, weak) LFClippingView *clippingView;
@property (nonatomic, weak) LFGridView *gridView;
/** 因为LFClippingView需要调整transform属性，需要额外创建一层进行缩放处理，理由：UIScrollView的缩放会自动重置transform */
@property (nonatomic, weak) UIView *clipZoomView;

/** 剪裁尺寸, CGRectInset(self.bounds, 20, 50) */
@property (nonatomic, assign) CGRect clippingRect;

/** 显示图片剪裁像素 */
@property (nonatomic, weak) UILabel *imagePixel;

/** 图片像素参照坐标 */
@property (nonatomic, assign) CGSize referenceSize;

/* 底部栏高度 默认44 */
@property (nonatomic, assign) CGFloat editToolbarDefaultHeight;

@property (nonatomic, copy) lf_me_dispatch_cancelable_block_t maskViewBlock;

/** 编辑操作次数记录-有3种编辑操作 拖动、缩放、网格 并且可以同时触发任意2种，避免多次回调代理 */
@property (nonatomic, assign) int editedCount;

/** 默认最大化缩放 */
@property (nonatomic, assign) CGFloat defaultMaximumZoomScale;

@end

@implementation LFEditingView

@synthesize image = _image;

- (NSArray <NSString *>*)aspectRatioDescs
{
    return [self.gridView aspectRatioDescs:(self.image.size.width > self.image.size.height)];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.backgroundColor = [UIColor blackColor];
    self.delegate = self;
    /** 缩放 */
    self.maximumZoomScale = kMaxZoomScale;
    self.minimumZoomScale = 1.0;
    _editToolbarDefaultHeight = 44.f;
    
    /** 创建缩放层，避免直接缩放LFClippingView，会改变其transform */
    UIView *clipZoomView = [[UIView alloc] initWithFrame:self.bounds];
    clipZoomView.backgroundColor = [UIColor clearColor];
    [self addSubview:clipZoomView];
    self.clipZoomView = clipZoomView;
    
    /** 创建剪裁层 */
    LFClippingView *clippingView = [[LFClippingView alloc] initWithFrame:self.bounds];
    clippingView.clippingDelegate = self;
    /** 非剪裁情况禁止剪裁层移动 */
    clippingView.scrollEnabled = NO;
    [self.clipZoomView addSubview:clippingView];
    self.clippingView = clippingView;
    
    LFGridView *gridView = [[LFGridView alloc] initWithFrame:self.bounds];
    gridView.delegate = self;
    /** 先隐藏剪裁网格 */
    gridView.alpha = 0.f;
    [self addSubview:gridView];
    self.gridView = gridView;
    
    self.clippingMinSize = CGSizeMake(80, 80);
    self.clippingMaxRect = CGRectInset(self.frame , 20, 50);
    
    /** 创建显示图片像素控件 */
    UILabel *imagePixel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.width-40, 30)];
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
}

- (void)safeAreaInsetsDidChange
{
    [super safeAreaInsetsDidChange];
    self.clippingMinSize = self.clippingMinSize;
    self.clippingMaxRect = self.clippingMaxRect;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    if (image) {
        CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(image.size, self.frame);
        self.gridView.controlSize = cropRect.size;
        self.gridView.gridRect = cropRect;
        self.imagePixel.center = CGPointMake(CGRectGetMidX(cropRect), CGRectGetMidY(cropRect));
        {
            if (cropRect.size.width < cropRect.size.height) {
                self.defaultMaximumZoomScale = self.frame.size.width * kMaxZoomScale / cropRect.size.width;
            } else {
                self.defaultMaximumZoomScale = self.frame.size.height * kMaxZoomScale / cropRect.size.height;
            }
            self.maximumZoomScale = self.defaultMaximumZoomScale;
        }
    }
    self.clippingView.image = image;
    
    /** 计算图片像素参照坐标 */
    self.referenceSize = AVMakeRectWithAspectRatioInsideRect(self.clippingView.size, self.clippingMaxRect).size;
}

- (void)setClippingRect:(CGRect)clippingRect
{
    if (_isClipping) {
        /** 关闭缩放 */
        self.maximumZoomScale = self.minimumZoomScale;
        [self setZoomScale:self.zoomScale];
        self.contentInset = UIEdgeInsetsZero;
        self.scrollIndicatorInsets = UIEdgeInsetsZero;
    } else {
        self.maximumZoomScale = MIN(MAX(self.minimumZoomScale + self.defaultMaximumZoomScale - self.defaultMaximumZoomScale * (self.clippingView.zoomScale/self.clippingView.maximumZoomScale), self.minimumZoomScale), self.defaultMaximumZoomScale);
    }
    
    if (_isClipping) {
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
    self.clippingView.cropRect = clippingRect;
    self.imagePixel.center = CGPointMake(CGRectGetMidX(self.gridView.gridRect), CGRectGetMidY(self.gridView.gridRect));
}

- (void)setClippingMinSize:(CGSize)clippingMinSize
{
    if (CGSizeEqualToSize(CGSizeZero, _clippingMinSize) || (clippingMinSize.width < CGRectGetWidth(_clippingMaxRect) && clippingMinSize.height < CGRectGetHeight(_clippingMaxRect))) {
        
        CGFloat toolbarHeight = self.editToolbarDefaultHeight + kClipZoom_margin;
        CGFloat topHeight = 0;
        if (@available(iOS 11.0, *)) {
            toolbarHeight += self.safeAreaInsets.bottom;
            topHeight += self.safeAreaInsets.top;
        }
        
        CGRect rect = CGRectInset(self.frame , 20, MAX(50, toolbarHeight));
        CGSize newClippingMinSize = AVMakeRectWithAspectRatioInsideRect(self.clippingView.size, rect).size;
        
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

- (void)setClippingMaxRect:(CGRect)clippingMaxRect
{
    if (CGRectEqualToRect(CGRectZero, _clippingMaxRect) || (CGRectGetWidth(clippingMaxRect) > _clippingMinSize.width && CGRectGetHeight(clippingMaxRect) > _clippingMinSize.height)) {
        
        CGFloat toolbarHeight = self.editToolbarDefaultHeight + kClipZoom_margin;
        CGFloat topHeight = 0;
        if (@available(iOS 11.0, *)) {
            toolbarHeight += self.safeAreaInsets.bottom;
            topHeight += self.safeAreaInsets.top;
        }
        
        CGRect newClippingMaxRect = CGRectInset(self.frame , 20, MAX(50, toolbarHeight));
        
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
        self.referenceSize = AVMakeRectWithAspectRatioInsideRect(self.clippingView.size, self.clippingMaxRect).size;
    }
}

- (void)setIsClipping:(BOOL)isClipping
{
    [self setIsClipping:isClipping animated:NO];
}
- (void)setIsClipping:(BOOL)isClipping animated:(BOOL)animated
{
    self.editedCount = 0;
    _isClipping = isClipping;
    self.clippingView.scrollEnabled = isClipping;
    if (isClipping) {
        CGFloat toolbarHeight = self.editToolbarDefaultHeight + kClipZoom_margin;
        if (@available(iOS 11.0, *)) {
            toolbarHeight += self.safeAreaInsets.bottom;
        }
        /** 动画切换 */
        if (animated) {
            [UIView animateWithDuration:0.25f animations:^{
                CGRect rect = CGRectInset(self.frame , 20, MAX(50, toolbarHeight));
                self.clippingRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.size, rect);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.25f animations:^{
                    self.gridView.alpha = 1.f;
                    self.imagePixel.alpha = 1.f;
                } completion:^(BOOL finished) {
                    /** 显示多余部分 */
                    self.clippingView.clipsToBounds = NO;
                }];
            }];
        } else {
            CGRect rect = CGRectInset(self.frame , 20, MAX(50, toolbarHeight));
            self.clippingRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.size, rect);
            self.gridView.alpha = 1.f;
            self.imagePixel.alpha = 1.f;
            /** 显示多余部分 */
            self.clippingView.clipsToBounds = NO;
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
                    CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.size, self.frame);
                    self.clippingRect = cropRect;
                }];
            }];
        } else {
            /** 剪裁多余部分 */
            self.clippingView.clipsToBounds = YES;
            self.gridView.alpha = 0.f;
            self.imagePixel.alpha = 0.f;
            CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.size, self.frame);
            self.clippingRect = cropRect;
        }
    }
}

/** 取消剪裁 */
- (void)cancelClipping:(BOOL)animated
{
    self.editedCount = 0;
    _isClipping = NO;
    /** 剪裁多余部分 */
    self.clippingView.clipsToBounds = YES;
    if (animated) {
        [UIView animateWithDuration:0.1f animations:^{
            self.gridView.alpha = 0.f;
            self.imagePixel.alpha = 0.f;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.25f animations:^{
                [self cancel];
            }];
        }];
    } else {
        [self cancel];
    }
}

- (void)cancel
{
    [self.clippingView cancel];
    self.gridView.gridRect = self.clippingView.frame;
    self.imagePixel.center = CGPointMake(CGRectGetMidX(self.gridView.gridRect), CGRectGetMidY(self.gridView.gridRect));
    self.maximumZoomScale = MIN(MAX(self.minimumZoomScale + self.defaultMaximumZoomScale - self.defaultMaximumZoomScale * (self.clippingView.zoomScale/self.clippingView.maximumZoomScale), self.minimumZoomScale), self.defaultMaximumZoomScale);
}

/** 还原 */
- (void)reset
{
    if (_isClipping) {
        [self.clippingView reset];
    }
}

- (BOOL)canReset
{
    if (_isClipping) {
        return self.clippingView.canReset;
    }
    return NO;
}

/** 旋转 isClipping=YES 的情况有效 */
- (void)rotate
{
    if (_isClipping) {
        [self.clippingView rotateClockwise:YES];
    }
}

/** 长宽比例 */
- (void)setAspectRatio:(NSString *)aspectRatio
{
    NSInteger index = 0;
    NSArray *aspectRatioDescs = [self aspectRatioDescs];
    if (aspectRatio.length && [aspectRatioDescs containsObject:aspectRatio]) {
        index = [aspectRatioDescs indexOfObject:aspectRatio] + 1;
    }
    [self.gridView setAspectRatio:(LFGridViewAspectRatioType)index];
}

/** 补底操作-多手势同时触发时，部分逻辑没有实时处理，当手势完全停止后补充处理 */
- (void)supplementHandle
{
    if (!CGRectEqualToRect(self.gridView.gridRect, self.clippingView.frame)) {
        self.gridView.showMaskLayer = NO;
        lf_me_dispatch_cancel(self.maskViewBlock);
        [self.clippingView zoomOutToRect:self.gridView.gridRect];
    }
}

/** 创建编辑图片 */
- (void)createEditImage:(void (^)(UIImage *editImage))complete
{
    CGFloat zoomScale = self.zoomScale;
    [self setZoomScale:1.f];
    
    CGFloat scale = self.clippingView.zoomScale;
    CGAffineTransform trans = self.clippingView.transform;
    CGPoint contentOffset = self.clippingView.contentOffset;
    CGSize size = self.clippingView.frame.size;
    
//    size.width = ((int)(size.width+0.5)*1.f);
//    size.height = ((int)(size.height+0.5)*1.f);
    
    /** 忽略原图的显示，仅需要原图以上的编辑图层 */
    self.clippingView.imageViewHidden = YES;
    /** 获取编辑图层视图 */
    UIImage *otherImage = [self.clipZoomView LFME_captureImageAtFrame:(CGRect){self.clippingView.frame.origin, size}];
    /** 恢复原图的显示 */
    self.clippingView.imageViewHidden = NO;
    
    /* Return a transform which rotates by `angle' radians:
     t' = [ cos(angle) sin(angle) -sin(angle) cos(angle) 0 0 ] */
    CGFloat rotate = acosf(trans.a);
    if (trans.b < 0) {
        rotate = M_PI-asinf(trans.b);
    }
    // 将弧度转换为角度
//    CGFloat degree = rotate/M_PI * 180;
    
    __block UIImage *editImage = self.image;
    CGRect clipViewRect = self.clippingView.normalRect;
    /** UIScrollView的缩放率 * 剪裁尺寸变化比例 / 图片屏幕缩放率 */
    CGFloat clipScale = scale * (clipViewRect.size.width/(editImage.size.width*editImage.scale));
    /** 计算被剪裁的原尺寸图片位置 */
    CGRect clipRect;
    if (fabs(trans.b) == 1.f) {
        clipRect = CGRectMake(contentOffset.x/clipScale, contentOffset.y/clipScale, size.height/clipScale, size.width/clipScale);
    } else {
        clipRect = CGRectMake(contentOffset.x/clipScale, contentOffset.y/clipScale, size.width/clipScale, size.height/clipScale);
    }
    /** 参数取整，否则可能会出现1像素偏差 */
    clipRect.origin.x = ((int)(clipRect.origin.x+0.5)*1.f);
    clipRect.origin.y = ((int)(clipRect.origin.y+0.5)*1.f);
    clipRect.size.width = ((int)(clipRect.size.width+0.5)*1.f);
    clipRect.size.height = ((int)(clipRect.size.height+0.5)*1.f);
    
    /** 滤镜图片 */
    UIImage *showImage = [self getFilterImage];
    if (showImage == nil) {
        showImage = self.image;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        /** 创建方法 */
        UIImage *(^ClipEditImage)(UIImage *) = ^UIImage * (UIImage *image) {
            /** 剪裁图片 */
            CGImageRef sourceImageRef = [image CGImage];
            CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, clipRect);
            UIImage *clipEditImage = [UIImage imageWithCGImage:newImageRef scale:image.scale orientation:image.imageOrientation];
            if (rotate > 0) {
                /** 调整图片方向 */
                clipEditImage = [clipEditImage LFME_imageRotatedByRadians:rotate];
            }
            /** 缩放至原图尺寸 */
            UIImage *scaleOtherImage = [otherImage LFME_scaleToSize:clipEditImage.size];
            if (scaleOtherImage) {
                /** 合并图层 */
                clipEditImage = [clipEditImage LFME_mergeimages:@[scaleOtherImage]];
            }
            return clipEditImage;
        };
        
        if (showImage.images.count) {
            NSMutableArray *images = [NSMutableArray arrayWithCapacity:showImage.images.count];
            for (UIImage *image in showImage.images) {
                UIImage *newImage = ClipEditImage(image);
                if (newImage) {
                    [images addObject:newImage];
                } else {
                    break;
                }
            }
            /** 若数量不一致，解析gif失败，生成静态图片 */
            if (images.count == showImage.images.count) {
                editImage = [UIImage animatedImageWithImages:images duration:showImage.duration];
            }
        } else {
            editImage = ClipEditImage(showImage);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *resultImage = editImage;
            
            if (!resultImage) {
                /** 合并操作有误，直接截取原始图层 */
                resultImage = [self.clipZoomView LFME_captureImageAtFrame:self.clippingView.frame];
            }
            [self setZoomScale:zoomScale];
            
            if (complete) {
                complete(resultImage);
            }
        });
    });
}

#pragma mark - LFClippingViewDelegate
- (void (^)(CGRect))lf_clippingViewWillBeginZooming:(LFClippingView *)clippingView
{
    if (self.editedCount==0 && [self.clippingDelegate respondsToSelector:@selector(lf_EditingViewWillBeginEditing:)]) {
        [self.clippingDelegate lf_EditingViewWillBeginEditing:self];
    }
    self.editedCount++;
    
    __weak typeof(self) weakSelf = self;
    void (^block)(CGRect) = ^(CGRect rect){
        if (clippingView.isReseting || clippingView.isRotating) { /** 重置/旋转 需要将遮罩显示也重置 */
            [weakSelf.gridView setGridRect:rect maskLayer:YES animated:YES];
        } else if (clippingView.isZooming) { /** 缩放 */
            weakSelf.gridView.showMaskLayer = NO;
            lf_me_dispatch_cancel(weakSelf.maskViewBlock);
        } else {
            [weakSelf.gridView setGridRect:rect animated:YES];
        }
        
        /** 图片像素 */
        [self updateImagePixelText];
    };
    
    return block;
}
- (void)lf_clippingViewDidZoom:(LFClippingView *)clippingView
{
    if (clippingView.zooming) {
        [self updateImagePixelText];
    }
}
- (void)lf_clippingViewDidEndZooming:(LFClippingView *)clippingView
{
    __weak typeof(self) weakSelf = self;
    self.maskViewBlock = lf_dispatch_block_t(0.25f, ^{
        if (!weakSelf.gridView.isDragging) {
            weakSelf.gridView.showMaskLayer = YES;
        }
    });
    
    [self updateImagePixelText];
    
    self.editedCount--;
    if (self.editedCount==0 && [self.clippingDelegate respondsToSelector:@selector(lf_EditingViewDidEndEditing:)]) {
        [self.clippingDelegate lf_EditingViewDidEndEditing:self];
    }
}

- (void)lf_clippingViewWillBeginDragging:(LFClippingView *)clippingView
{
    if (self.editedCount==0 && [self.clippingDelegate respondsToSelector:@selector(lf_EditingViewWillBeginEditing:)]) {
        [self.clippingDelegate lf_EditingViewWillBeginEditing:self];
    }
    self.editedCount++;
    /** 移动开始，隐藏 */
    self.gridView.showMaskLayer = NO;
    lf_me_dispatch_cancel(self.maskViewBlock);
}
- (void)lf_clippingViewDidEndDecelerating:(LFClippingView *)clippingView
{
    /** 移动结束，显示 */
    if (!self.gridView.isDragging && !CGRectEqualToRect(self.gridView.gridRect, self.clippingView.frame)) {
        [self supplementHandle];
        self.editedCount--;
    } else {
        __weak typeof(self) weakSelf = self;
        self.maskViewBlock = lf_dispatch_block_t(0.25f, ^{
            if (!weakSelf.gridView.isDragging) {
                weakSelf.gridView.showMaskLayer = YES;
            }
        });
        self.editedCount--;
        if (self.editedCount==0 && [self.clippingDelegate respondsToSelector:@selector(lf_EditingViewDidEndEditing:)]) {
            [self.clippingDelegate lf_EditingViewDidEndEditing:self];
        }
    }
}

#pragma mark - LFGridViewDelegate
- (void)lf_gridViewDidBeginResizing:(LFGridView *)gridView
{
    if (self.editedCount==0 && [self.clippingDelegate respondsToSelector:@selector(lf_EditingViewWillBeginEditing:)]) {
        [self.clippingDelegate lf_EditingViewWillBeginEditing:self];
    }
    self.editedCount++;
    gridView.showMaskLayer = NO;
    lf_me_dispatch_cancel(self.maskViewBlock);
}
- (void)lf_gridViewDidResizing:(LFGridView *)gridView
{
    /** 放大 */
    [self.clippingView zoomInToRect:gridView.gridRect];
    
    /** 图片像素 */
    [self updateImagePixelText];
}
- (void)lf_gridViewDidEndResizing:(LFGridView *)gridView
{
    /** 缩小 */
    [self.clippingView zoomOutToRect:gridView.gridRect];
    self.editedCount--;
    /** 让clippingView的动画回调后才显示showMaskLayer */
    //    self.gridView.showMaskLayer = YES;
}
/** 调整长宽比例 */
- (void)lf_gridViewDidAspectRatio:(LFGridView *)gridView
{
    [self lf_gridViewDidBeginResizing:gridView];
    [self lf_gridViewDidResizing:gridView];
    [self lf_gridViewDidEndResizing:gridView];
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

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    /** 重置contentSize */
    CGRect realClipZoomRect = AVMakeRectWithAspectRatioInsideRect(self.clippingView.size, self.clipZoomView.frame);
    CGFloat width = MAX(self.frame.size.width, realClipZoomRect.size.width);
    CGFloat height = MAX(self.frame.size.height, realClipZoomRect.size.height);
    CGFloat diffWidth = (width-self.clipZoomView.frame.size.width)/2;
    CGFloat diffHeight = (height-self.clipZoomView.frame.size.height)/2;
    self.contentInset = UIEdgeInsetsMake(diffHeight, diffWidth, 0, 0);
    self.scrollIndicatorInsets = UIEdgeInsetsMake(diffHeight, diffWidth, 0, 0);
    self.contentSize = CGSizeMake(width-diffWidth, height-diffHeight);
}


#pragma mark - 重写父类方法

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    
    if (!([[self subviews] containsObject:view] || [[self.clipZoomView subviews] containsObject:view])) { /** 非自身子视图 */
        if (event.allTouches.count == 2) { /** 2个手指 */
            return NO;
        }
    }
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    if (!([[self subviews] containsObject:view] || [[self.clipZoomView subviews] containsObject:view])) { /** 非自身子视图 */
        return NO;
    }
    return [super touchesShouldCancelInContentView:view];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (!self.isClipping && (self.clippingView == view || self.clipZoomView == view)) { /** 非编辑状态，改变触发响应最顶层的scrollView */
        return self;
    } else if (self.isClipping && (view == self || self.clipZoomView == view)) {
        return self.clippingView;
    }
    return view;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    /** 解决部分机型在编辑期间会触发滑动导致无法编辑的情况 */
    if (gestureRecognizer.view == self && touch.view != self && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        /** 自身手势被触发、响应视图非自身、被触发收拾为滑动手势 */
        return NO;
    }
    return YES;
}

#pragma mark - Private
- (void)refreshImageZoomViewCenter {
    CGFloat offsetX = (self.width > self.contentSize.width) ? ((self.width - self.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (self.height > self.contentSize.height) ? ((self.height - self.contentSize.height) * 0.5) : 0.0;
    self.clipZoomView.center = CGPointMake(self.contentSize.width * 0.5 + offsetX, self.contentSize.height * 0.5 + offsetY);
}

#pragma mark - 更新图片像素
- (void)updateImagePixelText;
{
    CGFloat scale = self.clippingView.zoomScale/self.clippingView.first_minimumZoomScale;
    CGSize realSize = CGSizeMake(CGRectGetWidth(self.gridView.gridRect)/scale, CGRectGetHeight(self.gridView.gridRect)/scale);
    CGFloat screenScale = [UIScreen mainScreen].scale;
    int pixelW = (int)((self.image.size.width*screenScale)/self.referenceSize.width*realSize.width+0.5);
    int pixelH = (int)((self.image.size.height*screenScale)/self.referenceSize.height*realSize.height+0.5);
    self.imagePixel.text = [NSString stringWithFormat:@"%dx%d", pixelW, pixelH];
    self.imagePixel.center = CGPointMake(CGRectGetMidX(self.gridView.gridRect), CGRectGetMidY(self.gridView.gridRect));
}

#pragma mark - LFEditingProtocol

- (void)setEditDelegate:(id<LFPhotoEditDelegate>)editDelegate
{
    self.clippingView.editDelegate = editDelegate;
}
- (id<LFPhotoEditDelegate>)editDelegate
{
    return self.clippingView.editDelegate;
}

/** 禁用其他功能 */
- (void)photoEditEnable:(BOOL)enable
{
    [self.clippingView photoEditEnable:enable];
}

#pragma mark - 数据
- (NSDictionary *)photoEditData
{
    return self.clippingView.photoEditData;
}

- (void)setPhotoEditData:(NSDictionary *)photoEditData
{
    self.clippingView.photoEditData = photoEditData;
    self.maximumZoomScale = MIN(MAX(self.minimumZoomScale + self.defaultMaximumZoomScale - self.defaultMaximumZoomScale * (self.clippingView.zoomScale/self.clippingView.maximumZoomScale), self.minimumZoomScale), self.defaultMaximumZoomScale);
}

#pragma mark - 滤镜功能
/** 滤镜类型 */
- (void)changeFilterColorMatrixType:(LFColorMatrixType)cmType
{
    [self.clippingView changeFilterColorMatrixType:cmType];
}
/** 当前使用滤镜类型 */
- (LFColorMatrixType)getFilterColorMatrixType
{
    return [self.clippingView getFilterColorMatrixType];
}
/** 获取滤镜图片 */
- (UIImage *)getFilterImage
{
    return [self.clippingView getFilterImage];
}

#pragma mark - 绘画功能
/** 启用绘画功能 */
- (void)setDrawEnable:(BOOL)drawEnable
{
    self.clippingView.drawEnable = drawEnable;
}
- (BOOL)drawEnable
{
    return self.clippingView.drawEnable;
}

- (BOOL)drawCanUndo
{
    return [self.clippingView drawCanUndo];
}
- (void)drawUndo
{
    [self.clippingView drawUndo];
}
/** 设置绘画颜色 */
- (void)setDrawColor:(UIColor *)color
{
    [self.clippingView setDrawColor:color];
}

#pragma mark - 贴图功能
/** 取消激活贴图 */
- (void)stickerDeactivated
{
    [self.clippingView stickerDeactivated];
}
- (void)activeSelectStickerView
{
    [self.clippingView activeSelectStickerView];
}
/** 删除选中贴图 */
- (void)removeSelectStickerView
{
    [self.clippingView removeSelectStickerView];
}
/** 获取选中贴图的内容 */
- (LFText *)getSelectStickerText
{
    return [self.clippingView getSelectStickerText];
}
/** 更改选中贴图内容 */
- (void)changeSelectStickerText:(LFText *)text
{
    [self.clippingView changeSelectStickerText:text];
}

/** 创建贴图 */
- (void)createStickerImage:(UIImage *)image
{
    [self.clippingView createStickerImage:image];
}

#pragma mark - 文字功能
/** 创建文字 */
- (void)createStickerText:(LFText *)text
{
    [self.clippingView createStickerText:text];
}

#pragma mark - 模糊功能
/** 启用模糊功能 */
- (void)setSplashEnable:(BOOL)splashEnable
{
    self.clippingView.splashEnable = splashEnable;
}
- (BOOL)splashEnable
{
    return self.clippingView.splashEnable;
}
/** 是否可撤销 */
- (BOOL)splashCanUndo
{
    return [self.clippingView splashCanUndo];
}
/** 撤销模糊 */
- (void)splashUndo
{
    [self.clippingView splashUndo];
}

- (void)setSplashState:(BOOL)splashState
{
    self.clippingView.splashState = splashState;
}

- (BOOL)splashState
{
    return self.clippingView.splashState;
}

@end
