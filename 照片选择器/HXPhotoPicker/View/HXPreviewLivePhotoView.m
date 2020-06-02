//
//  HXPreviewLivePhotoView.m
//  照片选择器
//
//  Created by 洪欣 on 2019/11/15.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import "HXPreviewLivePhotoView.h"
#import "HXPhotoModel.h"
#import <PhotosUI/PhotosUI.h>
#import "HXPhotoDefine.h"
#import "HXCircleProgressView.h"

@interface HXPreviewLivePhotoView ()<PHLivePhotoViewDelegate>
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (assign, nonatomic) BOOL livePhotoAnimating;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@end

@implementation HXPreviewLivePhotoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.progressView];
        [self addSubview:self.livePhotoView];
    }
    return self;
}

- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        [PHLivePhoto cancelLivePhotoRequestWithRequestID:self.requestID];
        self.requestID = -1;
    }
    if (_livePhotoView.livePhoto) {
        [self.livePhotoView stopPlayback];
        [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        return;
    }
    if (self.model.iCloudRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.model.iCloudRequestID];
        self.model.iCloudRequestID = -1;
    }
    HXWeakSelf
    if (model.type == HXPhotoModelMediaTypeCameraPhoto &&
        model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto) {
        self.requestID = [model requestLocalLivePhotoWithCompletion:^(PHLivePhoto * _Nullable livePhoto, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
            if (weakSelf.model != model) return;
            if (weakSelf.downloadICloudAssetComplete) {
                weakSelf.downloadICloudAssetComplete();
            }
            [weakSelf.livePhotoView stopPlayback];
            weakSelf.livePhotoView.livePhoto = livePhoto;
            [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        }];
        return;
    }
    self.requestID = [self.model requestLivePhotoWithSize:self.model.endImageSize startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
        if (weakSelf.model != model) return;
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
        weakSelf.requestID = iCloudRequestId;
    } progressHandler:^(double progress, HXPhotoModel *model) {
        if (weakSelf.model != model) return;
        if (weakSelf.model.isICloud) {
            weakSelf.progressView.hidden = NO;
        }
        weakSelf.progressView.progress = progress;
    } success:^(PHLivePhoto *livePhoto, HXPhotoModel *model, NSDictionary *info) {
        if (weakSelf.model != model) return;
        if (weakSelf.downloadICloudAssetComplete) {
            weakSelf.downloadICloudAssetComplete();
        }
        weakSelf.livePhotoView.livePhoto = livePhoto;
        [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
    } failed:^(NSDictionary *info, HXPhotoModel *model) {
        if (weakSelf.model != model) return;
        weakSelf.progressView.hidden = YES;
    }];
}
- (void)cancelLivePhoto {
    if (self.requestID) {
        if (self.model.type == HXPhotoModelMediaTypeCameraPhoto &&
            self.model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto) {
                [PHLivePhoto cancelLivePhotoRequestWithRequestID:self.requestID];
        }else {
            [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        }
        self.requestID = -1;
    }
    if (!self.stopCancel) {
        self.progressView.hidden = YES;
        self.progressView.progress = 0;
        if (_livePhotoView.livePhoto) {
            self.livePhotoView.livePhoto = nil;
            [self stopLivePhoto];
        }
    }
    self.stopCancel = NO;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectEqualToRect(self.livePhotoView.frame, self.bounds)) {
        self.livePhotoView.frame = self.bounds;
    }
}
#pragma mark - < PHLivePhotoViewDelegate >
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    self.livePhotoAnimating = YES;
}
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
//    [self stopLivePhoto];
    [livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
}
- (void)stopLivePhoto {
    self.livePhotoAnimating = NO;
    [self.livePhotoView stopPlayback];
}

- (PHLivePhotoView *)livePhotoView {
    if (!_livePhotoView) {
        _livePhotoView = [[PHLivePhotoView alloc] init];
        _livePhotoView.clipsToBounds = YES;
        _livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
        _livePhotoView.delegate = self;
    }
    return _livePhotoView;
}
- (HXCircleProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HXCircleProgressView alloc] init];
        _progressView.hidden = YES;
    }
    return _progressView;
}

@end
