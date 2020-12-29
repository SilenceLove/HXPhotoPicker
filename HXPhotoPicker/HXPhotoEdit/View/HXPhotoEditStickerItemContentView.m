//
//  HXPhotoEditStickerItemContentView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/23.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditStickerItemContentView.h"
#import "HXPhotoEditStickerItem.h"
#import "HX_PhotoEditViewController.h"

@interface HXPhotoEditStickerItemContentView ()<UIGestureRecognizerDelegate>
@property (strong, nonatomic) UIImageView *imageView;

@property (strong, nonatomic) HXPhotoEditStickerItem *item;
@end

@implementation HXPhotoEditStickerItemContentView

- (instancetype)initWithItem:(HXPhotoEditStickerItem *)item {
    self = [super initWithFrame:item.itemFrame];
    if (self) {
        self.item = item;
        [self addSubview:self.imageView];
    }
    return self;
}
- (void)updateItem:(HXPhotoEditStickerItem *)item {
    self.item = item;
    self.frame = item.itemFrame;
    self.imageView.image = item.image;
}
- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    gestureRecognizer.delegate = self;
    [super addGestureRecognizer:gestureRecognizer];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.delegate isKindOfClass:[HX_PhotoEditViewController class]]) {
        return NO;
    }
    if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
        [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return YES;
    }
    if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] ||
        [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return NO;
    }
    if (gestureRecognizer.view == self && otherGestureRecognizer.view == self) {
        return YES;
    }
    return NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithImage:self.item.image];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

@end
