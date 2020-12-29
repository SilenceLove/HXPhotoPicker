//
//  HXPreviewContentView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/11/19.
//  Copyright © 2019 Silence. All rights reserved.
//

#import "HXPreviewContentView.h"
#import "HXPhotoModel.h"
#import "HXPhotoDefine.h"

@interface HXPreviewContentView ()
@property (assign, nonatomic) HXPreviewContentViewType type;
@end

@implementation HXPreviewContentView
- (instancetype)initWithType:(HXPreviewContentViewType)type {
    self = [super init];
    if (self) {
        self.type = type;
        [self addSubview:self.imageView];
        if (type == HXPreviewContentViewTypeLivePhoto) {
            [self addSubview:self.livePhotoView];
        }else if (type == HXPreviewContentViewTypeVideo) {
            [self addSubview:self.videoView];
        }
    }
    return self;
}
- (void)setAllowPreviewDirectLoadOriginalImage:(BOOL)allowPreviewDirectLoadOriginalImage {
    _allowPreviewDirectLoadOriginalImage = allowPreviewDirectLoadOriginalImage;
    self.imageView.allowPreviewDirectLoadOriginalImage = allowPreviewDirectLoadOriginalImage;
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    if (self.type == HXPreviewContentViewTypeLivePhoto) {
        self.livePhotoView.hidden = YES;
    }else if (self.type == HXPreviewContentViewTypeVideo) {
        self.imageView.hidden = NO;
        [self.videoView cancelPlayer];
    }
    self.imageView.model = model;
}
- (AVAsset *)avAsset {
    return self.videoView.avAsset;
}
- (UIImage *)image {
    return self.imageView.image;
}
- (UIImage *)gifImage {
    return self.imageView.gifImage;
}
- (void)cancelRequest {
    if (!self.stopCancel) {
        self.imageView.hidden = NO;
    }
    if (self.type == HXPreviewContentViewTypeImage) {
        self.imageView.stopCancel = self.stopCancel;
        [self.imageView cancelImage];
    }else if (self.type == HXPreviewContentViewTypeLivePhoto) {
        self.livePhotoView.stopCancel = self.stopCancel;
        [self.livePhotoView cancelLivePhoto];
        if (!self.stopCancel) {
            self.livePhotoView.hidden = YES;
        }
    }else if (self.type == HXPreviewContentViewTypeVideo) {
        self.videoView.stopCancel = self.stopCancel;
        [self.videoView cancelPlayer];
    }
    self.stopCancel = NO;
}
- (void)requestHD {
    HXWeakSelf
    if (self.type == HXPreviewContentViewTypeImage) {
        [self.imageView requestHDImage];
        self.imageView.downloadICloudAssetComplete = self.downloadICloudAssetComplete;
    }else if (self.type == HXPreviewContentViewTypeLivePhoto) {
        if (self.model.photoEdit) {
            return;
        }
        [self.imageView requestHDImage];
        self.livePhotoView.model = self.model;
        if (self.model.type == HXPhotoModelMediaTypeCameraPhoto &&
            (self.model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto ||
             self.model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkLivePhoto)) {
            self.livePhotoView.hidden = NO;
        }
        self.livePhotoView.downloadICloudAssetComplete = ^{
            weakSelf.livePhotoView.hidden = NO;
            weakSelf.imageView.hidden = YES;
            if (weakSelf.downloadICloudAssetComplete) {
                weakSelf.downloadICloudAssetComplete();
            }
        };
    }else if (self.type == HXPreviewContentViewTypeVideo) {
        [self.imageView requestHDImage];
        self.videoView.model = self.model;
        self.videoView.downloadICloudAssetComplete = ^{
            if (weakSelf.downloadICloudAssetComplete) {
                weakSelf.downloadICloudAssetComplete();
            }
        };
        self.videoView.shouldPlayVideo = ^{
            weakSelf.imageView.hidden = YES;
        };
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
        self.imageView.frame = self.bounds;
    if (self.type == HXPreviewContentViewTypeLivePhoto) {
        self.livePhotoView.frame = self.bounds;
    }else if (self.type == HXPreviewContentViewTypeVideo) {
        self.videoView.frame = self.bounds;
    }
} 

- (HXPreviewImageView *)imageView {
    if (!_imageView) {
        _imageView = [[HXPreviewImageView alloc] init];
        HXWeakSelf
        _imageView.downloadNetworkImageComplete = ^{
            if (weakSelf.downloadNetworkImageComplete) {
                weakSelf.downloadNetworkImageComplete();
            }
        };
    }
    return _imageView;
}
- (HXPreviewLivePhotoView *)livePhotoView {
    if (!_livePhotoView) {
        _livePhotoView = [[HXPreviewLivePhotoView alloc] init];
    }
    return _livePhotoView;
}
- (HXPreviewVideoView *)videoView {
    if (!_videoView) {
        _videoView = [[HXPreviewVideoView alloc] init];
    }
    return _videoView;
}
@end
