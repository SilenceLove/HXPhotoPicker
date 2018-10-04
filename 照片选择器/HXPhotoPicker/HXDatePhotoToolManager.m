//
//  HXDatePhotoToolsManager.m
//  照片选择器
//
//  Created by 洪欣 on 2017/11/2.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoToolManager.h"
#import "UIImage+HXExtension.h"
#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIImageView+WebCache.h>
#elif __has_include("UIImageView+WebCache.h")
#import "UIImageView+WebCache.h"
#endif

#if __has_include(<YYWebImage/YYWebImage.h>)
#import <YYWebImage/YYWebImage.h>
#elif __has_include("YYWebImage.h")
#import "YYWebImage.h"
#endif

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

@property (strong, nonatomic) NSMutableArray *downloadTokenArray;


@property (copy, nonatomic) HXDatePhotoToolManagerGetImageListSuccessHandler imageSuccessHandler;
@property (copy, nonatomic) HXDatePhotoToolManagerGetImageListFailedHandler imageFailedHandler;
@property (assign, nonatomic) BOOL gettingImage;
@property (assign, nonatomic) BOOL cancelGetImage;
@property (assign, nonatomic) PHImageRequestID currentImageRequestID;
@property (strong, nonatomic) NSMutableArray *allImageModelArray;
@property (strong, nonatomic) NSMutableArray *waitImageModelArray;
@property (strong, nonatomic) NSMutableArray *currentImageModelArray;
@property (strong, nonatomic) NSMutableArray *imageArray;
@property (assign, nonatomic) HXDatePhotoToolManagerRequestType requestType;


@property (copy, nonatomic) HXDatePhotoToolManagerGetImageDataListSuccessHandler imageDataSuccessHandler;
@property (copy, nonatomic) HXDatePhotoToolManagerGetImageDataListFailedHandler imageDataFailedHandler;
@property (assign, nonatomic) BOOL gettingImageData;
@property (assign, nonatomic) BOOL cancelGetImageData;
@property (assign, nonatomic) PHImageRequestID currentImageDataRequestID;
@property (strong, nonatomic) NSMutableArray *allImageDataModelArray;
@property (strong, nonatomic) NSMutableArray *waitImageDataModelArray;
@property (strong, nonatomic) NSMutableArray *currentImageDataModelArray;
@property (strong, nonatomic) NSMutableArray *imageDataArray;
@end

@implementation HXDatePhotoToolManager
- (instancetype)init {
    if (self = [super init]) {
        self.requestType = HXDatePhotoToolManagerRequestTypeHD;
    }
    return self;
}

- (void)writeSelectModelListToTempPathWithList:(NSArray<HXPhotoModel *> *)modelList requestType:(HXDatePhotoToolManagerRequestType)requestType success:(HXDatePhotoToolManagerSuccessHandler)success failed:(HXDatePhotoToolManagerFailedHandler)failed {
    if (self.writing) {
        if (HXShowLog) NSSLog(@"已有写入任务,请等待");
        return;
    }
    self.requestType = requestType;
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

- (void)gifModelAssignmentData:(NSArray<HXPhotoModel *> *)gifModelArray success:(void (^)(void))success failed:(void (^)(void))failed {
    __block NSInteger count = 0;
    __block NSInteger modelCount = gifModelArray.count;
    for (HXPhotoModel *model in gifModelArray) {
        [HXPhotoTools getImageDataWithModel:model startRequestIcloud:^(HXPhotoModel *model, PHImageRequestID cloudRequestId) {
            
        } progressHandler:^(HXPhotoModel *model, double progress) {
            
        } completion:^(HXPhotoModel *model, NSData *imageData, UIImageOrientation orientation) {
            model.gifImageData = imageData;
            count++;
            if (count == modelCount) {
                if (success) {
                    success();
                }
            }
        } failed:^(HXPhotoModel *model, NSDictionary *info) {
            if (failed) {
                failed();
            }
        }];
    }
}

- (void)writeSelectModelListToTempPathWithList:(NSArray<HXPhotoModel *> *)modelList success:(HXDatePhotoToolManagerSuccessHandler)success failed:(HXDatePhotoToolManagerFailedHandler)failed {
    if (self.writing) {
        if (HXShowLog) NSSLog(@"已有写入任务,请等待");
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
        if (HXShowLog) NSSLog(@"全部压缩成功");
        dispatch_async(dispatch_get_main_queue(), ^{
            self.writing = NO;
            if (self.successHandler) {
                self.successHandler(self.allURL, self.photoURL, self.videoURL);
            }
        });
        return;
    }
    self.writeArray = [NSMutableArray arrayWithObjects:self.waitArray.lastObject, nil];
    [self.waitArray removeLastObject];
    HXPhotoModel *model = self.writeArray.firstObject;
    __weak typeof(self) weakSelf = self;
    if (model.type == HXPhotoModelMediaTypeVideo) {
        NSString *presetName;
        if (self.requestType == HXDatePhotoToolManagerRequestTypeOriginal) {
            presetName = AVAssetExportPresetHighestQuality;
        }else {
            presetName = AVAssetExportPresetMediumQuality;
        }
        if (model.asset) {
            [HXPhotoTools getExportSessionWithPHAsset:model.asset deliveryMode:PHVideoRequestOptionsDeliveryModeAutomatic presetName:presetName startRequestIcloud:^(PHImageRequestID cloudRequestId) {
                
            } progressHandler:^(double progress) {
                
            } completion:^(AVAssetExportSession *exportSession, NSDictionary *info) {
                NSString *fileName = [[weakSelf uploadFileName] stringByAppendingString:@".mp4"];
                NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                NSURL *videoURL = [NSURL fileURLWithPath:fullPathToFile];
                exportSession.outputURL = videoURL;
                exportSession.outputFileType = AVFileTypeMPEG4;
                exportSession.shouldOptimizeForNetworkUse = YES;
                
                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                            [weakSelf.allArray removeObject:weakSelf.writeArray.firstObject];
                            [weakSelf.allURL addObject:videoURL];
                            [weakSelf.videoURL addObject:videoURL];
                            [weakSelf writeModelToTempPath];
                        }else if ([exportSession status] == AVAssetExportSessionStatusFailed){
                            if (weakSelf.failedHandler) {
                                weakSelf.failedHandler();
                            }
                            [weakSelf cleanWriteList];
                        }else if ([exportSession status] == AVAssetExportSessionStatusCancelled) {
                            if (weakSelf.failedHandler) {
                                weakSelf.failedHandler();
                            }
                            [weakSelf cleanWriteList];
                        }
                    });
                }];
            } failed:^(NSDictionary *info) {
                if (weakSelf.failedHandler) {
                    weakSelf.failedHandler();
                }
                [weakSelf cleanWriteList];
            }];
        }else {
            [self compressedVideoWithMediumQualityWriteToTemp:model.fileURL progress:^(float progress) {
                
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

        }
        /*
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
         */
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        
        [self.allArray removeObject:weakSelf.writeArray.firstObject];
        [self.allURL addObject:model.videoURL];
        [self.videoURL addObject:model.videoURL];
        [self writeModelToTempPath];
//        [self compressedVideoWithMediumQualityWriteToTemp:model.videoURL progress:^(float progress) {
//
//        } success:^(NSURL *url) {
//            [weakSelf.allArray removeObject:weakSelf.writeArray.firstObject];
//            [weakSelf.allURL addObject:url];
//            [weakSelf.videoURL addObject:url];
//            [weakSelf writeModelToTempPath];
//        } failure:^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (weakSelf.failedHandler) {
//                    weakSelf.failedHandler();
//                }
//                [weakSelf cleanWriteList];
//            });
//        }];
    }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (model.networkPhotoUrl) {
            // 为网络图片时,直接使用图片地址
            [self.allArray removeObject:weakSelf.writeArray.firstObject];
            [self.allURL addObject:model.networkPhotoUrl];
            [self.photoURL addObject:model.networkPhotoUrl];
            [self writeModelToTempPath];
            return;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CGFloat scale;
            if (self.requestType == HXDatePhotoToolManagerRequestTypeHD) {
                scale = 0.7f;
            }else {
                scale = 1.0f;
            }
            NSData *imageData = UIImageJPEGRepresentation(model.thumbPhoto, scale);
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
        if (model.asset) {
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
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *fileName = [[self uploadFileName] stringByAppendingString:[NSString stringWithFormat:@".gif"]];
                
                NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                
                if ([model.gifImageData writeToFile:fullPathToFile atomically:YES]) {
                    [self.allArray removeObject:self.writeArray.firstObject];
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
        }
    }else {
        if (model.asset) {
            CGSize size = CGSizeZero;
            if (self.requestType == HXDatePhotoToolManagerRequestTypeHD) {
                CGFloat width = [UIScreen mainScreen].bounds.size.width;
                CGFloat height = [UIScreen mainScreen].bounds.size.height;
                CGFloat imgWidth = model.imageSize.width;
                CGFloat imgHeight = model.imageSize.height;
                if (imgHeight > imgWidth / 9 * 17) {
                    size = CGSizeMake(width, height);
                }else {
                    size = CGSizeMake(model.endImageSize.width * 1.5, model.endImageSize.height * 1.5);
                }
            }else {
                size = PHImageManagerMaximumSize;
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
                    
//                    NSString *UTI = [model.asset valueForKey:@"uniformTypeIdentifier"];
//                    BOOL isHEIF = NO;
//                    isHEIF = [UTI isEqualToString:@"public.heif"] || [UTI isEqualToString:@"public.heic"];
//                    if (isHEIF) {
//
//                    }
                    
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
        }else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                CGFloat scale;
                if (self.requestType == HXDatePhotoToolManagerRequestTypeHD) {
                    scale = 0.7f;
                }else {
                    scale = 1.0f;
                }
                NSData *imageData = UIImageJPEGRepresentation(model.thumbPhoto, scale);
                NSString *fileName = [[self uploadFileName] stringByAppendingString:[NSString stringWithFormat:@".jpeg"]];
                
                NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                
                if ([imageData writeToFile:fullPathToFile atomically:YES]) {
                    [self.allArray removeObject:self.writeArray.firstObject];
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
        }
    }
}

- (AVAssetExportSession *)compressedVideoWithMediumQualityWriteToTemp:(id)obj progress:(void (^)(float progress))progress success:(void (^)(NSURL *url))success failure:(void (^)(void))failure {
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
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
    NSString *uuidStr = [[uuidString stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
    NSString *name = [NSString stringWithFormat:@"%@",uuidStr];
    
    NSString *fileName = @"";
    NSDate *nowDate = [NSDate date];
    NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
    NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
    fileName = [fileName stringByAppendingString:@"hx"];
    fileName = [fileName stringByAppendingString:dateStr];
    fileName = [fileName stringByAppendingString:numStr];
    
    return [NSString stringWithFormat:@"%@%@",name,fileName];
}
- (void)getSelectedImageDataList:(NSArray<HXPhotoModel *> *)modelList success:(HXDatePhotoToolManagerGetImageDataListSuccessHandler)success failed:(HXDatePhotoToolManagerGetImageDataListFailedHandler)failed {
    if (self.gettingImageData) {
        if (HXShowLog) NSSLog(@"已有任务,请等待");
        return;
    }
    [self cancelGetImageList];
    
    self.cancelGetImageData = NO;
    self.gettingImageData = YES;
    self.imageDataSuccessHandler = success;
    self.imageDataFailedHandler = failed;
    
    [self.imageDataArray removeAllObjects];
    [self.currentImageDataModelArray removeAllObjects];
    
    self.allImageDataModelArray = [NSMutableArray array];
    for (HXPhotoModel *model in modelList) {
        [self.allImageDataModelArray insertObject:model atIndex:0];
    }
    self.waitImageDataModelArray = [NSMutableArray arrayWithArray:self.allImageDataModelArray];
    [self getCurrentModelImageData];
}
- (void)getCurrentModelImageData {
    if (self.cancelGetImageData) {
        self.cancelGetImageData = NO;
        self.gettingImageData = NO;
        [self.downloadTokenArray removeAllObjects];
        if (HXShowLog) NSSLog(@"取消了");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.imageDataFailedHandler) {
                self.imageDataFailedHandler();
            }
        });
        return;
    }
    if (self.waitImageDataModelArray.count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.downloadTokenArray removeAllObjects];
            self.gettingImageData = NO;
            self.cancelGetImageData = NO;
            if (self.imageDataSuccessHandler) {
                self.imageDataSuccessHandler(self.imageDataArray);
            }
        });
        return;
    }
    self.currentImageDataModelArray = [NSMutableArray arrayWithObjects:self.waitImageDataModelArray.lastObject, nil];
    [self.waitImageDataModelArray removeLastObject];
    HXPhotoModel *model = self.currentImageDataModelArray.firstObject;
    if (model.asset) {
        __weak typeof(self) weakSelf = self;
        self.currentImageDataRequestID = [HXPhotoTools getImageData:model.asset startRequestIcloud:^(PHImageRequestID cloudRequestId) {
            weakSelf.currentImageDataRequestID = cloudRequestId;
        } progressHandler:^(double progress) {
            
        } completion:^(NSData *imageData, UIImageOrientation orientation) {
            [weakSelf.imageDataArray addObject:imageData];
            [weakSelf.allImageDataModelArray removeObject:weakSelf.currentImageDataModelArray.firstObject];
            [weakSelf getCurrentModelImageData];
        } failed:^(NSDictionary *info) {
            if ([[info objectForKey:PHImageCancelledKey] boolValue]) {
                weakSelf.gettingImageData = NO;
                weakSelf.cancelGetImageData = NO;
                if (HXShowLog) NSSLog(@"取消了请求了");
                if (weakSelf.imageDataFailedHandler) {
                    weakSelf.imageDataFailedHandler();
                }
                return;
            }
            HXPhotoModel *model = weakSelf.currentImageDataModelArray.firstObject;
            if (model.gifImageData) {
                [weakSelf.imageDataArray addObject:model.gifImageData];
                [weakSelf.allImageDataModelArray removeObject:weakSelf.currentImageDataModelArray.firstObject];
                [weakSelf getCurrentModelImageData];
            }else {
                weakSelf.gettingImageData = NO;
                if (weakSelf.imageDataFailedHandler) {
                    weakSelf.imageDataFailedHandler();
                }
            }
        }];
    }else {
        if (model.networkPhotoUrl) {
            __weak typeof(self) weakSelf = self;
            if (model.downloadError) {
#if __has_include(<SDWebImage/UIImageView+WebCache.h>) || __has_include("UIImageView+WebCache.h")
                SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:model.networkPhotoUrl options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                    if (!error && data) {
                        model.thumbPhoto = image;
                        model.previewPhoto = image;
                        model.gifImageData = data;
                        [weakSelf.imageDataArray addObject:data];
                        [weakSelf.allImageDataModelArray removeObject:weakSelf.currentImageDataModelArray.firstObject];
                        [weakSelf getCurrentModelImageData];
                    }else {
                        [weakSelf.downloadTokenArray removeAllObjects];
                        weakSelf.gettingImageData = NO;
                        if (weakSelf.imageDataFailedHandler) {
                            weakSelf.imageDataFailedHandler();
                        }
                    }
                }];
                [self.downloadTokenArray addObject:token];
#endif
                return;
            }
            if (!model.downloadComplete) {
#if __has_include(<SDWebImage/UIImageView+WebCache.h>) || __has_include("UIImageView+WebCache.h")
                SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:model.networkPhotoUrl options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                    if (!error && image) {
                        model.thumbPhoto = image;
                        model.previewPhoto = image;
                        model.gifImageData = data;
                        [weakSelf.imageDataArray addObject:data];
                        [weakSelf.allImageDataModelArray removeObject:weakSelf.currentImageDataModelArray.firstObject];
                        [weakSelf getCurrentModelImageData];
                    }else {
                        [weakSelf.downloadTokenArray removeAllObjects];
                        weakSelf.gettingImageData = NO;
                        if (weakSelf.imageDataFailedHandler) {
                            weakSelf.imageDataFailedHandler();
                        }
                    }
                }];
                [self.downloadTokenArray addObject:token];
#endif
                return;
            }
        }
        if (model.gifImageData) {
            [self.imageDataArray addObject:model.gifImageData];
            [self.allImageDataModelArray removeObject:self.currentImageDataModelArray.firstObject];
            [self getCurrentModelImageData];
        }else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ 
                NSData *imageData = UIImageJPEGRepresentation(model.thumbPhoto, 1.0f);
                model.gifImageData = imageData;
                [self.imageDataArray addObject:imageData];
                [self.allImageDataModelArray removeObject:self.currentImageDataModelArray.firstObject];
                [self getCurrentModelImageData];
            });
        }
    }
}

- (void)getSelectedImageList:(NSArray<HXPhotoModel *> *)modelList requestType:(HXDatePhotoToolManagerRequestType)requestType success:(HXDatePhotoToolManagerGetImageListSuccessHandler)success failed:(HXDatePhotoToolManagerGetImageListFailedHandler)failed {
    if (self.gettingImage) {
        if (HXShowLog) NSSLog(@"已有任务,请等待");
        return;
    }
    [self cancelGetImageDataList];
    self.requestType = requestType;
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
- (void)getSelectedImageList:(NSArray<HXPhotoModel *> *)modelList success:(HXDatePhotoToolManagerGetImageListSuccessHandler)success failed:(HXDatePhotoToolManagerGetImageListFailedHandler)failed {
    if (self.gettingImage) {
        if (HXShowLog) NSSLog(@"已有任务,请等待");
        return;
    }
    [self cancelGetImageDataList];
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
        [self.downloadTokenArray removeAllObjects];
        if (HXShowLog) NSSLog(@"取消了");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.imageFailedHandler) {
                self.imageFailedHandler();
            }
        });
        return;
    }
    if (self.waitImageModelArray.count == 0) { 
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.downloadTokenArray removeAllObjects];
            self.gettingImage = NO;
            self.cancelGetImage = NO;
            if (self.imageSuccessHandler) {
                self.imageSuccessHandler(self.imageArray);
            }
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
        if (self.requestType == HXDatePhotoToolManagerRequestTypeHD) { 
            if (imgHeight > imgWidth / 9 * 17) {
                size = [UIScreen mainScreen].bounds.size;
            }else {
                size = CGSizeMake(model.endImageSize.width * 2.0, model.endImageSize.height * 2.0);
            }
        }else {
            size = PHImageManagerMaximumSize;
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
                weakSelf.gettingImage = NO;
                weakSelf.cancelGetImage = NO;
                if (HXShowLog) NSSLog(@"取消了请求了");
                if (weakSelf.imageFailedHandler) {
                    weakSelf.imageFailedHandler();
                }
                return;
            }
            HXPhotoModel *model = weakSelf.currentImageModelArray.firstObject;
            if (model.thumbPhoto) {
                [weakSelf.imageArray addObject:model.thumbPhoto];
                [weakSelf.allImageModelArray removeObject:weakSelf.currentImageModelArray.firstObject];
                [weakSelf getCurrentModelImage];
            }else {
                weakSelf.gettingImage = NO;
                if (weakSelf.imageFailedHandler) {
                    weakSelf.imageFailedHandler();
                }
            }
        }];
    }else {
        if (model.networkPhotoUrl) {
            __weak typeof(self) weakSelf = self;
            if (model.downloadError) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                YYWebImageOperation *operation = [[YYWebImageManager sharedManager] requestImageWithURL:model.networkPhotoUrl options:0 progress:nil transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
                    if (!error && image) {
                        model.thumbPhoto = image;
                        model.previewPhoto = image;
                        [weakSelf.imageArray addObject:model.thumbPhoto];
                        [weakSelf.allImageModelArray removeObject:weakSelf.currentImageModelArray.firstObject];
                        [weakSelf getCurrentModelImage];
                    }else {
                        [weakSelf.downloadTokenArray removeAllObjects];
                        weakSelf.gettingImage = NO;
                        if (weakSelf.imageFailedHandler) {
                            weakSelf.imageFailedHandler();
                        }
                    }
                }];
                [self.downloadTokenArray addObject:operation];
#elif __has_include(<SDWebImage/UIImageView+WebCache.h>) || __has_include("UIImageView+WebCache.h")
                SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:model.networkPhotoUrl options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                    if (!error && image) {
                        model.thumbPhoto = image;
                        model.previewPhoto = image;
                        [weakSelf.imageArray addObject:model.thumbPhoto];
                        [weakSelf.allImageModelArray removeObject:weakSelf.currentImageModelArray.firstObject];
                        [weakSelf getCurrentModelImage];
                    }else {
                        [weakSelf.downloadTokenArray removeAllObjects];
                        weakSelf.gettingImage = NO;
                        if (weakSelf.imageFailedHandler) {
                            weakSelf.imageFailedHandler();
                        }
                    }
                }];
                [self.downloadTokenArray addObject:token];
#endif
                return;
            }
            if (!model.downloadComplete) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                YYWebImageOperation *operation = [[YYWebImageManager sharedManager] requestImageWithURL:model.networkPhotoUrl options:0 progress:nil transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
                    if (!error && image) {
                        model.thumbPhoto = image;
                        model.previewPhoto = image;
                        [weakSelf.imageArray addObject:model.thumbPhoto];
                        [weakSelf.allImageModelArray removeObject:weakSelf.currentImageModelArray.firstObject];
                        [weakSelf getCurrentModelImage];
                    }else {
                        [weakSelf.downloadTokenArray removeAllObjects];
                        weakSelf.gettingImage = NO;
                        if (weakSelf.imageFailedHandler) {
                            weakSelf.imageFailedHandler();
                        }
                    }
                }];
                [self.downloadTokenArray addObject:operation];
#elif __has_include(<SDWebImage/UIImageView+WebCache.h>) || __has_include("UIImageView+WebCache.h")
                SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:model.networkPhotoUrl options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                    if (!error && image) {
                        model.thumbPhoto = image;
                        model.previewPhoto = image;
                        [weakSelf.imageArray addObject:model.thumbPhoto];
                        [weakSelf.allImageModelArray removeObject:weakSelf.currentImageModelArray.firstObject];
                        [weakSelf getCurrentModelImage];
                    }else {
                        [weakSelf.downloadTokenArray removeAllObjects];
                        weakSelf.gettingImage = NO;
                        if (weakSelf.imageFailedHandler) {
                            weakSelf.imageFailedHandler();
                        }
                    }
                }];
                [self.downloadTokenArray addObject:token];
#endif
                return;
            }
            [self.imageArray addObject:model.thumbPhoto];
            [self.allImageModelArray removeObject:self.currentImageModelArray.firstObject];
            [self getCurrentModelImage];
        }else {
            [self.imageArray addObject:model.thumbPhoto];
            [self.allImageModelArray removeObject:self.currentImageModelArray.firstObject];
            [self getCurrentModelImage];
        }
    }
}
- (void)cancelGetImageList {
    self.cancelGetImage = YES;
    for (id obj in self.downloadTokenArray) {
        if ([obj isKindOfClass:NSClassFromString(@"SDWebImageDownloadToken")]) {
#if __has_include(<SDWebImage/UIImageView+WebCache.h>) || __has_include("UIImageView+WebCache.h")
            [[SDWebImageDownloader sharedDownloader] cancel:obj];
#endif
        }else if ([obj isKindOfClass:NSClassFromString(@"YYWebImageOperation")]) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            [(YYWebImageOperation *)obj cancel];
#endif
        }
    }
    [self.downloadTokenArray removeAllObjects];
    if (self.currentImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.currentImageRequestID];
        self.currentImageRequestID = 0;
    }
}
- (void)cancelGetImageDataList {
    self.cancelGetImageData = YES;
    for (id obj in self.downloadTokenArray) {
        if ([obj isKindOfClass:NSClassFromString(@"SDWebImageDownloadToken")]) {
#if __has_include(<SDWebImage/UIImageView+WebCache.h>) || __has_include("UIImageView+WebCache.h")
            [[SDWebImageDownloader sharedDownloader] cancel:obj];
#endif
        }else if ([obj isKindOfClass:NSClassFromString(@"YYWebImageOperation")]) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            [(YYWebImageOperation *)obj cancel];
#endif
        }
    }
    [self.downloadTokenArray removeAllObjects];
    if (self.currentImageDataRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.currentImageDataRequestID];
        self.currentImageDataRequestID = 0;
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
- (NSMutableArray *)downloadTokenArray {
    if (!_downloadTokenArray) {
        _downloadTokenArray = [NSMutableArray array];
    }
    return _downloadTokenArray;
}
- (NSMutableArray *)allImageDataModelArray {
    if (!_allImageDataModelArray) {
        _allImageDataModelArray = [NSMutableArray array];
    }
    return _allImageDataModelArray;
}
- (NSMutableArray *)waitImageDataModelArray {
    if (!_waitImageDataModelArray) {
        _waitImageDataModelArray = [NSMutableArray array];
    }
    return _waitImageDataModelArray;
}
- (NSMutableArray *)currentImageDataModelArray {
    if (!_currentImageDataModelArray) {
        _currentImageDataModelArray = [NSMutableArray array];
    }
    return _currentImageDataModelArray;
}
- (NSMutableArray *)imageDataArray {
    if (!_imageDataArray) {
        _imageDataArray = [NSMutableArray array];
    }
    return _imageDataArray;
}

- (void)dealloc {
    if (HXShowLog) NSSLog(@"dealloc");
}
@end
