//
//  HXPhotoViewCell.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoViewCell.h"
#import "HXPhotoTools.h"
#import "UIButton+HXExtension.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import "HXPhotoPreviewViewController.h"
@interface HXPhotoViewCell ()<UIViewControllerPreviewingDelegate>
@property (strong, nonatomic) UIView *bottomView;
@property (strong, nonatomic) UIButton *cameraBtn;
@property (strong, nonatomic) UIImageView *videoIcon;
@property (strong, nonatomic) UILabel *videoTime;
@property (strong, nonatomic) UIImageView *gifIcon;
@property (strong, nonatomic) UIImageView *liveIcon;
@property (strong, nonatomic) UIButton *liveBtn;
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (copy, nonatomic) NSString *localIdentifier;
@property (strong, nonatomic) UIImageView *previewImg;
@property (assign, nonatomic) PHImageRequestID liveRequestID;
@property (assign, nonatomic) BOOL addImageComplete;
@end

@implementation HXPhotoViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.requestID = 0; 
        [self setup];
    }
    return self;
}
#pragma mark - < 懒加载 >
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.frame = self.bounds;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}
- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.hx_h - 25, self.hx_w, 25)];
        _bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        _bottomView.hidden = YES;
    }
    return _bottomView;
}
- (UIImageView *)videoIcon {
    if (!_videoIcon) {
        _videoIcon = [[UIImageView alloc] init];
        _videoIcon.frame = CGRectMake(5, 0, 17, 17);
        _videoIcon.center = CGPointMake(_videoIcon.center.x, 25 / 2);
    }
    return _videoIcon;
}
- (UILabel *)videoTime {
    if (!_videoTime) {
        _videoTime = [[UILabel alloc] init];
        _videoTime.textColor = [UIColor whiteColor];
        _videoTime.textAlignment = NSTextAlignmentRight;
        _videoTime.font = [UIFont systemFontOfSize:10];
        _videoTime.frame = CGRectMake(CGRectGetMaxX(_videoTime.frame), 0, self.hx_w - CGRectGetMaxX(_videoTime.frame) - 5, 25);
    }
    return _videoTime;
}
- (UIImageView *)gifIcon {
    if (!_gifIcon) {
        _gifIcon = [[UIImageView alloc] init];
        _gifIcon.frame = CGRectMake(self.hx_w - 28, self.hx_h - 18, 28, 18);
    }
    return _gifIcon;
}
- (UIImageView *)liveIcon {
    if (!_liveIcon) {
        _liveIcon = [[UIImageView alloc] init];
        _liveIcon.frame = CGRectMake(7, 5, 18, 18);
    }
    return _liveIcon;
}
- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.bounds];
        _maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        _maskView.hidden = YES;
    }
    return _maskView;
}
- (UIButton *)liveBtn {
    if (!_liveBtn) {
        _liveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_liveBtn setTitle:@"LIVE" forState:UIControlStateNormal];
        [_liveBtn setTitle:[NSBundle hx_localizedStringForKey:@"关闭"] forState:UIControlStateSelected];
        [_liveBtn setTitleColor:[UIColor colorWithRed:85/255.0 green:85/255.0 blue:85/255.0 alpha:1] forState:UIControlStateNormal];
        _liveBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        _liveBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 2, 0, 0);
        _liveBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        _liveBtn.frame = CGRectMake(5, 5, 55, 24);
        [_liveBtn addTarget:self action:@selector(didLivePhotoBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _liveBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _liveBtn.hidden = YES;
    }
    return _liveBtn;
}
- (UIButton *)selectBtn {
    if (!_selectBtn) {
        _selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectBtn addTarget:self action:@selector(didSelectClick:) forControlEvents:UIControlEventTouchUpInside];
        _selectBtn.frame = CGRectMake(self.hx_w - 32, 0, 32, 32);
        _selectBtn.center = CGPointMake(_selectBtn.center.x, self.liveBtn.center.y);
        self.liveIcon.center = CGPointMake(self.liveIcon.center.x, self.liveBtn.center.y);
        [_selectBtn setEnlargeEdgeWithTop:0 right:0 bottom:30 left:30];
    }
    return _selectBtn;
}
- (UIButton *)cameraBtn {
    if (!_cameraBtn) {
        _cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraBtn setBackgroundColor:[UIColor whiteColor]];
        _cameraBtn.userInteractionEnabled = NO;
        _cameraBtn.frame = self.bounds;
    }
    return _cameraBtn;
}
- (void)setIconDic:(NSDictionary *)iconDic {
    _iconDic = iconDic;
    if (self.addImageComplete) {
        return;
    }
    if (!self.videoIcon.image) {
        self.videoIcon.image = iconDic[@"videoIcon"];
    }
    if (!self.gifIcon.image) {
        self.gifIcon.image = iconDic[@"gifIcon"];
    }
    if (!self.liveIcon.image) {
        self.liveIcon.image = iconDic[@"liveIcon"];
    }
    if (!self.liveBtn.currentImage) {
        [self.liveBtn setImage:iconDic[@"liveBtnImageNormal"] forState:UIControlStateNormal];
        [self.liveBtn setImage:iconDic[@"liveBtnImageSelected"] forState:UIControlStateSelected];
    }
    if (!self.liveBtn.currentBackgroundImage) {
        [self.liveBtn setBackgroundImage:iconDic[@"liveBtnBackgroundImage"] forState:UIControlStateNormal];
    }
    if (!self.selectBtn.currentImage) {
        [self.selectBtn setImage:iconDic[@"selectBtnNormal"] forState:UIControlStateNormal];
        [self.selectBtn setImage:iconDic[@"selectBtnSelected"] forState:UIControlStateSelected];
    }
    self.addImageComplete = YES;
}
- (void)setup {
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.bottomView];
    [self.bottomView addSubview:self.videoIcon];
    [self.bottomView addSubview:self.videoTime];
    [self.contentView addSubview:self.gifIcon];
    [self.contentView addSubview:self.liveIcon];
    [self.contentView addSubview:self.maskView];
    [self.contentView addSubview:self.liveBtn];
    [self.contentView addSubview:self.selectBtn];
    [self.contentView addSubview:self.cameraBtn];
}

- (void)didLivePhotoBtnClick:(UIButton *)button {
    button.selected = !button.selected;
    self.model.isCloseLivePhoto = button.selected;
    if (button.selected) {
        [self.livePhotoView stopPlayback];
        [self.livePhotoView removeFromSuperview];
    }else {
        [self startLivePhoto];
    }
    if ([self.delegate respondsToSelector:@selector(cellChangeLivePhotoState:)]) {
        [self.delegate cellChangeLivePhotoState:self.model];
    }
}

- (PHLivePhotoView *)livePhotoView {
    if (!_livePhotoView) {
        _livePhotoView = [[PHLivePhotoView alloc] init];
        _livePhotoView.clipsToBounds = YES;
        _livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
        _livePhotoView.frame = self.bounds;
    }
    return _livePhotoView;
}

- (void)startLivePhoto {
    self.liveIcon.hidden = YES;
    self.liveBtn.hidden = NO;
    if (self.model.isCloseLivePhoto) {
        return;
    }
    [self.contentView insertSubview:self.livePhotoView aboveSubview:self.imageView];
    CGFloat width = self.frame.size.width;
    __weak typeof(self) weakSelf = self;
    CGSize size;
    if (self.model.imageSize.width > self.model.imageSize.height / 9 * 15) {
        size = CGSizeMake(width, width * 1.5);
    }else if (self.model.imageSize.height > self.model.imageSize.width / 9 * 15) {
        size = CGSizeMake(width * 1.5, width);
    }else {
        size = CGSizeMake(width, width);
    }
    self.liveRequestID = [HXPhotoTools FetchLivePhotoForPHAsset:self.model.asset Size:size Completion:^(PHLivePhoto *livePhoto, NSDictionary *info) {
        weakSelf.livePhotoView.livePhoto = livePhoto;
        [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleHint];
    }];
}

- (void)stopLivePhoto {
    [[PHCachingImageManager defaultManager] cancelImageRequest:self.liveRequestID];
    self.liveIcon.hidden = NO;
    self.liveBtn.hidden = YES;
    [self.livePhotoView stopPlayback];
    [self.livePhotoView removeFromSuperview];
}

- (void)didSelectClick:(UIButton *)button {
    if (self.model.type == HXPhotoModelMediaTypeCamera) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(cellDidSelectedBtnClick:Model:)]) {
        [self.delegate cellDidSelectedBtnClick:self Model:self.model];
    }
}

- (void)setSingleSelected:(BOOL)singleSelected {
    _singleSelected = singleSelected;
    if (singleSelected) {
        [self.maskView removeFromSuperview];
        [self.selectBtn removeFromSuperview];
    }
}

- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    if (model.type == HXPhotoModelMediaTypeCamera || model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
        self.imageView.image = model.thumbPhoto;
    }else {
        self.localIdentifier = model.asset.localIdentifier;
        __weak typeof(self) weakSelf = self;
        int32_t requestID = [HXPhotoTools fetchPhotoWithAsset:model.asset photoSize:model.requestSize completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.model.type != HXPhotoModelMediaTypeCamera && strongSelf.model.type != HXPhotoModelMediaTypeCameraPhoto && strongSelf.model.type != HXPhotoModelMediaTypeCameraVideo) {
                strongSelf.imageView.image = photo;
            }else {
                if (strongSelf.requestID) {
                    [[PHImageManager defaultManager] cancelImageRequest:strongSelf.requestID];
                    strongSelf.requestID = -1;
                }
            }
        }];
        if (requestID && self.requestID && requestID != self.requestID) {
            [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        }
        self.requestID = requestID;
    }

    self.videoTime.text = model.videoTime;
    self.liveIcon.hidden = YES;
    self.liveBtn.hidden = YES;
    self.gifIcon.hidden = YES;
    self.cameraBtn.hidden = YES;
    if (model.type == HXPhotoModelMediaTypeVideo) {
        self.bottomView.hidden = NO;
    }else if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)){
        self.bottomView.hidden = YES;
        if (model.type == HXPhotoModelMediaTypePhotoGif) {
            self.gifIcon.hidden = NO;
        }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            self.liveIcon.hidden = NO;
            if (model.selected) {
                self.liveIcon.hidden = YES;
                self.liveBtn.hidden = NO;
                self.liveBtn.selected = model.isCloseLivePhoto;
            }
        }
    }else if (model.type == HXPhotoModelMediaTypeCamera){
        [self.cameraBtn setImage:model.thumbPhoto forState:UIControlStateNormal];
        self.cameraBtn.hidden = NO;
    }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        self.bottomView.hidden = YES;
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        self.bottomView.hidden = NO;
    }
    self.maskView.hidden = !model.selected;
    self.selectBtn.selected = model.selected;
} 

@end
