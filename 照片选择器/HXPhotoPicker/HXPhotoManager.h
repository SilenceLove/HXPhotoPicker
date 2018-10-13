//
//  HX_PhotoManager.h
//  照片选择器
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "HXAlbumModel.h"
#import "HXPhotoModel.h"
#import "HXPhotoTools.h"
#import "HXPhotoConfiguration.h"
#import "HXCustomAssetModel.h"


typedef void (^ viewControllerDidDoneBlock)(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL original, UIViewController *viewController, HXPhotoManager *manager);

typedef void (^ viewControllerDidDoneAllImageBlock)(NSArray<UIImage *> *imageList, BOOL original, UIViewController *viewController, HXPhotoManager *manager);

typedef void (^ viewControllerDidDoneAllAssetBlock)(NSArray<PHAsset *> *allAsset, NSArray<PHAsset *> *photoAssets, NSArray<PHAsset *> *videoAssets, BOOL original, UIViewController *viewController, HXPhotoManager *manager);

typedef void (^ viewControllerDidCancelBlock)(UIViewController *viewController, HXPhotoManager *manager);

/**
 *  照片选择器的管理类, 使用照片选择器时必须先懒加载此类,然后赋值给对应的对象
 */
typedef NS_ENUM(NSUInteger, HXPhotoManagerSelectedType) {
    HXPhotoManagerSelectedTypePhoto = 0,        //!< 只显示图片
    HXPhotoManagerSelectedTypeVideo = 1,        //!< 只显示视频
    HXPhotoManagerSelectedTypePhotoAndVideo     //!< 图片和视频一起显示
};

typedef NS_ENUM(NSUInteger, HXPhotoManagerVideoSelectedType) {
    HXPhotoManagerVideoSelectedTypeNormal = 0,  //!< 普通状态显示选择按钮
    HXPhotoManagerVideoSelectedTypeSingle       //!< 单选不显示选择按钮
};

@interface HXPhotoManager : NSObject

@property (assign, nonatomic) HXPhotoManagerSelectedType type;

/**
 @param type 选择类型
 @return self
 */
- (instancetype)initWithType:(HXPhotoManagerSelectedType)type;

/**
 配置信息
 */
@property (strong, nonatomic) HXPhotoConfiguration *configuration; 

@property (assign, nonatomic) HXPhotoManagerVideoSelectedType videoSelectedType;

@property (strong, nonatomic) UIView *tempCameraPreviewView;
@property (strong, nonatomic) UIView *tempCameraView;

/**
 添加模型数组

 @param modelArray ...
 */
- (void)addModelArray:(NSArray<HXPhotoModel *> *)modelArray;

/**
 添加自定义资源模型
 如果图片/视频 选中的数量超过最大选择数时,之后选中的会变为未选中
 如果设置的图片/视频不能同时选择时
 图片在视频前面的话只会将图片添加到已选数组.
 视频在图片前面的话只会将视频添加到已选数组.
 如果 type = HXPhotoManagerSelectedTypePhoto 时 会过滤掉视频
 如果 type = HXPhotoManagerSelectedTypeVideo 时 会过滤掉图片
 
 @param assetArray 模型数组
 */
- (void)addCustomAssetModel:(NSArray<HXCustomAssetModel *> *)assetArray;

/**
 添加本地视频数组   内部会将  deleteTemporaryPhoto 设置为NO

 @param urlArray <NSURL *> 本地视频地址
 @param selected 是否选中   选中的话HXPhotoView自动添加显示 没选中可以在相册里手动选中
 */
- (void)addLocalVideo:(NSArray<NSURL *> *)urlArray selected:(BOOL)selected;

/**
 *  本地图片数组 <UIImage *> 装的是UIImage对象 - 已设置为选中状态
 */
@property (copy, nonatomic) NSArray *localImageList;

/**
 添加本地图片数组  内部会将  deleteTemporaryPhoto 设置为NO

 @param images <UIImage *> 装的是UIImage对象
 @param selected 是否选中   选中的话HXPhotoView自动添加显示 没选中可以在相册里手动选中
 */
- (void)addLocalImage:(NSArray *)images selected:(BOOL)selected;

/**
 将本地图片添加到相册中  内部会将  configuration.deleteTemporaryPhoto 设置为NO

 @param images <UIImage *> 装的是UIImage对象
 */
- (void)addLocalImageToAlbumWithImages:(NSArray *)images;

/**
 添加网络图片数组

 @param imageUrls 图片地址  NSString*
 @param selected 是否选中
 */
- (void)addNetworkingImageToAlbum:(NSArray<NSString *> *)imageUrls selected:(BOOL)selected;

/**
 相册列表
 */
@property (strong, nonatomic,readonly) NSMutableArray *albums;

/**
 网络图片地址数组
 */
@property (strong, nonatomic) NSArray<NSString *> *networkPhotoUrls;

/**
 源对象信息
 */
@property (strong, nonatomic) id sourceObject;

/**
 获取系统所有相册
 
 @param albums 相册集合
 */
- (void)getAllPhotoAlbums:(void(^)(HXAlbumModel *firstAlbumModel))firstModel albums:(void(^)(NSArray *albums))albums isFirst:(BOOL)isFirst;

- (void)fetchAlbums:(void (^)(HXAlbumModel *selectedModel))selectedModel albums:(void(^)(NSArray *albums))albums;
/**
 根据某个相册模型获取照片列表

 @param albumModel 相册模型
 @param complete 照片列表和首个选中的模型
 */
- (void)getPhotoListWithAlbumModel:(HXAlbumModel *)albumModel complete:(void (^)(NSArray *allList , NSArray *previewList,NSArray *photoList ,NSArray *videoList ,NSArray *dateList , HXPhotoModel *firstSelectModel))complete;

/**
 将下载完成的iCloud上的资源模型添加到数组中
 */
- (void)addICloudModel:(HXPhotoModel *)model;

/**
 判断最大值
 */
- (NSString *)maximumOfJudgment:(HXPhotoModel *)model;

- (BOOL)videoCanSelected;

- (NSInteger)cameraCount;
- (HXPhotoModel *)firstCameraModel;

/**  关于选择完成之前的一些方法  **/
/**
 完成之前选择的总数量
 */
- (NSInteger)selectedCount;
/**
 完成之前选择的照片数量
 */
- (NSInteger)selectedPhotoCount;
/**
 完成之前选择的视频数量
 */
- (NSInteger)selectedVideoCount;
/**
 完成之前选择的所有数组
 */
- (NSArray *)selectedArray;
/**
 完成之前选择的照片数组
 */
- (NSArray *)selectedPhotoArray;
/**
 完成之前选择的视频数组
 */
- (NSArray *)selectedVideoArray;
/**
 完成之前是否原图
 */
- (BOOL)original;
/**
 完成之前设置是否原图
 */
- (void)setOriginal:(BOOL)original;
/**
 完成之前的照片数组是否达到最大数
 @return yes or no
 */
- (BOOL)beforeSelectPhotoCountIsMaximum;
/**
 完成之前的视频数组是否达到最大数
 @return yes or no
 */
- (BOOL)beforeSelectVideoCountIsMaximum;
/**
 完成之前从已选数组中删除某个模型
 */
- (void)beforeSelectedListdeletePhotoModel:(HXPhotoModel *)model;
/**
 完成之前添加某个模型到已选数组中
 */
- (void)beforeSelectedListAddPhotoModel:(HXPhotoModel *)model;
/**
 完成之前添加编辑之后的模型到已选数组中
 */
- (void)beforeSelectedListAddEditPhotoModel:(HXPhotoModel *)model;
/**
 完成之前将拍摄之后的模型添加到已选数组中
 */
- (void)beforeListAddCameraTakePicturesModel:(HXPhotoModel *)model;

/*--  关于选择完成之后的一些方法  --*/
/**
 完成之后选择的总数是否达到最大
 */
- (BOOL)afterSelectCountIsMaximum;
/**
 完成之后选择的照片数是否达到最大
 */
- (BOOL)afterSelectPhotoCountIsMaximum;
/**
 完成之后选择的视频数是否达到最大
 */
- (BOOL)afterSelectVideoCountIsMaximum;
/**
 完成之后选择的总数
 */
- (NSInteger)afterSelectedCount;
/**
 完成之后选择的所有数组
 */
- (NSArray *)afterSelectedArray;
/**
 完成之后选择的照片数组
 */
- (NSArray *)afterSelectedPhotoArray;
/**
 完成之后选择的视频数组
 */
- (NSArray *)afterSelectedVideoArray;
/**
 设置完成之后选择的照片数组
 */
- (void)setAfterSelectedPhotoArray:(NSArray *)array;
/**
 设置完成之后选择的视频数组
 */
- (void)setAfterSelectedVideoArray:(NSArray *)array;
/**
 完成之后是否原图
 */
- (BOOL)afterOriginal;
/**
 交换完成之后的两个模型在已选数组里的位置
 */
- (void)afterSelectedArraySwapPlacesWithFromModel:(HXPhotoModel *)fromModel fromIndex:(NSInteger)fromIndex toModel:(HXPhotoModel *)toModel toIndex:(NSInteger)toIndex;
/**
 替换完成之后的模型
 */
- (void)afterSelectedArrayReplaceModelAtModel:(HXPhotoModel *)atModel withModel:(HXPhotoModel *)model;
/**
 完成之后添加编辑之后的模型到数组中
 */
- (void)afterSelectedListAddEditPhotoModel:(HXPhotoModel *)model;
/**
 完成之后将拍摄之后的模型添加到已选数组中
 */
- (void)afterListAddCameraTakePicturesModel:(HXPhotoModel *)model;
/**
 完成之后从已选数组中删除指定模型
 */
- (void)afterSelectedListdeletePhotoModel:(HXPhotoModel *)model;
/**
 完成之后添加某个模型到已选数组中
 */
- (void)afterSelectedListAddPhotoModel:(HXPhotoModel *)model;



- (void)selectedListTransformAfter;
- (void)selectedListTransformBefore;

/**
 取消选择
 */
- (void)cancelBeforeSelectedList;

/**
 清空所有已选数组
 */
- (void)clearSelectedList;

/**  cell上添加photoView时所需要用到的方法  */
- (void)changeAfterCameraArray:(NSArray *)array;
- (void)changeAfterCameraPhotoArray:(NSArray *)array;
- (void)changeAfterCameraVideoArray:(NSArray *)array;
- (void)changeAfterSelectedCameraArray:(NSArray *)array;
- (void)changeAfterSelectedCameraPhotoArray:(NSArray *)array;
- (void)changeAfterSelectedCameraVideoArray:(NSArray *)array;
- (void)changeAfterSelectedArray:(NSArray *)array;
- (void)changeAfterSelectedPhotoArray:(NSArray *)array;
- (void)changeAfterSelectedVideoArray:(NSArray *)array;
- (void)changeICloudUploadArray:(NSArray *)array;
- (NSArray *)afterCameraArray;
- (NSArray *)afterCameraPhotoArray;
- (NSArray *)afterCameraVideoArray;
- (NSArray *)afterSelectedCameraArray;
- (NSArray *)afterSelectedCameraPhotoArray;
- (NSArray *)afterSelectedCameraVideoArray;
- (NSArray *)afterICloudUploadArray;

- (NSString *)version;

/**
 保存模型数组到本地
 
 @param success 成功
 @param failed 失败
 */
- (void)saveSelectModelArraySuccess:(void (^)(void))success failed:(void (^)(void))failed;

/**
 删除本地保存的模型数组
 
 @return success or failed
 */
- (BOOL)deleteLocalSelectModelArray;

/**
 获取保存在本地的模型数组
 
 */
- (void)getSelectedModelArrayComplete:(void (^)(NSArray<HXPhotoModel *> *modelArray))complete;

- (BOOL)saveSelectModelArray;

- (NSArray<HXPhotoModel *> *)getSelectedModelArray;

- (BOOL)deleteSelectModelArray;

@end
