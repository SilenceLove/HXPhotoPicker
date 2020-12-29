//
//  HXPreviewLivePhotoView.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/11/15.
//  Copyright © 2019 Silence. All rights reserved.
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
