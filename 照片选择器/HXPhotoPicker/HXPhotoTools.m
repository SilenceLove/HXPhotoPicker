//
//  HXPhotoTools.m
//  照片选择器
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoTools.h"
#import "HXPhotoModel.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoManager.h"
#import <sys/utsname.h>
#import "HXDatePhotoToolManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
@implementation HXPhotoTools

+ (CLGeocoder *)getDateLocationDetailInformationWithModel:(HXPhotoDateModel *)model
                                               completion:(void (^)(CLPlacemark * _Nullable placemark, HXPhotoDateModel *model, NSError * _Nullable error))completion {
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init]; 
    [geoCoder reverseGeocodeLocation:model.location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        CLPlacemark *placemark = placemarks.firstObject;
        if (completion) {
            completion(placemark,model, error);
        }
    }];
    return geoCoder;
//    NSMutableArray *placemarkArray = [NSMutableArray array];
//    NSInteger locationCount = 0;
//    for (HXPhotoModel *subModel in model.photoModelArray) {
//        if (subModel.asset.location) {
//            [geoCoder reverseGeocodeLocation:subModel.asset.location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
//                if (placemarks.count > 0 && !error) {
//                    CLPlacemark *placemark = placemarks.firstObject;
//                    [placemarkArray addObject:placemark];
//                    if (placemark) {
//                        <#statements#>
//                    }
//                }
//            }];
//            locationCount++;
//        }
//    }
}

/**
 获取视频的时长
 */  
+ (NSString *)transformVideoTimeToString:(NSTimeInterval)duration {
    NSInteger time = roundf(duration);
    NSString *newTime;
    if (time < 10) {
        newTime = [NSString stringWithFormat:@"00:0%zd",time];
    } else if (time < 60) {
        newTime = [NSString stringWithFormat:@"00:%zd",time];
    } else {
        NSInteger min = roundf(time / 60);
        NSInteger sec = time - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}

+ (BOOL)assetIsHEIF:(PHAsset *)asset {
    if (!asset) return NO;
    __block BOOL isHEIF = NO;
    if (HX_IOS9Later) {
        NSArray *resourceList = [PHAssetResource assetResourcesForAsset:asset];
        [resourceList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            PHAssetResource *resource = obj;
            NSString *UTI = resource.uniformTypeIdentifier;
            if ([UTI isEqualToString:@"public.heif"] || [UTI isEqualToString:@"public.heic"]) {
                isHEIF = YES;
                *stop = YES;
            }
        }];
    } else {
        NSString *UTI = [asset valueForKey:@"uniformTypeIdentifier"];
        isHEIF = [UTI isEqualToString:@"public.heif"] || [UTI isEqualToString:@"public.heic"];
    }
    return isHEIF;
}
+ (void)FetchPhotosBytes:(NSArray *)photos completion:(void (^)(NSString *))completion
{
    __block NSInteger dataLength = 0;
    __block NSInteger assetCount = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0 ; i < photos.count ; i++) {
            HXPhotoModel *model = photos[i];
            if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                NSData *imageData;
                if (UIImagePNGRepresentation(model.thumbPhoto)) {
                    //返回为png图像。
                    imageData = UIImagePNGRepresentation(model.thumbPhoto);
                }else {
                    //返回为JPEG图像。
                    imageData = UIImageJPEGRepresentation(model.thumbPhoto, 1.0);
                }
                dataLength += imageData.length;
                assetCount ++;
                if (assetCount >= photos.count) {
                    NSString *bytes = [self getBytesFromDataLength:dataLength];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) completion(bytes);
                    });
                }
            }else {
                [model requestImageDataStartRequestICloud:nil progressHandler:nil success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
                    dataLength += imageData.length;
                    assetCount ++;
                    if (assetCount >= photos.count) {
                        NSString *bytes = [self getBytesFromDataLength:dataLength];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) completion(bytes);
                        });
                    }
                } failed:^(NSDictionary *info, HXPhotoModel *model) {
                    dataLength += 0;
                    assetCount ++;
                    if (assetCount >= photos.count) {
                        NSString *bytes = [self getBytesFromDataLength:dataLength];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) completion(bytes);
                        });
                    }
                }];
            }
        }
    });
} 
 

+ (void)requestAuthorization:(UIViewController *)viewController
                        handler:(void (^)(PHAuthorizationStatus status))handler {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        if (handler) handler(status);
    }else if (status == PHAuthorizationStatusDenied ||
              status == PHAuthorizationStatusRestricted) {
        [self showNoAuthorizedAlertWithViewController:viewController];
    }else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handler) handler(status);
                if (status != PHAuthorizationStatusAuthorized) {
                    [self showNoAuthorizedAlertWithViewController:viewController];
                }else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"HXPhotoRequestAuthorizationCompletion" object:nil];
                }
            });
        }];
    }
}
+ (void)showNoAuthorizedAlertWithViewController:(UIViewController *)viewController {
    hx_showAlert(viewController, [NSBundle hx_localizedStringForKey:@"无法访问相册"], [NSBundle hx_localizedStringForKey:@"请在设置-隐私-相册中允许访问相册"], [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"设置"], nil, ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    });
}

+ (void)exportEditVideoForAVAsset:(AVAsset *)asset
                        timeRange:(CMTimeRange)timeRange
                       presetName:(NSString *)presetName
                          success:(void (^)(NSURL *))success
                           failed:(void (^)(NSError *))failed {
    
    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    if ([presets containsObject:presetName]) {
        NSString *fileName = [[NSString hx_fileName] stringByAppendingString:@".mp4"];
        NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        NSURL *videoURL = [NSURL fileURLWithPath:fullPathToFile];
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:presetName];
        exportSession.outputURL = videoURL;
        NSArray *supportedTypeArray = exportSession.supportedFileTypes;
        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
            exportSession.outputFileType = AVFileTypeMPEG4;
        } else if (supportedTypeArray.count == 0) {
            if (failed) {
                failed([NSError errorWithDomain:@"不支持导入该类型视频" code:-222 userInfo:nil]);
            }
            return;
        }else {
            exportSession.outputFileType = [supportedTypeArray objectAtIndex:0];
        }
        exportSession.timeRange = timeRange;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                    if (success) {
                        success(videoURL);
                    }
                }else {
                    if (failed) {
                        failed(exportSession.error);
                    }
                }
            });
        }];
    }else {
        if (failed) {
            failed([NSError errorWithDomain:[NSString stringWithFormat:@"该设备不支持:%@",presetName] code:-111 userInfo:nil]); 
        }
    }
}
+ (NSString *)getBytesFromDataLength:(NSInteger)dataLength {
    NSString *bytes;
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%0.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB",dataLength];
    }
    return bytes;
}

+ (void)saveVideoToCustomAlbumWithName:(NSString *)albumName
                              videoURL:(NSURL *)videoURL
                              location:(CLLocation *)location
                              complete:(void (^)(HXPhotoModel *model, BOOL success))complete {
    if (!videoURL) {
        if (complete) {
            complete(nil, NO);
        }
        return;
    }
    // 判断授权状态
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status != PHAuthorizationStatusAuthorized) {
                if (complete) {
                    complete(nil, NO);
                }
                return;
            }
            if (!HX_IOS9Later) {
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([videoURL path])) {
                    //保存相册
                    UISaveVideoAtPathToSavedPhotosAlbum([videoURL path], nil, nil, nil);
                    if (complete) {
                        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithVideoURL:videoURL];
                        photoModel.creationDate = [NSDate date];
                        photoModel.location = location;
                        complete(photoModel, YES);
                    }
                }else {
                    if (complete) {
                        complete(nil, NO);
                    }
                }
                return;
            }
            NSError *error = nil;
            // 保存相片到相机胶卷
            __block PHObjectPlaceholder *createdAsset = nil;
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
                creationRequest.creationDate = [NSDate date];
                creationRequest.location = location;
                createdAsset = creationRequest.placeholderForCreatedAsset;
            } error:&error];
            
            if (error) {
                if (complete) {
                    complete(nil, NO);
                }
                if (HXShowLog) NSSLog(@"保存失败");
                return;
            }else { 
                if (createdAsset.localIdentifier) {
                    if (complete) {
                        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithPHAsset:[[PHAsset fetchAssetsWithLocalIdentifiers:@[createdAsset.localIdentifier] options:nil] firstObject]];
                        photoModel.creationDate = [NSDate date];
                        complete(photoModel, YES);
                    }
                }
            }
            
            // 拿到自定义的相册对象
            PHAssetCollection *collection = [self createCollection:albumName];
            if (collection == nil) {
                if (HXShowLog) NSSLog(@"保存自定义相册失败");
                return;
            }
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection] insertAssets:@[createdAsset] atIndexes:[NSIndexSet indexSetWithIndex:0]];
            } error:&error];
            
            if (error) {
                if (HXShowLog) NSSLog(@"保存自定义相册失败");
            } else {
                if (HXShowLog)  NSSLog(@"保存自定义相册成功");
            }
        });
    }];
}

+ (void)saveVideoToCustomAlbumWithName:(NSString *)albumName videoURL:(NSURL *)videoURL {
    [self saveVideoToCustomAlbumWithName:albumName videoURL:videoURL location:nil complete:nil];
}

+ (void)savePhotoToCustomAlbumWithName:(NSString *)albumName
                                 photo:(UIImage *)photo
                              location:(CLLocation *)location
                              complete:(void (^)(HXPhotoModel *model, BOOL success))complete {
    if (!photo) {
        if (complete) {
            complete(nil, NO);
        }
        return;
    }
    // 判断授权状态
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!HX_IOS9Later) {
                UIImage *tempImage = photo;
                if (tempImage.imageOrientation != UIImageOrientationUp) {
                    tempImage = [tempImage hx_normalizedImage];
                }
                UIImageWriteToSavedPhotosAlbum(tempImage, nil, nil, nil);
                if (complete) {
                    HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:tempImage];
                    photoModel.creationDate = [NSDate date];
                    photoModel.location = location;
                    complete(photoModel, YES);
                }
                return;
            }
            NSError *error = nil;
            // 保存相片到相机胶卷
            __block PHObjectPlaceholder *createdAsset = nil;
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAssetFromImage:photo];
                creationRequest.creationDate = [NSDate date];
                creationRequest.location = location;
                createdAsset = creationRequest.placeholderForCreatedAsset;
            } error:&error];
            
            if (error) {
                if (complete) {
                    complete(nil, NO);
                }
                if (HXShowLog) NSSLog(@"保存失败");
                return;
            }else {
                if (complete && createdAsset.localIdentifier) {
                    HXPhotoModel *photoModel = [HXPhotoModel photoModelWithPHAsset:[[PHAsset fetchAssetsWithLocalIdentifiers:@[createdAsset.localIdentifier] options:nil] firstObject]];
                    photoModel.creationDate = [NSDate date];
                    complete(photoModel, YES);
                }
            }
            
            // 拿到自定义的相册对象
            PHAssetCollection *collection = [self createCollection:albumName];
            if (collection == nil) {
                if (HXShowLog) NSSLog(@"创建自定义相册失败");
                return;
            }
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection] insertAssets:@[createdAsset] atIndexes:[NSIndexSet indexSetWithIndex:0]];
            } error:&error];
            
            if (error) {
                if (HXShowLog) NSSLog(@"保存自定义相册失败");
            } else {
                if (HXShowLog) NSSLog(@"保存自定义相册成功");
            }
        });
    }];
} 
+ (void)savePhotoToCustomAlbumWithName:(NSString *)albumName photo:(UIImage *)photo {
    [self savePhotoToCustomAlbumWithName:albumName photo:photo location:nil complete:nil];
}
// 创建自己要创建的自定义相册
+ (PHAssetCollection * )createCollection:(NSString *)albumName {
    NSString * title = albumName;
    PHFetchResult<PHAssetCollection *> *collections =  [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    PHAssetCollection * createCollection = nil;
    for (PHAssetCollection * collection in collections) {
        if ([collection.localizedTitle isEqualToString:title]) {
            createCollection = collection;
            break;
        }
    }
    if (createCollection == nil) {
        
        NSError * error1 = nil;
        __block NSString * createCollectionID = nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            NSString * title = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
            createCollectionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
        } error:&error1];
        
        if (error1) {
            if (HXShowLog) NSSLog(@"创建相册失败...");
            return nil;
        }
        // 创建相册之后我们还要获取此相册  因为我们要往进存储相片
        createCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createCollectionID] options:nil].firstObject;
    }
    
    return createCollection;
} 
+ (BOOL)isIphone6 {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if([platform isEqualToString:@"iPhone7,2"]){//6
        return YES;
    }
    if ([platform isEqualToString:@"iPhone8,1"]) {//6s
        return YES;
    }
    if([platform isEqualToString:@"iPhone9,1"] || [platform isEqualToString:@"iPhone9,3"]) {//7
        return YES;
    }
    if([platform isEqualToString:@"iPhone10,1"] || [platform isEqualToString:@"iPhone10,4"]) {//8
        return YES;
    }
    return NO;
}

+ (BOOL)platform {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    BOOL have = NO;
    if ([platform isEqualToString:@"iPhone8,1"]) { // iphone6s
        have = YES;
    }else if ([platform isEqualToString:@"iPhone8,2"]) { // iphone6s plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone9,1"]) { // iphone7
        have = YES;
    }else if ([platform isEqualToString:@"iPhone9,2"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,1"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,2"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,3"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,4"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,5"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,6"]) { // iphone7 plus
        have = YES;
    } 
    return have;
}
+ (void)selectListWriteToTempPath:(NSArray *)selectList requestList:(void (^)(NSArray *, NSArray *))requestList completion:(void (^)(NSArray<NSURL *> *, NSArray<NSURL *> *, NSArray<NSURL *> *))completion error:(void (^)(void))error {
    NSSLog(@"该方法无效!!!");
}
@end
