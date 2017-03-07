//
//  HXPhotoViewCell.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoModel.h"

@class HXPhotoViewCell;
@protocol HXPhotoViewCellDelegate <NSObject>

//- (void)didCameraClick;
- (void)cellDidSelectedBtnClick:(HXPhotoViewCell *)cell Model:(HXPhotoModel *)model;

@end

@interface HXPhotoViewCell : UICollectionViewCell
@property (weak, nonatomic) id<HXPhotoViewCellDelegate> delegate;
@property (strong, nonatomic) HXPhotoModel *model;
@property (weak, nonatomic, readonly) UIImageView *imageView;
@property (weak, nonatomic, readonly) UIView *maskView;
@property (weak, nonatomic, readonly) UIButton *selectBtn;
@end
