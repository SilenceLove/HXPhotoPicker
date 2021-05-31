//
//  LaFileUtil.m
//  student
//
//  Created by Taomy on 2020/11/4.
//  Copyright © 2020年 pplingo. All rights reserved.
//

#import "LaFileUtil.h"
#import "LaNSStringMacro.h"

@implementation LaFileUtil

//判断某文件是否存在
+(BOOL)isFileExist:(NSString *)filePath
{
    if ([M_VerifyString(filePath) length] > 0) {
        BOOL isDir;
        BOOL isExist;
        isExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
        return isExist&&(!isDir);
    }else{
        return NO;
    }
}

//删除某文件
+(BOOL)removeFileWithPath:(NSString *)path
{
    if ([M_VerifyString(path) length] > 0) {
        BOOL isSuc = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return isSuc;
    }else{
        return NO;
    }
}

@end
