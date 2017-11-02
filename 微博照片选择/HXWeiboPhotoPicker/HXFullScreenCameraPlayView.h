//
//  HXFullScreenCameraPlayView.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/5/23.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HXFullScreenCameraPlayView : UIView
@property (assign, nonatomic) CGFloat progress;
@property (strong, nonatomic) UIColor *color;
- (void)clean;
- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color;
@end
