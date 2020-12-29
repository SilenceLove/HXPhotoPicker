//
//  HXPhotoEditGraffitiColorSizeView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2020/8/14.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditGraffitiColorSizeView.h"
#import "UIView+HXExtension.h"
#import "HXPreviewVideoView.h"
#import "NSBundle+HXPhotoPicker.h"
#import "UIImage+HXExtension.h"

@interface HXPhotoEditGraffitiColorSizeView ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *indicatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *indicatorViewCenterYConstraint;
@property (assign, nonatomic) CGFloat indicatorCenterY;
@end

@implementation HXPhotoEditGraffitiColorSizeView

+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(CGRectMake(self.indicatorView.hx_x - 10, self.indicatorView.hx_y - 10, self.indicatorView.hx_w + 20, self.indicatorView.hx_h + 20), point)) {
        return self.indicatorView;
    }
    return [super hitTest:point withEvent:event];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.scale = 0.5f;
    self.imageView.image = [UIImage hx_imageContentsOfFile:@"hx_photo_edit_graffiti_size_backgroud"];
    [self.indicatorView hx_radiusWithRadius:10.f corner:UIRectCornerAllCorners];
    self.indicatorView.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f].CGColor;
    self.indicatorView.layer.shadowOpacity = 0.56f;
    self.indicatorView.layer.shadowRadius = 10.f;
    
    HXPanGestureRecognizer *panGesture = [[HXPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerClick:)];
    
    [self.indicatorView addGestureRecognizer:panGesture];
}

- (void)panGestureRecognizerClick:(UIPanGestureRecognizer *)panGesture {
    CGPoint point = [panGesture translationInView:self];
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        self.indicatorCenterY = self.indicatorViewCenterYConstraint.constant;
    }
    CGFloat centerY = self.indicatorCenterY + point.y;
    if (centerY < -(self.hx_h / 2)) {
        centerY = -(self.hx_h / 2);
    }else if (centerY > self.hx_h / 2) {
        centerY = self.hx_h / 2;
    }

    self.indicatorViewCenterYConstraint.constant = centerY;

    CGFloat scale = 1 - self.indicatorView.hx_centerY / self.hx_h;
    self.scale = scale;
    if (self.changeColorSize) {
        self.changeColorSize(scale);
    }
}

@end
