//
//  HXPhoto3DTouchViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/9/25.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhoto3DTouchViewController.h"
#import <PhotosUI/PhotosUI.h>
#import "UIImage+HXExtension.h"
@interface HXPhoto3DTouchViewController () {
    PHImageRequestID requestId;
}
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@end

@implementation HXPhoto3DTouchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.hx_size = self.model.endImageSize;
    self.imageView.image = self.image;
    [self.view addSubview:self.imageView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    switch (self.model.type) {
        case HXPhotoModelMediaTypeVideo:
            [self loadVideo];
            break;
        case HXPhotoModelMediaTypeCameraVideo:
            [self loadVideo];
            break;
        case HXPhotoModelMediaTypePhotoGif:
            [self loadGifPhoto];
            break;
        case HXPhotoModelMediaTypeLivePhoto:
            [self loadLivePhoto];
            break;
        default:
            [self loadPhoto];
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[PHImageManager defaultManager] cancelImageRequest:requestId];
    [self.player pause];
    if (_livePhotoView) {
        [self.livePhotoView stopPlayback];
    }
}

- (void)loadPhoto {
    if (self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
        self.imageView.image = self.model.thumbPhoto;
        return;
    }
    __weak typeof(self) weakSelf = self;
    requestId = [HXPhotoTools fetchPhotoWithAsset:self.model.asset photoSize:CGSizeMake(self.model.endImageSize.width * 1.5, self.model.endImageSize.height * 1.5) completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        weakSelf.imageView.image = photo;
    }];
}

- (void)loadGifPhoto {
    __weak typeof(self) weakSelf = self;
    requestId = [HXPhotoTools FetchPhotoDataForPHAsset:self.model.asset completion:^(NSData *imageData, NSDictionary *info) {
        if (imageData) {
            UIImage *gifImage = [UIImage animatedGIFWithData:imageData];
            if (gifImage.images.count > 0) {
                weakSelf.imageView.image = nil;
                weakSelf.imageView.image = gifImage;
            }
        }
    }];
}

- (void)loadLivePhoto {
    if (self.model.isCloseLivePhoto) {
        [self loadPhoto];
        return;
    }
    self.livePhotoView.hx_size = self.model.endImageSize;
    [self.view addSubview:self.livePhotoView];
    __weak typeof(self) weakSelf = self;
    requestId = [HXPhotoTools FetchLivePhotoForPHAsset:self.model.asset Size:CGSizeMake(self.model.endImageSize.width * 1.5, self.model.endImageSize.height * 1.5) Completion:^(PHLivePhoto *livePhoto, NSDictionary *info) {
        weakSelf.livePhotoView.livePhoto = livePhoto;
        [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        [weakSelf.imageView removeFromSuperview];
    }];
}

- (void)loadVideo {
    if (self.model.type == HXPhotoModelMediaTypeCameraVideo) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.model.videoURL];
        self.player = [AVPlayer playerWithPlayerItem:playerItem];
    }else {
        self.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.model.avAsset]];
    }
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 0, self.model.endImageSize.width, self.model.endImageSize.height);
    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player play];
        [self.imageView removeFromSuperview];
    });
}

- (void)dealloc {
    [self.playerLayer removeFromSuperlayer];
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.hx_x = 0;
        _imageView.hx_y = 0;
    }
    return _imageView;
}
- (PHLivePhotoView *)livePhotoView {
    if (!_livePhotoView) {
        _livePhotoView = [[PHLivePhotoView alloc] init];
        _livePhotoView.clipsToBounds = YES;
        _livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _livePhotoView;
}
@end
