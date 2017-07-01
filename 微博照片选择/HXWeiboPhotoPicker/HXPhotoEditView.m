//
//  HXPhotoEditView.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/6/30.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoEditView.h"

@implementation HXPhotoEditView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
 
    //背景
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:0];
    //镂空
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(width / 2, height / 2) radius:(width - 20) / 2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    [path appendPath:circlePath];
    [path setUsesEvenOddFillRule:YES];
    
    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;//中间镂空的关键点 填充规则
    fillLayer.fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor;
    [self.layer addSublayer:fillLayer];

    
    CGContextRef context = UIGraphicsGetCurrentContext();
    //保存旧的绘图上下文
    CGContextSaveGState(context);
    
    //2.设置阴影(参数：上下文、阴影偏移量、阴影模糊系数)
    //不带颜色的阴影
    CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 5.f,[[[UIColor blackColor] colorWithAlphaComponent:0.8] CGColor]);
    CGContextAddArc(context, width / 2, height / 2, (width - 20) / 2, 0, M_PI * 2, YES);
    //4.设置绘图属性
    [[UIColor clearColor] setFill];      //填充色
    [[UIColor whiteColor] setStroke];  //描边
    CGContextDrawPath(context, kCGPathEOFillStroke);
    CGContextRestoreGState(context);
}
@end
