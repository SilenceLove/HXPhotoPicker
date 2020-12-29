//
//  HXPhotoEditChartletPreviewView.h
//  photoEditDemo
//
//  Created by Silence on 2020/7/1.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoEditChartletListViewCell, HXPhotoEditChartletModel;
@interface HXPhotoEditChartletPreviewView : UIView
@property (weak, nonatomic) HXPhotoEditChartletListViewCell *cell;
+ (instancetype)showPreviewWithModel:(HXPhotoEditChartletModel *)model atPoint:(CGPoint)point;
@end

NS_ASSUME_NONNULL_END
