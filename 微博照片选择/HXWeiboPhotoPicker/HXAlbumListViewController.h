//
//  HXDateAlbumViewController.h
//  微博照片选择
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
- (void)albumListViewControllerDidCancel:(HXAlbumListViewController *)albumListViewController;
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original;
@end

@interface HXAlbumListViewController : UIViewController
@property (weak, nonatomic) id<HXAlbumListViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@end

@interface HXAlbumListQuadrateViewCell : UICollectionViewCell
@property (strong, nonatomic) HXAlbumModel *model;
- (void)cancelRequest ;
@end
