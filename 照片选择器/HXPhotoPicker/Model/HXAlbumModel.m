//
//  HXAlbumModel.m
//  照片选择器
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXAlbumModel.h"
#import "HXPhotoTools.h"
@implementation HXAlbumModel

- (void)getResultWithCompletion:(void (^)(HXAlbumModel *albumModel))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:self.collection options:self.option];
        self.result = result;
        self.count = result.count;
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self);
            });
        }
    });
}
@end
