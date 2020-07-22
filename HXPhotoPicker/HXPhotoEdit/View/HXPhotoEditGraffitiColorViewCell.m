//
//  HXPhotoEditGraffitiColorViewCell.m
//  photoEditDemo
//
//  Created by 洪欣 on 2020/6/22.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "HXPhotoEditGraffitiColorViewCell.h"
#import "UIView+HXExtension.h"
#import "UIColor+HXExtension.h"

@interface HXPhotoEditGraffitiColorViewCell ()
@property (weak, nonatomic) IBOutlet UIView *colorView;

@end

@implementation HXPhotoEditGraffitiColorViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.colorView.backgroundColor = [UIColor redColor];
    self.colorView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.colorView.layer.borderWidth = 2.5f;
    [self.colorView hx_radiusWithRadius:11.f corner:UIRectCornerAllCorners];
}

- (void)setModel:(HXPhotoEditGraffitiColorModel *)model {
    _model = model;
    if ([model.color hx_colorIsWhite]) {
        self.colorView.backgroundColor = [UIColor hx_colorWithHexStr:@"#eeeeee"];
    }else {
        self.colorView.backgroundColor = model.color;
    }
    [self setupColor];
}
- (void)setupColor {
    if (self.model.selected) {
        self.colorView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        self.colorView.layer.borderWidth = 2.5f * 1.25;
    }else {
        self.colorView.transform = CGAffineTransformIdentity;
        self.colorView.layer.borderWidth = 2.5f;
    }
}
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.model.selected = selected;
    [UIView animateWithDuration:0.2 animations:^{
        [self setupColor];
    }];
}

@end
