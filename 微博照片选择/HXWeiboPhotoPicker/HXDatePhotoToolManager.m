//
//  HXDatePhotoToolsManager.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/11/2.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoToolManager.h"
#import "UIImage+HXExtension.h"

@interface HXDatePhotoToolManager ()
@property (copy, nonatomic) HXDatePhotoToolManagerSuccessHandler successHandler;
@property (copy, nonatomic) HXDatePhotoToolManagerFailedHandler failedHandler;

@property (assign, nonatomic) BOOL writing;
@property (strong, nonatomic) NSMutableArray *allURL;
@property (strong, nonatomic) NSMutableArray *photoURL;
@property (strong, nonatomic) NSMutableArray *videoURL;
@property (strong, nonatomic) NSMutableArray *writeArray;
@property (strong, nonatomic) NSMutableArray *waitArray;
@property (strong, nonatomic) NSMutableArray *allArray;


@property (copy, nonatomic) HXDatePhotoToolManagerGetImageListSuccessHandler imageSuccessHandler;
@property (copy, nonatomic) HXDatePhotoToolManagerGetImageListFailedHandler imageFailedHandler;
@property (assign, nonatomic) BOOL gettingImage;
@property (assign, nonatomic) BOOL cancelGetImage;
@property (assign, nonatomic) PHImageRequestID currentImageRequestID;
@property (strong, nonatomic) NSMutableArray *allImageModelArray;
@property (strong, nonatomic) NSMutableArray *waitImageModelArray;
@property (strong, nonatomic) NSMutableArray *currentImageModelArray;
@property (strong, nonatomic) NSMutableArray *imageArray;
@end

@implementation HXDatePhotoToolManager


- (void)writeSelectModelListToTempPathWithList:(NSArray<HXPhotoModel *> *)modelList success:(HXDatePhotoToolManagerSuccessHandler)success failed:(HXDatePhotoToolManagerFailedHandler)failed {
    if (self.writing) {
        NSSLog(@"已有写入任务,请等待");
        return;
    }
    self.writing = YES;
    self.successHandler = success;
    self.failedHandler = failed;
    
    [self.allURL removeAllObjects];
    [self.photoURL removeAllObjects];
    [self.videoURL removeAllObjects];
    
    self.allArray = [NSMutableArray array];
    for (HXPhotoModel *model in modelList) {
        [self.allArray insertObject:model atIndex:0];
    }
    self.waitArray = [NSMutableArray arrayWithArray:self.allArray];
    [self writeModelToTempPath];
}
- (void)cleanWriteList {
    self.writing = NO;
    self.successHandler = nil;
    self.failedHandler = nil;
    
    [self.allURL removeAllObjects];
    [self.photoURL removeAllObjects];
    [self.videoURL removeAllObjects];
    [self.allArray removeAllObjects];
}
- (void)writeModelToTempPath {
    if (self.waitArray.count == 0) {
        NSSLog(@"全部压缩成功");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.successHandler) {
                self.successHandler(self.allURL, self.photoURL, self.videoURL);
            }
            self.writing = NO;
        });
        return;
    }
    self.writeArray = [NSMutableArray arrayWithObjects:self.waitArray.lastObject, nil];
    [self.waitArray removeLastObject];
    HXPhotoModel *model = self.writeArray.firstObject;
    __weak typeof(self) weakSelf = self;
    if (model.type == HXPhotoModelMediaTypeVideo) {
        [HXPhotoTools getAVAssetWithPHAsset:model.asset startRequestIcloud:^(PHImageRequestID cloudRequestId) {
            
        } progressHandler:^(double progress) {
            
        } completion:^(AVAsset *asset) {
            [weakSelf compressedVideoWithMediumQualityWriteToTemp:asset progress:^(float progress) {
                
            } success:^(NSURL *url) {
                [weakSelf.allArray removeObject:weakSelf.writeArray.firstObject];
                [weakSelf.allURL addObject:url];
                [weakSelf.videoURL addObject:url];
                [weakSelf writeModelToTempPath];
            } failure:^{
                if (weakSelf.failedHandler) {
                    weakSelf.failedHandler();
                }
                [weakSelf cleanWriteList];
            }];
        } failed:^(NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.failedHandler) {
                    weakSelf.failedHandler();
                }
                [weakSelf cleanWriteList];
            });
        }];
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self compressedVideoWithMediumQualityWriteToTemp:model.videoURL progress:^(float progress) {
            
        } success:^(NSURL *url) {
            [weakSelf.allArray removeObject:weakSelf.writeArray.firstObject];
            [weakSelf.allURL addObject:url];
            [weakSelf.videoURL addObject:url];
            [weakSelf writeModelToTempPath];
        } failure:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.failedHandler) {
                    weakSelf.failedHandler();
                }
                [weakSelf cleanWriteList];
            });
        }];
    }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData = UIImageJPEGRepresentation(model.thumbPhoto, 0.8);
            NSString *fileName = [[self uploadFileName] stringByAppendingString:[NSString stringWithFormat:@".jpeg"]];
            
            NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
            
            if ([imageData writeToFile:fullPathToFile atomically:YES]) {
                [self.allArray removeObject:weakSelf.writeArray.firstObject];
                [self.allURL addObject:[NSURL fileURLWithPath:fullPathToFile]];
                [self.photoURL addObject:[NSURL fileURLWithPath:fullPathToFile]];
                [self writeModelToTempPath];
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.failedHandler) {
                        self.failedHandler();
                    }
                    [self cleanWriteList];
                });
            }
        });
    }else if (model.type == HXPhotoModelMediaTypePhotoGif) {
        [HXPhotoTools getImageData:model.asset startRequestIcloud:^(PHImageRequestID cloudRequestId) {
            
        } progressHandler:^(double progress) {
            
        } completion:^(NSData *imageData, UIImageOrientation orientation) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *fileName = [[weakSelf uploadFileName] stringByAppendingString:[NSString stringWithFormat:@".gif"]];
                
                NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                
                if ([imageData writeToFile:fullPathToFile atomically:YES]) {
                    [weakSelf.allArray removeObject:weakSelf.writeArray.firstObject];
                    [weakSelf.allURL addObject:[NSURL fileURLWithPath:fullPathToFile]];
                    [weakSelf.photoURL addObject:[NSURL fileURLWithPath:fullPathToFile]];
                    [weakSelf writeModelToTempPath];
                }else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakSelf.failedHandler) {
                            weakSelf.failedHandler();
                        }
                        [weakSelf cleanWriteList];
                    });
                }
            });
        } failed:^(NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.failedHandler) {
                    weakSelf.failedHandler();
                    [weakSelf cleanWriteList];
                }
            });
        }];
    }else {
        CGSize size = CGSizeZero;
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.height;
        CGFloat imgWidth = model.imageSize.width;
        CGFloat imgHeight = model.imageSize.height; 
        if (imgHeight > imgWidth / 9 * 17) {
            size = CGSizeMake(width, height);
        }else {
            size = CGSizeMake(model.endImageSize.width * 1.5, model.endImageSize.height * 1.5);
        }
        [HXPhotoTools getHighQualityFormatPhoto:model.asset size:size startRequestIcloud:^(PHImageRequestID cloudRequestId) {
            
        } progressHandler:^(double progress) {
            
        } completion:^(UIImage *image) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *tempImage = image;
                if (tempImage.imageOrientation != UIImageOrientationUp) {
                    tempImage = [tempImage normalizedImage];
                }
                NSData *imageData;
                NSString *suffix;
                if (UIImagePNGRepresentation(tempImage)) {
                    //返回为png图像。
                    imageData = UIImagePNGRepresentation(tempImage);
                    suffix = @"png";
                }else {
                    //返回为JPEG图像。
                    imageData = UIImageJPEGRepresentation(tempImage, 0.8);
                    suffix = @"jpeg";
                }
                
                NSString *fileName = [[weakSelf uploadFileName] stringByAppendingString:[NSString stringWithFormat:@".%@",suffix]];
                
                NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                
                if ([imageData writeToFile:fullPathToFile atomically:YES]) {
                    [weakSelf.allArray removeObject:weakSelf.writeArray.firstObject];
                    [weakSelf.allURL addObject:[NSURL fileURLWithPath:fullPathToFile]];
                    [weakSelf.photoURL addObject:[NSURL fileURLWithPath:fullPathToFile]];
                    [weakSelf writeModelToTempPath];
                }else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakSelf.failedHandler) {
                            weakSelf.failedHandler();
                        }
                        [weakSelf cleanWriteList];
                    });
                }
            });
        } failed:^(NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.failedHandler) {
                    weakSelf.failedHandler();
                }
                [weakSelf cleanWriteList];
            });
        }];
    }
}

- (AVAssetExportSession *)compressedVideoWithMediumQualityWriteToTemp:(id)obj progress:(void (^)(float progress))progress success:(void (^)(NSURL *url))success failure:(void (^)())failure {
    AVAsset *avAsset;
    if ([obj isKindOfClass:[AVAsset class]]) {
        avAsset = obj;
    }else {
        avAsset = [AVURLAsset URLAssetWithURL:obj options:nil];
    }
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        
        NSString *fileName = [[self uploadFileName] stringByAppendingString:@".mp4"];
        NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        NSURL *videoURL = [NSURL fileURLWithPath:fullPathToFile];
        exportSession.outputURL = videoURL;
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                if (success) {
                    success(videoURL);
                }
            }else if ([exportSession status] == AVAssetExportSessionStatusFailed){
                if (failure) {
                    failure();
                }
            }else if ([exportSession status] == AVAssetExportSessionStatusCancelled) {
                if (failure) {
                    failure();
                }
            }
        }];
        return exportSession;
    }else {
        if (failure) {
            failure();
        }
        return nil;
    }
}
- (NSString *)uploadFileName {
    NSString *fileName = @"";
    NSDate *nowDate = [NSDate date];
    NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
    
    NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
    
    fileName = [fileName stringByAppendingString:@"hx"];
    fileName = [fileName stringByAppendingString:dateStr];
    fileName = [fileName stringByAppendingString:numStr];
    return fileName;
}
- (void)getSelectedImageList:(NSArray<HXPhotoModel *> *)modelList success:(HXDatePhotoToolManagerGetImageListSuccessHandler)success failed:(HXDatePhotoToolManagerGetImageListFailedHandler)failed {
    if (self.gettingImage) {
        NSSLog(@"已有任务,请等待");
        return;
    }
    self.cancelGetImage = NO;
    self.gettingImage = YES;
    self.imageSuccessHandler = success;
    self.imageFailedHandler = failed;
    
    [self.imageArray removeAllObjects];
    [self.currentImageModelArray removeAllObjects];
    
    self.allImageModelArray = [NSMutableArray array];
    for (HXPhotoModel *model in modelList) {
        [self.allImageModelArray insertObject:model atIndex:0];
    }
    self.waitImageModelArray = [NSMutableArray arrayWithArray:self.allImageModelArray];
    [self getCurrentModelImage];
}
- (void)getCurrentModelImage {
    if (self.cancelGetImage) {
        self.cancelGetImage = NO;
        self.gettingImage = NO;
        NSSLog(@"取消了");
        if (self.imageFailedHandler) {
            self.imageFailedHandler();
        }
        return;
    }
    if (self.waitImageModelArray.count == 0) { 
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.imageSuccessHandler) {
                self.imageSuccessHandler(self.imageArray);
            }
            self.gettingImage = NO;
            self.cancelGetImage = NO;
        });
        return;
    }
    self.currentImageModelArray = [NSMutableArray arrayWithObjects:self.waitImageModelArray.lastObject, nil];
    [self.waitImageModelArray removeLastObject];
    HXPhotoModel *model = self.currentImageModelArray.firstObject;
    if (model.asset) {
        __weak typeof(self) weakSelf = self;
        CGFloat imgWidth = model.imageSize.width;
        CGFloat imgHeight = model.imageSize.height;
        CGSize size;
        if (imgHeight > imgWidth / 9 * 17) {
            size = [UIScreen mainScreen].bounds.size;
        }else {
            size = CGSizeMake(model.endImageSize.width * 2.0, model.endImageSize.height * 2.0);
        }
        self.currentImageRequestID = [HXPhotoTools getHighQualityFormatPhoto:model.asset size:size startRequestIcloud:^(PHImageRequestID cloudRequestId) {
            weakSelf.currentImageRequestID = cloudRequestId;
        } progressHandler:^(double progress) {
            
        } completion:^(UIImage *image) {
            [weakSelf.imageArray addObject:image];
            [weakSelf.allImageModelArray removeObject:weakSelf.currentImageModelArray.firstObject];
            [weakSelf getCurrentModelImage];
        } failed:^(NSDictionary *info) {
            if ([[info objectForKey:PHImageCancelledKey] boolValue]) {
                if (weakSelf.imageFailedHandler) {
                    weakSelf.imageFailedHandler();
                }
                weakSelf.gettingImage = NO;
                weakSelf.cancelGetImage = NO;
                NSSLog(@"取消了请求了");
                return;
            }
            HXPhotoModel *model = weakSelf.currentImageModelArray.firstObject;
            if (model.thumbPhoto) {
                [weakSelf.imageArray addObject:model.thumbPhoto];
                [weakSelf.allImageModelArray removeObject:weakSelf.currentImageModelArray.firstObject];
                [weakSelf getCurrentModelImage];
            }else {
                if (weakSelf.imageFailedHandler) {
                    weakSelf.imageFailedHandler();
                }
                weakSelf.gettingImage = NO;
            }
        }];
    }else {
        [self.imageArray addObject:model.thumbPhoto];
        [self.allImageModelArray removeObject:self.currentImageModelArray.firstObject];
        [self getCurrentModelImage];
    }
}
- (void)cancelGetImageList {
    self.cancelGetImage = YES;
    if (self.currentImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.currentImageRequestID];
        self.currentImageRequestID = 0;
    }
}
- (NSMutableArray *)allURL {
    if (!_allURL) {
        _allURL = [NSMutableArray array];
    }
    return _allURL;
}
- (NSMutableArray *)photoURL {
    if (!_photoURL) {
        _photoURL = [NSMutableArray array];
    }
    return _photoURL;
}
- (NSMutableArray *)videoURL {
    if (!_videoURL) {
        _videoURL = [NSMutableArray array];
    }
    return _videoURL;
}
- (NSMutableArray *)writeArray {
    if (!_writeArray) {
        _writeArray = [NSMutableArray array];
    }
    return _writeArray;
}
- (NSMutableArray *)waitArray {
    if (!_waitArray) {
        _waitArray = [NSMutableArray array];
    }
    return _waitArray;
}
- (NSMutableArray *)imageArray {
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}
- (NSMutableArray *)currentImageModelArray {
    if (!_currentImageModelArray) {
        _currentImageModelArray = [NSMutableArray array];
    }
    return _currentImageModelArray;
}
- (NSMutableArray *)waitImageModelArray {
    if (!_waitImageModelArray) {
        _waitImageModelArray = [NSMutableArray array];
    }
    return _waitImageModelArray;
}
- (NSMutableArray *)allImageModelArray {
    if (!_allImageModelArray) {
        _allImageModelArray = [NSMutableArray array];
    }
    return _allImageModelArray;
}
@end
