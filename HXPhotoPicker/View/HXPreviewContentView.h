//
//  HXPreviewContentView.h
//  照片选择器
//
//  Created by 洪欣 on 2019/11/19.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPreviewImageView.h"
#import "HXPreviewVideoView.h"
#import "HXPreviewLivePhotoView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HXPreviewContentViewType) {
    HXPreviewContentViewTypeImage       = 0,    //!< 图片
    HXPreviewContentViewTypeLivePhoto   = 1,    //!< LivePhoto
    HXPreviewContentViewTypeVideo       = 2     //!< 视频
};
@class HXPhotoModel;
@interface HXPreviewContentView : UIView
@property (assign, nonatomic) BOOL stopCancel;
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) UIImage * _Nullable gifImage;
@property (strong, nonatomic) UIImage * _Nullable image;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) HXPreviewImageView *imageView;
@property (strong, nonatomic) HXPreviewVideoView *videoView;
@property (strong, nonatomic) HXPreviewLivePhotoView *livePhotoView;
@property (strong, nonatomic) AVAsset *avAsset;
@property (copy, nonatomic) void (^ downloadICloudAssetComplete)(void);
@property (copy, nonatomic) void (^ downloadNetworkImageComplete)(void);
- (void)cancelRequest;
- (void)requestHD;

- (instancetype)initWithType:(HXPreviewContentViewType)type;
@end

NS_ASSUME_NONNULL_END
