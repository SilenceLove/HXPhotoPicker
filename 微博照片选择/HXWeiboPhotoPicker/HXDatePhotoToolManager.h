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

@interface HXDatePhotoToolManager : NSObject

- (void)writeSelectModelListToTempPathWithList:(NSArray<HXPhotoModel *> *)modelList success:(HXDatePhotoToolManagerSuccessHandler)success failed:(HXDatePhotoToolManagerFailedHandler)failed;


@end
