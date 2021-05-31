//
//  LaNetService.h


#ifndef LaNetService_h
#define LaNetService_h

#import <UIKit/UIKit.h>

@interface LaNetService : NSObject

// 获取网络环境的方法
+ (NSString *)networkType;

+(NSString *)serviceProvider;
@end

#endif /* DeviceInfoPlugin_h */
