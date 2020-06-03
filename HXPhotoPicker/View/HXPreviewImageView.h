//
//  HXPreviewImageView.h
//  照片选择器
//
//  Created by 洪欣 on 2019/11/15.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
NS_ASSUME_NONNULL_BEGIN

@class HXPhotoModel;
@interface HXPreviewImageView : UIView
@property (strong, nonatomic) HXPhotoModel *model;
@property (assign, nonatomic) BOOL stopCancel;
@property (strong, nonatomic) UIImage * _Nullable gifImage;
@property (strong, nonatomic) UIImage * _Nullable gifFirstFrame;
@property (strong, nonatomic) UIImage * _Nullable image;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (assign, nonatomic) PHContentEditingInputRequestID gifRequestID;
@property (copy, nonatomic) void (^ downloadICloudAssetComplete)(void);
@property (copy, nonatomic) void (^ downloadNetworkImageComplete)(void);
- (void)cancelImage;
- (void)requestHDImage;
@end

NS_ASSUME_NONNULL_END
