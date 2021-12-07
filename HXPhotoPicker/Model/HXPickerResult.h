//
//  HXPickerResult.h
//  HXPhotoPickerExample
//
//  Created by Slience on 2021/12/6.
//  Copyright © 2021 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HXPickerResult : NSObject

@property (copy, nonatomic, readonly) NSArray<HXPhotoModel *> *models;
@property (assign, nonatomic, readonly) BOOL isOriginal;

- (instancetype)initWithModels:(NSArray<HXPhotoModel *> *)models
                    isOriginal:(BOOL)isOriginal;

- (void)getURLsWithVideoExportPreset:(HXVideoExportPreset)videoExportPreset
                        videoQuality:(NSInteger)videoQuality
                          UrlHandler:(void (^ _Nullable)(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel, NSInteger index))urlHandler
                   completionHandler:(void (^ _Nullable)(void))completionHandler;

- (void)getImageURLsWithUrlHandler:(void (^ _Nullable)(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel, NSInteger index))urlHandler
                 completionHandler:(void (^ _Nullable)(void))completionHandler;

- (void)getVideoURlsWithExportPreset:(HXVideoExportPreset)exportPreset
                        videoQuality:(NSInteger)videoQuality
                          urlHandler:(void (^ _Nullable)(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel, NSInteger index))urlHandler
                   completionHandler:(void (^ _Nullable)(void))completionHandler;
@end


typedef NS_ENUM(NSUInteger, HXAssetURLType) {
    HXAssetURLTypeLocal = 0,
    HXAssetURLTypeNetwork
};

@interface HXAssetURLResult: NSObject

@property (strong, nonatomic, readonly) NSURL *url;
@property (assign, nonatomic, readonly) HXAssetURLType urlType;
@property (assign, nonatomic, readonly) HXPhotoModelMediaSubType mediaType;

- (instancetype)initWithUrl:(NSURL *)url
                    urlType:(HXAssetURLType)urlType
                  mediaType:(HXPhotoModelMediaSubType)mediaType;
@end

NS_ASSUME_NONNULL_END
