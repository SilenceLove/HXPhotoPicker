//
//  UIView+HXExtension.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/16.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (HXExtension)

- (void)showImageHUDText:(NSString *)text;
- (void)showLoadingHUDText:(NSString *)text;
- (void)handleLoading;

@end


@interface HXHUD : UIView
- (instancetype)initWithFrame:(CGRect)frame imageName:(NSString *)imageName text:(NSString *)text;
- (void)showloading;
@end
