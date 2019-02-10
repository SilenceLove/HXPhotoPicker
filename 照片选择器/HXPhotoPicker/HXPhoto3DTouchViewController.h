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
#elif __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKit.h>
#elif __has_include("YYKit.h")
#import "YYKit.h"
#endif

@interface HXPhoto3DTouchViewController : UIViewController
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *imageView;
#if HasYYKitOrWebImage
@property (strong, nonatomic) YYAnimatedImageView *animatedImageView;
#endif
@property (strong, nonatomic) NSIndexPath *indexPath;

@property (copy, nonatomic) NSArray<id<UIPreviewActionItem>> *(^ previewActionItemsBlock)(void);
@property (copy, nonatomic) void (^downloadImageComplete)(HXPhoto3DTouchViewController *vc, HXPhotoModel *model);
@end

