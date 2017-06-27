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
@property (weak, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) UIButton *deleteBtn;
@property (weak, nonatomic) UIView *bottomView;
@property (weak, nonatomic) UIImageView *videoIcon;
@property (weak, nonatomic) UILabel *videoTime;
@property (weak, nonatomic) UIImageView *gifIcon;
@property (weak, nonatomic) UIImageView *liveIcon;
@property (strong, nonatomic) HXCircleProgressView *progressView;
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

- (void)setup
{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:imageView];
    self.imageView = imageView;
    
    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [deleteBtn setImage:[HXPhotoTools hx_imageNamed:@"compose_delete@2x.png"] forState:UIControlStateNormal];
    [deleteBtn addTarget:self action:@selector(didDeleteClick) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:deleteBtn];
    self.deleteBtn = deleteBtn;
    
    UIImageView *liveIcon = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"compose_live_photo_open_only_icon@2x.png"]];
    liveIcon.frame = CGRectMake(5, 5, liveIcon.image.size.width, liveIcon.image.size.height);
    [self.contentView addSubview:liveIcon];
    self.liveIcon = liveIcon;
    
    UIView *bottomView = [[UIView alloc] init];
    bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    bottomView.hidden = YES;
    [self.contentView addSubview:bottomView];
    self.bottomView = bottomView;
    
    UIImageView *videoIcon = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"VideoSendIcon@2x.png"]];
    [bottomView addSubview:videoIcon];
    self.videoIcon = videoIcon;
    
    UILabel *videoTime = [[UILabel alloc] init];
    videoTime.textColor = [UIColor whiteColor];
    videoTime.textAlignment = NSTextAlignmentRight;
    videoTime.font = [UIFont systemFontOfSize:10];
    [bottomView addSubview:videoTime];
    self.videoTime = videoTime;
    
    UIImageView *gifIcon = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"timeline_image_gif@2x.png"]];
    [self.contentView addSubview:gifIcon];
    self.gifIcon = gifIcon;
    
    self.progressView = [[HXCircleProgressView alloc] init];
    self.progressView.hidden = YES;
    [self.contentView addSubview:self.progressView];
}

- (void)didDeleteClick
{
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
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:self.model.networkPhotoUrl] placeholderImage:self.model.thumbPhoto options:SDWebImageCacheMemoryOnly progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        self.model.receivedSize = receivedSize;
        self.model.expectedSize = expectedSize;
        CGFloat progress = (CGFloat)receivedSize / expectedSize;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
        });
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (error != nil) {
            self.model.downloadError = YES;
            self.model.downloadComplete = YES;
            [self.progressView showError];
        }else {
            if (image) {
                self.progressView.progress = 1;
                self.progressView.hidden = YES;
                self.imageView.image = image;
                self.model.imageSize = image.size;
                self.model.thumbPhoto = image;
                self.model.previewPhoto = image;
                self.userInteractionEnabled = YES;
                self.model.downloadComplete = YES;
            }
        }
    }];
}

- (void)setModel:(HXPhotoModel *)model
{
    _model = model;
    if (model.previewPhoto) {
        self.imageView.image = model.previewPhoto;
    }else {
        self.imageView.image = model.thumbPhoto;
    }
    self.videoTime.text = model.videoTime;
    self.gifIcon.hidden = YES;
    self.liveIcon.hidden = YES;
    if (model.type == HXPhotoModelMediaTypeCamera) {
        self.deleteBtn.hidden = YES;
        self.bottomView.hidden = YES;
    }else {
        self.deleteBtn.hidden = NO;
    }
    if (model.networkPhotoUrl.length > 0) {
//        if ([[model.networkPhotoUrl substringFromIndex:model.networkPhotoUrl.length - 3] isEqualToString:@"gif"]) {
//            self.gifIcon.hidden = NO;
//        }
        self.progressView.hidden = model.downloadComplete;
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:model.networkPhotoUrl] placeholderImage:model.thumbPhoto options:SDWebImageCacheMemoryOnly progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            model.receivedSize = receivedSize;
            model.expectedSize = expectedSize;
            CGFloat progress = (CGFloat)receivedSize / expectedSize;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressView.progress = progress;
            });
        } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (error != nil) {
                model.downloadError = YES;
                model.downloadComplete = YES;
                [self.progressView showError];
            }else {
                if (image) {
                    self.progressView.progress = 1;
                    self.progressView.hidden = YES;
//                    self.imageView.image = image;
                    model.imageSize = image.size;
                    model.thumbPhoto = image;
                    model.previewPhoto = image;
                    self.userInteractionEnabled = YES;
                    model.downloadComplete = YES;
                }
            }
        }];
    }else {
        self.progressView.hidden = YES;
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
