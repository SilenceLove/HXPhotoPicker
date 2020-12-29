//
//  HXFullScreenCameraPlayView.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/5/23.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HXFullScreenCameraPlayView : UIView
@property (assign, nonatomic) CGFloat progress;
@property (strong, nonatomic) UIColor *color;
@property (assign, nonatomic) NSTimeInterval duration;
- (void)startAnimation;
- (void)clear;
- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color;
@end
