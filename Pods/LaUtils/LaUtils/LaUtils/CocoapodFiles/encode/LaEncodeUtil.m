//
//  LaEncodeUtil.m
//  taomy


#import "LaEncodeUtil.h"
#import "LaNSStringMacro.h"
#import <CommonCrypto/CommonDigest.h>

@implementation LaEncodeUtil

+ (NSString *)sha1:(NSString *)str {
    if ([M_VerifyString(str) length] > 0) {
        const char *cstr = [str cStringUsingEncoding:NSUTF8StringEncoding];
        NSData *data = [NSData dataWithBytes:cstr length:str.length];
        
        uint8_t digest[CC_SHA1_DIGEST_LENGTH];
        
        CC_SHA1(data.bytes, data.length, digest);
        
        NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
        
        for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
            [output appendFormat:@"%02x", digest[i]];
        }
        
        return output;
    }else{
        return str;
    }
}

+ (NSString *)md5Hash:(NSString *)str {
    if ([M_VerifyString(str) length] > 0) {
        const char *cStr = [str UTF8String];
        unsigned char result[16];
        CC_MD5( cStr, strlen(cStr), result );
        NSString *md5Result = [NSString stringWithFormat:
                               @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                               result[0], result[1], result[2], result[3],
                               result[4], result[5], result[6], result[7],
                               result[8], result[9], result[10], result[11],
                               result[12], result[13], result[14], result[15]
                               ];
        return md5Result;
    }else{
        return str;
    }
}

+ (NSString *)utf8:(NSString *)str{
    if ([M_VerifyString(str) length] > 0) {
        return  [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    }else{
        return str;
    }
}

//对url中的无效字符进行编码处理
+ (NSString *)urlEncode:(NSString *)str{
    if ([M_VerifyString(str) length] > 0) {
        return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:str]];
    }else{
        return str;
    }
}
@end
