//
//  HXPhotoEditMosaicView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/22.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditMosaicView.h"
#import "UIImage+HXExtension.h"
#import "NSBundle+HXPhotoPicker.h"

@interface HXPhotoEditMosaicView ()
@property (weak, nonatomic) IBOutlet UIButton *normalBtn;
@property (weak, nonatomic) IBOutlet UIButton *colorBtn;

@property (weak, nonatomic) IBOutlet UIButton *undoBtn;
@end

@implementation HXPhotoEditMosaicView

+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.undoBtn.enabled = NO;
    
    UIImage *normalImage = [[UIImage hx_imageContentsOfFile:@"hx_photo_edit_mosaic_normal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.normalBtn setImage:normalImage forState:UIControlStateNormal];
    [self.normalBtn setImage:normalImage forState:UIControlStateSelected];
    
    UIImage *colorImage = [[UIImage hx_imageContentsOfFile:@"hx_photo_edit_mosaic_color"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.colorBtn setImage:colorImage forState:UIControlStateNormal];
    [self.colorBtn setImage:colorImage forState:UIControlStateSelected];
    
    [self.undoBtn setImage:[UIImage hx_imageContentsOfFile:@"hx_photo_edit_repeal"] forState:UIControlStateNormal];
}
- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    self.normalBtn.selected = YES;
    self.normalBtn.imageView.tintColor = themeColor;
}
- (void)setUndo:(BOOL)undo {
    _undo = undo;
    self.undoBtn.enabled = undo;
}
- (IBAction)didBtnClick:(UIButton *)button {
    if (button.tag == 0) {
        self.normalBtn.selected = YES;
        self.normalBtn.imageView.tintColor = self.themeColor;
        self.colorBtn.selected = NO;
        self.colorBtn.imageView.tintColor = nil;
    }else {
        self.colorBtn.selected = YES;
        self.colorBtn.imageView.tintColor = self.themeColor;
        self.normalBtn.selected = NO;
        self.normalBtn.imageView.tintColor = nil;
    }
    if (self.didBtnBlock) {
        self.didBtnBlock(button.tag);
    }
}
- (IBAction)didUndoBtn:(UIButton *)button {
    if (self.undoBlock) {
        self.undoBlock();
    }
}

@end
