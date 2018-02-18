//
//  HXPhotoView.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"
#import "HXCollectionView.h"

/*
 *  使用选择照片之后自动布局的功能时就创建此块View. 初始化方法传入照片管理类
 */
@class HXPhotoView;
@protocol HXPhotoViewDelegate <NSObject>
@optional
// 代理返回 选择、移动顺序、删除之后的图片以及视频
- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal;

// 这次在相册选择的图片,不是所有选择的所有图片.
//- (void)photoViewCurrentSelected:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal;

// 当view更新高度时调用
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame;

// 删除网络图片的地址
- (void)photoView:(HXPhotoView *)photoView deleteNetworkPhoto:(NSString *)networkPhotoUrl;

@end

@interface HXPhotoView : UIView
@property (weak, nonatomic) id<HXPhotoViewDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) NSIndexPath *currentIndexPath; // 自定义转场动画时用到的属性
@property (strong, nonatomic) HXCollectionView *collectionView;


/**
 是否把相机功能放在外面 默认 NO
 */
@property (assign, nonatomic) BOOL outerCamera;

/**
 每行个数 默认3;
 */
@property (assign, nonatomic) NSInteger lineCount;

/**
 每个item间距 默认 3
 */
@property (assign, nonatomic) CGFloat spacing;

- (instancetype)initWithFrame:(CGRect)frame WithManager:(HXPhotoManager *)manager;
/**  不要使用 "initWithFrame" 这个方法初始化否者会出现异常, 请使用下面这个三个初始化方法  */
- (instancetype)initWithFrame:(CGRect)frame manager:(HXPhotoManager *)manager;
- (instancetype)initWithManager:(HXPhotoManager *)manager;
+ (instancetype)photoManager:(HXPhotoManager *)manager;
- (NSIndexPath *)currentModelIndexPath:(HXPhotoModel *)model;
/**  跳转相册 如果需要选择相机/相册时 还是需要选择  */
- (void)goPhotoViewController;
/**  跳转相册 过滤掉选择 - 不管需不需要选择 直接前往相册  */
- (void)directGoPhotoViewController;
/**  跳转相机  */
- (void)goCameraViewController;
/**  删除某个模型  */
- (void)deleteModelWithIndex:(NSInteger)index;
/**  刷新view  */
- (void)refreshView;
/**  删除添加按钮(即不需要)  */
//- (void)deleteAddBtn;
@end
