//
//  HXPhotoEditStickerItemContentView.h
//  photoEditDemo
//
//  Created by 洪欣 on 2020/6/23.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoEditStickerItem;
@interface HXPhotoEditStickerItemContentView : UIView
@property (strong, nonatomic, readonly) HXPhotoEditStickerItem *item;
- (instancetype)initWithItem:(HXPhotoEditStickerItem *)item;
- (void)updateItem:(HXPhotoEditStickerItem *)item;
@end

NS_ASSUME_NONNULL_END
