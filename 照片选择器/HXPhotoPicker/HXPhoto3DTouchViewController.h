//
//  HXPhoto3DTouchViewController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/9/25.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoTools.h"
#if __has_include(<YYWebImage/YYWebImage.h>)
#import <YYWebImage/YYWebImage.h>
#elif __has_include("YYWebImage.h")
#import "YYWebImage.h"
#endif

@interface HXPhoto3DTouchViewController : UIViewController
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *imageView;
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
@property (strong, nonatomic) YYAnimatedImageView *animatedImageView;
#endif
@property (strong, nonatomic) NSIndexPath *indexPath;

@property (copy, nonatomic) NSArray<id<UIPreviewActionItem>> *(^ previewActionItemsBlock)(void);
@property (copy, nonatomic) void (^downloadImageComplete)(HXPhoto3DTouchViewController *vc, HXPhotoModel *model);
@end

