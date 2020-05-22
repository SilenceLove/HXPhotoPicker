//
//  HXPhotoCommon.m
//  照片选择器
//
//  Created by 洪欣 on 2019/1/8.
//  Copyright © 2019年 洪欣. All rights reserved.
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
@property (strong, nonatomic) NSURLConnection *urlFileLengthConnection;
@property (copy, nonatomic) HXPhotoCommonGetUrlFileLengthSuccess fileLengthSuccessBlock;
@property (copy, nonatomic) HXPhotoCommonGetUrlFileLengthFailure fileLengthFailureBlock;
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
        self.isVCBasedStatusBarAppearance = [[[NSBundle mainBundle]objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"] boolValue];
#if HasAFNetworking
        self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [self listenNetWorkStatus];
#endif
        NSData *imageData = [[NSUserDefaults standardUserDefaults] objectForKey:HXCameraImageKey];
        if (imageData) {
            self.cameraImage = [NSKeyedUnarchiver unarchiveObjectWithData:imageData];
        }

        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        }else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestAuthorizationCompletion) name:@"HXPhotoRequestAuthorizationCompletion" object:nil];
        }
    }
    return self;
}
- (void)requestAuthorizationCompletion {
    if (!self.hasAuthorization && [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        self.hasAuthorization = YES;
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
}

#pragma mark - < PHPhotoLibraryChangeObserver >
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.cameraRollAlbumModel.result];
    if (collectionChanges) {
        if ([collectionChanges hasIncrementalChanges]) {
            PHFetchResult *result = collectionChanges.fetchResultAfterChanges;
            self.cameraRollAlbumModel.result = result;
            self.cameraRollAlbumModel.count = result.count;
            if (collectionChanges.insertedObjects.count > 0) {
                // 添加照片了
            }
            if (collectionChanges.removedObjects.count > 0) {
                // 删除照片了
                
            }
            if (collectionChanges.changedObjects.count > 0) {
                // 改变照片了
            }
            if ([collectionChanges hasMoves]) {
                // 移动照片了
            }
        }
    }
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
- (BOOL)isDark {
    if (self.photoStyle == HXPhotoStyleDark) {
        return YES;
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
        NSData *imageData = [NSKeyedArchiver archivedDataWithRootObject:self.cameraImage];
        [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:HXCameraImageKey];
    }
}
- (void)setCameraImage:(UIImage *)cameraImage {
    _cameraImage = cameraImage;
}

- (void)getURLFileLengthWithURL:(NSURL *)url success:(HXPhotoCommonGetUrlFileLengthSuccess)success failure:(HXPhotoCommonGetUrlFileLengthFailure)failure {
    if (self.urlFileLengthConnection) {
        [self.urlFileLengthConnection cancel];
    }
    NSMutableURLRequest *mURLRequest = [NSMutableURLRequest requestWithURL:url];
    [mURLRequest setHTTPMethod:@"HEAD"];
    mURLRequest.timeoutInterval = 5.0;
    self.urlFileLengthConnection = [NSURLConnection connectionWithRequest:mURLRequest delegate:self];
    [self.urlFileLengthConnection start];
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSDictionary *dict = [(NSHTTPURLResponse *)response allHeaderFields];
    NSNumber *length = [dict objectForKey:@"Content-Length"];
    [connection cancel];
    if (self.fileLengthSuccessBlock) {
        self.fileLengthSuccessBlock(length.unsignedIntegerValue);
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [connection cancel];
    if (self.fileLengthFailureBlock) {
        self.fileLengthFailureBlock();
    }
}
/** 初始化并监听网络变化 */
- (void)listenNetWorkStatus {
#if HasAFNetworking
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    self.netStatus = manager.networkReachabilityStatus;
    [manager startMonitoring];
    HXWeakSelf
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        weakSelf.netStatus = status;
        if (weakSelf.reachabilityStatusChangeBlock) {
            weakSelf.reachabilityStatusChangeBlock(status);
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
//        NSLog(@"下载进度：%.0f％", downloadProgress.fractionCompleted * 100);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return videoFileURL;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                if (success) {
                    success(filePath, videoURL);
                }
            }else {
                if (failure) {
                    failure(error, videoURL);
                }
            }
        });
//        NSLog(@"下载完成");
    }];
    [downloadTask resume];
    return downloadTask;
#else
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
//    NSSLog(@"dealloc");
    
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"HXPhotoRequestAuthorizationCompletion" object:nil];
#if HasAFNetworking
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
#endif
}
@end
