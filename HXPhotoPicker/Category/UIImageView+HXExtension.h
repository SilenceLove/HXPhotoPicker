//
//  UIImageView+HXExtension.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2018/2/14.
//  Copyright © 2018年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HXPhotoModel;
@interface UIImageView (HXExtension)
- (void)hx_setImageWithModel:(HXPhotoModel *)model progress:(void (^)(CGFloat progress, HXPhotoModel *model))progressBlock completed:(void (^)(UIImage * image, NSError * error, HXPhotoModel * model))completedBlock;

- (void)hx_setImageWithModel:(HXPhotoModel *)model original:(BOOL)original progress:(void (^)(CGFloat progress, HXPhotoModel *model))progressBlock completed:(void (^)(UIImage * image, NSError * error, HXPhotoModel * model))completedBlock;
- (void)hx_setImageWithURL:(NSURL *)url
                  progress:(void (^)(CGFloat progress))progressBlock
                 completed:(void (^)(UIImage * image, NSError * error))completedBlock;
@end
