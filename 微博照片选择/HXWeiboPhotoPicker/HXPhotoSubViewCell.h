//
//  HXPhotoSubViewCell.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"

@protocol HXPhotoSubViewCellDelegate <NSObject>

- (void)cellDidDeleteClcik:(UICollectionViewCell *)cell;
- (void)cellNetworkingPhotoDownLoadComplete;
@end

@class HXPhotoModel;
@interface HXPhotoSubViewCell : UICollectionViewCell
@property (weak, nonatomic) id<HXPhotoSubViewCellDelegate> delegate;
@property (copy, nonatomic) NSDictionary *dic;
@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic) HXPhotoModel *model;
/**
 删除网络图片时是否显示Alert // 默认显示
 */
@property (assign, nonatomic) BOOL showDeleteNetworkPhotoAlert;
// 重新下载
- (void)againDownload;
@end
