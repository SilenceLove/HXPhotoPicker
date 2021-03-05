//
//  HXPhotoTools.m
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXPhotoTools.h"
#import "HXPhotoModel.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoManager.h"
#import <sys/utsname.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

#import <PhotosUI/PhotosUI.h>

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageManager.h>
#elif __has_include("UIImageView+WebCache.h")
#import "UIImageView+WebCache.h"
#import "SDWebImageManager.h"
#endif


#if __has_include(<YYWebImage/YYWebImage.h>)
#import <YYWebImage/YYWebImage.h>
#elif __has_include("YYWebImage.h")
#import "YYWebImage.h"
#elif __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKit.h>
#elif __has_include("YYKit.h")
#import "YYKit.h"
#endif

#import "HXAssetManager.h"

NSString *const hx_kFigAppleMakerNote_AssetIdentifier = @"17";
NSString *const hx_kKeySpaceQuickTimeMetadata = @"mdta";
NSString *const hx_kKeyStillImageTime = @"com.apple.quicktime.still-image-time";
NSString *const hx_kKeyContentIdentifier = @"com.apple.quicktime.content.identifier";
@implementation HXPhotoTools

+ (void)saveModelToCustomAlbumWithAlbumName:(NSString * _Nullable)albumName
                                 photoModel:(HXPhotoModel * _Nullable)photoModel
                                   location:(CLLocation * _Nullable)location
                                   complete:(void (^ _Nullable)(HXPhotoModel * _Nullable model, BOOL success))complete {
    if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
        
    }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
        
    }
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
+ (void)fetchPhotosBytes:(NSArray *)photos completion:(void (^)(NSString *))completion
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
    PHAuthorizationStatus status = [self authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        if (handler) handler(status);
    }
#ifdef __IPHONE_14_0
    else if (@available(iOS 14, *)) {
        if (status == PHAuthorizationStatusLimited) {
            if (handler) handler(status);
        }
#endif
    else if (status == PHAuthorizationStatusDenied ||
             status == PHAuthorizationStatusRestricted) {
        if (handler) handler(status);
        [self showNoAuthorizedAlertWithViewController:viewController status:status];
    }else {
#ifdef __IPHONE_14_0
        if (@available(iOS 14, *)) {
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) handler(status);
                    if (status != PHAuthorizationStatusAuthorized &&
                        status != PHAuthorizationStatusLimited) {
                        [self showNoAuthorizedAlertWithViewController:viewController status:status];
                    }else {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"HXPhotoRequestAuthorizationCompletion" object:nil];
                    }
                });
            }];
        }
#else
        if (NO) {}
#endif
        else {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) handler(status);
                    if (status != PHAuthorizationStatusAuthorized) {
                        [self showNoAuthorizedAlertWithViewController:viewController status:status];
                    }else {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"HXPhotoRequestAuthorizationCompletion" object:nil];
                    }
                });
            }];
        }
    }
#ifdef __IPHONE_14_0
    }else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handler) handler(status);
                if (status != PHAuthorizationStatusAuthorized) {
                    [self showNoAuthorizedAlertWithViewController:viewController status:status];
                }else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"HXPhotoRequestAuthorizationCompletion" object:nil];
                }
            });
        }];
    }
#endif
}
+ (void)showNoAuthorizedAlertWithViewController:(UIViewController *)viewController
                                         status:(PHAuthorizationStatus)status {
    if (!viewController) {
        return;
    }
#ifdef __IPHONE_14_0
    if (@available(iOS 14, *)) {
        if (status == PHAuthorizationStatusLimited) {
            hx_showAlert(viewController, [NSBundle hx_localizedStringForKey:@"无法访问所有照片"], [NSBundle hx_localizedStringForKey:@"请在设置-隐私-相册中允许访问所有照片"], [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"设置"], nil, ^{
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                }else {
                    [[UIApplication sharedApplication] openURL:url];
                }
            });
            return;;
        }
    }
#endif
    hx_showAlert(viewController, [NSBundle hx_localizedStringForKey:@"无法访问相册"], [NSBundle hx_localizedStringForKey:@"请在设置-隐私-相册中允许访问相册"], [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"设置"], nil, ^{
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }else {
            [[UIApplication sharedApplication] openURL:url];
        }
    });
}

+ (PHAuthorizationStatus)authorizationStatus {
    PHAuthorizationStatus status;
#ifdef __IPHONE_14_0
    if (@available(iOS 14, *)) {
        status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
#else
    if(NO) {
#endif
    }else {
        status = [PHPhotoLibrary authorizationStatus];
    }
    return status;
}
+ (BOOL)authorizationStatusIsLimited {
    PHAuthorizationStatus status = [self authorizationStatus];
#ifdef __IPHONE_14_0
    if (@available(iOS 14, *)) {
        if (status == PHAuthorizationStatusLimited) {
            return YES;
        }
    }
#endif
    return NO;
}
+ (void)showUnusableCameraAlert:(UIViewController *)vc {
    hx_showAlert(vc, [NSBundle hx_localizedStringForKey:@"无法使用相机"], [NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问相机"], [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"设置"] , nil, ^{
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }else {
            [[UIApplication sharedApplication] openURL:url];
        }
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
        }else if (supportedTypeArray.count == 0) {
            if (failed) {
                failed([NSError errorWithDomain:@"不支持导出该类型视频" code:-222 userInfo:nil]);
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
+ (NSString *)getBytesFromDataLength:(NSUInteger)dataLength {
    NSString *bytes;
    if (dataLength >= 0.5 * (1024 * 1024)) {
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
    if (!albumName) {
        albumName = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
    }
    // 判断授权状态
    [self requestAuthorization:nil handler:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusNotDetermined ||
                status == PHAuthorizationStatusRestricted ||
                status == PHAuthorizationStatusDenied) {
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
                if (complete) {
                    if (createdAsset.localIdentifier) {
                        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithPHAsset:[HXAssetManager fetchAssetWithLocalIdentifier:createdAsset.localIdentifier]];
                        photoModel.videoURL = videoURL;
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
    if (photo.imageOrientation != UIImageOrientationUp) {
        photo = [photo hx_normalizedImage];
    }
    if (!albumName) {
        albumName = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
    }
    // 判断授权状态
    [self requestAuthorization:nil handler:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusNotDetermined ||
                status == PHAuthorizationStatusRestricted ||
                status == PHAuthorizationStatusDenied) {
                if (complete) {
                    complete(nil, NO);
                }
                return;
            }
            if (!HX_IOS9Later) {
                UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil);
                if (complete) {
                    HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:photo];
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
                if (complete) {
                    if (createdAsset.localIdentifier) {
                        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithPHAsset:[HXAssetManager fetchAssetWithLocalIdentifier:createdAsset.localIdentifier]];
                        photoModel.thumbPhoto = photo;
                        photoModel.previewPhoto = photo;
                        photoModel.location = location;
                        photoModel.creationDate = [NSDate date];
                        complete(photoModel, YES);
                    }
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
            
            if (error != nil) {
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
+ (BOOL)isIphone12Mini {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if([platform isEqualToString:@"iPhone13,1"]) {
        return YES;
    }else if ([platform isEqualToString:@"x86_64"] || [platform isEqualToString:@"i386"]) {
        if (([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) && !HX_UI_IS_IPAD : NO)) {
            return YES;
        }
    }
    return NO;
}
+ (BOOL)isRTLLanguage
{
    return [NSLocale characterDirectionForLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]] == NSLocaleLanguageDirectionRightToLeft;
}

+ (BOOL)fileExistsAtVideoURL:(NSURL *)videoURL {
    if (!videoURL) {
        return NO;
    }
    NSString * downloadPath = HXPhotoPickerDownloadVideosPath;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString *fullPathToFile = [self getVideoURLFilePath:videoURL];
    if (![fileManager fileExistsAtPath:downloadPath]) {
        [fileManager createDirectoryAtPath:downloadPath withIntermediateDirectories:YES attributes:nil error:nil];
    }else {
        if ([fileManager fileExistsAtPath:fullPathToFile]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)fileExistsAtImageURL:(NSURL *)ImageURL {
    if (!ImageURL) {
        return NO;
    }
    NSString * downloadPath = HXPhotoPickerDownloadPhotosPath;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString *fullPathToFile = [self getImageURLFilePath:ImageURL];
    if (![fileManager fileExistsAtPath:downloadPath]) {
        [fileManager createDirectoryAtPath:downloadPath withIntermediateDirectories:YES attributes:nil error:nil];
    }else {
        if ([fileManager fileExistsAtPath:fullPathToFile]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)fileExistsAtLivePhotoVideoURL:(NSURL *)videoURL {
    if (!videoURL) {
        return NO;
    }
    NSString * downloadPath = HXPhotoPickerLivePhotoVideosPath;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString *fullPathToFile = [[self getLivePhotoVideoURLFilePath:videoURL] stringByAppendingString:@".mov"];
    if (![fileManager fileExistsAtPath:downloadPath]) {
        [fileManager createDirectoryAtPath:downloadPath withIntermediateDirectories:YES attributes:nil error:nil];
    }else {
        if ([fileManager fileExistsAtPath:fullPathToFile]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)fileExistsAtLivePhotoImageURL:(NSURL *)ImageURL {
    if (!ImageURL) {
        return NO;
    }
    NSString * downloadPath = HXPhotoPickerLivePhotoImagesPath;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString *fullPathToFile = [[self getLivePhotoImageURLFilePath:ImageURL] stringByAppendingString:@".jpg"];
    if (![fileManager fileExistsAtPath:downloadPath]) {
        [fileManager createDirectoryAtPath:downloadPath withIntermediateDirectories:YES attributes:nil error:nil];
    }else {
        if ([fileManager fileExistsAtPath:fullPathToFile]) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)getLivePhotoVideoURLFilePath:(NSURL *)videoURL {
    if (!videoURL) {
        return nil;
    }
    NSString *fileName = HXDiskCacheFileNameForKey(videoURL.lastPathComponent, NO);
//    NSString * fileName = [videoURL.lastPathComponent stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
//    fileName = [fileName stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString *fullPathToFile = [HXPhotoPickerLivePhotoVideosPath stringByAppendingPathComponent:fileName];
    return fullPathToFile;
}
+ (NSString *)getLivePhotoImageURLFilePath:(NSURL *)imageURL {
    if (!imageURL) {
        return nil;
    }
    NSString *fileName = HXDiskCacheFileNameForKey(imageURL.lastPathComponent, NO);
//    NSString * fileName = [imageURL.lastPathComponent stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
//    fileName = [fileName stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString *fullPathToFile = [HXPhotoPickerLivePhotoImagesPath stringByAppendingPathComponent:fileName];
    return fullPathToFile;
}
+ (NSString *)getImageURLFilePath:(NSURL *)imageURL {
    if (!imageURL) {
        return nil;
    }
    NSString *fileName = HXDiskCacheFileNameForKey(imageURL.absoluteString, YES);
//    NSString * fileName = [imageURL.lastPathComponent stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *fullPathToFile = [HXPhotoPickerDownloadPhotosPath stringByAppendingPathComponent:fileName];
    return fullPathToFile;
}
+ (NSString *)getVideoURLFilePath:(NSURL *)videoURL {
    if (!videoURL) {
        return nil;
    }
    NSString *fileName = HXDiskCacheFileNameForKey(videoURL.absoluteString, YES);
//    NSString * fileName = [videoURL.lastPathComponent stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *fullPathToFile = [HXPhotoPickerDownloadVideosPath stringByAppendingPathComponent:fileName];
    return fullPathToFile;
}
+ (void)downloadImageWithURL:(NSURL *)URL completed:(void (^)(UIImage * image, NSError * error))completedBlock {
#if HasSDWebImage
    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:URL];
    [[SDWebImageManager sharedManager].imageCache queryImageForKey:cacheKey options:SDWebImageQueryMemoryData context:nil completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        if (image) {
            if (completedBlock) {
                completedBlock(image, nil);
            }
        }else {
            NSURL *url = URL;
            [[SDWebImageManager sharedManager] loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                if (completedBlock) {
                    completedBlock(image,error);
                }
            }];
        }
    }];
#elif HasYYKitOrWebImage
    YYWebImageManager *manager = [YYWebImageManager sharedManager];
    [manager.cache getImageForKey:[manager cacheKeyForURL:URL]  withType:YYImageCacheTypeAll withBlock:^(UIImage * _Nullable image, YYImageCacheType type) {
        if (image) {
            if (completedBlock) {
                completedBlock(image, nil);
            }
        }else {
            [manager requestImageWithURL:URL options:kNilOptions progress:nil transform:^UIImage * _Nullable(UIImage * _Nonnull image, NSURL * _Nonnull url) {
                return image;
            } completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
                if (completedBlock) {
                    completedBlock(image, error);
                }
            }];
        }
    }];
#else
    NSAssert(NO, @"请导入YYWebImage/SDWebImage后再使用网络图片功能，HXPhotoPicker为pod导入的那么YY或者SD也必须是pod导入的否则会找不到");
#endif
}

+ (AVAssetWriterInputMetadataAdaptor *)metadataSetAdapter {
    NSString *identifier = [hx_kKeySpaceQuickTimeMetadata stringByAppendingFormat:@"/%@",hx_kKeyStillImageTime];
    const NSDictionary *spec = @{(__bridge_transfer  NSString*)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier :
                                     identifier,
                                 (__bridge_transfer  NSString*)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType :
                                     @"com.apple.metadata.datatype.int8"
                                 };
    CMFormatDescriptionRef desc;
    CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, (__bridge CFArrayRef)@[spec], &desc);
    AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata outputSettings:nil sourceFormatHint:desc];
    CFRelease(desc);
    return [AVAssetWriterInputMetadataAdaptor assetWriterInputMetadataAdaptorWithAssetWriterInput:input];
}
+ (void)writeToFileWithOriginJPGPath:(NSURL *)originJPGPath
                TargetWriteFilePath:(NSURL *)finalJPGPath
                         completion:(void (^ _Nullable)(BOOL success))completion {
    NSString * assetIdentifier = [HXPhotoCommon photoCommon].UUIDString;
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)finalJPGPath, kUTTypeJPEG, 1, nil);
    if (!dest) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((CFDataRef)[NSData dataWithContentsOfFile:originJPGPath.path], nil);
     if (!imageSourceRef) {
         if (dest) {
             CFRelease(dest);
         }
         if (completion) {
             completion(NO);
         }
         return;
     }
    NSMutableDictionary *metaData = [(__bridge_transfer  NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, nil) mutableCopy];
    if (!metaData) {
        if (dest) {
            CFRelease(dest);
        }
        if (imageSourceRef) {
            CFRelease(imageSourceRef);
        }
        if (completion) {
            completion(NO);
        }
        return;
    }
    NSMutableDictionary *makerNote = [NSMutableDictionary dictionary];
    [makerNote setValue:assetIdentifier forKey:hx_kFigAppleMakerNote_AssetIdentifier];
    [metaData setValue:makerNote forKey:(__bridge_transfer  NSString*)kCGImagePropertyMakerAppleDictionary];
    CGImageDestinationAddImageFromSource(dest, imageSourceRef, 0, (CFDictionaryRef)metaData);
    CGImageDestinationFinalize(dest);
    CFRelease(imageSourceRef);
    if (dest) {
        CFRelease(dest);
    }
     if (completion) {
         completion(YES);
     }
}
+ (void)writeToFileWithOriginMovPath:(NSURL *)originMovPath
                 TargetWriteFilePath:(NSURL *)finalMovPath
                              header:(void (^ _Nullable)(AVAssetWriter *, AVAssetReader *, AVAssetReader *))header
                          completion:(void (^ _Nullable)(BOOL))completion{
    NSString * assetIdentifier = [HXPhotoCommon photoCommon].UUIDString;
    AVURLAsset* asset = [AVURLAsset assetWithURL:originMovPath];
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    if (!videoTrack) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    AVAssetReaderOutput *videoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:@{(__bridge_transfer  NSString*)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]}];
    NSError *error;
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if([reader canAddOutput:videoOutput]) {
        [reader addOutput:videoOutput];
    } else {
        NSSLog(@"Add video output error\n");
    }
    NSString *videoCodeec;
    if (@available(iOS 11.0, *)) {
        videoCodeec = AVVideoCodecTypeH264;
    } else {
        videoCodeec = AVVideoCodecH264;
    }
    NSDictionary * outputSetting = @{AVVideoCodecKey: videoCodeec,
                                     AVVideoWidthKey: [NSNumber numberWithFloat:videoTrack.naturalSize.width],
                                     AVVideoHeightKey: [NSNumber numberWithFloat:videoTrack.naturalSize.height]
                                     };
    
                              
    NSError *error_two;
    
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:finalMovPath fileType:AVFileTypeQuickTimeMovie error:&error_two];
    if(error_two) {
        NSSLog(@"CreateWriterError:%@\n",error_two);
    }
    writer.metadata = @[ [self metaDataSet:assetIdentifier]];
                              
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSetting];
    videoInput.expectsMediaDataInRealTime = YES;
    videoInput.transform = videoTrack.preferredTransform;
    
    if ([writer canAddInput:videoInput]) {
        [writer addInput:videoInput];
    }
    AVAssetWriterInput *audioInput;
    AVAssetReaderTrackOutput *audioOutput;
    AVAssetReader *audioReader;
    AVAsset *aAudioAsset = [AVAsset assetWithURL:originMovPath];
    if (aAudioAsset.tracks.count > 1) {
        NSSLog(@"Has Audio");
        // setup audio writer
        audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil];
        audioInput.expectsMediaDataInRealTime = NO;
        if ([writer canAddInput:audioInput]) {
            [writer addInput:audioInput];
        }
        // setup audio reader
        AVAssetTrack *audioTrack = [aAudioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        audioOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack outputSettings:nil];

        NSError *audioReaderError = nil;
        audioReader = [AVAssetReader assetReaderWithAsset:aAudioAsset error:&audioReaderError];
        if (audioReaderError) {
            NSSLog(@"Unable to read Asset, error: %@",audioReaderError);
        }
        
        if ([audioReader canAddOutput:audioOutput]) {
            [audioReader addOutput:audioOutput];
        } else {
            NSSLog(@"cant add audio reader");
        }
    }
                              
    AVAssetWriterInputMetadataAdaptor *adapter = [self metadataSetAdapter];
    [writer addInput:adapter.assetWriterInput];
    [writer startWriting];
    [reader startReading];
    [writer startSessionAtSourceTime:kCMTimeZero];
    
    if (header) {
        header(writer, reader, audioReader);
    }
    
    CMTimeRange dummyTimeRange = CMTimeRangeMake(CMTimeMake(0, 1000), CMTimeMake(200, 3000));
    //Meta data reset:
    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.key = hx_kKeyStillImageTime;
    item.keySpace = hx_kKeySpaceQuickTimeMetadata;
    item.value = [NSNumber numberWithInt:0];
    item.dataType = @"com.apple.metadata.datatype.int8";
    [adapter appendTimedMetadataGroup:[[AVTimedMetadataGroup alloc] initWithItems:[NSArray arrayWithObject:item] timeRange:dummyTimeRange]];
    
    dispatch_queue_t createMovQueue = dispatch_queue_create("createMovQueue", DISPATCH_QUEUE_SERIAL);
                              
    [videoInput requestMediaDataWhenReadyOnQueue:createMovQueue usingBlock:^{
      while ([videoInput isReadyForMoreMediaData]) {
          if (reader.status == AVAssetReaderStatusReading) {
              CMSampleBufferRef videoBuffer = [videoOutput copyNextSampleBuffer];
              if (videoBuffer) {
                  if (![videoInput appendSampleBuffer:videoBuffer]) {
                      [reader cancelReading];
                  }
                  CFRelease(videoBuffer);
                  videoBuffer = nil;
              }else {
                  [videoInput markAsFinished];
                  if (reader.status == AVAssetReaderStatusCompleted && audioInput) {
                      [audioReader startReading];
                      [writer startSessionAtSourceTime:kCMTimeZero];
                      [audioInput requestMediaDataWhenReadyOnQueue:createMovQueue usingBlock:^{
                          while ([audioInput isReadyForMoreMediaData]) {
                            CMSampleBufferRef audioBuffer = [audioOutput copyNextSampleBuffer];
                            if (audioBuffer) {
                                if (![audioInput appendSampleBuffer:audioBuffer]) {
                                    [audioReader cancelReading];
                                }
                                CFRelease(audioBuffer);
                                audioBuffer = nil;
                            }else {
                                [audioInput markAsFinished];

                                [writer finishWritingWithCompletionHandler:^{
                                }];
                                break;
                            }
                          }
                      }];
                  }else {
                      [writer finishWritingWithCompletionHandler:^{
                      }];
                  }
                  break;
              }
          }else {
              [writer finishWritingWithCompletionHandler:^{
              }];
          }
      }
    }];
    while (writer.status == AVAssetWriterStatusWriting) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        }
    }
    if (writer.status == AVAssetWriterStatusCancelled ||
        writer.status == AVAssetWriterStatusFailed) {
        [[NSFileManager defaultManager] removeItemAtURL:finalMovPath error:nil];
    }
                              
    if (writer.error) {
        if (completion) {
            completion(NO);
        }
        NSSLog(@"cannot write: %@", writer.error);
    } else {
        if (completion) {
            completion(YES);
        }
    }
}

+ (AVMetadataItem *)metaDataSet:(NSString *)assetIdentifier {
    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.key = hx_kKeyContentIdentifier;
    item.keySpace = hx_kKeySpaceQuickTimeMetadata;
    item.value = assetIdentifier;
    item.dataType = @"com.apple.metadata.datatype.UTF-8";
    return item;
}
    
+ (long long)fileSizeAtPath:(NSString*)filePath {
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}
+ (long long)folderSizeAtPath:(NSString *)folderPath {
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil) {
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize;
}
/// 获取所有缓存的大小
+ (long long)getAllLocalFileSize {
    return [self folderSizeAtPath:HXPhotoPickerAssetCachesPath];
}

/// 获取缓存在本地所有的HXPhotoModel的大小
+ (long long)getAllLocalModelsFileSize{
    return [self folderSizeAtPath:HXPhotoPickerLocalModelsPath];
}

/// 获取生成LivePhoto缓存在本地的图片视频大小
+ (long long)getLivePhotoAssetFileSize {
    return [self folderSizeAtPath:HXPhotoPickerCachesLivePhotoPath];
}

/// 获取下载网络视频缓存的大小
+ (long long)getNetWorkVideoFileSize {
    return [self folderSizeAtPath:HXPhotoPickerCachesDownloadPath];
}

/// 删除HXPhotoPicker所有文件
+ (void)deleteAllLocalFile {
    [[NSFileManager defaultManager] removeItemAtPath:HXPhotoPickerAssetCachesPath error:nil];
}

/// 删除本地HXPhotoModel缓存文件
+ (void)deleteAllLocalModelsFile {
    [[NSFileManager defaultManager] removeItemAtPath:HXPhotoPickerLocalModelsPath error:nil];
}

/// 删除生成LivePhoto相关的缓存文件
+ (void)deleteLivePhotoCachesFile {
    [[NSFileManager defaultManager] removeItemAtPath:HXPhotoPickerCachesLivePhotoPath error:nil];
}

/// 删除下载的网络视频缓存文件
+ (void)deleteNetWorkVideoFile {
    [[NSFileManager defaultManager] removeItemAtPath:HXPhotoPickerCachesDownloadPath error:nil];
}
    
    
+ (CGFloat)getStatusBarHeight {
    CGFloat statusBarHeight = 0;
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].windows.firstObject.windowScene.statusBarManager;
        statusBarHeight = statusBarManager.statusBarFrame.size.height;
        if ([HXPhotoTools isIphone12Mini]) {
            statusBarHeight = 50;
        }else {
            if ([UIApplication sharedApplication].statusBarHidden) {
                statusBarHeight = HX_IS_IPhoneX_All ? 44: 20;
            }
        }
    }
    else {
        if ([UIApplication sharedApplication].statusBarHidden) {
            statusBarHeight = HX_IS_IPhoneX_All ? 44: 20;
        }else {
            statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        }
    }
    return statusBarHeight;
}
@end
