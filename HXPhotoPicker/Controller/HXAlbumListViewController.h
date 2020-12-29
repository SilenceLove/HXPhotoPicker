//
//  HXDateAlbumViewController.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/14.
//  Copyright © 2017年 Silence. All rights reserved.
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

- (void)albumListViewControllerFinishDismissCompletion:(HXAlbumListViewController *)albumListViewController;
- (void)albumListViewControllerCancelDismissCompletion:(HXAlbumListViewController *)albumListViewController;
@end

@interface HXAlbumListViewController : UIViewController
@property (weak, nonatomic) id<HXAlbumListViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (copy, nonatomic) viewControllerDidDoneBlock doneBlock;
@property (copy, nonatomic) viewControllerDidCancelBlock cancelBlock;
- (instancetype)initWithManager:(HXPhotoManager *)manager;
@end

@interface HXAlbumListSingleViewCell : UITableViewCell
@property (strong, nonatomic) UIColor *bgColor;
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) UIColor *selectedBgColor;
@property (strong, nonatomic) UIColor *lineViewColor;

@property (strong, nonatomic) HXAlbumModel *model;
@property (copy, nonatomic) void (^getResultCompleteBlock)(NSInteger count, HXAlbumListSingleViewCell *myCell);
- (void)cancelRequest ;
@end
