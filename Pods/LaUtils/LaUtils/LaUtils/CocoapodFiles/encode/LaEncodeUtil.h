//
//  LaEncodeUtil.h
//  taomy
//

#import <Foundation/Foundation.h>

@interface LaEncodeUtil : NSObject
//对str进行sha1编码
+ (NSString *)sha1:(NSString *)str;

//对str进行md5编码
+ (NSString *)md5Hash:(NSString *)str;

//对str进行utf8编码
+ (NSString *)utf8:(NSString *)str;

//对url中的无效字符进行编码处理
+ (NSString *)urlEncode:(NSString *)str;
@end
