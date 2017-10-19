//
//  HXDatePhotoCollectionViewLayoutAttributes.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/18.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoCollectionViewLayoutAttributes.h"

@implementation HXDatePhotoCollectionViewLayoutAttributes
- (instancetype)init {
    if (self = [super init]) {
        self.anchorPoint = CGPointMake(0.5, 0.5);
    }
    return self;
}
- (void)setScale:(CGFloat)scale {
    _scale = scale;
    self.transform = CGAffineTransformMakeScale(scale, 1);
}
- (id)copyWithZone:(NSZone *)zone {
    HXDatePhotoCollectionViewLayoutAttributes *copyAttributes = (HXDatePhotoCollectionViewLayoutAttributes *)[super copyWithZone:zone];
    copyAttributes.anchorPoint = self.anchorPoint;
    return copyAttributes;
}
@end
