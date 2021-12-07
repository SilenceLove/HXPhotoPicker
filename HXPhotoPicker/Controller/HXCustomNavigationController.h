//
//  HXCustomNavigationController.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/31.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"
#import "HXPickerResult.h"
@class HXPhotoModel, HXCustomNavigationController;

@protocol HXCustomNavigationControllerDelegate <NSObject>
@optional
/**
 点击完成按钮
 
 @param photoNavigationViewController self
 @param allList 已选的所有列表(包含照片、视频)
 @param photoList 已选的照片列表
 @param videoList 已选的视频列表
 @param original 是否原图
 */
- (void)photoNavigationViewController:(HXCustomNavigationController *)photoNavigationViewController
                       didDoneAllList:(NSArray<HXPhotoModel *> *)allList
                               photos:(NSArray<HXPhotoModel *> *)photoList
                               videos:(NSArray<HXPhotoModel *> *)videoList
                             original:(BOOL)original;

- (void)photoNavigationViewController:(HXCustomNavigationController *)photoNavigationViewController
                      didDoneWithResult:(HXPickerResult *)result;

/**
 点击取消
 
 @param photoNavigationViewController self
 */
- (void)photoNavigationViewControllerDidCancel:(HXCustomNavigationController *)photoNavigationViewController;

- (void)photoNavigationViewControllerFinishDismissCompletion:(HXCustomNavigationController *)photoNavigationViewController;
- (void)photoNavigationViewControllerCancelDismissCompletion:(HXCustomNavigationController *)photoNavigationViewController;
@end

@interface HXCustomNavigationController : UINavigationController
@property (strong, nonatomic) NSMutableArray *albums;
@property (strong, nonatomic) HXAlbumModel *cameraRollAlbumModel;

@property (copy, nonatomic) void (^requestCameraRollPhotoListCompletion)(void);

@property (copy, nonatomic) void (^requestCameraRollCompletion)(void);
@property (copy, nonatomic) void (^requestAllAlbumCompletion)(void);

@property (copy, nonatomic) void (^ reloadAsset)(BOOL initialAuthorization);

//@property (copy, nonatomic) void (^ photoLibraryDidChange)(HXAlbumModel *albumModel);

@property (assign ,nonatomic) BOOL isCamera;
@property (weak, nonatomic) id<HXCustomNavigationControllerDelegate> hx_delegate;
@property (assign, nonatomic) BOOL supportRotation;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (copy, nonatomic) viewControllerDidDoneBlock doneBlock;
@property (copy, nonatomic) viewControllerDidCancelBlock cancelBlock;
- (instancetype)initWithManager:(HXPhotoManager *)manager;
- (instancetype)initWithManager:(HXPhotoManager *)manager
                       delegate:(id<HXCustomNavigationControllerDelegate>)delegate;
- (instancetype)initWithManager:(HXPhotoManager *)manager 
                      doneBlock:(viewControllerDidDoneBlock)doneBlock
                    cancelBlock:(viewControllerDidCancelBlock)cancelBlock;
- (instancetype)initWithManager:(HXPhotoManager *)manager
                       delegate:(id<HXCustomNavigationControllerDelegate>)delegate
                      doneBlock:(viewControllerDidDoneBlock)doneBlock
                    cancelBlock:(viewControllerDidCancelBlock)cancelBlock;

- (void)clearAssetCache;
@end
