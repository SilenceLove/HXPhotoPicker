//
//  HXCollectionView.h
//  照片选择器
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

/**
 长按手势结束时是否删除当前拖动的cell

 @param collectionView 视图本身
 @return 是否删除
 */
- (BOOL)collectionViewShouldDeleteCurrentMoveItem:(UICollectionView *)collectionView gestureRecognizer:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath;

/**
 长按手势发生改变时调用

 @param collectionView 视图本身
 @param longPgr 长按手势识别器
 */
- (void)collectionView:(UICollectionView *)collectionView gestureRecognizerChange:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath;

/**
 长按手势开始时调用

 @param collectionView 视图本身
 @param longPgr 长按手势识别器
 */
- (void)collectionView:(UICollectionView *)collectionView gestureRecognizerBegan:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath;

/**
 长按手势结束时调用

 @param collectionView 视图本身
 @param longPgr 长按手势识别器
 */
- (void)collectionView:(UICollectionView *)collectionView gestureRecognizerEnded:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath;
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
@property (assign, nonatomic) BOOL editEnabled;

@end
