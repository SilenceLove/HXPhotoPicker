//
//  HXDateAlbumViewController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXAlbumModel.h"
#import "HXPhotoManager.h" 

@class HXAlbumListViewController;

@protocol HXAlbumListViewControllerDelegate <NSObject>
@optional

/**
 点击取消

 @param albumListViewController self
 */
- (void)albumListViewControllerDidCancel:(HXAlbumListViewController *)albumListViewController;

/**
 点击完成时获取图片image完成后的回调
 选中了原图返回的就是原图
 需 requestImageAfterFinishingSelection = YES 才会有回调
 
 @param albumListViewController self
 @param imageList 图片数组
 */
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController
                didDoneAllImage:(NSArray<UIImage *> *)imageList;

/**
 点击完成

 @param albumListViewController self
 @param allList 已选的所有列表(包含照片、视频)
 @param photoList 已选的照片列表
 @param videoList 已选的视频列表
 @param original 是否原图
 */
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController
                 didDoneAllList:(NSArray<HXPhotoModel *> *)allList
                         photos:(NSArray<HXPhotoModel *> *)photoList
                         videos:(NSArray<HXPhotoModel *> *)videoList
                       original:(BOOL)original;

- (void)albumListViewControllerDidDone:(HXAlbumListViewController *)albumListViewController
                          allAssetList:(NSArray<PHAsset *> *)allAssetList
                           photoAssets:(NSArray<PHAsset *> *)photoAssetList
                           videoAssets:(NSArray<PHAsset *> *)videoAssetList
                              original:(BOOL)original;
@end

@interface HXAlbumListViewController : UIViewController
@property (weak, nonatomic) id<HXAlbumListViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (copy, nonatomic) viewControllerDidDoneBlock doneBlock;
@property (copy, nonatomic) viewControllerDidDoneAllImageBlock allImageBlock;
@property (copy, nonatomic) viewControllerDidDoneAllAssetBlock allAssetBlock;
@property (copy, nonatomic) viewControllerDidCancelBlock cancelBlock;
@end

@interface HXAlbumListQuadrateViewCell : UICollectionViewCell
@property (strong, nonatomic) HXAlbumModel *model;
- (void)cancelRequest ;
@end

@interface HXAlbumListSingleViewCell : UITableViewCell
@property (strong, nonatomic) HXAlbumModel *model;
- (void)cancelRequest ;
@end
