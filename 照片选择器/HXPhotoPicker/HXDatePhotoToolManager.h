//
//  HXDatePhotoToolsManager.h
//  照片选择器
//
//  Created by 洪欣 on 2017/11/2.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HXPhotoTools.h"

typedef enum : NSUInteger {
    HXDatePhotoToolManagerRequestTypeHD = 0, // 高清
    HXDatePhotoToolManagerRequestTypeOriginal // 原图
} HXDatePhotoToolManagerRequestType;

typedef void (^ HXDatePhotoToolManagerSuccessHandler)(NSArray<NSURL *> *allURL,NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL);
typedef void (^ HXDatePhotoToolManagerFailedHandler)(void);

typedef void (^ HXDatePhotoToolManagerGetImageListSuccessHandler)(NSArray<UIImage *> *imageList);
typedef void (^ HXDatePhotoToolManagerGetImageListFailedHandler)(void);

typedef void (^ HXDatePhotoToolManagerGetImageDataListSuccessHandler)(NSArray<NSData *> *imageDataList);
typedef void (^ HXDatePhotoToolManagerGetImageDataListFailedHandler)(void);

//typedef void (^ HXDatePhotoToolManagerGetImagePathSuccessHandler)(NSArray<NSString *> *paths);
//typedef void (^ HXDatePhotoToolManagerGetImagePathFailedHandler)(void);

@interface HXDatePhotoToolManager : NSObject

/**
 将选择的模型数组写入临时目录 -   HXDatePhotoToolManagerRequestTypeHD
 
 注意!!!!
 如果有网络图片时,对应的URL为该网络图片的地址。顺序下标与网络图片在模型数组的下标一致
 也可以根据 http || https 来判断是否网络图片
 
 @param modelList 模型数组
 @param success 成功回调
 @param failed 失败回调
 */
- (void)writeSelectModelListToTempPathWithList:(NSArray<HXPhotoModel *> *)modelList
                                       success:(HXDatePhotoToolManagerSuccessHandler)success
                                        failed:(HXDatePhotoToolManagerFailedHandler)failed;

/**
 将选择的模型数组写入临时目录
 
 注意!!!!
 如果有网络图片时,对应的URL为该网络图片的地址。顺序下标与网络图片在模型数组的下标一致
 也可以根据 http || https 来判断是否网络图片
 
 @param modelList 模型数组
 @param requestType 请求类型
 @param success 成功回调
 @param failed 失败回调
 */
- (void)writeSelectModelListToTempPathWithList:(NSArray<HXPhotoModel *> *)modelList
                                   requestType:(HXDatePhotoToolManagerRequestType)requestType
                                       success:(HXDatePhotoToolManagerSuccessHandler)success
                                        failed:(HXDatePhotoToolManagerFailedHandler)failed;

/**
 根据模型数组获取与之对应的image数组   -   HXDatePhotoToolManagerRequestTypeHD
 如果有网络图片时，会先判断是否已经下载完成了，未下载完则重新下载。
 @param modelList 模型数组
 @param success 成功
 @param failed 失败
 */
- (void)getSelectedImageList:(NSArray<HXPhotoModel *> *)modelList
                     success:(HXDatePhotoToolManagerGetImageListSuccessHandler)success
                      failed:(HXDatePhotoToolManagerGetImageListFailedHandler)failed;

/**
 根据模型数组获取与之对应的image数组
 如果有网络图片时，会先判断是否已经下载完成了，未下载完则重新下载。
 @param modelList 模型数组
 @param requestType 请求类型
 @param success 成功回调
 @param failed 失败回调
 */
- (void)getSelectedImageList:(NSArray<HXPhotoModel *> *)modelList
                 requestType:(HXDatePhotoToolManagerRequestType)requestType
                     success:(HXDatePhotoToolManagerGetImageListSuccessHandler)success
                      failed:(HXDatePhotoToolManagerGetImageListFailedHandler)failed;

/**
 取消获取image
 */
- (void)cancelGetImageList;

//- (void)getSelectedImagePath:(NSArray<HXPhotoModel *> *)modelList success:(HXDatePhotoToolManagerGetImagePathSuccessHandler)success failed:(HXDatePhotoToolManagerGetImagePathFailedHandler)failed;

/**
 根据模型数组获取与之对应的NSData数组
 如果有网络图片时，会先判断是否已经下载完成了，未下载完则重新下载。
 
 @param modelList 模型数组
 @param success 成功
 @param failed 失败
 */
- (void)getSelectedImageDataList:(NSArray<HXPhotoModel *> *)modelList
                         success:(HXDatePhotoToolManagerGetImageDataListSuccessHandler)success
                          failed:(HXDatePhotoToolManagerGetImageDataListFailedHandler)failed;

- (void)gifModelAssignmentData:(NSArray<HXPhotoModel *> *)gifModelArray
                       success:(void (^)(void))success
                        failed:(void (^)(void))failed;
@end
