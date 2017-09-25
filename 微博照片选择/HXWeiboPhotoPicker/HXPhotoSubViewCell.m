//
//  HXPhotoSubViewCell.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoSubViewCell.h"
#import "HXPhotoModel.h"
#import "HXCircleProgressView.h"
#import "HXPhotoTools.h"
@interface HXPhotoSubViewCell ()<UIAlertViewDelegate>
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIButton *deleteBtn;
@property (strong, nonatomic) UIView *bottomView;
@property (strong, nonatomic) UIImageView *videoIcon;
@property (strong, nonatomic) UILabel *videoTime;
@property (strong, nonatomic) UIImageView *gifIcon;
@property (strong, nonatomic) UIImageView *liveIcon;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@property (assign, nonatomic) int32_t requestID;
@end

@implementation HXPhotoSubViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
#pragma mark - < 懒加载 >
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imageView;
}
- (UIButton *)deleteBtn {
    if (!_deleteBtn) {
        _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteBtn setImage:[HXPhotoTools hx_imageNamed:@"compose_delete@2x.png"] forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(didDeleteClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteBtn;
}
- (UIImageView *)liveIcon {
    if (!_liveIcon) {
        _liveIcon = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"compose_live_photo_open_only_icon@2x.png"]];
        _liveIcon.frame = CGRectMake(5, 5, _liveIcon.image.size.width, _liveIcon.image.size.height);
    }
    return _liveIcon;
}
- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        _bottomView.hidden = YES;
    }
    return _bottomView;
}
- (UIImageView *)videoIcon {
    if (!_videoIcon) {
        _videoIcon = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"VideoSendIcon@2x.png"]];
    }
    return _videoIcon;
}
- (UILabel *)videoTime {
    if (!_videoTime) {
        _videoTime = [[UILabel alloc] init];
        _videoTime.textColor = [UIColor whiteColor];
        _videoTime.textAlignment = NSTextAlignmentRight;
        _videoTime.font = [UIFont systemFontOfSize:10];
    }
    return _videoTime;
}
- (UIImageView *)gifIcon {
    if (!_gifIcon) {
        _gifIcon = [[UIImageView alloc] init];
    }
    return _gifIcon;
}
- (HXCircleProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HXCircleProgressView alloc] init];
        _progressView.hidden = YES;
    }
    return _progressView;
}
- (void)setup
{
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.deleteBtn];
    [self.contentView addSubview:self.liveIcon];
    [self.contentView addSubview:self.bottomView];
    [self.bottomView addSubview:self.videoIcon];
    [self.bottomView addSubview:self.videoTime];
    [self.contentView addSubview:self.gifIcon];
    [self.contentView addSubview:self.progressView];
}

- (void)setDic:(NSDictionary *)dic {
    _dic = dic;
    if (!self.gifIcon.image && dic) {
        self.gifIcon.image = dic[@"gifIcon"];
    }
}

- (void)didDeleteClick {
    if (self.model.networkPhotoUrl.length > 0) {
        if (self.showDeleteNetworkPhotoAlert) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"是否删除此照片" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            [alert show];
            return;
        }
    }
    [self.imageView sd_cancelCurrentAnimationImagesLoad];
    if ([self.delegate respondsToSelector:@selector(cellDidDeleteClcik:)]) {
        [self.delegate cellDidDeleteClcik:self];
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if ([self.delegate respondsToSelector:@selector(cellDidDeleteClcik:)]) {
            [self.delegate cellDidDeleteClcik:self];
        }
    }
}

- (void)againDownload {
    self.model.downloadError = NO;
    self.model.downloadComplete = NO;
    __weak typeof(self) weakSelf = self;
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:self.model.networkPhotoUrl] placeholderImage:self.model.thumbPhoto options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        weakSelf.model.receivedSize = receivedSize;
        weakSelf.model.expectedSize = expectedSize;
        CGFloat progress = (CGFloat)receivedSize / expectedSize;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progressView.progress = progress;
        });
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (error != nil) {
            weakSelf.model.downloadError = YES;
            weakSelf.model.downloadComplete = YES;
            [weakSelf.progressView showError];
        }else {
            if (image) {
                weakSelf.progressView.progress = 1;
                weakSelf.progressView.hidden = YES;
                weakSelf.imageView.image = image;
                weakSelf.model.imageSize = image.size;
                weakSelf.model.thumbPhoto = image;
                weakSelf.model.previewPhoto = image;
                weakSelf.userInteractionEnabled = YES;
                weakSelf.model.downloadComplete = YES;
                weakSelf.model.downloadError = NO;
                if ([weakSelf.delegate respondsToSelector:@selector(cellNetworkingPhotoDownLoadComplete)]) {
                    [weakSelf.delegate cellNetworkingPhotoDownLoadComplete];
                }
            }
        }
    }];
}

- (void)setModel:(HXPhotoModel *)model
{
    _model = model;
//    if (model.previewPhoto) {
//        self.imageView.image = model.previewPhoto;
//    }else {
//        self.imageView.image = model.thumbPhoto;
//    }
    self.videoTime.text = model.videoTime;
    self.gifIcon.hidden = YES;
    self.liveIcon.hidden = YES;
    if (model.type == HXPhotoModelMediaTypeCamera) {
        self.deleteBtn.hidden = YES;
        self.bottomView.hidden = YES;
//        self.imageView.image = model.thumbPhoto;
    }else {
        self.deleteBtn.hidden = NO;
    }
    if (model.networkPhotoUrl.length > 0) {
//        if ([[model.networkPhotoUrl substringFromIndex:model.networkPhotoUrl.length - 3] isEqualToString:@"gif"]) {
//            self.gifIcon.hidden = NO;
//        }
        __weak typeof(self) weakSelf = self;
        self.progressView.hidden = model.downloadComplete;
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:model.networkPhotoUrl] placeholderImage:model.thumbPhoto options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            model.receivedSize = receivedSize;
            model.expectedSize = expectedSize;
            CGFloat progress = (CGFloat)receivedSize / expectedSize;
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.progressView.progress = progress;
            });
        } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (error != nil) {
                model.downloadError = YES;
                model.downloadComplete = YES;
                [weakSelf.progressView showError];
            }else {
                if (image) {
                    weakSelf.progressView.progress = 1;
                    weakSelf.progressView.hidden = YES;
                    weakSelf.imageView.image = image;
                    
                    model.imageSize = image.size;
                    model.thumbPhoto = image;
                    model.previewPhoto = image;
                    weakSelf.userInteractionEnabled = YES;
                    model.downloadComplete = YES;
                    model.downloadError = NO;
                    if ([weakSelf.delegate respondsToSelector:@selector(cellNetworkingPhotoDownLoadComplete)]) {
                        [weakSelf.delegate cellNetworkingPhotoDownLoadComplete];
                    }
                }
            }
        }];
    }else {
        self.progressView.hidden = YES;
        if (model.previewPhoto) {
            self.imageView.image = model.previewPhoto;
        }else {
            self.imageView.image = model.thumbPhoto;
        }
    }
    if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        if (model.type == HXPhotoModelMediaTypePhotoGif) {
            self.gifIcon.hidden = NO;
        }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            self.liveIcon.hidden = NO;
        }
        self.bottomView.hidden = YES;
    }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
        self.bottomView.hidden = NO;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat deleteBtnW = self.deleteBtn.currentImage.size.width;
    CGFloat deleteBtnH = self.deleteBtn.currentImage.size.height;
    self.deleteBtn.frame = CGRectMake(width - deleteBtnW, 0, deleteBtnW, deleteBtnH);
    
    self.bottomView.frame = CGRectMake(0, height - 25, width, 25);
    CGFloat iconWidth = self.videoIcon.image.size.width;
    CGFloat iconHeight = self.videoIcon.image.size.height;
    self.videoIcon.frame = CGRectMake(5, 0, iconWidth, iconHeight);
    self.videoIcon.center = CGPointMake(self.videoIcon.center.x, 25 / 2);
    self.videoTime.frame = CGRectMake(CGRectGetMaxX(self.videoIcon.frame), 0, width - CGRectGetMaxX(self.videoIcon.frame) - 5, 25);
    
    self.gifIcon.frame = CGRectMake(width - self.gifIcon.image.size.width, height - self.gifIcon.image.size.height, self.gifIcon.image.size.width, self.gifIcon.image.size.height);
    
//    self.progressView.frame = CGRectMake(0, 0, 60, 60);
    self.progressView.center = CGPointMake(width / 2, height / 2);
}

@end
