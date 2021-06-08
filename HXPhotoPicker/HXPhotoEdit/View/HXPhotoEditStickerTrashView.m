//
//  HXPhotoEditStickerTrashView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/27.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditStickerTrashView.h"
#import "UIView+HXExtension.h"
#import "UIImage+HXExtension.h"
#import "NSBundle+HXPhotoPicker.h"

@interface HXPhotoEditStickerTrashView ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLb;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *visualView;
@property (weak, nonatomic) IBOutlet UIView *redView;

@end

@implementation HXPhotoEditStickerTrashView

+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.inArea = NO;
    self.redView.hidden = YES;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 10.f;
    self.imageView.image = [UIImage hx_imageContentsOfFile:@"hx_photo_edit_trash_close"];
}
- (void)setInArea:(BOOL)inArea {
    _inArea = inArea;
    if (inArea) {
        self.imageView.image = [UIImage hx_imageContentsOfFile:@"hx_photo_edit_trash_open"];
        self.redView.hidden = NO;
        self.visualView.hidden = YES;
        self.titleLb.text = [NSBundle hx_localizedStringForKey:@"松手即可删除"];
    }else {
        self.imageView.image = [UIImage hx_imageContentsOfFile:@"hx_photo_edit_trash_close"];
        self.redView.hidden = YES;
        self.visualView.hidden = NO;
        self.titleLb.text = [NSBundle hx_localizedStringForKey:@"拖动到此处删除"];
    }
}

@end
