//
//  HXPhotoModel.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoModel.h"
@implementation HXPhotoModel
- (CGSize)imageSize
{
    if (_imageSize.width == 0 || _imageSize.height == 0) {
        _imageSize = CGSizeMake(self.asset.pixelWidth, self.asset.pixelHeight);
    }
    return _imageSize;
}

- (CGSize)endImageSize
{
    if (_endImageSize.width == 0 || _endImageSize.height == 0) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.height - 64;
        CGFloat imgWidth = self.imageSize.width;
        CGFloat imgHeight = self.imageSize.height;
        CGFloat w;
        CGFloat h;
        imgHeight = width / imgWidth * imgHeight;
        if (imgHeight > height) {
            w = height / self.imageSize.height * imgWidth;
            h = height;
        }else {
            w = width;
            h = imgHeight;
        }
        _endImageSize = CGSizeMake(w, h);
    }
    return _endImageSize;
}

@end
