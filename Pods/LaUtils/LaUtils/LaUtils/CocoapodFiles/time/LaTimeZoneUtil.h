//
//  LaTimeZoneUtil.h
//  student
//
//  Created by taomingyan on 2020/12/1.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LaTimeZoneUtil : NSObject
//获取当前时区的描述格式  例 GMT +80   或者  GMT -80
+(NSString *)currentZone;
@end

NS_ASSUME_NONNULL_END
