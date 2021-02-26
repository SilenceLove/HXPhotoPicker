//
//  UIViewController+HXExtension.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/11/24.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HXCustomCameraViewController.h"
#import "HXPhotoEditViewController.h"
#import "HX_PhotoEditViewController.h"
#import "HXVideoEditViewController.h"
#import "HXPhotoView.h"
#import "HXCustomNavigationController.h"

@class HXPhotoView;
@interface UIViewController (HXExtension)

/// 跳转相册列表
/// @param manager 照片管理者
/// @param models NSArray<HXPhotoModel *> *allList - 所选的所有模型数组
///               NSArray<HXPhotoModel *> *videoList - 所选的视频模型数组
///               NSArray<HXPhotoModel *> *photoList - 所选的照片模型数组
///               BOOL original - 是否原图
///               UIViewController *viewController 相册列表控制器
/// @param cancel 取消选择
- (void)hx_presentSelectPhotoControllerWithManager:(HXPhotoManager *_Nullable)manager
                                           didDone:(void (^_Nullable)
                                                    (NSArray<HXPhotoModel *> * _Nullable allList,
                                                     NSArray<HXPhotoModel *> * _Nullable photoList,
                                                     NSArray<HXPhotoModel *> * _Nullable videoList,
                                                     BOOL isOriginal,
                                                     UIViewController * _Nullable viewController,
                                                     HXPhotoManager * _Nullable manager))models
                                            cancel:(void (^_Nullable)
                                                    (UIViewController * _Nullable viewController,
                                                     HXPhotoManager * _Nullable manager))cancel;

/// 跳转相册列表
/// @param delegate HXCustomNavigationControllerDelegate
- (void)hx_presentSelectPhotoControllerWithManager:(HXPhotoManager * _Nullable)manager
                                          delegate:(id _Nullable )delegate;

/// 跳转预览照片界面
/// @param manager 照片管理者
/// @param previewStyle 预览样式
/// @param currentIndex 当前预览的下标
/// @param photoView 照片展示视图 - 没有就不传
- (void)hx_presentPreviewPhotoControllerWithManager:(HXPhotoManager * _Nullable)manager
                                       previewStyle:(HXPhotoViewPreViewShowStyle)previewStyle
                                       currentIndex:(NSUInteger)currentIndex
                                          photoView:(HXPhotoView * _Nullable)photoView;

- (void)hx_presentPreviewPhotoControllerWithManager:(HXPhotoManager * _Nullable)manager
                                       previewStyle:(HXPhotoViewPreViewShowStyle)previewStyle
                              showBottomPageControl:(BOOL)showBottomPageControl
                                       currentIndex:(NSUInteger)currentIndex;

- (void)hx_presentPreviewPhotoControllerWithManager:(HXPhotoManager * _Nullable)manager
                                       previewStyle:(HXPhotoViewPreViewShowStyle)previewStyle
                              showBottomPageControl:(BOOL)showBottomPageControl
                                       currentIndex:(NSUInteger)currentIndex
                                          photoView:(HXPhotoView * _Nullable)photoView;

/// 跳转相机界面
/// @param manager 照片管理者
/// @param delegate 代理
- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager * _Nullable)manager
                                               delegate:(id _Nullable )delegate;

/// 跳转相机界面
/// @param manager 照片管理者
/// @param done 完成回调
/// @param cancel 取消回调
- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager * _Nullable)manager
                                                   done:(HXCustomCameraViewControllerDidDoneBlock _Nullable )done
                                                 cancel:(HXCustomCameraViewControllerDidCancelBlock _Nullable )cancel;

/// 跳转照片编辑界面
/// @param manager 照片管理者，主要设置编辑参数
/// @param photomodel 需要编辑的照片模型
/// @param delegate 代理
/// @param done 完成回调
/// @param cancel 取消回调
- (void)hx_presentPhotoEditViewControllerWithManager:(HXPhotoManager * _Nonnull)manager
                                          photoModel:(HXPhotoModel * _Nonnull)photomodel
                                            delegate:(id _Nullable )delegate
                                                done:(HXPhotoEditViewControllerDidDoneBlock _Nullable)done
                                              cancel:(HXPhotoEditViewControllerDidCancelBlock _Nullable)cancel;

/// 跳转照片编辑界面
/// @param manager 照片管理者，主要设置编辑参数
/// @param editPhoto 需要编辑的照片
/// @param done 完成回调
/// @param cancel 取消回调
- (void)hx_presentPhotoEditViewControllerWithManager:(HXPhotoManager * _Nonnull)manager
                                           editPhoto:(UIImage * _Nonnull)editPhoto
                                                done:(HXPhotoEditViewControllerDidDoneBlock _Nullable)done
                                              cancel:(HXPhotoEditViewControllerDidCancelBlock _Nullable)cancel;

/// 跳转视频编辑界面
/// @param manager 照片管理者，主要设置编辑参数
/// @param videoModel 需要编辑的视频模型
/// @param delegate 代理
/// @param done 完成后的回调
/// @param cancel 取消回调
- (void)hx_presentVideoEditViewControllerWithManager:(HXPhotoManager * _Nonnull)manager
                                          videoModel:(HXPhotoModel * _Nonnull)videoModel
                                            delegate:(id _Nullable )delegate
                                                done:(HXVideoEditViewControllerDidDoneBlock _Nullable)done
                                              cancel:(HXVideoEditViewControllerDidCancelBlock _Nullable)cancel;

/// 跳转视频编辑界面
/// @param manager 照片管理者，主要设置编辑参数
/// @param videoURL 需要编辑的视频本地地址
/// @param done 完成后的回调
/// @param cancel 取消回调
- (void)hx_presentVideoEditViewControllerWithManager:(HXPhotoManager * _Nonnull)manager
                                            videoURL:(NSURL * _Nonnull)videoURL
                                                done:(HXVideoEditViewControllerDidDoneBlock _Nullable)done
                                              cancel:(HXVideoEditViewControllerDidCancelBlock _Nullable)cancel;

/// 跳转仿微信照片编辑界面
/// @param configuration 配置
/// @param photomodel 需要编辑的照片模型
///                   如果需要在原有编辑的基础上进行编辑，直接将之前编辑model传入即可
///                   如果不需要在原有基础上编辑，请将 model.photoEdit 置为nil
/// @param delegate 代理
/// @param finish 完成后的回调
/// @param cancel 取消回调
- (void)hx_presentWxPhotoEditViewControllerWithConfiguration:(HXPhotoEditConfiguration * _Nonnull)configuration
                                                  photoModel:(HXPhotoModel * _Nonnull)photomodel
                                                    delegate:(id _Nullable)delegate
                                                      finish:(HX_PhotoEditViewControllerDidFinishBlock _Nullable)finish
                                                      cancel:(HX_PhotoEditViewControllerDidCancelBlock _Nullable)cancel;

/// 跳转仿微信照片编辑界面
/// @param configuration 配置
/// @param editImage 需要编辑的图片
/// @param photoEdit 之前编辑的数据，为nil则重新开始编辑
/// @param finish 完成后的回调
/// @param cancel 取消回调
- (void)hx_presentWxPhotoEditViewControllerWithConfiguration:(HXPhotoEditConfiguration * _Nonnull)configuration
                                                   editImage:(UIImage * _Nonnull)editImage
                                                   photoEdit:(HXPhotoEdit * _Nullable)photoEdit
                                                      finish:(HX_PhotoEditViewControllerDidFinishBlock _Nullable)finish
                                                      cancel:(HX_PhotoEditViewControllerDidCancelBlock _Nullable)cancel;

- (BOOL)hx_navigationBarWhetherSetupBackground;

- (HXCustomNavigationController *_Nullable)hx_customNavigationController;

#pragma mark - < obsoleting >
/*  <HXAlbumListViewControllerDelegate>
 *  delegate 不传则代表自己
 */
- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *_Nullable)manager
                                            delegate:(id _Nullable )delegate DEPRECATED_MSG_ATTRIBUTE("Use 'hx_presentSelectPhotoControllerWithManager:' instead");
@end
