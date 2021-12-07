//
//  HXPickerResult.m
//  HXPhotoPickerExample
//
//  Created by Slience on 2021/12/6.
//  Copyright © 2021 洪欣. All rights reserved.
//

#import "HXPickerResult.h"

@interface HXPickerResult()
@property (copy, nonatomic) NSArray<HXPhotoModel *> *models;
@property (assign, nonatomic) BOOL isOriginal;
@end

@implementation HXPickerResult

- (instancetype)initWithModels:(NSArray<HXPhotoModel *> *)models
                    isOriginal:(BOOL)isOriginal {
    self = [super init];
    if (self) {
        self.models = models;
        self.isOriginal = isOriginal;
    }
    return self;
}

- (void)getURLsWithVideoExportPreset:(HXVideoExportPreset)videoExportPreset
                        videoQuality:(NSInteger)videoQuality
                          UrlHandler:(void (^ _Nullable)(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel, NSInteger index))urlHandler
                   completionHandler:(void (^ _Nullable)(void))completionHandler {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("hxphpicker.get.urls", NULL);
    NSInteger index = 0;
    for (HXPhotoModel *model in self.models) {
        dispatch_group_async(group, queue, ^{
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            if (model.subType == HXPhotoModelMediaSubTypePhoto) {
                [model getImageURLWithResultHandler:^(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel) {
                    if (urlHandler) {
                        urlHandler(result, photoModel, index);
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
            }else {
                [model getVideoURLWithExportPreset:videoExportPreset videoQuality:videoQuality resultHandler:^(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel) {
                    if (urlHandler) {
                        urlHandler(result, photoModel, index);
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        });
        index++;
    }
    dispatch_group_notify(group, queue, ^{
        if (completionHandler) {
            completionHandler();
        }
    });
}

- (void)getImageURLsWithUrlHandler:(void (^ _Nullable)(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel, NSInteger index))urlHandler
                 completionHandler:(void (^ _Nullable)(void))completionHandler {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("hxphpicker.get.imageURL", NULL);
    NSInteger index = 0;
    for (HXPhotoModel *model in self.models) {
        if (model.subType != HXPhotoModelMediaSubTypePhoto) {
            continue;
        }
        dispatch_group_async(group, queue, ^{
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [model getImageURLWithResultHandler:^(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel) {
                if (urlHandler) {
                    urlHandler(result, photoModel, index);
                }
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        });
        index++;
    }
    dispatch_group_notify(group, queue, ^{
        if (completionHandler) {
            completionHandler();
        }
    });
}

- (void)getVideoURlsWithExportPreset:(HXVideoExportPreset)exportPreset
                        videoQuality:(NSInteger)videoQuality
                          urlHandler:(void (^ _Nullable)(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel, NSInteger index))urlHandler
                   completionHandler:(void (^ _Nullable)(void))completionHandler {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("hxphpicker.get.videoURL", NULL);
    NSInteger index = 0;
    for (HXPhotoModel *model in self.models) {
        if (model.subType != HXPhotoModelMediaSubTypeVideo) {
            continue;
        }
        dispatch_group_async(group, queue, ^{
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [model getVideoURLWithExportPreset:exportPreset videoQuality:videoQuality resultHandler:^(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel) {
                if (urlHandler) {
                    urlHandler(result, photoModel, index);
                }
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        });
        index++;
    }
    dispatch_group_notify(group, queue, ^{
        if (completionHandler) {
            completionHandler();
        }
    });
}
@end

@interface HXAssetURLResult()
@property (strong, nonatomic) NSURL *url;
@property (assign, nonatomic) HXAssetURLType urlType;
@property (assign, nonatomic) HXPhotoModelMediaSubType mediaType;
@end

@implementation HXAssetURLResult

- (instancetype)initWithUrl:(NSURL *)url
                    urlType:(HXAssetURLType)urlType
                  mediaType:(HXPhotoModelMediaSubType)mediaType {
    self = [super init];
    if (self) {
        self.url = url;
        self.urlType = urlType;
        self.mediaType = mediaType;
    }
    return self;
}
@end

