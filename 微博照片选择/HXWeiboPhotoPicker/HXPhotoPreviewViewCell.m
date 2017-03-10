//
//  HXPhotoPreviewViewCell.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/9.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoPreviewViewCell.h"
#import "HXPhotoTools.h"
#import "UIImage+HXExtension.h"
@interface HXPhotoPreviewViewCell ()<UIScrollViewDelegate,PHLivePhotoViewDelegate>
@property (weak, nonatomic) UIScrollView *scrollView;
@property (weak, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) CGPoint imageCenter;
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@end

@implementation HXPhotoPreviewViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.bouncesZoom = YES;
    scrollView.minimumZoomScale = 1;
    scrollView.multipleTouchEnabled = YES;
    scrollView.delegate = self;
    scrollView.scrollsToTop = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.delaysContentTouches = NO;
    scrollView.canCancelContentTouches = YES;
    scrollView.alwaysBounceVertical = NO;
    scrollView.contentSize = CGSizeMake(width, height);
    [self.contentView addSubview:scrollView];
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    tap2.numberOfTapsRequired = 2;
    [scrollView addGestureRecognizer:tap2];
    self.scrollView = scrollView;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    
    [scrollView addSubview:imageView];
    self.imageView = imageView;
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle
{
    self.isAnimating = YES;
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle
{
    [self stopLivePhoto];
}

- (void)startLivePhoto
{
    if (self.isAnimating) {
        return;
    }
    self.livePhotoView = [[PHLivePhotoView alloc] init];
    self.livePhotoView.clipsToBounds = YES;
    self.livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
    self.livePhotoView.frame = self.imageView.frame;
    self.livePhotoView.delegate = self;
    [self.scrollView addSubview:self.livePhotoView];
    if (self.model.livePhoto) {
        self.livePhotoView.livePhoto = self.model.livePhoto;
        [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
    }else {
        __weak typeof(self) weakSelf = self;
        [HXPhotoTools FetchLivePhotoForPHAsset:self.model.asset Size:CGSizeMake(self.model.endImageSize.width * 2, self.model.endImageSize.height * 2) Completion:^(PHLivePhoto *livePhoto, NSDictionary *info) {
            weakSelf.model.livePhoto = livePhoto;
            weakSelf.livePhotoView.livePhoto = livePhoto;
            [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        }];
    }
}

- (void)stopLivePhoto
{
    self.isAnimating = NO;
    [self.livePhotoView stopPlayback];
    [self.livePhotoView removeFromSuperview];
}

- (void)setModel:(HXPhotoModel *)model
{
    _model = model;
    [self.scrollView setZoomScale:1.0 animated:NO];
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = model.imageSize.width;
    CGFloat imgHeight = model.imageSize.height;
    CGFloat w;
    CGFloat h;
    
    imgHeight = width / imgWidth * imgHeight;
    if (imgHeight > height) {
        w = height / model.imageSize.height * imgWidth;
        h = height;
        self.scrollView.maximumZoomScale = width / w + 0.5;
    }else {
        w = width;
        h = imgHeight;
        self.scrollView.maximumZoomScale = 2.5;
    }
    _imageView.frame = CGRectMake(0, 0, w, h);
    _imageView.center = CGPointMake(width / 2, height / 2);
    if (model.type == HXPhotoModelMediaTypePhotoGif) {
        if (model.imageData) {
            self.imageView.image = [UIImage animatedGIFWithData:model.imageData];
        }else {
            __weak typeof(self) weakSelf = self;
            [HXPhotoTools FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
                model.imageData = imageData;
                UIImage *gifImage = [UIImage animatedGIFWithData:imageData];
                weakSelf.imageView.image = gifImage;
                model.gifImage = gifImage;
            }];
        }
    }else {
        CGFloat scale = [UIScreen mainScreen].scale;
        __weak typeof(self) weakSelf = self;
        if (imgHeight > imgWidth / 9 * 17) {
            [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:CGSizeMake(width * scale, height * scale) resizeMode:PHImageRequestOptionsResizeModeFast completion:^(UIImage *image, NSDictionary *info) {
                model.previewPhoto = image;
                weakSelf.imageView.image = image;
            }];
        }else {
            if (model.previewPhoto) {
                self.imageView.image = model.previewPhoto;
            }else {
                [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:CGSizeMake(model.endImageSize.width * scale, model.endImageSize.height * scale) resizeMode:PHImageRequestOptionsResizeModeFast completion:^(UIImage *image, NSDictionary *info) {
                    model.previewPhoto = image;
                    weakSelf.imageView.image = image;
                }];
            }
        }
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)tap {
    if (_scrollView.zoomScale > 1.0) {
        [_scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGFloat width = self.frame.size.width;
        CGFloat height = self.frame.size.height;
        CGPoint touchPoint = [tap locationInView:self.imageView];
        CGFloat newZoomScale = _scrollView.maximumZoomScale;
        CGFloat xsize = width / newZoomScale;
        CGFloat ysize = height / newZoomScale;
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}

#pragma mark - 返回需要缩放的控件
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (self.isAnimating) {
        [self stopLivePhoto];
    }
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.frame.size.width > scrollView.contentSize.width) ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.frame.size.height > scrollView.contentSize.height) ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)updateImageSize
{
    [_scrollView setZoomScale:1.0 animated:NO];
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGFloat w;
    CGFloat h;
    
    imgHeight = width / imgWidth * imgHeight;
    if (imgHeight > height) {
        w = height / self.model.imageSize.height * imgWidth;
        h = height;
    }else {
        w = width;
        h = imgHeight;
    }
    _imageView.frame = CGRectMake(0, 0, w, h);
    _imageView.center = CGPointMake(width / 2, height / 2);
    _imageCenter = _imageView.center;
}
@end
