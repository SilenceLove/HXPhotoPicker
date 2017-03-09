//
//  HXPhotoViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"

/**
 *  使用说明: 如果只使用选择图片的功能,就只用跳转此控制器. 照片管理类必须在跳转前赋值
 *  选择的照片/视频通过代理返回
 */


@protocol HXPhotoViewControllerDelegate <NSObject>

/**
 点击下一步执行的代理  数组里面装的都是 HXPhotoModel 对象

 @param allList 所有对象 - 之前选择的所有对象
 @param photos 图片对象 - 之前选择的所有图片
 @param videos 视频对象 - 之前选择的所有视频
 @param original 是否原图
 */
- (void)photoViewControllerDidNext:(NSArray *)allList Photos:(NSArray *)photos Videos:(NSArray *)videos Original:(BOOL)original;

/**
 点击取消执行的代理
 */
- (void)photoViewControllerDidCancel;

@end

@interface HXPhotoViewController : UIViewController
@property (strong, nonatomic) HXPhotoManager *manager; // 照片管理类必须在跳转前赋值
@property (weak, nonatomic) id<HXPhotoViewControllerDelegate> delegate;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic, readonly) NSIndexPath *currentIndexPath;
@property (assign, nonatomic) BOOL isPreview;
@property (strong, nonatomic, readonly) HXAlbumModel *albumModel;
@end

typedef enum : NSUInteger {
    HXPhotoBottomTyPepreview = 0,
    HXPhotoBottomTyOriginalPhoto,
} HXPhotoBottomType;

@protocol HXPhotoBottomViewDelegate <NSObject>

- (void)didPhotoBottomViewClick:(HXPhotoBottomType)type Button:(UIButton *)button;

@end

@interface HXPhotoBottomView : UIView
@property (weak, nonatomic) id<HXPhotoBottomViewDelegate> delegate;
@property (weak, nonatomic) UIButton *previewBtn;
@property (weak, nonatomic) UIButton *originalBtn;
@end
