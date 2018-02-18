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
@property (strong, nonatomic) HXCircleProgressView *progressView;
@property (assign, nonatomic) int32_t requestID;
@property (strong, nonatomic) UILabel *stateLb;
@property (strong, nonatomic) CAGradientLayer *bottomMaskLayer;
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
        [_imageView.layer addSublayer:self.bottomMaskLayer];
    }
    return _imageView;
}
- (UILabel *)stateLb {
    if (!_stateLb) {
        _stateLb = [[UILabel alloc] init];
        _stateLb.textColor = [UIColor whiteColor];
        _stateLb.textAlignment = NSTextAlignmentRight;
        _stateLb.font = [UIFont systemFontOfSize:12];
    }
    return _stateLb;
}
- (CAGradientLayer *)bottomMaskLayer {
    if (!_bottomMaskLayer) {
        _bottomMaskLayer = [CAGradientLayer layer];
        _bottomMaskLayer.colors = @[
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.35].CGColor
                                    ];
        _bottomMaskLayer.startPoint = CGPointMake(0, 0);
        _bottomMaskLayer.endPoint = CGPointMake(0, 1);
        _bottomMaskLayer.locations = @[@(0.15f),@(0.9f)];
        _bottomMaskLayer.borderWidth  = 0.0;
    }
    return _bottomMaskLayer;
}
- (UIButton *)deleteBtn {
    if (!_deleteBtn) {
        _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteBtn setImage:[HXPhotoTools hx_imageNamed:@"compose_delete@2x.png"] forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(didDeleteClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteBtn;
}
- (HXCircleProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HXCircleProgressView alloc] init];
        _progressView.hidden = YES;
    }
    return _progressView;
}
- (void)setup {
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.stateLb];
    [self.contentView addSubview:self.deleteBtn];
    [self.contentView addSubview:self.progressView];
}

- (void)didDeleteClick {
    if (self.model.networkPhotoUrl) {
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
    [self.imageView hx_setImageWithModel:self.model progress:^(CGFloat progress, HXPhotoModel *model) {
        if (weakSelf.model == model) {
            weakSelf.progressView.progress = progress;
        }
    } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
        if (weakSelf.model == model) {
            if (error != nil) {
                weakSelf.model.downloadError = YES;
                weakSelf.model.downloadComplete = YES;
                [weakSelf.progressView showError];
            }else {
                if (image) {
                    weakSelf.progressView.progress = 1;
                    weakSelf.progressView.hidden = YES;
                    weakSelf.imageView.image = image;
                    weakSelf.userInteractionEnabled = YES; 
                }
            }
        }
    }];
}

- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    self.progressView.hidden = YES;
    self.progressView.progress = 0;
    self.imageView.image = nil;
    if (model.type == HXPhotoModelMediaTypeCamera) {
        self.deleteBtn.hidden = YES;
        self.imageView.image = model.thumbPhoto;
    }else {
        self.deleteBtn.hidden = NO;
        if (model.networkPhotoUrl) {
            //        if ([[model.networkPhotoUrl substringFromIndex:model.networkPhotoUrl.length - 3] isEqualToString:@"gif"]) {
            //            self.gifIcon.hidden = NO;
            //        }
            __weak typeof(self) weakSelf = self;
            self.progressView.hidden = model.downloadComplete;
            [self.imageView hx_setImageWithModel:model progress:^(CGFloat progress, HXPhotoModel *model) {
                if (weakSelf.model == model) {
                    weakSelf.progressView.progress = progress;
                }
            } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                if (weakSelf.model == model) {
                    if (error != nil) {
                        [weakSelf.progressView showError];
                    }else {
                        if (image) {
                            weakSelf.progressView.progress = 1;
                            weakSelf.progressView.hidden = YES;
                            weakSelf.imageView.image = image;
                        }
                    }
                }
            }];
        }else {
            if (model.previewPhoto) {
                self.imageView.image = model.previewPhoto;
            }else {
                self.imageView.image = model.thumbPhoto;
            }
        }
    }
    if (model.type == HXPhotoModelMediaTypePhotoGif) {
        self.stateLb.text = @"GIF";
        self.stateLb.hidden = NO;
        self.bottomMaskLayer.hidden = NO;
    }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        self.stateLb.text = @"Live";
        self.stateLb.hidden = NO;
        self.bottomMaskLayer.hidden = NO;
    }else {
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            self.stateLb.text = model.videoTime;
            self.stateLb.hidden = NO;
            self.bottomMaskLayer.hidden = NO;
        }else {
            self.stateLb.hidden = YES;
            self.bottomMaskLayer.hidden = YES;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    
    self.stateLb.frame = CGRectMake(0, self.hx_h - 18, self.hx_w - 4, 18);
    self.bottomMaskLayer.frame = CGRectMake(0, self.hx_h - 25, self.hx_w, 25);
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat deleteBtnW = self.deleteBtn.currentImage.size.width;
    CGFloat deleteBtnH = self.deleteBtn.currentImage.size.height;
    self.deleteBtn.frame = CGRectMake(width - deleteBtnW, 0, deleteBtnW, deleteBtnH);
    
    self.progressView.center = CGPointMake(width / 2, height / 2);
}

@end
