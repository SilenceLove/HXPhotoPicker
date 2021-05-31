//
//  LaImageUtil.h
//  taomy

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LaImageUtil : NSObject

//截取图片的一部分
+(UIImage*)getSubImage:(UIImage *)image mCGRect:(CGRect)mCGRect;

//缩放图片到合适的大小
+ (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size;

//根据颜色和大小生成image,用于按钮的背景色设置
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

//将视图转换成图片
+(UIImage *)imageFromView:(UIView *)view;
@end
