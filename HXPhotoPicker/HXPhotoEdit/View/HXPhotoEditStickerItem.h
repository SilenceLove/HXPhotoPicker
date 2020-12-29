//
//  HXPhotoEditStickerItem.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/23.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoEditTextModel;
@interface HXPhotoEditStickerItem : NSObject<NSCoding>

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) HXPhotoEditTextModel *textModel;

@property (assign, nonatomic) CGRect itemFrame;

@end

NS_ASSUME_NONNULL_END
