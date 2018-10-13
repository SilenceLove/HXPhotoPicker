//
//  LFStickerLabel.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/4/6.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFStickerLabel.h"
#import "LFText.h"
#import "NSString+LFMECoreText.h"

@implementation LFStickerLabel

- (instancetype)init {
    if (self = [super init]) {
        _textInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _textInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (void)setLf_text:(LFText *)lf_text
{
    _lf_text = lf_text;
    _textSize = [self.lf_text.text LFME_sizeWithConstrainedToWidth:[UIScreen mainScreen].bounds.size.width-(self.textInsets.left+self.textInsets.right) fromFont:self.lf_text.font lineSpace:1.f lineBreakMode:kCTLineBreakByCharWrapping];
    CGRect frame = self.frame;
    frame.size.width = self.textSize.width+(self.textInsets.left+self.textInsets.right);
    frame.size.height = self.textSize.height+(self.textInsets.top+self.textInsets.bottom);
    self.frame = frame;
}

- (void)drawText
{
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    /** 创建画布 */
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.lf_text.text LFME_drawInContext:context withPosition:CGPointMake(self.textInsets.left, self.textInsets.top) andFont:self.lf_text.font andTextColor:self.lf_text.textColor andHeight:self.textSize.height andWidth:self.textSize.width linespace:1.f lineBreakMode:kCTLineBreakByCharWrapping];
    
    UIImage *temp = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CALayer *lay = [[CALayer alloc] init];
    lay.frame = (CGRect){CGPointZero, self.frame.size};
    lay.contents = (__bridge id _Nullable)(temp.CGImage);
    [self.layer addSublayer:lay];
}

@end
