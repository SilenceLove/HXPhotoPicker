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
#import "HXCircleProgressView.h"
@interface HXPhotoPreviewViewCell ()<UIScrollViewDelegate,PHLivePhotoViewDelegate>
@property (weak, nonatomic) UIScrollView *scrollView;
@property (weak, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) CGPoint imageCenter;
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (strong, nonatomic) UIImage *gifImage;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (assign, nonatomic) PHImageRequestID longRequestId;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@property (assign, nonatomic) PHImageRequestID liveRequestID;
@property (strong, nonatomic) UIImage *firstImage;

@end

@implementation HXPhotoPreviewViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.requestID = 0;
        self.longRequestId = 0;
        [self setup];
    }
    return self;
}

- (void)setup {
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

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    self.isAnimating = YES;
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    [self stopLivePhoto];
}

- (void)startLivePhoto {
    if (self.isAnimating) {
        return;
    }
    self.livePhotoView = [[PHLivePhotoView alloc] init];
    self.livePhotoView.clipsToBounds = YES;
    self.livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
    self.livePhotoView.frame = self.imageView.frame;
    self.livePhotoView.delegate = self;
    [self.scrollView addSubview:self.livePhotoView];
//    if (self.model.livePhoto) {
//        self.livePhotoView.livePhoto = self.model.livePhoto;
//        [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
//    }else {
        __weak typeof(self) weakSelf = self;
        self.liveRequestID = [HXPhotoTools FetchLivePhotoForPHAsset:self.model.asset Size:CGSizeMake(self.model.endImageSize.width * 2, self.model.endImageSize.height * 2) Completion:^(PHLivePhoto *livePhoto, NSDictionary *info) {
//            weakSelf.model.livePhoto = livePhoto;
            weakSelf.livePhotoView.livePhoto = livePhoto;
            [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        }];
//    }
}

- (void)stopLivePhoto {
    [[PHImageManager defaultManager] cancelImageRequest:self.liveRequestID];
    self.isAnimating = NO;
    [self.livePhotoView stopPlayback];
    [self.livePhotoView removeFromSuperview];
    self.livePhotoView.delegate = nil;
    self.livePhotoView = nil;
}

- (void)fetchLongPhoto {
    [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    PHImageRequestID requestID;
    __weak typeof(self) weakSelf = self;
    if (imgHeight > imgWidth / 9 * 17) {
        requestID = [HXPhotoTools FetchPhotoForPHAsset:self.model.asset Size:CGSizeMake(width, height) deliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat completion:^(UIImage *image, NSDictionary *info) {
            weakSelf.imageView.image = image;
            weakSelf.progressView.hidden = YES;
        } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            weakSelf.progressView.hidden = NO;
            weakSelf.progressView.progress = progress;
        }];
    }else {
        requestID = [HXPhotoTools FetchPhotoForPHAsset:self.model.asset Size:CGSizeMake(_model.endImageSize.width * 2.0, _model.endImageSize.height * 2.0) deliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat completion:^(UIImage *image, NSDictionary *info) {
            weakSelf.imageView.image = image;
            weakSelf.progressView.hidden = YES;
        } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            weakSelf.progressView.hidden = NO;
            weakSelf.progressView.progress = progress;
        }];
    }
    if (self.longRequestId != requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.longRequestId];
        self.longRequestId = requestID;
    }
}

- (void)startGifImage {
    self.imageView.image = self.gifImage;
}

- (void)stopGifImage {
    self.imageView.image = self.firstImage;
}

- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    self.gifImage = nil;
    [[PHImageManager defaultManager] cancelImageRequest:self.longRequestId];
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
        __weak typeof(self) weakSelf = self;
        [HXPhotoTools FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) { 
            UIImage *gifImage = [UIImage animatedGIFWithData:imageData];
            if (gifImage.images.count == 0) {
                weakSelf.firstImage = gifImage;
                weakSelf.imageView.image = gifImage;
            }else {
                weakSelf.firstImage = gifImage.images.firstObject;
                weakSelf.imageView.image = gifImage.images.firstObject;
            }
            weakSelf.gifImage = gifImage;
        }];
    }else {
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            self.imageView.image = model.thumbPhoto;
        }else {
            if (model.previewPhoto) {
                self.imageView.image = model.previewPhoto;
            }else {
                __weak typeof(self) weakSelf = self;
                PHImageRequestID requestID;
                if (imgHeight > imgWidth / 9 * 17) {
                    requestID = [HXPhotoTools getPhotoForPHAsset:model.asset size:CGSizeMake(width * 0.5, height * 0.5) completion:^(UIImage *image, NSDictionary *info) {
                        weakSelf.imageView.image = image;
                    }]; 
                }else {
                    requestID = [HXPhotoTools getPhotoForPHAsset:model.asset size:CGSizeMake(model.endImageSize.width * 0.8, model.endImageSize.height * 0.8) completion:^(UIImage *image, NSDictionary *info) {
                        weakSelf.imageView.image = image;
                    }];
                }
                if (self.requestID != requestID) {
                    [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
                }
                self.requestID = requestID;
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
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    self.progressView.center = CGPointMake(width / 2, height / 2);
    
}
@end
