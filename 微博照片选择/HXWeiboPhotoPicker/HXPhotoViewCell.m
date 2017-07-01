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
@property (weak, nonatomic) UIView *bottomView;
@property (weak, nonatomic) UIImageView *videoIcon;
@property (weak, nonatomic) UILabel *videoTime;
@property (weak, nonatomic) UIButton *cameraBtn;
@property (weak, nonatomic) UIImageView *gifIcon;
@property (weak, nonatomic) UIImageView *liveIcon;
@property (weak, nonatomic) UIButton *liveBtn;
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (copy, nonatomic) NSString *localIdentifier;
@property (strong, nonatomic) UIImageView *previewImg;
@property (assign, nonatomic) PHImageRequestID liveRequestID;

@end

@implementation HXPhotoViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.requestID = 0;
        [self setup];
    }
    return self;
}
- (void)setup
{
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = self.bounds;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [self.contentView addSubview:imageView];
    self.imageView = imageView;
    
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, height - 25, width, 25)];
    bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    bottomView.hidden = YES;
    [self.contentView addSubview:bottomView];
    self.bottomView = bottomView;
    
    UIImageView *videoIcon = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"VideoSendIcon@2x.png"]];
    CGFloat iconWidth = videoIcon.image.size.width;
    CGFloat iconHeight = videoIcon.image.size.height;
    videoIcon.frame = CGRectMake(5, 0, iconWidth, iconHeight);
    videoIcon.center = CGPointMake(videoIcon.center.x, 25 / 2);
    [bottomView addSubview:videoIcon];
    self.videoIcon = videoIcon;
    
    UILabel *videoTime = [[UILabel alloc] init];
    videoTime.textColor = [UIColor whiteColor];
    videoTime.textAlignment = NSTextAlignmentRight;
    videoTime.font = [UIFont systemFontOfSize:10];
    videoTime.frame = CGRectMake(CGRectGetMaxX(videoIcon.frame), 0, width - CGRectGetMaxX(videoIcon.frame) - 5, 25);
    [bottomView addSubview:videoTime];
    self.videoTime = videoTime;
    
    UIImageView *gifIcon = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"timeline_image_gif@2x.png"]];
    gifIcon.frame = CGRectMake(self.frame.size.width - gifIcon.image.size.width, self.frame.size.height - gifIcon.image.size.height, gifIcon.image.size.width, gifIcon.image.size.height);
    [self.contentView addSubview:gifIcon];
    self.gifIcon = gifIcon;
    
    UIImageView *liveIcon = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"compose_live_photo_open_only_icon@2x.png"]];
    liveIcon.frame = CGRectMake(7, 5, liveIcon.image.size.width, liveIcon.image.size.height);
    [self.contentView addSubview:liveIcon];
    self.liveIcon = liveIcon;
    
    UIView *maskView = [[UIView alloc] initWithFrame:self.bounds];
    maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    maskView.hidden = YES;
    [self.contentView addSubview:maskView];
    self.maskView = maskView;
    
    UIButton *liveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [liveBtn setImage:[HXPhotoTools hx_imageNamed:@"compose_live_photo_open_icon@2x.png"] forState:UIControlStateNormal];
    [liveBtn setTitle:@"LIVE" forState:UIControlStateNormal];
    [liveBtn setImage:[HXPhotoTools hx_imageNamed:@"compose_live_photo_close_icon@2x.png"] forState:UIControlStateSelected];
    [liveBtn setTitle:@"关闭" forState:UIControlStateSelected];
    [liveBtn setBackgroundImage:[HXPhotoTools hx_imageNamed:@"compose_live_photo_background@2x.png"] forState:UIControlStateNormal];
    [liveBtn setTitleColor:[UIColor colorWithRed:85/255.0 green:85/255.0 blue:85/255.0 alpha:1] forState:UIControlStateNormal];
    liveBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
    liveBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 2, 0, 0);
    liveBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    liveBtn.frame = CGRectMake(5, 5, liveBtn.currentBackgroundImage.size.width, liveBtn.currentBackgroundImage.size.height);
    [liveBtn addTarget:self action:@selector(didLivePhotoBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    liveBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    liveBtn.hidden = YES;
    [self.contentView addSubview:liveBtn];
    self.liveBtn = liveBtn;

    UIButton *selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [selectBtn setImage:[HXPhotoTools hx_imageNamed:@"compose_guide_check_box_default@2x.png"] forState:UIControlStateNormal];
    [selectBtn setImage:[HXPhotoTools hx_imageNamed:@"compose_guide_check_box_right@2x.png"] forState:UIControlStateSelected];
    [selectBtn addTarget:self action:@selector(didSelectClick:) forControlEvents:UIControlEventTouchUpInside];
    CGFloat imageWidth = selectBtn.currentImage.size.width;
    CGFloat imageHeight = selectBtn.currentImage.size.height;
    selectBtn.frame = CGRectMake(width - imageWidth, 0, imageWidth, imageHeight);
    selectBtn.center = CGPointMake(selectBtn.center.x, liveBtn.center.y);
    liveIcon.center = CGPointMake(liveIcon.center.x, liveBtn.center.y);
    [selectBtn setEnlargeEdgeWithTop:0 right:0 bottom:30 left:30];
    [self.contentView addSubview:selectBtn];
    self.selectBtn = selectBtn;
    
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cameraBtn setBackgroundColor:[UIColor whiteColor]];
    cameraBtn.userInteractionEnabled = NO;
    [self.contentView addSubview:cameraBtn];
    cameraBtn.frame = self.bounds;
    self.cameraBtn = cameraBtn;
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

- (void)startLivePhoto {
    self.liveIcon.hidden = YES;
    self.liveBtn.hidden = NO;
    if (self.model.isCloseLivePhoto) {
        return;
    }
    self.livePhotoView = [[PHLivePhotoView alloc] init];
    self.livePhotoView.clipsToBounds = YES;
    self.livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
    self.livePhotoView.frame = self.bounds;
    [self.contentView insertSubview:self.livePhotoView aboveSubview:self.imageView];
//    if (self.model.livePhoto) {
//        self.livePhotoView.livePhoto = self.model.livePhoto;
//        [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleHint];
//    }else {
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
//            weakSelf.model.livePhoto = livePhoto;
            weakSelf.livePhotoView.livePhoto = livePhoto;
            [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleHint];
        }];
//    }
}

- (void)stopLivePhoto {
    [[PHCachingImageManager defaultManager] cancelImageRequest:self.liveRequestID];
    self.liveIcon.hidden = NO;
    self.liveBtn.hidden = YES;
    [self.livePhotoView stopPlayback];
    [self.livePhotoView removeFromSuperview];
    self.livePhotoView.delegate = nil;
    self.livePhotoView = nil;
    self.model.livePhoto = nil;
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
        self.maskView.hidden = YES;
        self.selectBtn.hidden = YES;
    }
}

- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    CGFloat width = self.frame.size.width;
    
    if (model.thumbPhoto) {
        self.imageView.image = model.thumbPhoto;
    }else {
        self.localIdentifier = model.asset.localIdentifier;
        __weak typeof(self) weakSelf = self;
        CGSize size;
        if (model.imageSize.width > model.imageSize.height / 9 * 15) {
            size = CGSizeMake(width, width * [UIScreen mainScreen].scale);
        }else if (model.imageSize.height > model.imageSize.width / 9 * 15) {
            size = CGSizeMake(width * [UIScreen mainScreen].scale, width);
        }else {
            size = CGSizeMake(width * 1.5, width * 1.5);
        }
        //if (model.endImageSize.height > model.endImageSize.width * 20) {
            //size = CGSizeMake(model.imageSize.width, [UIScreen mainScreen].bounds.size.height);
        //}
        int32_t requestID = [HXPhotoTools fetchPhotoWithAsset:model.asset photoSize:size completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ([strongSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                strongSelf.imageView.image = photo;
            } else {
                [[PHImageManager defaultManager] cancelImageRequest:strongSelf.requestID];
            }
            if (!isDegraded) {
                strongSelf.requestID = 0;
            }
        }];
        if (requestID && self.requestID && requestID != self.requestID) {
            [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        }
        self.requestID = requestID;
    }
//        model.requestID = [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:size resizeMode:PHImageRequestOptionsResizeModeFast completion:^(UIImage *image, NSDictionary *info) {

//                model.thumbPhoto = image;
//        }];

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
