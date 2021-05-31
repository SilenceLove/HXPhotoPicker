//
//  LaFolderUtil.m
//  student
//
//  Created by Taomy on 2020/11/4.
//  Copyright © 2020年 pplingo. All rights reserved.
//

#import "LaFolderUtil.h"
#import "LaNSStringMacro.h"

@implementation LaFolderUtil

+(BOOL)removeAllFilesIncludeFolder:(NSString *)path
{
    if ([M_VerifyString(path) length] > 0) {
        BOOL isSuc1 = [[self class] removeAllFilesInFolder:path];
        BOOL isSuc2 = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return isSuc1&&isSuc2;
    }else{
        return NO;
    }
}

+(BOOL)removeAllFilesInFolder:(NSString *)path
{
    if ([M_VerifyString(path) length] > 0) {
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
        NSEnumerator *eDir = [contents objectEnumerator];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString* fileName;
        while (fileName = [eDir nextObject])
        {
            if (fileName!=nil)
            {
                [fileManager removeItemAtPath:[path stringByAppendingPathComponent:fileName] error:NULL];
            }
        }
        return YES;
    }else{
        return NO;
    }
}

+(BOOL)createFolder:(NSString *)path
{
    if ([M_VerifyString(path) length] > 0) {
        NSString *documentPath = [NSHomeDirectory() stringByAppendingString:@"/Documents"];
        NSInteger documentPathLen = [documentPath length];
        NSString *folderPathAfterDocument = [path substringFromIndex:documentPathLen+1];
        NSArray *pathItemArray = [folderPathAfterDocument componentsSeparatedByString:@"/"];
        NSString *middlePath = documentPath;
        for (NSString *pathItem in pathItemArray)
        {
            if (![pathItem isEqualToString:@""])
            {
                middlePath = [middlePath stringByAppendingPathComponent:pathItem];
                [[self class] p_createPathIfNotExist:middlePath];
            }
        }
        return YES;
    }else{
        return NO;
    }
}

//如果不存在path创建
+(BOOL)p_createPathIfNotExist:(NSString *)path
{
    if ([M_VerifyString(path) length] > 0) {
        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory;
        if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
            [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        }
        return YES;
    }else{
        return NO;
    }
}

//判断某文件夹是否存在
+(BOOL)isFolderExist:(NSString *)folerPath
{
    if ([M_VerifyString(folerPath) length] > 0) {
        BOOL isDir;
        BOOL isExist;
        isExist = [[NSFileManager defaultManager] fileExistsAtPath:folerPath isDirectory:&isDir];
        return isExist&&isDir;
    }else{
        return NO;
    }
}

@end
