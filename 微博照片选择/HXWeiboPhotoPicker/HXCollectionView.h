//
//  HXCollectionView.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HXCollectionView;
@protocol HXCollectionViewDelegate <UICollectionViewDelegate>

@required
/**
 *  当数据源更新的到时候调用，必须实现，需将新的数据源设置为当前的数据源(例如 :_data = newDataArray)
 *  @param newDataArray   更新后的数据源
 */
- (void)dragCellCollectionView:(HXCollectionView *)collectionView newDataArrayAfterMove:(NSArray *)newDataArray;

@optional
/**
 *  cell移动完毕，并成功移动到新位置的时候调用
 */
- (void)dragCellCollectionViewCellEndMoving:(HXCollectionView *)collectionView;
/**
 *  成功交换了位置的时候调用
 *  @param fromIndexPath    交换cell的起始位置
 *  @param toIndexPath      交换cell的新位置
 */
- (void)dragCellCollectionView:(HXCollectionView *)collectionView moveCellFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
@end

@protocol HXCollectionViewDataSource<UICollectionViewDataSource>


@required
/**
 *  返回整个CollectionView的数据，必须实现，需根据数据进行移动后的数据重排
 */
- (NSArray *)dataSourceArrayOfCollectionView:(HXCollectionView *)collectionView;

@end


@interface HXCollectionView : UICollectionView

@property (weak, nonatomic) id<HXCollectionViewDelegate> delegate;
@property (weak, nonatomic) id<HXCollectionViewDataSource> dataSource;
@end
