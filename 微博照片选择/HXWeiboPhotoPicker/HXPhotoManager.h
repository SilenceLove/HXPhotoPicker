//
//  HX_PhotoManager.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "HXAlbumModel.h"
#import "HXPhotoModel.h"
#import "HXPhotoTools.h"
#import "HXPhotoUIManager.h"

/**
 *  照片选择的管理类, 使用照片选择时必须先懒加载此类,然后赋值给对应的对象
 */
typedef enum : NSUInteger {
    HXPhotoManagerSelectedTypePhoto = 0,        // 只选择图片
    HXPhotoManagerSelectedTypeVideo = 1,        // 只选择视频
    HXPhotoManagerSelectedTypePhotoAndVideo     // 图片和视频一起
} HXPhotoManagerSelectedType;

typedef enum : NSUInteger {
    HXPhotoManagerCameraTypeHalfScreen = 0,     // 半屏相机
    HXPhotoManagerCameraTypeFullScreen = 1,     // 全屏相机
    HXPhotoManagerCameraTypeSystem              // 系统相机
} HXPhotoManagerCameraType;

@interface HXPhotoManager : NSObject

/**
 *  删除临时的照片/视频 - 注:相机拍摄的照片并没有保存到系统相册 或 是本地图片 如果当这样的照片都没有被选中时会清空这些照片 有一张选中了就不会删..  - 默认 YES
 */
@property (assign, nonatomic) BOOL deleteTemporaryPhoto;

/**
 *  本地图片数组 <UIImage *> 装的是UIImage对象 - 已设置为选中状态
 */
@property (copy, nonatomic) NSArray *localImageList;

/**
 添加本地图片数组  内部会将  deleteTemporaryPhoto 设置为NO

 @param images <UIImage *> 装的是UIImage对象
 @param selected 是否选中  选中的话HXPhotoView自动添加显示 没选中可以在相册里手动选中
 */
- (void)addLocalImage:(NSArray *)images selected:(BOOL)selected;

/**
 将本地图片添加到相册中  内部会将  deleteTemporaryPhoto 设置为NO 

 @param images <UIImage *> 装的是UIImage对象
 */
- (void)addLocalImageToAlbumWithImages:(NSArray *)images;

/**
 *  管理UI的类
 */
@property (strong, nonatomic) HXPhotoUIManager *UIManager;

/**
 *  拍摄的 照片/视频 是否保存到系统相册  默认NO 此功能需要配合 监听系统相册 和 缓存相册 功能 (请不要关闭)
 */
@property (assign, nonatomic) BOOL saveSystemAblum;

/**
 *  视频能选择的最大秒数  -  默认 5分钟/300秒
 */
@property (assign, nonatomic) NSTimeInterval videoMaxDuration;

/**
 *  是否缓存相册, manager会监听系统相册变化(需要此功能时请不要关闭监听系统相册功能)   默认YES
 */
@property (assign, nonatomic) BOOL cacheAlbum;

/**
 *  是否监听系统相册  -  如果开启了缓存相册 自动开启监听   默认 YES
 */
@property (assign, nonatomic) BOOL monitorSystemAlbum;

/**
 是否为单选模式 默认 NO
 */
@property (assign, nonatomic) BOOL singleSelected;

/**
 单选模式下是否需要裁剪  默认YES
 */
@property (assign, nonatomic) BOOL singleSelecteClip;

/**
 是否开启3DTouch预览功能 默认 YES
 */
@property (assign, nonatomic) BOOL open3DTouchPreview;

/**
 相机界面类型 //  默认  半屏
 */
@property (assign, nonatomic) HXPhotoManagerCameraType cameraType;

/**
 删除网络图片时是否显示Alert // 默认不显示
 */
@property (assign, nonatomic) BOOL showDeleteNetworkPhotoAlert;

/**
 网络图片地址数组
 */
@property (strong, nonatomic) NSMutableArray *networkPhotoUrls;

/**
 是否把相机功能放在外面 默认 NO   使用 HXPhotoView 时有用
 */
@property (assign, nonatomic) BOOL outerCamera;

/**
 是否打开相机功能
 */
@property (assign, nonatomic) BOOL openCamera;

/**
 是否开启查看GIF图片功能 - 默认开启
 */
@property (assign, nonatomic) BOOL lookGifPhoto;

/**
 是否开启查看LivePhoto功能呢 - 默认 NO
 */
@property (assign, nonatomic) BOOL lookLivePhoto;

/**
 当选择类型为 HXPhotoManagerSelectedTypePhotoAndVideo 时 此属性为YES时 选择的视频会跟图片分开排  反之  视频和图片混合在一起排
 */
@property (assign, nonatomic) BOOL separate; // ---- 预留

/**
 是否一开始就进入相机界面
 */
@property (assign, nonatomic) BOOL goCamera;

/**
 最大选择数 等于 图片最大数 + 视频最大数 默认10 - 必填
 */
@property (assign, nonatomic) NSInteger maxNum;

/**
 图片最大选择数 默认9 - 必填
 */
@property (assign, nonatomic) NSInteger photoMaxNum;

/**
 视频最大选择数 // 默认1 - 必填
 */
@property (assign, nonatomic) NSInteger videoMaxNum;

/**
 图片和视频是否能够同时选择 默认支持
 */
@property (assign, nonatomic) BOOL selectTogether;

/**
 相册列表每行多少个照片 默认4个 iphone 4s / 5  默认3个
 */
@property (assign, nonatomic) NSInteger rowCount;

/*-------------------------------------------------------*/







//------// 当要删除的已选中的图片或者视频的时候需要在对应的end数组里面删除
// 例如: 如果删除的是通过相机拍的照片需要在 endCameraList 和 endCameraPhotos 数组删除对应的图片模型
@property (strong, nonatomic) NSMutableArray *selectedList;
@property (strong, nonatomic) NSMutableArray *selectedPhotos;
@property (strong, nonatomic) NSMutableArray *selectedVideos;
@property (strong, nonatomic) NSMutableArray *cameraList;
@property (strong, nonatomic) NSMutableArray *cameraPhotos;
@property (strong, nonatomic) NSMutableArray *cameraVideos;
@property (strong, nonatomic) NSMutableArray *endCameraList;
@property (strong, nonatomic) NSMutableArray *endCameraPhotos;
@property (strong, nonatomic) NSMutableArray *endCameraVideos;
@property (strong, nonatomic) NSMutableArray *selectedCameraList;
@property (strong, nonatomic) NSMutableArray *selectedCameraPhotos;
@property (strong, nonatomic) NSMutableArray *selectedCameraVideos;
@property (strong, nonatomic) NSMutableArray *endSelectedCameraList;
@property (strong, nonatomic) NSMutableArray *endSelectedCameraPhotos;
@property (strong, nonatomic) NSMutableArray *endSelectedCameraVideos;
@property (strong, nonatomic) NSMutableArray *endSelectedList;
@property (strong, nonatomic) NSMutableArray *endSelectedPhotos;
@property (strong, nonatomic) NSMutableArray *endSelectedVideos;
//------//
@property (assign, nonatomic) HXPhotoManagerSelectedType type;
@property (assign, nonatomic) BOOL isOriginal;
@property (assign, nonatomic) BOOL endIsOriginal;
@property (copy, nonatomic) NSString *photosTotalBtyes;
@property (copy, nonatomic) NSString *endPhotosTotalBtyes;


@property (strong, nonatomic) NSMutableArray *albums;


@property (copy, nonatomic) NSDictionary *photoViewCellIconDic;

/**  是否正在照片控制器里选择图片  */
@property (assign, nonatomic) BOOL selectPhoto;

/**  系统相册发生了变化  */
@property (copy, nonatomic) void (^photoLibraryDidChangeWithPhotoViewController)(NSArray *collectionChanges);
@property (copy, nonatomic) void (^photoLibraryDidChangeWithPhotoPreviewViewController)(NSArray *collectionChanges);
@property (copy, nonatomic) void (^photoLibraryDidChangeWithVideoViewController)(NSArray *collectionChanges);
@property (copy, nonatomic) void (^photoLibraryDidChangeWithPhotoView)(NSArray *collectionChanges ,BOOL selectPhoto);

/**  是否为相机拍摄的图片  */
@property (assign, nonatomic) BOOL cameraPhoto;

@property (strong, nonatomic) HXAlbumModel *tempAlbumMd;


/**
 HXPhotoManagerSelectedTypePhoto            // 只选择图片 - 默认类型
 HXPhotoManagerSelectedTypeVideo            // 只选择视频
 HXPhotoManagerSelectedTypePhotoAndVideo    // 图片视频一起选
 
 @param type 选择类型
 @return self
 */
- (instancetype)initWithType:(HXPhotoManagerSelectedType)type;

/**
 获取系统所有相册
 
 @param albums 相册集合
 */
- (void)FetchAllAlbum:(void(^)(NSArray *albums))albums IsShowSelectTag:(BOOL)isShow;

/**
 根据PHFetchResult获取某个相册里面的所有图片和视频

 @param result PHFetchResult对象
 @param index 相册下标
 @param list 照片和视频的集合
 */
- (void)FetchAllPhotoForPHFetchResult:(PHFetchResult *)result Index:(NSInteger)index FetchResult:(void(^)(NSArray *photos, NSArray *videos, NSArray *Objs))list;

/**
 删除指定model

 @param model 模型
 */
- (void)deleteSpecifiedModel:(HXPhotoModel *)model;

/**
 将传入数组里的所有模型添加到已选数组中
 
 @param list 模型数组
 */
- (void)addSpecifiedArrayToSelectedArray:(NSArray *)list;

/**
 清空所有已选数组
 */
- (void)clearSelectedList;

- (void)getImage;

@end
