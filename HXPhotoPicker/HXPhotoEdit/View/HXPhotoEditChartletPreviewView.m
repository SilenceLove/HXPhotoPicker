//
//  HXPhotoEditChartletPreviewView.m
//  photoEditDemo
//
//  Created by Silence on 2020/7/1.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditChartletPreviewView.h"
#import "UIView+HXExtension.h"
#import "HXPhotoDefine.h"
#import "HXPhotoEditChartletModel.h"
#import "UIImage+HXExtension.h"
#import "UIImageView+HXExtension.h"
#import "NSBundle+HXPhotoPicker.h"

@interface HXPhotoEditChartletPreviewView ()
@property (strong, nonatomic) UIActivityIndicatorView *loadingView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (assign, nonatomic) CGSize imageSize;
@property (assign, nonatomic) CGRect viewFrame;
@property (assign, nonatomic) CGPoint point;
@property (assign, nonatomic) CGFloat triangleX;
@property (strong, nonatomic) HXPhotoEditChartletModel *model;
@end

@implementation HXPhotoEditChartletPreviewView

+ (instancetype)showPreviewWithModel:(HXPhotoEditChartletModel *)model atPoint:(CGPoint)point {
    HXPhotoEditChartletPreviewView *view = [self initView];
    view.point = point;
    view.model = model;
    return view;
}

+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextBeginPath(context);
    CGContextMoveToPoint   (context, self.triangleX - 15, self.hx_h - 20);
    CGContextAddLineToPoint(context, self.triangleX + 15, self.hx_h - 20);
    CGContextAddLineToPoint(context, self.triangleX, self.hx_h);
    CGContextClosePath(context);
    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextFillPath(context);
}
- (void)setModel:(HXPhotoEditChartletModel *)model {
    _model = model;
    if (model.type == HXPhotoEditChartletModelType_Image) {
        self.imageView.image = model.image;
        self.imageSize = self.imageView.image.size;
        [self updateFrame];
    }else if (model.type == HXPhotoEditChartletModelType_ImageNamed) {
        UIImage *image = [UIImage hx_imageContentsOfFile:model.imageNamed];
        self.imageView.image = image;
        self.imageSize = self.imageView.image.size;
        [self updateFrame];
    }else if (model.type == HXPhotoEditChartletModelType_NetworkURL) {
        self.loadingView.hidden = NO;
        [self.loadingView startAnimating];
        self.imageSize = CGSizeMake(HX_ScreenWidth / 3, HX_ScreenWidth / 3);
        [self updateFrame];
        [self layoutIfNeeded];
        HXWeakSelf
        [self.imageView hx_setImageWithURL:model.networkURL progress:^(CGFloat progress) {
            if (progress < 1) {
                weakSelf.loadingView.hidden = NO;
                [weakSelf.loadingView startAnimating];
            }
        } completed:^(UIImage *image, NSError *error) {
            weakSelf.loadingView.hidden = YES;
            [weakSelf.loadingView stopAnimating];
            weakSelf.viewFrame = CGRectZero;
            weakSelf.imageSize = weakSelf.imageView.image.size;
            [UIView animateWithDuration:0.25 animations:^{
                [weakSelf updateFrame];
                [weakSelf layoutIfNeeded];
                [weakSelf setNeedsDisplay];
            }];
        }];
    }
}
- (void)updateFrame {
    self.frame = self.viewFrame;
    self.loadingView.center = CGPointMake(self.hx_w / 2, self.hx_h / 2 - 5);
}
- (CGRect)viewFrame {
    if (CGRectIsEmpty(_viewFrame)) {
        CGFloat width = HX_ScreenWidth / 2;
        CGFloat height = width;
        CGFloat imgWidth = self.imageSize.width;
        CGFloat imgHeight = self.imageSize.height;
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown || HX_UI_IS_IPAD) {
            if (imgWidth > imgHeight) {
                width = HX_ScreenWidth - 40;
            }else if (imgHeight > imgWidth) {
                height = HX_ScreenWidth - 40;
            }
        }else {
            width = HX_ScreenHeight / 2;
            height = width;
            if (imgWidth > imgHeight) {
                width = HX_ScreenHeight - 40;
            }else if (imgHeight > imgWidth) {
                height = HX_ScreenHeight - 40;
            }
        }
        CGFloat w;
        CGFloat h;
        
        if (imgWidth > width) {
            imgHeight = width / imgWidth * imgHeight;
        }
        if (imgHeight > height) {
            w = height / self.imageSize.height * imgWidth;
            h = height;
        }else {
            if (imgWidth > width) {
                w = width;
            }else {
                w = imgWidth;
            }
            h = imgHeight;
        }
        w += 10;
        h += 20;
        CGFloat x = self.point.x - w / 2;
        CGFloat y = self.point.y - 10 - h;
        if (x + w > HX_ScreenWidth - 15) {
            x = HX_ScreenWidth - 15 - w;
        }
        if (x < 15) {
            x = 15;
        }
        self.triangleX = self.point.x - x;
        _viewFrame = CGRectMake(x, y, w, h);
    }
    return _viewFrame;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    [self addSubview:self.loadingView];
    if (HX_IOS11_Later) {
        [self.contentView hx_radiusWithRadius:5 corner:UIRectCornerAllCorners];
    }
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowRadius = 5.f;
    self.layer.shadowOpacity = 0.3f;
    _viewFrame = CGRectZero;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    if (HX_IOS11_Earlier) {
        [self.contentView hx_radiusWithRadius:5 corner:UIRectCornerAllCorners];
    }
}
- (UIActivityIndicatorView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _loadingView.hidden = YES;
    }
    return _loadingView;
}
@end
