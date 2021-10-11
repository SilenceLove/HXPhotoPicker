//
//  HXPhotoCommon.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/1/8.
//  Copyright © 2019年 Silence. All rights reserved.
//

#import "HXPhotoCommon.h"
#import "HXPhotoTools.h"

static dispatch_once_t once;
static dispatch_once_t once1;
static id instance;

@interface HXPhotoCommon ()<NSURLConnectionDataDelegate, PHPhotoLibraryChangeObserver>
#if HasAFNetworking
@property (strong, nonatomic) AFURLSessionManager *sessionManager;
#endif
@property (assign, nonatomic) BOOL hasAuthorization;
@end

@implementation HXPhotoCommon


+ (instancetype)photoCommon {
    if (instance == nil) {
        dispatch_once(&once, ^{
            instance = [[HXPhotoCommon alloc] init];
        });
    }
    return instance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (instance == nil) {
        dispatch_once(&once1, ^{
            instance = [super allocWithZone:zone];
        });
    }
    return instance;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.audioSessionCategory = AVAudioSessionCategoryPlayback;
        self.isVCBasedStatusBarAppearance = [[[NSBundle mainBundle]objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"] boolValue];
        
#if HasAFNetworking
        self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [self listenNetWorkStatus];
#endif
        NSURL *imageURL = [[NSUserDefaults standardUserDefaults] URLForKey:HXCameraImageKey];
        if (imageURL) {
            self.cameraImageURL = imageURL;
        }
        self.cameraRollLocalIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"HXCameraRollLocalIdentifier"];
        
        PHAuthorizationStatus status = [HXPhotoTools authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        }
#ifdef __IPHONE_14_0
        else if (@available(iOS 14, *)) {
            if (status == PHAuthorizationStatusLimited) {
                self.cameraRollLocalIdentifier = nil;
                self.cameraRollResult = nil;
                [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
            }else {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestAuthorizationCompletion) name:@"HXPhotoRequestAuthorizationCompletion" object:nil];
            }
        }
#endif
        else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestAuthorizationCompletion) name:@"HXPhotoRequestAuthorizationCompletion" object:nil];
        }
    }
    return self;
}
- (void)setCameraRollLocalIdentifier:(NSString *)cameraRollLocalIdentifier {
    _cameraRollLocalIdentifier = cameraRollLocalIdentifier;
    if (cameraRollLocalIdentifier) {
        [[NSUserDefaults standardUserDefaults] setObject:cameraRollLocalIdentifier forKey:@"HXCameraRollLocalIdentifier"];
    }
}
- (void)requestAuthorizationCompletion {
    if (!self.hasAuthorization) {
        PHAuthorizationStatus status = [HXPhotoTools authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized) {
            self.hasAuthorization = YES;
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        }
#ifdef __IPHONE_14_0
        else if (@available(iOS 14, *)) {
            if (status == PHAuthorizationStatusLimited) {
                self.cameraRollLocalIdentifier = nil;
                self.cameraRollResult = nil;
                self.hasAuthorization = YES;
                [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
            }
        }
#endif
    }
}

#pragma mark - < PHPhotoLibraryChangeObserver >
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
//    if (!self.cameraRollResult) {
//        [self photoListReload];
//        return;
//    }
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.cameraRollResult];
    if (collectionChanges) {
        if ([collectionChanges hasIncrementalChanges]) {
            if (collectionChanges.insertedObjects.count > 0 ||
                collectionChanges.removedObjects.count > 0 ||
                collectionChanges.changedObjects.count > 0 ||
                [collectionChanges hasMoves]) {
                PHFetchResult *result = collectionChanges.fetchResultAfterChanges;
                self.cameraRollResult = result;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"HXPhotoViewNeedReloadNotification" object:nil];
                });
            }
        }else {
            PHFetchResult *result = collectionChanges.fetchResultAfterChanges;
            self.cameraRollResult = result;
            [self photoListReload];
        }
    }
}
- (void)photoListReload {
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef __IPHONE_14_0
        if (@available(iOS 14, *)) {
            PHAuthorizationStatus status = [HXPhotoTools authorizationStatus];
            if (status == PHAuthorizationStatusLimited) {
                if (self.photoLibraryDidChange) {
                    self.photoLibraryDidChange();
                }
            }
        }
#endif
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HXPhotoViewNeedReloadNotification" object:nil];
    });
}
- (NSBundle *)languageBundle {
    if (!_languageBundle) {
        NSString *language = [NSLocale preferredLanguages].firstObject;
        HXPhotoLanguageType type = self.languageType;
        switch (type) {
            case HXPhotoLanguageTypeSc : {
                language = @"zh-Hans"; // 简体中文
            } break;
            case HXPhotoLanguageTypeTc : {
                language = @"zh-Hant"; // 繁體中文
            } break;
            case HXPhotoLanguageTypeJa : {
                // 日文
                language = @"ja";
            } break;
            case HXPhotoLanguageTypeKo : {
                // 韩文
                language = @"ko";
            } break;
            case HXPhotoLanguageTypeEn : {
                language = @"en";
            } break;
            default : {
                if ([language hasPrefix:@"en"]) {
                    language = @"en";
                } else if ([language hasPrefix:@"zh"]) {
                    if ([language rangeOfString:@"Hans"].location != NSNotFound) {
                        language = @"zh-Hans"; // 简体中文
                    } else { // zh-Hant\zh-HK\zh-TW
                        language = @"zh-Hant"; // 繁體中文
                    }
                } else if ([language hasPrefix:@"ja"]){
                    // 日文
                    language = @"ja";
                }else if ([language hasPrefix:@"ko"]) {
                    // 韩文
                    language = @"ko";
                }else {
                    language = @"en";
                }
            }break;
        }
        [HXPhotoCommon photoCommon].languageBundle = [NSBundle bundleWithPath:[[NSBundle hx_photoPickerBundle] pathForResource:language ofType:@"lproj"]];
    }
    return _languageBundle;
}
- (NSString *)UUIDString {
    if (!_UUIDString) {
        _UUIDString = [[NSUUID UUID] UUIDString];
    }
    return _UUIDString;
}
- (BOOL)isDark {
    if (self.photoStyle == HXPhotoStyleDark) {
        return YES;
    }else if (self.photoStyle == HXPhotoStyleInvariant) {
        return NO;
    }
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return YES;
        }
    }
#endif
    return NO;
}
- (void)saveCamerImage {
    if (self.cameraImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData;
            NSString *suffix;
            if (UIImagePNGRepresentation(self.cameraImage)) {
                //返回为png图像。
                imageData = UIImagePNGRepresentation(self.cameraImage);
                suffix = @"png";
            }else {
                //返回为JPEG图像。
                imageData = UIImageJPEGRepresentation(self.cameraImage, 0.5);
                suffix = @"jpeg";
            }
            NSString *fileName = [HXCameraImageKey stringByAppendingString:[NSString stringWithFormat:@".%@",suffix]];
            NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *fullPathToFile = [array.firstObject stringByAppendingPathComponent:fileName];
            
            if ([imageData writeToFile:fullPathToFile atomically:YES]) {
                NSURL *imageURL = [NSURL fileURLWithPath:fullPathToFile];
                [[NSUserDefaults standardUserDefaults] setURL:imageURL forKey:HXCameraImageKey];
                self.cameraImageURL = imageURL;
            }
            self.cameraImage = nil;
        });
    }
}
- (void)setCameraImage:(UIImage *)cameraImage {
    if (!cameraImage) {
        _cameraImage = nil;
    }
    UIImage *image = [cameraImage hx_scaleImagetoScale:0.5];
    if (image) {
        _cameraImage = image;
    }else {
        _cameraImage = cameraImage;
    }
}
/** 初始化并监听网络变化 */
- (void)listenNetWorkStatus {
#if HasAFNetworking
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    self.netStatus = manager.networkReachabilityStatus;
    [manager startMonitoring];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        self.netStatus = status;
        if (self.reachabilityStatusChangeBlock) {
            self.reachabilityStatusChangeBlock(status);
        }
    }];
#endif
}

- (NSURLSessionDownloadTask * _Nullable)downloadVideoWithURL:(NSURL *)videoURL
                                          progress:(void (^)(float progress, long long downloadLength, long long totleLength, NSURL * _Nullable videoURL))progress
                                   downloadSuccess:(void (^)(NSURL * _Nullable filePath, NSURL * _Nullable videoURL))success
                                   downloadFailure:(void (^)(NSError * _Nullable error, NSURL * _Nullable videoURL))failure {
    NSString *videoFilePath = [HXPhotoTools getVideoURLFilePath:videoURL];
    
    NSURL *videoFileURL = [NSURL fileURLWithPath:videoFilePath];
    if ([HXPhotoTools fileExistsAtVideoURL:videoURL]) {
        if (success) {
            success(videoFileURL, videoURL);
        }
        return nil;
    }
#if HasAFNetworking
    NSURLRequest *request = [NSURLRequest requestWithURL:videoURL];
    /* 开始请求下载 */
    NSURLSessionDownloadTask *downloadTask = [self.sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
        if (progress) {
            progress(downloadProgress.fractionCompleted, downloadProgress.completedUnitCount, downloadProgress.totalUnitCount, videoURL);
            }
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return videoFileURL;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                if (success) {
                    success(filePath, videoURL);
                }
            }else {
                [[NSFileManager defaultManager] removeItemAtURL:videoFileURL error:nil];
                if (failure) {
                    failure(error, videoURL);
                }
            }
        });
    }];
    [downloadTask resume];
    return downloadTask;
#else
    /// pod导入的请改成 "HXPhotoPicker/SDWebImage_AF" 或 "HXPhotoPicker/YYWebImage_AF"
    NSSLog(@"没有导入AFNetworking网络框架无法下载视频");
    return nil;
#endif
}

+ (void)deallocPhotoCommon {
    once = 0;
    once1 = 0;
    instance = nil;
}
- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"HXPhotoRequestAuthorizationCompletion" object:nil];
#if HasAFNetworking
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
#endif
}
@end
