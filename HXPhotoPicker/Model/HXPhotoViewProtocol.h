//
//  HXPhotoViewProtocol.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2020/8/1.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HXPhotoView, HXPhotoModel, HXPhotoSubViewCell;


/**
 照片/视频发生改变时调用 - 选择、移动顺序、删除

 @param allList 所有类型的模型数组
 @param photos 照片类型的模型数组
 @param videos 视频类型的模型数组
 @param isOriginal 是否原图
 */
typedef void (^HXPhotoViewChangeCompleteBlock)(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photos, NSArray<HXPhotoModel *> *videos, BOOL isOriginal);

/**
 点击了添加cell的事件
 */
typedef void (^HXPhotoViewDidAddCellBlock)(HXPhotoView *myPhotoView);

/**
 当view高度改变时调用

 @param frame 位置大小
 */
typedef void (^HXPhotoViewUpdateFrameBlock)(CGRect frame);

/**
 点击取消时调用
 */
typedef void (^HXPhotoViewDidCancelBlock)(void);

/**
 删除网络图片时调用

 @param networkPhotoUrl 被删除的图片地址
 */
typedef void (^HXPhotoViewDeleteNetworkPhotoBlock)(NSString *networkPhotoUrl);

/**
 当前删除的模型

 @param model 模型
 @param index 下标
 */
typedef void (^HXPhotoViewCurrentDeleteModelBlock)(HXPhotoModel *model, NSInteger index);

/**
 长按手势结束时是否删除当前拖动的cell

 @param longPgr 长按手势识别器
 @param indexPath 当前拖动的cell
 @return 是否删除
 */
typedef BOOL (^HXPhotoViewShouldDeleteCurrentMoveItemBlock)(UILongPressGestureRecognizer *longPgr, NSIndexPath *indexPath);

/**
 长按手势发生改变时调用

 @param longPgr 长按手势识别器
 @param indexPath 当前拖动的cell
 */
typedef void (^HXPhotoViewLongGestureRecognizerChangeBlock)(UILongPressGestureRecognizer *longPgr, NSIndexPath *indexPath);

/**
 长按手势开始时调用

 @param longPgr 长按手势识别器
 @param indexPath 当前拖动的cell
 */
typedef void (^HXPhotoViewLongGestureRecognizerBeganBlock)(UILongPressGestureRecognizer *longPgr, NSIndexPath *indexPath);

/**
 长按手势结束时调用

 @param longPgr 长按手势识别器
 @param indexPath 当前拖动的cell
 */
typedef void (^HXPhotoViewLongGestureRecognizerEndedBlock)(UILongPressGestureRecognizer *longPgr, NSIndexPath *indexPath);

@protocol HXPhotoViewDelegate <NSObject>
@optional

/// 照片/视频发生改变、HXPohotView初始化、manager赋值时调用 - 选择、移动顺序、删除、刷新视图
/// 调用 refreshView 会触发此代理
/// @param allList 所有类型的模型数组
/// @param photos 照片类型的模型数组
/// @param videos 视频类型的模型数组
/// @param isOriginal 是否选择了原图
- (void)photoView:(HXPhotoView *)photoView
   changeComplete:(NSArray<HXPhotoModel *> *)allList
           photos:(NSArray<HXPhotoModel *> *)photos
           videos:(NSArray<HXPhotoModel *> *)videos
         original:(BOOL)isOriginal;

/// 照片/视频发生改变、HXPohotView初始化、manager赋值时调用 - 选择、移动顺序、删除、刷新视图
/// 调用 refreshView 会触发此代理
- (void)photoViewChangeComplete:(HXPhotoView *)photoView
                   allAssetList:(NSArray<PHAsset *> *)allAssetList
                    photoAssets:(NSArray<PHAsset *> *)photoAssets
                    videoAssets:(NSArray<PHAsset *> *)videoAssets
                       original:(BOOL)isOriginal;

/// 相册相片列表点击了完成按钮/删除/移动、HXPohotView初始化且有数据、manager赋值且有数据时
/// 调用 refreshView 不会触发此代理
- (void)photoListViewControllerDidDone:(HXPhotoView *)photoView
                               allList:(NSArray<HXPhotoModel *> *)allList
                                photos:(NSArray<HXPhotoModel *> *)photos
                                videos:(NSArray<HXPhotoModel *> *)videos
                              original:(BOOL)isOriginal;

/// 点击了添加按钮的事件
- (void)photoViewDidAddCellClick:(HXPhotoView *)photoView;

/// 当view高度改变时调用
/// @param frame 位置大小
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame;

/// 取消选择图片时调用
- (void)photoViewDidCancel:(HXPhotoView *)photoView;

/// 删除网络图片时调用
/// @param networkPhotoUrl 被删除的图片地址
- (void)photoView:(HXPhotoView *)photoView deleteNetworkPhoto:(NSString *)networkPhotoUrl;

/// 当前删除的模型
- (void)photoView:(HXPhotoView *)photoView currentDeleteModel:(HXPhotoModel *)model currentIndex:(NSInteger)index;

/// 长按手势结束时是否删除当前拖动的cell
- (BOOL)photoViewShouldDeleteCurrentMoveItem:(HXPhotoView *)photoView
                           gestureRecognizer:(UILongPressGestureRecognizer *)longPgr
                                   indexPath:(NSIndexPath *)indexPath;

/// 长按手势发生改变时调用
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerChange:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath;

/// 长按手势开始时调用
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerBegan:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath;

/// 长按手势结束时调用
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerEnded:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath;

/// collectionView是否可以选择当前这个item（不包括添加按钮）
- (BOOL)photoView:(HXPhotoView *)photoView collectionViewShouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
            model:(HXPhotoModel *)model;

/// 当前选择的model数组，不是已经选择的model数组
/// 例: 已经选择了 照片1、视频1，再跳转相册选择了照片2、视频2，那么一共就是 照片1、视频1、照片2、视频2.那这个代理返回的数据就是 照片2、视频2
/// 只有在相册列表点了确定按钮才会触发
- (void)photoViewCurrentSelected:(NSArray<HXPhotoModel *> *)allList
                          photos:(NSArray<HXPhotoModel *> *)photos
                          videos:(NSArray<HXPhotoModel *> *)videos
                        original:(BOOL)isOriginal;

/// 取消预览大图的回调
- (void)photoViewPreviewDismiss:(HXPhotoView *)photoView;

/// 实现这个代理返回的高度就是HXPhotoView的高度，不会进行自动计算高度.
/// 每次需要更新高度的时候触发，请确保高度正确
- (CGFloat)photoViewHeight:(HXPhotoView *)photoView;

/// 自定义每个item的大小，实现此代码必须将 HXPhotoViewCustomItemSize 此宏的值修改为 1
/// 如果为pod导入的话，请使用  pod 'HXPhotoPicker/CustomItem'
/// 并且必须实现 - (CGFloat)photoViewHeight:(HXPhotoView *)photoView 此代理返回HXPhotoView的高度，如果不实现则HXPhotoView的高度为0
/// @param isAddItem 是否是添加按钮的item
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
               isAddItem:(BOOL)isAddItem
               photoView:(HXPhotoView *)photoView;

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
                photoView:(HXPhotoView *)photoView;

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
                photoView:(HXPhotoView *)photoView;

/// 相机拍照完成
- (void)photoViewCameraTakePictureCompletion:(HXPhotoView *)photoView
                                       model:(HXPhotoModel *)model;
@end

NS_ASSUME_NONNULL_END
