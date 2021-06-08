//
//  HXPhotoPreviewViewCell.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/12/5.
//  Copyright © 2019 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"
#import "HXPreviewContentView.h"
#import "HXPreviewImageView.h"
#import "HXPreviewVideoView.h"
#import "HXPreviewLivePhotoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoPreviewViewCell : UICollectionViewCell

/// 预览大图时允许直接加载原图，不先加载小图
@property (assign, nonatomic) BOOL allowPreviewDirectLoadOriginalImage;
@property (assign, nonatomic) BOOL stopCancel;
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic, readonly) UIScrollView *scrollView;
@property (assign, nonatomic) CGFloat zoomScale;
@property (assign, nonatomic) BOOL dragging;
@property (nonatomic, copy) void (^cellTapClick)(HXPhotoModel *model, HXPhotoPreviewViewCell *myCell);
@property (nonatomic, copy) void (^cellDidPlayVideoBtn)(BOOL play);
@property (nonatomic, copy) void (^cellDownloadICloudAssetComplete)(HXPhotoPreviewViewCell *myCell);
@property (nonatomic, copy) void (^cellDownloadImageComplete)(HXPhotoPreviewViewCell *myCell);
@property (copy, nonatomic) void (^ cellViewLongPressGestureRecognizerBlock)(UILongPressGestureRecognizer *longPress);
- (void)againAddImageView;
- (void)refreshImageSize;
- (void)resetScale:(BOOL)animated;
- (void)resetScale:(CGFloat)scale animated:(BOOL)animated;
- (void)requestHDImage;
- (void)cancelRequest;
- (CGSize)getImageSize;

@property (strong, nonatomic) HXPreviewContentView *previewContentView;
- (UIImage *)image;

@property (assign, nonatomic) BOOL allowInteration;
@end

NS_ASSUME_NONNULL_END
