//
//  HXPhoto3DTouchViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/9/25.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoTools.h"

@interface HXPhoto3DTouchViewController : UIViewController
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) NSIndexPath *indexPath;
@end
