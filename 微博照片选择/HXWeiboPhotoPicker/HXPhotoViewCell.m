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
@interface HXPhotoViewCell ()
@property (weak, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) UIButton *selectBtn;
@property (weak, nonatomic) UIView *bottomView;
@property (weak, nonatomic) UIImageView *videoIcon;
@property (weak, nonatomic) UILabel *videoTime;
@property (weak, nonatomic) UIView *maskView;
@property (weak, nonatomic) UIButton *cameraBtn;
@property (weak, nonatomic) UIImageView *gifIcon;
@end

@implementation HXPhotoViewCell

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
    
    UIImageView *videoIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"VideoSendIcon@2x.png"]];
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
    
    UIView *maskView = [[UIView alloc] initWithFrame:self.bounds];
    maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    maskView.hidden = YES;
    [self.contentView addSubview:maskView];
    self.maskView = maskView;

    UIButton *selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [selectBtn setImage:[UIImage imageNamed:@"compose_guide_check_box_default@2x.png"] forState:UIControlStateNormal];
    [selectBtn setImage:[UIImage imageNamed:@"compose_guide_check_box_right@2x.png"] forState:UIControlStateSelected];
    [selectBtn addTarget:self action:@selector(didSelectClick:) forControlEvents:UIControlEventTouchUpInside];
    CGFloat imageWidth = selectBtn.currentImage.size.width;
    CGFloat imageHeight = selectBtn.currentImage.size.height;
    selectBtn.frame = CGRectMake(width - imageWidth, 0, imageWidth, imageHeight);
    [selectBtn setEnlargeEdgeWithTop:0 right:0 bottom:30 left:30];
    [self.contentView addSubview:selectBtn];
    self.selectBtn = selectBtn;
    
    UIImageView *gifIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timeline_image_gif@2x.png"]];
    gifIcon.frame = CGRectMake(self.frame.size.width - gifIcon.image.size.width, self.frame.size.height - gifIcon.image.size.height, gifIcon.image.size.width, gifIcon.image.size.height);
    [self.contentView addSubview:gifIcon];
    self.gifIcon = gifIcon;
    
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cameraBtn setBackgroundColor:[UIColor whiteColor]];
    cameraBtn.userInteractionEnabled = NO;
    [self.contentView addSubview:cameraBtn];
    cameraBtn.frame = self.bounds;
    self.cameraBtn = cameraBtn;
}

- (void)didSelectClick:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(cellDidSelectedBtnClick:Model:)]) {
        [self.delegate cellDidSelectedBtnClick:self Model:self.model];
    }
//    NSDictionary *dic = @{@"model":self.model,
//                          @"cell" : self};
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"HXPhotoPickerSelectedPhotoNotification" object:nil userInfo:dic];
}

- (void)setModel:(HXPhotoModel *)model
{
    _model = model;
    
    if (model.thumbPhoto) {
        self.imageView.image = model.thumbPhoto;
    }else {
        __weak typeof(self) weakSelf = self;
        CGFloat width = self.frame.size.width;
        [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:CGSizeMake(width * 2, width *2) resizeMode:PHImageRequestOptionsResizeModeFast completion:^(UIImage *image, NSDictionary *info) {
            weakSelf.imageView.image = image;
            model.thumbPhoto = image;
        }];
    }
    
    self.videoTime.text = model.videoTime;
    
    self.gifIcon.hidden = YES;
    self.cameraBtn.hidden = YES;
    if (model.type == HXPhotoModelMediaTypeVideo) {
        self.bottomView.hidden = NO;
    }else if (model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif){
        self.bottomView.hidden = YES;
        if (model.type == HXPhotoModelMediaTypePhotoGif) {
            self.gifIcon.hidden = NO;
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
