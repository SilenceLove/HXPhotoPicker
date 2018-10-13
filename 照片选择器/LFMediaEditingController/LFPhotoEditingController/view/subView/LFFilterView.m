//
//  LFFilterView.m
//  LFMediaEditingController
//
//  Created by TsanFeng Lam on 2018/8/6.
//  Copyright © 2018年 LamTsanFeng. All rights reserved.
//

#import "LFFilterView.h"

NSString *const kLFFilterViewData = @"LFFilterViewData";

@interface LFFilterView ()

@property (nonatomic, weak) UIImageView *imageView;

@property (nonatomic, strong) UIImage *defaultImage;

@end

@implementation LFFilterView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.backgroundColor = [UIColor clearColor];
    self.contentMode = UIViewContentModeScaleAspectFit;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.backgroundColor = [UIColor clearColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:imageView];
    self.imageView = imageView;
}

- (UIImage *)image
{
    return self.imageView.image;
}

- (void)setImage:(UIImage *)image
{
    self.defaultImage = image;
    self.imageView.image = image;
    /** 重新生成滤镜 */
    self.cmType = self.cmType;
}

- (void)setCmType:(LFColorMatrixType)cmType
{
    _cmType = cmType;
    self.imageView.image = lf_colorMatrixImage(self.defaultImage, cmType);
}

#pragma mark  - 数据
- (NSDictionary *)data
{
    if (self.cmType != LFColorMatrixType_None) {
        return @{kLFFilterViewData:@(self.cmType)};
    }
    return nil;
}

- (void)setData:(NSDictionary *)data
{
    self.cmType = [data[kLFFilterViewData] integerValue];
}


@end
