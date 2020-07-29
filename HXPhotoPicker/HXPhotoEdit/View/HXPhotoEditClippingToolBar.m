//
//  HXPhotoEditClippingToolBar.m
//  photoEditDemo
//
//  Created by 洪欣 on 2020/6/30.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "HXPhotoEditClippingToolBar.h"
#import "UIImage+HXExtension.h"
#import "NSBundle+HXPhotoPicker.h"

@interface HXPhotoEditClippingToolBar ()
@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *resetBtn;

@end

@implementation HXPhotoEditClippingToolBar

+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.confirmBtn setImage:[UIImage hx_imageNamed:@"hx_photo_edit_clip_confirm"] forState:UIControlStateNormal];
    [self.cancelBtn setImage:[UIImage hx_imageNamed:@"hx_photo_edit_clip_cancel"] forState:UIControlStateNormal];
    self.resetBtn.enabled = NO;
    [self.resetBtn setTitle:[NSBundle hx_localizedStringForKey:@"还原"] forState:UIControlStateNormal];
}

- (void)setEnableReset:(BOOL)enableReset {
    _enableReset = enableReset;
    self.resetBtn.enabled = enableReset;
}
- (IBAction)didBtnClick:(UIButton *)sender {
    if (self.didBtnBlock) {
        self.didBtnBlock(sender.tag);
    }
}

@end
