//
//  NSString+LFCoreTextSize.m
//  DrawCoreText
//
//  Created by LamTsanFeng on 16/9/19.
//  Copyright © 2016年 LamTsamFeng. All rights reserved.
//

#import "NSString+LFMECoreText.h"
#import <CoreText/CoreText.h>

@implementation NSString (LFMECoreText)

- (CGSize)LFME_sizeWithConstrainedToWidth:(float)width fromFont:(UIFont *)font1
{
    return [self LFME_sizeWithConstrainedToWidth:width fromFont:font1 lineBreakMode:kCTLineBreakByWordWrapping];
}

- (CGSize)LFME_sizeWithConstrainedToWidth:(float)width fromFont:(UIFont *)font1 lineBreakMode:(CTLineBreakMode)lineBreakMode
{
    return [self LFME_sizeWithConstrainedToWidth:width fromFont:font1 lineSpace:0 lineBreakMode:lineBreakMode];
}

- (CGSize)LFME_sizeWithConstrainedToWidth:(float)width fromFont:(UIFont *)font1 lineSpace:(float)lineSpace lineBreakMode:(CTLineBreakMode)lineBreakMode {
    return [self LFME_sizeWithConstrainedToSize:CGSizeMake(width, CGFLOAT_MAX) fromFont:font1 lineSpace:lineSpace lineBreakMode:lineBreakMode];
}

- (CGSize)LFME_sizeWithConstrainedToSize:(CGSize)size fromFont:(UIFont *)font1 lineSpace:(float)lineSpace lineBreakMode:(CTLineBreakMode)lineBreakMode {
    NSDictionary* attributes = [NSString LFME_attributeFont:font1 andTextColor:nil linespace:lineSpace lineBreakMode:lineBreakMode];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self attributes:attributes];
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)string;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
    CGSize result = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [string length]), NULL, size, NULL);
    CFRelease(framesetter);
    string = nil;
    attributes = nil;
    return result;
}

+ (NSMutableDictionary *)LFME_attributeFont:(UIFont *)font andTextColor:(UIColor *)color linespace:(float)linespace lineBreakMode:(CTLineBreakMode)lineBreakMode {
    
    //Determine default text color
    UIColor* textColor = color;
    //Set line height, font, color and break mode
    CTFontRef font1 = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize,NULL);
    
//    CGFloat minimumLineHeight = font.pointSize,maximumLineHeight = minimumLineHeight+10;
    CTTextAlignment alignment = kCTTextAlignmentLeft;
    
    //Apply paragraph settings
    CTParagraphStyleRef style = CTParagraphStyleCreate((CTParagraphStyleSetting[5]){
        {kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment},
//        {kCTParagraphStyleSpecifierMinimumLineHeight,sizeof(minimumLineHeight),&minimumLineHeight},
//        {kCTParagraphStyleSpecifierMaximumLineHeight,sizeof(maximumLineHeight),&maximumLineHeight},
        {kCTParagraphStyleSpecifierMaximumLineSpacing, sizeof(linespace), &linespace},
        {kCTParagraphStyleSpecifierMinimumLineSpacing, sizeof(linespace), &linespace},
        { kCTParagraphStyleSpecifierLineSpacingAdjustment, sizeof(CGFloat), &linespace },
        {kCTParagraphStyleSpecifierLineBreakMode,sizeof(CTLineBreakMode),&lineBreakMode}
    },5);
    
    
    NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
    attributes[(id)kCTForegroundColorAttributeName] = (id)textColor.CGColor;
    attributes[(id)kCTFontAttributeName] = (__bridge id)font1;
    attributes[(id)kCTParagraphStyleAttributeName] = (__bridge id)style;
    
    CFRelease(font1);
    CFRelease(style);
    
    return attributes;
}


- (void)LFME_drawInContext:(CGContextRef)context withPosition:(CGPoint)p andFont:(UIFont *)font andTextColor:(UIColor *)color andHeight:(float)height andWidth:(float)width linespace:(float)linespace lineBreakMode:(CTLineBreakMode)lineBreakMode {
    CGSize size = CGSizeMake(width, height);
    // 翻转坐标系
    CGContextSetTextMatrix(context,CGAffineTransformIdentity);
    CGContextTranslateCTM(context,0,height);
    CGContextScaleCTM(context,1.0,-1.0);
    
    NSMutableDictionary * attributes = [NSString LFME_attributeFont:font andTextColor:color linespace:linespace lineBreakMode:lineBreakMode];
    
    // 创建绘制区域（路径）
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path,NULL,CGRectMake(p.x, height-p.y-size.height,(size.width),(size.height)));
    
    // 创建AttributedString
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:self attributes:attributes];
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)attributedStr;
    
    // 绘制frame
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
    CTFrameRef ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(0,0),path,NULL);
    CTFrameDraw(ctframe,context);
    CGPathRelease(path);
    CFRelease(framesetter);
    CFRelease(ctframe);
    [[attributedStr mutableString] setString:@""];
    CGContextSetTextMatrix(context,CGAffineTransformIdentity);
    CGContextTranslateCTM(context,0, height);
    CGContextScaleCTM(context,1.0,-1.0);
}

@end
