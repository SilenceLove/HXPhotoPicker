//
//  HXPhotoEditChartletListView.h
//  photoEditDemo
//
//  Created by 洪欣 on 2020/6/23.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoEditChartletModel, HXPhotoEditChartletTitleModel, HXPhotoEditConfiguration;
@interface HXPhotoEditChartletListView : UIView
+ (void)showEmojiViewWithConfiguration:(HXPhotoEditConfiguration *)configuration
                            completion:(void (^ _Nullable)(UIImage *image))completion;
+ (void)showEmojiViewWithModels:(NSArray<HXPhotoEditChartletTitleModel *> *)models
                     completion:(void (^ _Nullable)(UIImage *image))completion;
@end

@interface HXPhotoEditChartletListViewCell : UICollectionViewCell
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) HXPhotoEditChartletTitleModel *titleModel;
@property (strong, nonatomic) HXPhotoEditChartletModel *model;
@property (assign, nonatomic) BOOL showMask;
- (void)setShowMask:(BOOL)showMask isAnimate:(BOOL)isAnimate;
@end

NS_ASSUME_NONNULL_END
