//
//  LaColorUtil.h
//  taomy

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LaColorUtil : NSObject

//color六位是 2-r 2-g 2-b
//example:[ColorTool colorWithHexString:@"#FBF700"]
+ (UIColor *) colorWithHexString: (NSString *)color;

//color六位是 2-r 2-g 2-b
//alpha是0-1
//[ColorTool colorWithHexString:@"#FBF700" alpha:0.5]
+ (UIColor *) colorWithHexString: (NSString *)color alpha:(CGFloat)alpha;

@end
