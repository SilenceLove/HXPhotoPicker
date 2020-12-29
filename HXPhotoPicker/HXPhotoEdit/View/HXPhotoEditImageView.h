//
//  HXPhotoEditImageView.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/23.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoEditDrawView.h"
#import "HXPhotoEditStickerView.h"
#import "HXPhotoEditSplashView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HXPhotoEditImageViewType) {
    HXPhotoEditImageViewTypeNormal = 0, //!< 正常情况
    HXPhotoEditImageViewTypeDraw = 1,   //!< 绘图状态
    HXPhotoEditImageViewTypeSplash = 2  //!< 绘图状态
};
@class HXPhotoEditConfiguration;
@interface HXPhotoEditImageView : UIView
@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic) UIImage *image;
@property (assign, nonatomic) HXPhotoEditImageViewType type;
@property (strong, nonatomic, readonly) HXPhotoEditDrawView *drawView;
@property (strong, nonatomic, readonly) HXPhotoEditStickerView *stickerView;
@property (strong, nonatomic, readonly) HXPhotoEditSplashView *splashView;

@property (assign, nonatomic) BOOL splashViewEnable;
/// 显示界面的缩放率
@property (nonatomic, assign) CGFloat screenScale;

/** 贴图是否需要移到屏幕中心 */
@property (nonatomic, copy) BOOL(^moveCenter)(CGRect rect);
@property (nonatomic, copy, nullable) CGFloat (^ getMinScale)(CGSize size);
@property (nonatomic, copy, nullable) CGFloat (^ getMaxScale)(CGSize size);

@property (strong, nonatomic) HXPhotoEditConfiguration *configuration;
/** 数据 */
@property (nonatomic, strong, nullable) NSDictionary *photoEditData;
- (UIImage * _Nullable)editOtherImagesInRect:(CGRect)rect rotate:(CGFloat)rotate mirrorHorizontally:(BOOL)mirrorHorizontally;
- (void)changeSubviewFrame;
- (void)clearCoverage;
@end

NS_ASSUME_NONNULL_END
