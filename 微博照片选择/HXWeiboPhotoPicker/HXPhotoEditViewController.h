//
//  HXPhotoEditViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/6/30.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HXPhotoModel,HXPhotoManager;
@protocol HXPhotoEditViewControllerDelegate <NSObject>

- (void)editViewControllerDidNextClick:(HXPhotoModel *)model;

@end

@class HXPhotoModel;
@interface HXPhotoEditViewController : UIViewController
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) UIImage *coverImage;
@property (weak, nonatomic) id<HXPhotoEditViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *photoManager;
@end
