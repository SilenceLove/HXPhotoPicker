//
//  LFScrollView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFScrollView.h"

@implementation LFScrollView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self lf_customInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self lf_customInit];
    }
    return self;
}

- (void)lf_customInit
{
    self.delaysContentTouches = NO;
    self.canCancelContentTouches = NO;
    
    self.scrollsToTop = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    if (@available(iOS 11.0, *)){
        [self setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }
}

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    return [super touchesShouldCancelInContentView:view];
}

////重写touchesBegin方法
//
//-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    
//    //主要代码实现：
//    
//    [[self nextResponder] touchesBegan:touches withEvent:event];
//    
//    //super调用，别漏
//    
//    [super touchesBegan:touches withEvent:event];
//    
//}
//
//
//
////重写touchesEnded方法
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    
//    [[self nextResponder] touchesEnded:touches withEvent:event];
//    
//    [super touchesEnded:touches withEvent:event];
//    
//}
//
//
//
////重写touchesMoved方法
//
//-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    
//    [[self nextResponder] touchesMoved:touches withEvent:event];
//    
//    [super touchesMoved:touches withEvent:event];
//    
//}
//
//
//
////重写touchesCancelled方法
//
//- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
//    
//    [[self nextResponder] touchesCancelled:touches withEvent:event];
//    
//    [super touchesCancelled:touches withEvent:event];
//}

@end
