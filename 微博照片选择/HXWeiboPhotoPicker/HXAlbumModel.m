//
//  HXAlbumModel.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXAlbumModel.h"
#import "HXPhotoTools.h"
@implementation HXAlbumModel
- (CGFloat)albumNameWidth {
    if (_albumNameWidth == 0) {
        _albumNameWidth = [HXPhotoTools getTextWidth:self.albumName height:18 fontSize:17];
    }
    return _albumNameWidth;
}
@end
