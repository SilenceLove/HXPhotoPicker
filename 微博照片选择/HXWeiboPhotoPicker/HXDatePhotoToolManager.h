//
//  HXDatePhotoToolsManager.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/11/2.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HXPhotoTools.h"


typedef void (^ HXDatePhotoToolManagerSuccessHandler)(NSArray<NSURL *> *allURL,NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL);
typedef void (^ HXDatePhotoToolManagerFailedHandler)();

typedef void (^ HXDatePhotoToolManagerGetImageListSuccessHandler)(NSArray<UIImage *> *imageList);
typedef void (^ HXDatePhotoToolManagerGetImageListFailedHandler)();

@interface HXDatePhotoToolManager : NSObject

/**
 将选择的模型数组写入临时目录

 @param modelList 模型数组
 @param success 成功回调
 @param failed 失败回调
 */
- (void)writeSelectModelListToTempPathWithList:(NSArray<HXPhotoModel *> *)modelList success:(HXDatePhotoToolManagerSuccessHandler)success failed:(HXDatePhotoToolManagerFailedHandler)failed;

/**
 根据模型数组获取与之对应的image数组

 @param modelList 模型数组
 @param success 成功
 @param failed 失败
 */
- (void)getSelectedImageList:(NSArray<HXPhotoModel *> *)modelList success:(HXDatePhotoToolManagerGetImageListSuccessHandler)success failed:(HXDatePhotoToolManagerGetImageListFailedHandler)failed;

/**
 取消获取image
 */
- (void)cancelGetImageList;

@end
