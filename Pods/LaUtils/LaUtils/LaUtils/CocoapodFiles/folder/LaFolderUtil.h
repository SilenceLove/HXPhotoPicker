//
//  LaFolderUtil.h
//  student
//
//  Created by Taomy on 2020/11/4.
//  Copyright © 2020年 pplingo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LaFolderUtil : NSObject

//判断某文件夹是否存在
+(BOOL)isFolderExist:(NSString *)folerPath;

//创建文件夹目录
+(BOOL)createFolder:(NSString *)folderPath;

//删除path文件夹下的所有文件
+(BOOL)removeAllFilesInFolder:(NSString *)folderPath;

//删除path文件夹下的所有文件（包括目录）
+(BOOL)removeAllFilesIncludeFolder:(NSString *)folderPath;

@end
