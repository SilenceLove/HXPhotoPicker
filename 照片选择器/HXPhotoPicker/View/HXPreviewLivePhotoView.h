//
//  HXPreviewLivePhotoView.h
//  照片选择器
//
//  Created by 洪欣 on 2019/11/15.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoModel;
@interface HXPreviewLivePhotoView : UIView
@property (assign, nonatomic) BOOL stopCancel;
@property (strong, nonatomic) HXPhotoModel *model;
@property (copy, nonatomic) void (^ downloadICloudAssetComplete)(void);
- (void)cancelLivePhoto;
@end

NS_ASSUME_NONNULL_END
