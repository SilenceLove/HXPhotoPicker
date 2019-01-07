//
//  HXCustomNavigationController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/31.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"
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

/**
 点击取消
 
 @param photoNavigationViewController self
 */
- (void)photoNavigationViewControllerDidCancel:(HXCustomNavigationController *)photoNavigationViewController;

/**
 点击完成时获取图片image完成后的回调
 选中了原图返回的就是原图
 需 requestImageAfterFinishingSelection = YES 才会有回调
 
 @param photoNavigationViewController self
 @param imageList 图片数组
 */
- (void)photoNavigationViewController:(HXCustomNavigationController *)photoNavigationViewController
                      didDoneAllImage:(NSArray<UIImage *> *)imageList;

- (void)photoNavigationViewControllerDidDone:(HXCustomNavigationController *)photoNavigationViewController
                                allAssetList:(NSArray<PHAsset *> *)allAssetList
                                 photoAssets:(NSArray<PHAsset *> *)photoAssetList
                                 videoAssets:(NSArray<PHAsset *> *)videoAssetList
                                    original:(BOOL)original;
@end

@interface HXCustomNavigationController : UINavigationController
@property (nonatomic) BOOL isCamera;
@property (weak, nonatomic) id<HXCustomNavigationControllerDelegate> hx_delegate;
@property (assign, nonatomic) BOOL supportRotation;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (copy, nonatomic) viewControllerDidDoneBlock doneBlock;
@property (copy, nonatomic) viewControllerDidDoneAllImageBlock allImageBlock;
@property (copy, nonatomic) viewControllerDidDoneAllAssetBlock allAssetBlock;
@property (copy, nonatomic) viewControllerDidCancelBlock cancelBlock;
- (instancetype)initWithManager:(HXPhotoManager *)manager;
- (instancetype)initWithManager:(HXPhotoManager *)manager
                       delegate:(id<HXCustomNavigationControllerDelegate>)delegate;
- (instancetype)initWithManager:(HXPhotoManager *)manager 
                      doneBlock:(viewControllerDidDoneBlock)doneBlock
                  allImageBlock:(viewControllerDidDoneAllImageBlock)allImageBlock
                    cancelBlock:(viewControllerDidCancelBlock)cancelBlock;
- (instancetype)initWithManager:(HXPhotoManager *)manager
                       delegate:(id<HXCustomNavigationControllerDelegate>)delegate
                      doneBlock:(viewControllerDidDoneBlock)doneBlock
                  allImageBlock:(viewControllerDidDoneAllImageBlock)allImageBlock
                    cancelBlock:(viewControllerDidCancelBlock)cancelBlock;
@end
