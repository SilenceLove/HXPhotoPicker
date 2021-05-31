//
//  LaFileUtil.h
//  student
//
//  Created by Taomy on 2020/11/4.
//  Copyright © 2020年 pplingo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LaFileUtil : NSObject

//判断某文件是否存在
+(BOOL)isFileExist:(NSString *)filePath;

//删除某文件
+(BOOL)removeFileWithPath:(NSString *)path;

@end
