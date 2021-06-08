//
//  HXPhotoPreviewViewCell.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/12/5.
//  Copyright © 2019 Silence. All rights reserved.
//

#import "HXPhotoPreviewViewCell.h"

@interface HXPhotoPreviewViewCell ()<UIScrollViewDelegate>
@property (strong, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) CGPoint imageCenter;
@end

@implementation HXPhotoPreviewViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)setup {
    self.allowInteration = YES;
    [self.contentView addSubview:self.scrollView];
}
- (void)resetScale:(BOOL)animated {
    if (self.model.type != HXPhotoModelMediaTypePhotoGif) {
        self.previewContentView.gifImage = nil;
    }
    [self resetScale:1.0f animated:animated];
}
- (void)resetScale:(CGFloat)scale animated:(BOOL)animated {
    [self.scrollView setZoomScale:scale animated:animated];
}
- (void)againAddImageView {
    [self refreshImageSize];
    [self.scrollView setZoomScale:1.0f animated:NO];
    [self.scrollView addSubview:self.previewContentView];
    [self.scrollView insertSubview:self.previewContentView atIndex:0];
}
- (CGSize)getImageSize {
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGFloat w;
    CGFloat h;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        w = height / self.model.imageSize.height * imgWidth;
        h = height;
    }else {
        imgHeight = width / imgWidth * imgHeight;
        w = width;
        h = imgHeight;
    }
    return CGSizeMake(w, h);
}
- (void)refreshImageSize {
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGFloat w;
    CGFloat h;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        w = height / self.model.imageSize.height * imgWidth;
        h = height;
        self.scrollView.maximumZoomScale = width / w + 0.5;
        self.previewContentView.frame = CGRectMake(0, 0, w, h);
        self.previewContentView.center = CGPointMake(width / 2, height / 2);
        self.scrollView.contentSize = CGSizeMake(self.hx_w, self.hx_h);
    }else {
        imgHeight = width / imgWidth * imgHeight;
        w = width;
        h = imgHeight;
        if (w < h) {
            self.scrollView.maximumZoomScale = self.frame.size.width * 2.5f / w;
        } else {
            self.scrollView.maximumZoomScale = self.frame.size.height * 2.5f / h;
        }
        self.previewContentView.frame = CGRectMake(0, 0, w, h);
        if (h < height) {
            self.previewContentView.center = CGPointMake(width / 2, height / 2);
            self.scrollView.contentSize = CGSizeMake(self.hx_w, self.hx_h);
        }else {
            self.scrollView.contentSize = self.previewContentView.hx_size;
        }
    }
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    [self cancelRequest];
    [self resetScale:NO];

    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGFloat w;
    CGFloat h;
    
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        w = height / self.model.imageSize.height * imgWidth;
        h = height;
        self.scrollView.maximumZoomScale = width / w + 0.5;

        self.previewContentView.frame = CGRectMake(0, 0, w, h);
        self.previewContentView.center = CGPointMake(width / 2, height / 2);
        self.scrollView.contentSize = CGSizeMake(self.hx_w, self.hx_h);
    }else {
        imgHeight = width / imgWidth * imgHeight;
        w = width;
        h = imgHeight;
        if (w < h) {
            self.scrollView.maximumZoomScale = self.frame.size.width * 2.5f / w;
        } else {
            self.scrollView.maximumZoomScale = self.frame.size.height * 2.5f / h;
        }

        self.previewContentView.frame = CGRectMake(0, 0, w, h);
        if (h < height) {
            self.previewContentView.center = CGPointMake(width / 2, height / 2);
            self.scrollView.contentSize = CGSizeMake(self.hx_w, self.hx_h);
        }else {
            self.scrollView.contentSize = self.previewContentView.hx_size;
        }
    }
    self.previewContentView.model = model;
}
- (void)requestHDImage {
    HXWeakSelf
    [self.previewContentView requestHD];
    self.previewContentView.downloadICloudAssetComplete = ^{
        [weakSelf downloadICloudAssetComplete];
    };
}
- (void)downloadICloudAssetComplete {
    if (self.model.isICloud) {
        self.model.iCloudDownloading = NO;
        self.model.isICloud = NO;
        if (self.cellDownloadICloudAssetComplete) {
            self.cellDownloadICloudAssetComplete(self);
        }
    }
}
- (void)cancelRequest {
    self.previewContentView.stopCancel = self.stopCancel;
    [self.previewContentView cancelRequest];
    self.stopCancel = NO;
}
- (void)singleTap:(UITapGestureRecognizer *)tap {
    if (self.cellTapClick) {
        self.cellTapClick(self.model, self);
    }
}
- (void)doubleTap:(UITapGestureRecognizer *)tap {
    if (self.scrollView.zoomScale > 1.0) {
        [self.scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGFloat width = self.frame.size.width;
        CGFloat height = self.frame.size.height;
        CGPoint touchPoint;
        touchPoint = [tap locationInView:self.previewContentView];
        CGFloat newZoomScale = self.scrollView.maximumZoomScale;
        CGFloat xsize = width / newZoomScale;
        CGFloat ysize = height / newZoomScale;
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}
#pragma mark - < UIScrollViewDelegate >
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.isTracking && scrollView.isDecelerating) {
        self.allowInteration = NO;
    }
}
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.previewContentView;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.frame.size.width > scrollView.contentSize.width) ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.frame.size.height > scrollView.contentSize.height) ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    self.previewContentView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y >= -40) {
        self.allowInteration = YES;
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectEqualToRect(self.scrollView.frame, self.bounds)) {
        self.scrollView.frame = self.bounds;
    }
}
#pragma mark - < 懒加载 >
- (UIScrollView *)scrollView {
    if (!_scrollView) {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.bouncesZoom = YES;
    _scrollView.minimumZoomScale = 1;
    _scrollView.multipleTouchEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.scrollsToTop = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.delaysContentTouches = NO;
    _scrollView.canCancelContentTouches = YES;
    _scrollView.alwaysBounceVertical = NO;
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
        if ((NO)) {
#endif
        }
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [_scrollView addGestureRecognizer:tap1];
        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        tap2.numberOfTapsRequired = 2;
        [tap1 requireGestureRecognizerToFail:tap2];
        [_scrollView addGestureRecognizer:tap2];
        [self addGesture];
    }
    return _scrollView;
}
- (void)addGesture {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToLongPress:)];
    [self.scrollView addGestureRecognizer:longPress];
}
- (void)respondsToLongPress:(UILongPressGestureRecognizer *)sender {
    if (self.cellViewLongPressGestureRecognizerBlock) {
        self.cellViewLongPressGestureRecognizerBlock(sender);
    }
}
- (UIImage *)image {
    return self.previewContentView.image;
} 
- (CGFloat)zoomScale {
    return self.scrollView.zoomScale;
}
- (void)dealloc {
    [self cancelRequest];
}
@end
