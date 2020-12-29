//
//  HXCameraBottomView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2020/7/17.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXCameraBottomView.h"
#import "UIImage+HXExtension.h"
#import "HXFullScreenCameraPlayView.h"
#import "HXPhotoManager.h"
#import "UIView+HXExtension.h"
#import "NSBundle+HXPhotoPicker.h"

@interface HXCameraBottomView ()
@property (weak, nonatomic) IBOutlet UIView *zoomInBgView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *zoomInView;
@property (weak, nonatomic) IBOutlet UIView *zoomOutView;
@property (weak, nonatomic) IBOutlet UILabel *titleLb;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;

@property (strong, nonatomic) CAGradientLayer *maskLayer;
@property (strong, nonatomic) HXFullScreenCameraPlayView *playView;

@property (assign, nonatomic) CGPoint firstLongGestureLocation;
@property (weak, nonatomic) UILongPressGestureRecognizer *longGesture;
@property (weak, nonatomic) UISwipeGestureRecognizer *swipeGesture;
@property (weak, nonatomic) UITapGestureRecognizer *tapGesture;
@property (assign, nonatomic) BOOL isAnimation;
@end

@implementation HXCameraBottomView

+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.layer insertSublayer:self.maskLayer atIndex:0];
    [self.backBtn setImage:[UIImage hx_imageNamed:@"hx_camera_down_back"] forState:UIControlStateNormal];
    
    self.zoomOutView.userInteractionEnabled = NO;
    
    
    [self.zoomInBgView addSubview:self.playView];
    
    self.zoomInView.layer.masksToBounds = YES;
    [self.zoomInView hx_radiusWithRadius:45.f corner:UIRectCornerAllCorners];
    [self.zoomOutView hx_radiusWithRadius:65.f / 2.f corner:UIRectCornerAllCorners];
    
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longAction:)];
    [self.zoomInView addGestureRecognizer:longGesture];
    self.longGesture = longGesture;
    
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown;
    [self.zoomInView addGestureRecognizer:swipeGesture];
    self.swipeGesture = swipeGesture;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.zoomInView addGestureRecognizer:tapGesture];
    self.tapGesture = tapGesture;
    
    self.titleLb.alpha = 0;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.35 animations:^{
            self.titleLb.alpha = 1;
        } completion:^(BOOL finished) {
            [self hiddenTitle];
        }];
    });
}
- (void)hiddenTitle {
    [UIView animateWithDuration:0.5 delay:1.5f options:0 animations:^{
        self.titleLb.alpha = 0;
    } completion:nil];
}
- (void)tapAction:(UILongPressGestureRecognizer *)tapGesture {
    if (self.inTakePictures || self.inTranscribe) {
        return;
    }
    self.inTakePictures = YES;
    self.backBtn.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.15 animations:^{
        self.zoomOutView.transform = CGAffineTransformMakeScale(0.6, 0.6);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            self.zoomOutView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.backBtn.userInteractionEnabled = YES;
        }];
    }];
    if (self.takePictures) {
        self.takePictures();
    }
}
- (void)longAction:(UILongPressGestureRecognizer *)longGesture {
    if (self.inTakePictures) {
        return;
    }
    if (longGesture.state == UIGestureRecognizerStateBegan) {
        [self.playView clear];
        CGPoint point = [longGesture locationInView:[UIApplication sharedApplication].keyWindow];
        self.firstLongGestureLocation = point;
        self.inTranscribe = YES;
        self.isAnimation = YES;
        [UIView animateWithDuration:0.2 animations:^{
            self.backBtn.alpha = 0;
            self.zoomInView.transform = CGAffineTransformMakeScale(1.2, 1.2);
            self.zoomOutView.transform = CGAffineTransformMakeScale(0.6, 0.6);
        } completion:^(BOOL finished) {
            self.isAnimation = NO;
            if (self.startTranscribe && self.inTranscribe) {
                self.backBtn.hidden = YES;
                self.startTranscribe();
                [self.playView startAnimation];
            }
        }];
    }else if (longGesture.state == UIGestureRecognizerStateChanged) {
        if (self.isAnimation) {
            return;
        }
        CGPoint point = [longGesture locationInView:[UIApplication sharedApplication].keyWindow];
        CGFloat margin = self.firstLongGestureLocation.y - point.y;
        if (margin < 0) {
            margin = 0;
        }
        if (margin < 80.f) {
            return;
        }
        margin -= 80.f;
        if (self.changedTranscribe) {
            self.changedTranscribe(margin);
        }
    }else if (longGesture.state == UIGestureRecognizerStateEnded ||
              longGesture.state == UIGestureRecognizerStateCancelled ||
              longGesture.state == UIGestureRecognizerStateFailed) {
        self.inTranscribe = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.zoomInView.transform = CGAffineTransformIdentity;
            self.zoomOutView.transform = CGAffineTransformIdentity;
        }];
        [self.playView clear];
        if (self.endTranscribe) {
            self.endTranscribe(self.isAnimation);
        }
        self.backBtn.alpha = 1;
        self.backBtn.hidden = NO;
    }
}
- (void)swipeAction:(UILongPressGestureRecognizer *)swipeGesture {
    if (self.inTakePictures || self.inTranscribe) {
        return;
    }
    self.inTakePictures = YES;
    if (self.takePictures) {
        self.takePictures();
    }
}
- (void)videoRecordEnd {
    self.longGesture.enabled = NO;
    self.longGesture.enabled = YES;
}
- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
    self.playView.color = self.manager.configuration.cameraFocusBoxColor;
    self.playView.duration = self.manager.configuration.videoMaximumDuration + 0.4f;
    
    switch (self.manager.configuration.customCameraType) {
        case HXPhotoCustomCameraTypeUnused: {
            if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
                if (!self.manager.configuration.selectTogether && self.isOutside) {
                    if (self.manager.afterSelectedPhotoArray.count > 0) {
                        self.titleLb.text = [NSBundle hx_localizedStringForKey:@"轻触拍照"];
                        self.longGesture.enabled = NO;
                    }else if (self.manager.afterSelectedVideoArray.count > 0) {
                        self.titleLb.text = [NSBundle hx_localizedStringForKey:@"按住摄像"];
                        self.swipeGesture.enabled = NO;
                        self.tapGesture.enabled = NO;
                    }else {
                        self.titleLb.text = [NSBundle hx_localizedStringForKey:@"轻触拍照，按住摄像"];
                    }
                }else {
                    self.titleLb.text = [NSBundle hx_localizedStringForKey:@"轻触拍照，按住摄像"];
                }
            }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
                self.titleLb.text = [NSBundle hx_localizedStringForKey:@"轻触拍照"];
                self.longGesture.enabled = NO;
            }else {
                self.titleLb.text = [NSBundle hx_localizedStringForKey:@"按住摄像"];
                self.swipeGesture.enabled = NO;
                self.tapGesture.enabled = NO;
            }
        } break;
        case HXPhotoCustomCameraTypePhoto: {
            self.titleLb.text = [NSBundle hx_localizedStringForKey:@"轻触拍照"];
            self.longGesture.enabled = NO;
        } break;
        case HXPhotoCustomCameraTypeVideo: {
            self.titleLb.text = [NSBundle hx_localizedStringForKey:@"按住摄像"];
            self.swipeGesture.enabled = NO;
            self.tapGesture.enabled = NO;
        } break;
        case HXPhotoCustomCameraTypePhotoAndVideo: {
            self.titleLb.text = [NSBundle hx_localizedStringForKey:@"轻触拍照，按住摄像"];
        } break;
        default:
            break;
    }
}

- (void)startRecord {
    
}
- (void)stopRecord {
    self.longGesture.enabled = NO;
    self.longGesture.enabled = YES;
    
    [self.playView clear];
    self.playView.transform = CGAffineTransformIdentity;
}
- (IBAction)backClick:(UIButton *)sender {
    if (self.backClick) {
        self.backClick();
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.maskLayer.frame = CGRectMake(0, -40, self.hx_w, self.hx_h + 40);
    self.playView.center = CGPointMake(self.zoomInView.hx_w / 2, self.zoomInView.hx_h / 2);
}
- (CAGradientLayer *)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [CAGradientLayer layer];
        _maskLayer.colors = @[
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor
                                    ];
        _maskLayer.startPoint = CGPointMake(0, 0);
        _maskLayer.endPoint = CGPointMake(0, 1);
        _maskLayer.locations = @[@(0),@(1.f)];
        _maskLayer.borderWidth  = 0.0;
    }
    return _maskLayer;
}

- (HXFullScreenCameraPlayView *)playView {
    if (!_playView) {
        _playView = [[HXFullScreenCameraPlayView alloc] initWithFrame:CGRectMake(0, 0, 90, 90) color:self.manager.configuration.cameraFocusBoxColor];
        _playView.duration = self.manager.configuration.videoMaximumDuration;
    }
    return _playView;
}
@end
