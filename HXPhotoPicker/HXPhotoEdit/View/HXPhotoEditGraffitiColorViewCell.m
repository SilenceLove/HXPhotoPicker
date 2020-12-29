//
//  HXPhotoEditGraffitiColorViewCell.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/22.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditGraffitiColorViewCell.h"
#import "UIView+HXExtension.h"
#import "UIColor+HXExtension.h"

@interface HXPhotoEditGraffitiColorViewCell ()
@property (weak, nonatomic) IBOutlet UIView *colorView;
@property (weak, nonatomic) IBOutlet UIView *colorCenterView;

@end

@implementation HXPhotoEditGraffitiColorViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.colorView.backgroundColor = [UIColor whiteColor];
    [self.colorView hx_radiusWithRadius:11.f corner:UIRectCornerAllCorners];
    [self.colorCenterView hx_radiusWithRadius:16.f / 2.f corner:UIRectCornerAllCorners];
}

- (void)setModel:(HXPhotoEditGraffitiColorModel *)model {
    _model = model;
    if ([model.color hx_colorIsWhite]) {
        self.colorView.backgroundColor = [UIColor hx_colorWithHexStr:@"#dadada"];
    }else {
        self.colorView.backgroundColor = [UIColor whiteColor];
    }
    self.colorCenterView.backgroundColor = model.color;
    [self setupColor];
}
- (void)setupColor {
    if (self.model.selected) {
        self.colorView.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }else {
        self.colorView.transform = CGAffineTransformIdentity;
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
