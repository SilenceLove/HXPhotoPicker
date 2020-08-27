//
//  HX_PhotoManager.h
//  HXPhotoPicker-Demo
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
#import "HXPhotoTypes.h"

@interface HXPhotoManager : NSObject

/// 当前选择类型
@property (assign, nonatomic) HXPhotoManagerSelectedType type;

/// 相关配置
@property (strong, nonatomic) HXPhotoConfiguration *configuration;

/// init
/// @param type 选择类型
- (instancetype)initWithType:(HXPhotoManagerSelectedType)type;
+ (instancetype)managerWithType:(HXPhotoManagerSelectedType)type;

/// 选择照片界面完成时的dismiss时是否需要动画效果
/// 默认YES
@property (assign, nonatomic) BOOL selectPhotoFinishDismissAnimated;

/// 选择照片界面取消时的dismiss时是否需要动画效果
/// 默认YES
@property (assign, nonatomic) BOOL selectPhotoCancelDismissAnimated;

/// 相机界面拍照完成时dismiss时是否需要动画效果
/// 默认YES
@property (assign, nonatomic) BOOL cameraFinishDismissAnimated;

/// 相机界面取消时dismiss时是否需要动画效果
/// 默认YES
@property (assign, nonatomic) BOOL cameraCancelDismissAnimated;

/// 只使用相机功能不加载相册信息
@property (assign, nonatomic) BOOL onlyCamera;

/// 保存在本地的模型
/// 如果为空，请调用 getLocalModelsInFileWithAddData: 方法获取
@property (copy, nonatomic) NSArray<HXPhotoModel *> *localModels;

#pragma mark - < 保存本地的方法 >
/// 保存本地的方法都是在主线程调用
/// 获取保存在本地文件的模型数组
/// @param addData 是否添加到manager的数据中
- (NSArray<HXPhotoModel *> *)getLocalModelsInFileWithAddData:(BOOL)addData;

/// 获取保存在本地文件的模型数组
- (NSArray<HXPhotoModel *> *)getLocalModelsInFile;

/// 将模型数组保存到本地文件
- (BOOL)saveLocalModelsToFile;

/// 将保存在本地文件的模型数组删除
- (BOOL)deleteLocalModelsInFile;

/// 将本地获取的模型数组添加到manager的数据中
/// @param models 在本地获取的模型数组
- (void)addLocalModels:(NSArray<HXPhotoModel *> *)models;

/// 将本地获取的模型数组添加到manager的数据中
- (void)addLocalModels;

/// 添加自定义资源模型
/// 如果图片/视频 选中的数量超过最大选择数时,之后选中的会变为未选中
/// 如果设置的图片/视频不能同时选择时
/// 图片在视频前面的话只会将图片添加到已选数组.
/// 视频在图片前面的话只会将视频添加到已选数组.
/// 如果 type = HXPhotoManagerSelectedTypePhoto 时 会过滤掉视频
/// 如果 type = HXPhotoManagerSelectedTypeVideo 时 会过滤掉图片
/// @param assetArray 模型数组
- (void)addCustomAssetModel:(NSArray<HXCustomAssetModel *> *)assetArray;

/// 获取已选照片数组的照片总大小
- (void)requestPhotosBytesWithCompletion:(void (^)(NSString *totalBytes, NSUInteger totalDataLengths))completion;

/// 已选照片数据的总大小
@property (assign, nonatomic) NSUInteger *selectPhotoTotalDataLengths;
@property (strong, nonatomic) NSOperationQueue *dataOperationQueue;

/**
 建议使用 addCustomAssetModel: 此方法
 添加本地视频数组   内部会将  deleteTemporaryPhoto 设置为NO

 @param urlArray <NSURL *> 本地视频地址
 @param selected 是否选中   选中的话HXPhotoView自动添加显示 没选中可以在相册里手动选中
 */
- (void)addLocalVideo:(NSArray<NSURL *> *)urlArray selected:(BOOL)selected DEPRECATED_MSG_ATTRIBUTE("Use 'addCustomAssetModel:' instead");

/**
 *  建议使用 addCustomAssetModel: 此方法
 *  本地图片数组 <UIImage *> 装的是UIImage对象 - 已设置为选中状态
 */
@property (copy, nonatomic) NSArray *localImageList DEPRECATED_MSG_ATTRIBUTE("Use 'addCustomAssetModel:' instead");

/**
 建议使用 addCustomAssetModel: 此方法
 添加本地图片数组  内部会将  deleteTemporaryPhoto 设置为NO

 @param images <UIImage *> 装的是UIImage对象
 @param selected 是否选中   选中的话HXPhotoView自动添加显示 没选中可以在相册里手动选中
 */
- (void)addLocalImage:(NSArray *)images selected:(BOOL)selected DEPRECATED_MSG_ATTRIBUTE("Use 'addCustomAssetModel:' instead");

/**
 建议使用 addCustomAssetModel: 此方法
 将本地图片添加到相册中  内部会将  configuration.deleteTemporaryPhoto 设置为NO

 @param images <UIImage *> 装的是UIImage对象
 */
- (void)addLocalImageToAlbumWithImages:(NSArray *)images DEPRECATED_MSG_ATTRIBUTE("Use 'addCustomAssetModel:' instead");

/**
 建议使用 addCustomAssetModel: 此方法
 添加网络图片数组

 @param imageUrls 图片地址  NSString*
 @param selected 是否选中
 */
- (void)addNetworkingImageToAlbum:(NSArray<NSString *> *)imageUrls selected:(BOOL)selected DEPRECATED_MSG_ATTRIBUTE("Use 'addCustomAssetModel:' instead");

/**
 建议使用 addCustomAssetModel: 此方法
 网络图片地址数组
 */
@property (strong, nonatomic) NSArray<NSString *> *networkPhotoUrls DEPRECATED_MSG_ATTRIBUTE("Use 'addCustomAssetModel:' instead");

/**
 获取系统所有相册
 */
- (void)getAllAlbumModelWithCompletion:(getAllAlbumListBlock)completion;

/**
 获取所有照片的这个相册
 */
- (void)getCameraRollAlbumCompletion:(void (^)(HXAlbumModel *albumModel))completion;

/**
 根据某个相册模型获取照片列表

 @param albumModel 相册模型
 @param complete 照片列表和首个选中的模型
 */
- (void)getPhotoListWithAlbumModel:(HXAlbumModel *)albumModel complete:(getPhotoListBlock)complete;
/**
 将下载完成的iCloud上的资源模型添加到数组中
 */
- (void)addICloudModel:(HXPhotoModel *)model;
/**
 判断最大值
 */
- (NSString *)maximumOfJudgment:(HXPhotoModel *)model;

/**
 即将要选择模型时调用
 return nil 则走判断是否达到最大值
 return 任意字符串 则会提醒返回的字符串，并且禁止选择
 */
@property (copy, nonatomic) NSString * (^ shouldSelectModel)(HXPhotoModel *model);

#pragma mark - < 关于选择完成之前的一些方法>
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
 完成之前添加 相机拍照/录制/本地/编辑的照片模型到cameraList里
 */
- (void)beforeListAddCameraPhotoModel:(HXPhotoModel *)model;
/**
 完成之前将拍摄之后的模型添加到已选数组中
 */
- (void)beforeListAddCameraTakePicturesModel:(HXPhotoModel *)model;

#pragma mark - < 关于选择完成之后的一些方法 >
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
 刷新已选数组里模型下标
 */
- (void)sortSelectedListIndex;

/**
 清空所有已选数组
 */
- (void)clearSelectedList;

#pragma mark - < 辅助属性 >
@property (assign, nonatomic) HXPhotoManagerVideoSelectedType videoSelectedType;

@property (assign, nonatomic) BOOL selectPhotoing;

#pragma mark - < 辅助方法 >
- (BOOL)videoCanSelected;
/**
 本地资源数量
 
 @return count
 */
- (NSInteger)cameraCount;
/**
 本地图片数量
 
 @return count
 */
- (NSInteger)cameraPhotoCount;
/**
 本地视频数量
 
 @return count
 */
- (NSInteger)cameraVideoCount;

/**
 获取本地模型数组里的第一个模型
 
 @return model
 */
- (HXPhotoModel *)firstCameraModel;

#pragma mark - < cell上添加photoView时所需要用到的方法 >
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
@end
