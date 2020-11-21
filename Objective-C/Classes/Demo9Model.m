//
//  Demo9Model.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2018/2/14.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "Demo9Model.h"

@implementation Demo9Model
- (CGFloat)cellHeight {
    _cellHeight = self.photoViewHeight;
    return _cellHeight;
}
//- (CGFloat)photoViewHeight {
//    if (_photoViewHeight == 0) {
//        _photoViewHeight = (([UIScreen mainScreen].bounds.size.width - 24) - 3 * (3 - 1)) / 3;
//    }
//    return _photoViewHeight;
//}
- (NSMutableArray *)endCameraList {
    if (!_endCameraList) {
        _endCameraList = [NSMutableArray array];
    }
    return _endCameraList;
}
- (NSMutableArray *)endCameraPhotos {
    if (!_endCameraPhotos) {
        _endCameraPhotos = [NSMutableArray array];
    }
    return _endCameraPhotos;
}
- (NSMutableArray *)endCameraVideos {
    if (!_endCameraVideos) {
        _endCameraVideos = [NSMutableArray array];
    }
    return _endCameraVideos;
}
- (NSMutableArray *)endSelectedCameraList {
    if (!_endSelectedCameraList) {
        _endSelectedCameraList = [NSMutableArray array];
    }
    return _endSelectedCameraList;
}
- (NSMutableArray *)endSelectedCameraPhotos {
    if (!_endSelectedCameraPhotos) {
        _endSelectedCameraPhotos = [NSMutableArray array];
    }
    return _endSelectedCameraPhotos;
}
- (NSMutableArray *)endSelectedCameraVideos {
    if (!_endSelectedCameraVideos) {
        _endSelectedCameraVideos = [NSMutableArray array];
    }
    return _endSelectedCameraVideos;
}
- (NSMutableArray *)endSelectedList {
    if (!_endSelectedList) {
        _endSelectedList = [NSMutableArray array];
    }
    return _endSelectedList;
}
- (NSMutableArray *)endSelectedPhotos {
    if (!_endSelectedPhotos) {
        _endSelectedPhotos = [NSMutableArray array];
    }
    return _endSelectedPhotos;
}
- (NSMutableArray *)endSelectedVideos {
    if (!_endSelectedVideos) {
        _endSelectedVideos = [NSMutableArray array];
    }
    return _endSelectedVideos;
}
- (NSMutableArray *)iCloudUploadArray {
    if (!_iCloudUploadArray) {
        _iCloudUploadArray = [NSMutableArray array];
    }
    return _iCloudUploadArray;
} 
@end
