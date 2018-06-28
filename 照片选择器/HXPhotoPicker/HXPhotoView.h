//
//  HXPhotoView.h
//  照片选择器
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

/**
 照片/视频发生改变时调用 - 选择、移动顺序、删除

 @param photoView 视图本身
 @param allList 所有类型的模型数组
 @param photos 照片类型的模型数组
 @param videos 视频类型的模型数组
 @param isOriginal 是否原图
 */
- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal;

/**
 照片/视频发生改变时调用 - 选择、移动顺序、删除

 @param photoView 视图本身
 @param imageList 图片数组
 */
- (void)photoView:(HXPhotoView *)photoView imageChangeComplete:(NSArray<UIImage *> *)imageList;

/**
 当view高度改变时调用

 @param photoView 视图本身
 @param frame 位置大小
 */
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame;

/**
 删除网络图片时调用

 @param photoView 视图本身
 @param networkPhotoUrl 被删除的图片地址
 */
- (void)photoView:(HXPhotoView *)photoView deleteNetworkPhoto:(NSString *)networkPhotoUrl;

/**
 当前删除的模型

 @param photoView self
 @param model 模型
 @param index 下标
 */
- (void)photoView:(HXPhotoView *)photoView currentDeleteModel:(HXPhotoModel *)model currentIndex:(NSInteger)index;

/**
 长按手势结束时是否删除当前拖动的cell
 
 @param photoView 视图本身
 @return 是否删除
 */
- (BOOL)photoViewShouldDeleteCurrentMoveItem:(HXPhotoView *)photoView;

/**
 长按手势发生改变时调用

 @param photoView 视图本身
 @param longPgr 长按手势识别器
 */
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerChange:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath;

/**
 长按手势开始时调用

 @param photoView 视图本身
 @param longPgr 长按手势识别器
 */
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerBegan:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath;

/**
 长按手势结束时调用

 @param photoView 视图本身
 @param longPgr 长按手势识别器
 */
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerEnded:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath;



// 这次在相册选择的图片,不是所有选择的所有图片.
//- (void)photoViewCurrentSelected:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal;
@end

@interface HXPhotoView : UIView
@property (weak, nonatomic) id<HXPhotoViewDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) NSIndexPath *currentIndexPath; // 自定义转场动画时用到的属性
@property (strong, nonatomic) HXCollectionView *collectionView; 

/**  是否把相机功能放在外面 默认 NO  */
@property (assign, nonatomic) BOOL outerCamera;
/**  每行个数 默认 3  */
@property (assign, nonatomic) NSInteger lineCount;
/**  每个item间距 默认 3  */
@property (assign, nonatomic) CGFloat spacing;
/**  隐藏cell上的删除按钮  */
@property (assign, nonatomic) BOOL hideDeleteButton;
/**  cell是否可以长按拖动编辑  */
@property (assign, nonatomic) BOOL editEnabled;
/**  是否显示添加的cell    默认 YES  */
@property (assign, nonatomic) BOOL showAddCell;
/**  预览大图时是否显示删除按钮  */
@property (assign, nonatomic) BOOL previewShowDeleteButton;
/**  已选的image数组  */
@property (strong, nonatomic) NSMutableArray *imageList;

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
@end
