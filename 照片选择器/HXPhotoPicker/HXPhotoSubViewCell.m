//
//  HXPhotoSubViewCell.m
//  照片选择器
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
        [_deleteBtn setImage:[HXPhotoTools hx_imageNamed:@"hx_compose_delete@2x.png"] forState:UIControlStateNormal];
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"提示"] message:[NSBundle hx_localizedStringForKey:@"是否删除此照片"] delegate:self cancelButtonTitle:[NSBundle hx_localizedStringForKey:@"取消"] otherButtonTitles:[NSBundle hx_localizedStringForKey:@"确定"], nil];
            [alert show];
            return;
        }
    } 
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
    [self.imageView yy_cancelCurrentImageRequest];
#elif __has_include(<SDWebImage/UIImageView+WebCache.h>) || __has_include("UIImageView+WebCache.h")
    [self.imageView sd_cancelCurrentAnimationImagesLoad];
#endif
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
    [self.imageView hx_setImageWithModel:self.model original:NO progress:^(CGFloat progress, HXPhotoModel *model) {
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
- (void)setHideDeleteButton:(BOOL)hideDeleteButton {
    _hideDeleteButton = hideDeleteButton;
    if (self.model.type != HXPhotoModelMediaTypeCamera) {
        self.deleteBtn.hidden = hideDeleteButton;
    }
}
- (void)setDeleteImageName:(NSString *)deleteImageName {
    _deleteImageName = deleteImageName;
    [self.deleteBtn setImage:[HXPhotoTools hx_imageNamed:deleteImageName] forState:UIControlStateNormal];
}
- (void)resetNetworkImage {
    if (self.model.networkPhotoUrl &&
        self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
        self.model.loadOriginalImage = YES;
        HXWeakSelf
        [self.imageView hx_setImageWithModel:self.model original:YES progress:nil completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                weakSelf.imageView.image = image;
            }
        }];
    }
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
        if (model.localIdentifier && !model.asset) {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            model.asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[model.localIdentifier] options:options] firstObject];
        }
        self.deleteBtn.hidden = NO;
        if (model.networkPhotoUrl) {
            HXWeakSelf
            self.progressView.hidden = model.downloadComplete;
            [self.imageView hx_setImageWithModel:model original:NO progress:^(CGFloat progress, HXPhotoModel *model) {
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
            }else if (model.thumbPhoto) {
                self.imageView.image = model.thumbPhoto;
            }else {
                HXWeakSelf
                model.clarityScale = 1.5f;
                model.rowCount = 3.f;
                [HXPhotoTools getImageWithModel:model completion:^(UIImage *image, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        weakSelf.imageView.image = image;
                    }
                }];
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
            if (model.networkPhotoUrl) {
                if ([[model.networkPhotoUrl.absoluteString substringFromIndex:model.networkPhotoUrl.absoluteString.length - 3] isEqualToString:@"gif"]) {
                    self.stateLb.text = @"GIF";
                    self.stateLb.hidden = NO;
                    self.bottomMaskLayer.hidden = NO;
                    return;
                }
            }
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

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
}

@end
