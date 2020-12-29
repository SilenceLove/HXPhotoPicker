//
//  HX_PhotoEditBottomView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/20.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HX_PhotoEditBottomView.h"
#import "UIView+HXExtension.h"
#import "UIImage+HXExtension.h"
#import "NSBundle+HXPhotoPicker.h"
#import "UIFont+HXExtension.h"

@interface HX_PhotoEditBottomView ()
@property (weak, nonatomic) IBOutlet UIButton *graffitiBtn;
@property (weak, nonatomic) IBOutlet UIButton *emojiBtn;
@property (weak, nonatomic) IBOutlet UIButton *textBtn;
@property (weak, nonatomic) IBOutlet UIButton *clipBtn;
@property (weak, nonatomic) IBOutlet UIButton *mosaicBtn;
@property (weak, nonatomic) IBOutlet UIButton *doneBtn;
@end

@implementation HX_PhotoEditBottomView

+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    UIImage *graffitiImage = [[UIImage hx_imageContentsOfFile:@"hx_photo_edit_tools_graffiti"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.graffitiBtn setImage:graffitiImage forState:UIControlStateNormal];
    [self.graffitiBtn setImage:graffitiImage forState:UIControlStateSelected];
    
    UIImage *emojiImage = [[UIImage hx_imageContentsOfFile:@"hx_photo_edit_tools_emoji"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.emojiBtn setImage:emojiImage forState:UIControlStateNormal];
    [self.emojiBtn setImage:emojiImage forState:UIControlStateSelected];
    
    UIImage *textImage = [[UIImage hx_imageContentsOfFile:@"hx_photo_edit_tools_text"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.textBtn setImage:textImage forState:UIControlStateNormal];
    [self.textBtn setImage:textImage forState:UIControlStateSelected];
    
    UIImage *clipImage = [[UIImage hx_imageContentsOfFile:@"hx_photo_edit_tools_clip"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.clipBtn setImage:clipImage forState:UIControlStateNormal];
    [self.clipBtn setImage:clipImage forState:UIControlStateSelected];
    
    UIImage *mosaicImage = [[UIImage hx_imageContentsOfFile:@"hx_photo_edit_tools_mosaic"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.mosaicBtn setImage:mosaicImage forState:UIControlStateNormal];
    [self.mosaicBtn setImage:mosaicImage forState:UIControlStateSelected];
    
    [self.doneBtn hx_radiusWithRadius:3 corner:UIRectCornerAllCorners];
    [self.doneBtn setTitle:[NSBundle hx_localizedStringForKey:@"完成"] forState:UIControlStateNormal];
    self.doneBtn.titleLabel.font = [UIFont hx_mediumPingFangOfSize:16];
}
- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    [self.doneBtn setBackgroundColor:themeColor];
}
- (IBAction)didToolsBtnClick:(UIButton *)button {
    if (button.tag == 1 || button.tag == 2) {
        if (self.didToolsBtnBlock) {
            self.didToolsBtnBlock(button.tag, button.selected);
        }
        return;
    }
    if (button.selected) {
        button.selected = NO;
        button.imageView.tintColor = nil;
    }else {
        button.selected = YES;
        if (button.tag != 3) {
            button.imageView.tintColor = self.themeColor;
        }
    }
    if (button.tag != 3) {
        [self resetAllBtnState:button];
    }
    if (self.didToolsBtnBlock) {
        self.didToolsBtnBlock(button.tag, button.selected);
    }
}
- (IBAction)didDoneBtnClick:(UIButton *)button {
    if (self.didDoneBtnBlock) {
        self.didDoneBtnBlock();
    }
}
- (void)resetAllBtnState:(UIButton *)button {
    if (self.graffitiBtn != button) {
        self.graffitiBtn.selected = NO;
        self.graffitiBtn.imageView.tintColor = nil;
    }
    if (self.emojiBtn != button) {
        self.emojiBtn.selected = NO;
        self.emojiBtn.imageView.tintColor = nil;
    }
    if (self.textBtn != button) {
        self.textBtn.selected = NO;
        self.textBtn.imageView.tintColor = nil;
    }
    if (self.clipBtn != button) {
        self.clipBtn.selected = NO;
        self.clipBtn.imageView.tintColor = nil;
    }
    if (self.mosaicBtn != button) {
        self.mosaicBtn.selected = NO;
        self.mosaicBtn.imageView.tintColor = nil;
    }
    if (self.doneBtn != button) {
        self.doneBtn.selected = NO;
        self.doneBtn.imageView.tintColor = nil;
    }
}
- (void)endCliping {
    if (self.clipBtn.selected) {
        [self didToolsBtnClick:self.clipBtn];
    }
}
@end
