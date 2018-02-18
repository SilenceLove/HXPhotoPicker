//
//  UIImageView+HXExtension.h
//  微博照片选择
//
//  Created by 洪欣 on 2018/2/14.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HXPhotoModel;
@interface UIImageView (HXExtension)
- (void)hx_setImageWithModel:(HXPhotoModel *)model progress:(void (^)(CGFloat progress, HXPhotoModel *model))progressBlock completed:(void (^)(UIImage * image, NSError * error, HXPhotoModel * model))completedBlock;
@end
