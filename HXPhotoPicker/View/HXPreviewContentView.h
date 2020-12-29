//
//  HXPreviewContentView.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/11/19.
//  Copyright © 2019 Silence. All rights reserved.
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

/// 预览大图时允许直接加载原图，不先加载小图
@property (assign, nonatomic) BOOL allowPreviewDirectLoadOriginalImage;
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
