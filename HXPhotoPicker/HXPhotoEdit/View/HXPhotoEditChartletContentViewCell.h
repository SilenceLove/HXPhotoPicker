//
//  HXPhotoEditChartletContentViewCell.h
//  photoEditDemo
//
//  Created by 洪欣 on 2020/7/2.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoEditChartletModel;
@interface HXPhotoEditChartletContentViewCell : UICollectionViewCell
@property (weak, nonatomic, readonly) IBOutlet UICollectionView *collectionView;
@property (copy, nonatomic) NSArray<HXPhotoEditChartletModel *> *models;
@property (copy, nonatomic) void (^ selectCellBlock)(UIImage *image);
@end

NS_ASSUME_NONNULL_END
