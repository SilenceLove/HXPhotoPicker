//
//  HX_PhotoEditViewController.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/20.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "HXPhotoEdit.h"
#import "HXPhotoEditConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class HX_PhotoEditViewController, HXPhotoModel;

typedef void (^ HX_PhotoEditViewControllerDidFinishBlock)(HXPhotoEdit * _Nullable photoEdit, HXPhotoModel *photoModel, HX_PhotoEditViewController *viewController);
typedef void (^ HX_PhotoEditViewControllerDidCancelBlock)(HX_PhotoEditViewController *viewController);

@protocol HX_PhotoEditViewControllerDelegate <NSObject>
@optional
/// 照片编辑完成
/// @param photoEditingVC 编辑控制器
/// @param photoEdit 编辑完之后的数据，如果为nil。则未处理
- (void)photoEditingController:(HX_PhotoEditViewController *)photoEditingVC
            didFinishPhotoEdit:(HXPhotoEdit * _Nullable)photoEdit
                    photoModel:(HXPhotoModel *)photoModel;

/// 取消编辑
/// @param photoEditingVC 编辑控制器
- (void)photoEditingControllerDidCancel:(HX_PhotoEditViewController *)photoEditingVC;
@end

@interface HX_PhotoEditViewController : UIViewController<UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) HXPhotoModel *photoModel;

/// 编辑的数据
/// 传入之前的编辑数据可以在原有基础上继续编辑
@property (strong, nonatomic) HXPhotoEdit *photoEdit;
/// 编辑原图
@property (strong, nonatomic) UIImage *editImage;
/// 编辑配置
@property (strong, nonatomic) HXPhotoEditConfiguration *configuration;
/// 只要裁剪
@property (assign, nonatomic) BOOL onlyCliping;
/// 是否保存到系统相册
/// 当保存系统相册时photoEdit会为空
@property (assign, nonatomic) BOOL saveAlbum;
/// 保存到自定义相册的名称
@property (copy, nonatomic) NSString *albumName;
/// 照片定位信息
@property (strong, nonatomic) CLLocation *location;

/// 是否支持旋转，优先级比 configuration.supportRotation 高
@property (assign, nonatomic) BOOL supportRotation;

@property (weak, nonatomic) id<HX_PhotoEditViewControllerDelegate> delegate;

@property (copy, nonatomic) HX_PhotoEditViewControllerDidFinishBlock finishBlock;

@property (copy, nonatomic) HX_PhotoEditViewControllerDidCancelBlock cancelBlock;

- (instancetype)initWithConfiguration:(HXPhotoEditConfiguration *)configuration;
- (instancetype)initWithPhotoEdit:(HXPhotoEdit *)photoEdit
                    configuration:(HXPhotoEditConfiguration *)configuration;
- (instancetype)initWithEditImage:(UIImage *)editImage
                    configuration:(HXPhotoEditConfiguration *)configuration;


#pragma mark - < other >
@property (assign, nonatomic) BOOL imageRequestComplete;
@property (assign, nonatomic) BOOL transitionCompletion;
@property (assign, nonatomic) BOOL isCancel;
- (CGRect)getImageFrame;
- (void)showBgViews;
- (void)completeTransition:(UIImage *)image;
- (CGRect)getDismissImageFrame;
- (UIImage *)getCurrentImage;
- (void)hideImageView;
- (void)hiddenTopBottomView;
- (void)showTopBottomView;
@property (assign, nonatomic) BOOL isAutoBack;
@end

NS_ASSUME_NONNULL_END
