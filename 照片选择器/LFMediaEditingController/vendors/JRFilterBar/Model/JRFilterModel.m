//
//  JRImgObj.m
//  JRCollectionView
//
//  Created by Mr.D on 2018/8/6.
//  Copyright © 2018年 Mr.D. All rights reserved.
//

#import "JRFilterModel.h"

@implementation JRFilterModel

@synthesize image = _image;

- (instancetype)initWithEffectType:(LFColorMatrixType)type
{
    self = [super init];
    if (self) {
        _name = lf_colorMatrixName(type);
        _effectType = type;
    } return self;
}

- (void)createFilterImage:(UIImage *)image
{
    if (_image == nil) {
        _image = lf_colorMatrixImage(image, _effectType);
    }
}

@end
