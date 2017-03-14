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

/**
 *  照片选择的管理类, 使用照片选择时必须先懒加载此类,然后赋值给对应的对象
 */

typedef enum : NSUInteger {
    HXPhotoManagerSelectedTypePhoto = 0, // 只选择图片
    HXPhotoManagerSelectedTypeVideo, // 只选择视频
    HXPhotoManagerSelectedTypePhotoAndVideo // 图片和视频一起
} HXPhotoManagerSelectedType;

@interface HXPhotoManager : NSObject
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
 是否开启查看LivePhoto功能呢 - 默认开启
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
 最大选择数 默认10 - 必填
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
 相册列表每行多少个照片 默认4个
 */
@property (assign, nonatomic) NSInteger rowCount;

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
- (void)emptySelectedList;

@end
