//
//  HXPhotoModel.m
//  照片选择器
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoModel.h"
#import "HXPhotoTools.h"
#import "HXPhotoManager.h"
#import "UIImage+HXExtension.h"
#import <MediaPlayer/MediaPlayer.h>
#import "HXPhotoCommon.h" 

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

@implementation HXPhotoModel

- (NSURL *)fileURL {
    if (self.type == HXPhotoModelMediaTypeCameraVideo && !_fileURL) {
        _fileURL = self.videoURL;
    }
    if (self.type != HXPhotoModelMediaTypeCameraPhoto) {
        if (self.asset && !_fileURL) {
            _fileURL = [self.asset valueForKey:@"mainFileURL"];
        }
    }
    return _fileURL;
}

- (NSDate *)creationDate {
    if (self.type == HXPhotoModelMediaTypeCameraPhoto || self.type == HXPhotoModelMediaTypeCameraVideo) {
        return _creationDate ?: [NSDate date];
    }
    if (!_creationDate) {
        _creationDate = [self.asset valueForKey:@"creationDate"];
    }
    return _creationDate;
}

- (NSDate *)modificationDate {
    if (self.type == HXPhotoModelMediaTypeCameraPhoto || self.type == HXPhotoModelMediaTypeCameraVideo) {
//        if (!_modificationDate) {
            return [NSDate date];
//        }
    }
//    if (!_modificationDate) {
        return [self.asset valueForKey:@"modificationDate"];
//    }
    return _modificationDate;
} 
- (CLLocation *)location {
    if (!_location) {
        if (self.asset) {
            _location = [self.asset valueForKey:@"location"];
        }
    }
    return _location;
}

- (NSString *)localIdentifier {
    if (self.asset) {
        return self.asset.localIdentifier;
    }
    return _localIdentifier;
}

- (NSTimeInterval)videoDuration {
    if (!_videoDuration) {
        if (self.asset) {
            return self.asset.duration;
        }
    }
    return _videoDuration;
}

+ (instancetype)photoModelWithPHAsset:(PHAsset *)asset {
    return [[self alloc] initWithPHAsset:asset];
}
+ (instancetype)videoCoverWithPHAsset:(PHAsset *)asset {
    return [[self alloc] initVideoCoverWithPHAsset:asset];
}
+ (instancetype)photoModelWithImage:(UIImage *)image {
    return [[self alloc] initWithImage:image];
}

+ (instancetype)photoModelWithImageURL:(NSURL *)imageURL {
    return [[self alloc] initWithImageURL:imageURL thumbURL:imageURL];
}

+ (instancetype)photoModelWithVideoURL:(NSURL *)videoURL videoTime:(NSTimeInterval)videoTime {
    return [[self alloc] initWithVideoURL:videoURL videoTime:videoTime];
}

+ (instancetype)photoModelWithVideoURL:(NSURL *)videoURL {
    return [[self alloc] initWithVideoURL:videoURL];
}

+ (instancetype)photoModelWithImageURL:(NSURL *)imageURL thumbURL:(NSURL *)thumbURL {
    return [[self alloc] initWithImageURL:imageURL thumbURL:thumbURL];
}
- (instancetype)initWithImageURL:(NSURL *)imageURL thumbURL:(NSURL *)thumbURL  {
    if (self = [super init]) {
        self.type = HXPhotoModelMediaTypeCameraPhoto;
        self.subType = HXPhotoModelMediaSubTypePhoto;
        self.thumbPhoto = [UIImage hx_imageNamed:@"hx_qz_photolist_picture_fail"];
        self.previewPhoto = self.thumbPhoto;
        self.imageSize = self.thumbPhoto.size;
        if (!imageURL && thumbURL) {
            imageURL = thumbURL;
        }else if (imageURL && !thumbURL) {
            thumbURL = imageURL;
        }
        self.networkPhotoUrl = imageURL;
        self.networkThumbURL = thumbURL;
        if (imageURL.absoluteString.length > 3 && [[imageURL.absoluteString substringFromIndex:imageURL.absoluteString.length - 3] isEqualToString:@"gif"]) {
            self.cameraPhotoType = HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif;
        }else {
            self.cameraPhotoType = HXPhotoModelMediaTypeCameraPhotoTypeNetWork;
        } 
        if (imageURL == thumbURL ||
            [imageURL.absoluteString isEqualToString:thumbURL.absoluteString]) {
            self.loadOriginalImage = YES;
        }
    }
    return self;
}

- (instancetype)initWithPHAsset:(PHAsset *)asset {
    if (self = [super init]) {
        if (asset.mediaType == PHAssetMediaTypeImage) {
            self.subType = HXPhotoModelMediaSubTypePhoto;
            self.type = HXPhotoModelMediaTypePhoto;
        }else if (asset.mediaType == PHAssetMediaTypeVideo) {
            self.subType = HXPhotoModelMediaSubTypeVideo;
            self.type = HXPhotoModelMediaTypeVideo;
            self.videoDuration = [[NSString stringWithFormat:@"%.0f",asset.duration] floatValue];
            NSString *time = [HXPhotoTools transformVideoTimeToString:self.videoDuration];
            self.videoTime = time;
        }
        self.asset = asset;
    }
    return self;
}
- (instancetype)initVideoCoverWithPHAsset:(PHAsset *)asset {
    if (self = [super init]) {
        self.subType = HXPhotoModelMediaSubTypePhoto;
        self.type = HXPhotoModelMediaTypePhoto;
        self.asset = asset;
    }
    return self;
}

- (instancetype)initWithVideoURL:(NSURL *)videoURL {
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:videoURL options:opts];
    float second = 0;
    second = urlAsset.duration.value / urlAsset.duration.timescale;
    return [self initWithVideoURL:videoURL videoTime:second];
}
- (instancetype)initWithVideoURL:(NSURL *)videoURL videoTime:(NSTimeInterval)videoTime {
    if (self = [super init]) {
        self.type = HXPhotoModelMediaTypeCameraVideo;
        self.subType = HXPhotoModelMediaSubTypeVideo;
        self.cameraVideoType = HXPhotoModelMediaTypeCameraVideoTypeLocal;
        self.videoURL = videoURL;
        if (videoTime <= 0) {
            videoTime = 1;
        }
        UIImage  *image = [UIImage hx_thumbnailImageForVideo:videoURL atTime:0.1f];
        NSString *time = [HXPhotoTools transformVideoTimeToString:videoTime];
        self.videoDuration = videoTime;
        self.videoURL = videoURL;
        self.videoTime = time;
        self.thumbPhoto = image;
        self.previewPhoto = image;
        self.imageSize = self.thumbPhoto.size;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        self.type = HXPhotoModelMediaTypeCameraPhoto;
        self.cameraPhotoType = HXPhotoModelMediaTypeCameraPhotoTypeLocal;
        self.subType = HXPhotoModelMediaSubTypePhoto;
        if (image.imageOrientation != UIImageOrientationUp) {
            image = [image hx_normalizedImage];
        }
        self.thumbPhoto = image;
        self.previewPhoto = image;
        self.imageSize = image.size;
    }
    return self;
}

- (CGSize)imageSize
{
    if (_imageSize.width == 0 || _imageSize.height == 0) {
        if (self.asset) {
            if (self.asset.pixelWidth == 0 || self.asset.pixelHeight == 0) {
                _imageSize = CGSizeMake(200, 200);
            }else {
                _imageSize = CGSizeMake(self.asset.pixelWidth, self.asset.pixelHeight);
            }
        }else {
            if (CGSizeEqualToSize(self.thumbPhoto.size, CGSizeZero)) {
                _imageSize = CGSizeMake(200, 200);
            }else {
                _imageSize = self.thumbPhoto.size;
            }
        }
    }
    return _imageSize;
}
- (NSString *)videoTime {
    if (!_videoTime) { 
        _videoTime = [HXPhotoTools transformVideoTimeToString:self.videoDuration];
    }
    return _videoTime;
}
- (CGSize)endImageSize
{
    if (_endImageSize.width == 0 || _endImageSize.height == 0) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.height;
        CGFloat imgWidth = self.imageSize.width;
        CGFloat imgHeight = self.imageSize.height;
        CGFloat w;
        CGFloat h;
        imgHeight = width / imgWidth * imgHeight;
        if (imgHeight > height) {
            w = height / self.imageSize.height * imgWidth;
            h = height;
        }else {
            w = width;
            h = imgHeight;
        }
        _endImageSize = CGSizeMake(w, h);
    }
    return _endImageSize;
}
- (CGSize)previewViewSize {
    if (_previewViewSize.width == 0 || _previewViewSize.height == 0) {
        _previewViewSize = self.endImageSize;
        CGFloat height = [UIScreen mainScreen].bounds.size.height;
        if (_previewViewSize.height > height + 20) {
            _previewViewSize.height = height;
        } 
    }
    return _previewViewSize;
}
- (CGSize)requestSize {
    if (_requestSize.width == 0 || _requestSize.height == 0) {
        
        CGFloat width = ([UIScreen mainScreen].bounds.size.width - 1 * self.rowCount - 1 ) / self.rowCount;
        CGSize size = CGSizeMake(width * self.clarityScale, width * self.clarityScale);
        
        _requestSize = size;
    }
    return _requestSize;
}
- (CGSize)dateBottomImageSize {
    if (_dateBottomImageSize.width == 0 || _dateBottomImageSize.height == 0) {
        CGFloat width = 0;
        CGFloat height = 50;
        CGFloat imgWidth = self.imageSize.width;
        CGFloat imgHeight = self.imageSize.height;
        if (imgHeight > height) {
            width = imgWidth * (height / imgHeight);
        }else {
            width = imgWidth * (imgHeight / height);
        }
        if (width < 50 / 16 * 9) {
            width = 50 / 16 * 9;
        }
        _dateBottomImageSize = CGSizeMake(width, height);
    }
    return _dateBottomImageSize;
}
- (NSString *)barTitle {
    if (!_barTitle) {
        if ([self.creationDate hx_isToday]) {
            _barTitle = [NSBundle hx_localizedStringForKey:@"今天"];
        }else if ([self.creationDate hx_isYesterday]) {
            _barTitle = [NSBundle hx_localizedStringForKey:@"昨天"];
        }else if ([self.creationDate hx_isSameWeek]) {
            _barTitle = [self.creationDate hx_getNowWeekday];
        }else if ([self.creationDate hx_isThisYear]) {
            HXPhotoLanguageType type = [HXPhotoCommon photoCommon].languageType;
            switch (type) {
                case HXPhotoLanguageTypeSc :
                case HXPhotoLanguageTypeTc :
                case HXPhotoLanguageTypeJa : {
                    // 中 / 日 / 繁
                    _barTitle = [NSString stringWithFormat:@"%@ %@",[self.creationDate hx_dateStringWithFormat:@"MM月dd日"],[self.creationDate hx_getNowWeekday]];
                } break;
                case HXPhotoLanguageTypeKo : {
                    // 韩语
                    _barTitle = [NSString stringWithFormat:@"%@ %@",[self.creationDate hx_dateStringWithFormat:@"MM월dd일"],[self.creationDate hx_getNowWeekday]];
                } break;
                case HXPhotoLanguageTypeEn : {
                    // 英文
                    _barTitle = [NSString stringWithFormat:@"%@ %@",[self.creationDate hx_dateStringWithFormat:@"MMM dd"],[self.creationDate hx_getNowWeekday]];
                } break;
                default : {
                    NSString *language = [NSLocale preferredLanguages].firstObject;
                    if ([language hasPrefix:@"zh"] ||
                               [language hasPrefix:@"ja"]) {
                        // 中 / 日 / 繁
                        _barTitle = [NSString stringWithFormat:@"%@ %@",[self.creationDate hx_dateStringWithFormat:@"MM月dd日"],[self.creationDate hx_getNowWeekday]];
                    }else if ([language hasPrefix:@"ko"]) {
                        // 韩语
                        _barTitle = [NSString stringWithFormat:@"%@ %@",[self.creationDate hx_dateStringWithFormat:@"MM월dd일"],[self.creationDate hx_getNowWeekday]];
                    } else {
                        // 英文
                        _barTitle = [NSString stringWithFormat:@"%@ %@",[self.creationDate hx_dateStringWithFormat:@"MMM dd"],[self.creationDate hx_getNowWeekday]];
                    }
                }break;
            }
        }else {
            HXPhotoLanguageType type = [HXPhotoCommon photoCommon].languageType;
            switch (type) {
                case HXPhotoLanguageTypeSc :
                case HXPhotoLanguageTypeTc :
                case HXPhotoLanguageTypeJa : {
                    // 中 / 日 / 繁
                    _barTitle = [self.creationDate hx_dateStringWithFormat:@"yyyy年MM月dd日"];
                } break;
                case HXPhotoLanguageTypeKo : {
                    // 韩语
                    _barTitle = [self.creationDate hx_dateStringWithFormat:@"yyyy년MM월dd일"];
                } break;
                case HXPhotoLanguageTypeEn : {
                    // 英文
                    _barTitle = [self.creationDate hx_dateStringWithFormat:@"MMM dd, yyyy"];
                } break;
                default : {
                    NSString *language = [NSLocale preferredLanguages].firstObject;
                    if ([language hasPrefix:@"zh"] ||
                        [language hasPrefix:@"ja"]) {
                        // 中 / 日 / 繁
                        _barTitle = [self.creationDate hx_dateStringWithFormat:@"yyyy年MM月dd日"];
                    }else if ([language hasPrefix:@"ko"]) {
                        // 韩语
                        _barTitle = [self.creationDate hx_dateStringWithFormat:@"yyyy년MM월dd일"];
                    } else {
                        // 英文
                        _barTitle = [self.creationDate hx_dateStringWithFormat:@"MMM dd, yyyy"];
                    }
                }break;
            }
        }
    }
    return _barTitle;
}
- (NSString *)barSubTitle {
    if (!_barSubTitle) {
        _barSubTitle = [self.creationDate hx_dateStringWithFormat:@"HH:mm"];
    }
    return _barSubTitle;
}
- (void)dealloc {
    if (self.iCloudRequestID) {
        if (self.iCloudDownloading) {
            [[PHImageManager defaultManager] cancelImageRequest:self.iCloudRequestID];
        }
    }
//    [self cancelImageRequest];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.type = [aDecoder decodeIntegerForKey:@"type"];
        self.subType = [aDecoder decodeIntegerForKey:@"subType"];
        if (self.type == HXPhotoModelMediaTypeCameraPhoto ||
            self.type == HXPhotoModelMediaTypeCameraVideo) {
            self.thumbPhoto = [aDecoder decodeObjectForKey:@"thumbPhoto"];
            self.previewPhoto = [aDecoder decodeObjectForKey:@"previewPhoto"];
        }
        self.localIdentifier = [aDecoder decodeObjectForKey:@"localIdentifier"];
        self.videoDuration = [aDecoder decodeFloatForKey:@"videoDuration"];
        self.selected = [aDecoder decodeBoolForKey:@"selected"];
        self.videoURL = [aDecoder decodeObjectForKey:@"videoURL"];
        self.networkPhotoUrl = [aDecoder decodeObjectForKey:@"networkPhotoUrl"];
        self.networkThumbURL = [aDecoder decodeObjectForKey:@"networkThumbURL"];
        self.creationDate = [aDecoder decodeObjectForKey:@"creationDate"];
        self.modificationDate = [aDecoder decodeObjectForKey:@"modificationDate"];
        self.location = [aDecoder decodeObjectForKey:@"location"];
        self.videoTime = [aDecoder decodeObjectForKey:@"videoTime"];
        self.selectIndexStr = [aDecoder decodeObjectForKey:@"videoTime"];
        self.cameraIdentifier = [aDecoder decodeObjectForKey:@"cameraIdentifier"];
        self.fileURL = [aDecoder decodeObjectForKey:@"fileURL"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (self.type == HXPhotoModelMediaTypeCameraPhoto ||
        self.type == HXPhotoModelMediaTypeCameraVideo) {
        [aCoder encodeObject:self.thumbPhoto forKey:@"thumbPhoto"];
        [aCoder encodeObject:self.previewPhoto forKey:@"previewPhoto"];
    }
    [aCoder encodeObject:self.localIdentifier forKey:@"localIdentifier"];
    [aCoder encodeInteger:self.type forKey:@"type"];
    [aCoder encodeInteger:self.subType forKey:@"subType"];
    [aCoder encodeFloat:self.videoDuration forKey:@"videoDuration"];
    [aCoder encodeBool:self.selected forKey:@"selected"];
    [aCoder encodeObject:self.videoURL forKey:@"videoURL"];
    [aCoder encodeObject:self.networkPhotoUrl forKey:@"networkPhotoUrl"];
    [aCoder encodeObject:self.networkThumbURL forKey:@"networkThumbURL"];
    [aCoder encodeObject:self.creationDate forKey:@"creationDate"];
    [aCoder encodeObject:self.modificationDate forKey:@"modificationDate"]; 
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeObject:self.videoTime forKey:@"videoTime"];
    [aCoder encodeObject:self.selectIndexStr forKey:@"selectIndexStr"];
    [aCoder encodeObject:self.cameraIdentifier forKey:@"cameraIdentifier"];
    [aCoder encodeObject:self.fileURL forKey:@"fileURL"];
}
#pragma mark - < Request >

+ (id)requestImageWithURL:(NSURL *)url progress:(void (^ _Nullable)(NSInteger, NSInteger))progress completion:(void (^ _Nullable)(UIImage * _Nullable, NSURL * _Nonnull, NSError * _Nullable))completion {
#if HasYYKitOrWebImage
    YYWebImageOperation *operation = [[YYWebImageManager sharedManager] requestImageWithURL:url options:0 progress:progress transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
        if (completion) {
            completion(image, url, error);
        }
    }];
    return operation;
#elif HasSDWebImage
    SDWebImageCombinedOperation *operation = [[SDWebImageManager sharedManager] loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        if (completion) {
            completion(image, url, error);
        }
    }];
    return operation;
#endif
    return nil;
}
+ (PHImageRequestID)requestThumbImageWithPHAsset:(PHAsset *)asset size:(CGSize)size completion:(void (^)(UIImage * _Nullable, PHAsset * _Nullable))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(result, asset);
            });
        }
    }];
}
- (PHImageRequestID)requestThumbImageCompletion:(HXModelImageSuccessBlock)completion {
    return [self requestThumbImageWithSize:self.requestSize completion:completion];
}

- (PHImageRequestID)requestThumbImageWithSize:(CGSize)size completion:(HXModelImageSuccessBlock)completion {
    if (self.type == HXPhotoModelMediaTypeCameraPhoto ||
        self.type == HXPhotoModelMediaTypeCameraVideo) {
        if (!self.networkPhotoUrl) {
            if (completion) completion(self.thumbPhoto, self, nil);
        }else {
            HXWeakSelf
            [HXPhotoModel requestImageWithURL:self.networkPhotoUrl progress:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, NSError * _Nullable error) {
                if (completion) completion(image, weakSelf, nil);
            }];
        }
        return 0;
    }
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    HXWeakSelf
    return [self requestImageWithOptions:option targetSize:size resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(result, weakSelf, info);
            });
        }
    }];
}
- (PHImageRequestOptions *)imageRequestOptionsWithDeliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.deliveryMode = deliveryMode;
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    return option;
}
- (PHImageRequestOptions *)imageHighQualityRequestOptions {
    return [self imageRequestOptionsWithDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
}
- (PHImageRequestID)requestPreviewImageWithSize:(CGSize)size
                             startRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                progressHandler:(HXModelProgressHandler)progressHandler
                                        success:(HXModelImageSuccessBlock)success
                                         failed:(HXModelFailedBlock)failed {
    HXWeakSelf
    if (self.type == HXPhotoModelMediaTypeCameraPhoto ||
        self.type == HXPhotoModelMediaTypeCameraVideo) {
        if (!self.networkPhotoUrl) {
            if (success) success(self.previewPhoto, self, nil);
        }else {
            if (startRequestICloud) startRequestICloud(0, self);
            [HXPhotoModel requestImageWithURL:self.networkPhotoUrl progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progressHandler) {
                        progressHandler((CGFloat)receivedSize / (CGFloat)expectedSize, weakSelf);
                    }
                });
            } completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (image) {
                        if (!weakSelf.thumbPhoto) weakSelf.thumbPhoto = image;
                        if (!weakSelf.previewPhoto) weakSelf.previewPhoto = image;
                        if (success) success(image, weakSelf, nil);
                    }else {
                        if (failed) failed(nil, weakSelf);
                    }
                });
            }];
        }
        return 0;
    }
//    [[PHImageManager defaultManager] cancelImageRequest:self.iCloudRequestID];
    
    PHImageRequestOptions *option = [self imageHighQualityRequestOptions];
    option.networkAccessAllowed = NO;
    self.iCloudDownloading = YES;
    PHImageRequestID requestId = [self requestImageWithOptions:option targetSize:size resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        [weakSelf requestDataWithResult:result info:info size:size resultClass:[UIImage class] orientation:0 audioMix:nil startRequestICloud:startRequestICloud progressHandler:progressHandler success:^(id result, NSDictionary *info, UIImageOrientation orientation, AVAudioMix *audioMix) {
            if (success) {
                if (!weakSelf.thumbPhoto) weakSelf.thumbPhoto = result;
                if (!weakSelf.previewPhoto) weakSelf.previewPhoto = result;
                success(result, weakSelf, info);
            }
        } failed:failed];
    }];
    self.iCloudRequestID = requestId;
    return requestId;
}
- (PHImageRequestID)requestLivePhotoWithSize:(CGSize)size
                          startRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                             progressHandler:(HXModelProgressHandler)progressHandler
                                     success:(HXModelLivePhotoSuccessBlock)success
                                      failed:(HXModelFailedBlock)failed {
//    [[PHImageManager defaultManager] cancelImageRequest:self.iCloudRequestID];
    
    PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.networkAccessAllowed = NO;
    PHImageRequestID requestId = 0;
    self.iCloudDownloading = YES;
    HXWeakSelf
    requestId = [[PHImageManager defaultManager] requestLivePhotoForAsset:self.asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        [weakSelf requestDataWithResult:livePhoto info:info size:size resultClass:[PHLivePhoto class] orientation:0 audioMix:nil startRequestICloud:startRequestICloud progressHandler:progressHandler success:^(id result, NSDictionary *info, UIImageOrientation orientation, AVAudioMix *audioMix) {
            if (success) {
                success(result, weakSelf, info);
            }
        } failed:failed];
    }];
    self.iCloudRequestID = requestId;
    return requestId;
}

- (PHImageRequestID)requestImageDataStartRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                       progressHandler:(HXModelProgressHandler)progressHandler
                                               success:(HXModelImageDataSuccessBlock)success
                                                failed:(HXModelFailedBlock)failed {
    
    HXWeakSelf
    if (self.type == HXPhotoModelMediaTypeCameraPhoto && self.networkPhotoUrl) {
#if HasYYKitOrWebImage
        [[YYWebImageManager sharedManager] requestImageWithURL:self.networkPhotoUrl options:0 progress:nil transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
            if (image) {
                if (success) {
                    NSData *imageData;
                    if (UIImagePNGRepresentation(image)) {
                        //返回为png图像。
                        imageData = UIImagePNGRepresentation(image);
                    }else {
                        //返回为JPEG图像。
                        imageData = UIImageJPEGRepresentation(image, 1.0);
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success(imageData, 0, weakSelf, nil);
                    });
                }
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed(nil, weakSelf);
                    }
                });
            }
        }];
        return 0;
#elif HasSDWebImage
        [[SDWebImageManager sharedManager] loadImageWithURL:self.networkPhotoUrl options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            if (data) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        success(data, 0, weakSelf, nil);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed(nil, weakSelf);
                    }
                });
            }
        }];
        return 0;
#endif
    }
//    [[PHImageManager defaultManager] cancelImageRequest:self.iCloudRequestID];
    
    PHImageRequestOptions *option = [self imageHighQualityRequestOptions];
    option.networkAccessAllowed = NO;
    if (self.type == HXPhotoModelMediaTypePhotoGif) {
        option.version = PHImageRequestOptionsVersionOriginal;
    }
    self.iCloudDownloading = YES;
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestImageDataForAsset:self.asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        [weakSelf requestDataWithResult:imageData info:info size:CGSizeZero resultClass:[NSData class] orientation:orientation audioMix:nil startRequestICloud:startRequestICloud progressHandler:progressHandler success:^(id result, NSDictionary *info, UIImageOrientation orientation, AVAudioMix *audioMix) {
            if (success) {
                success(result, orientation, weakSelf, info);
            }
        } failed:failed];
    }];
    self.iCloudRequestID = requestID;
    return requestID;
}

- (PHImageRequestID)requestAVAssetStartRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                     progressHandler:(HXModelProgressHandler)progressHandler
                                             success:(HXModelAVAssetSuccessBlock)success
                                              failed:(HXModelFailedBlock)failed {
    if (self.type == HXPhotoModelMediaTypeCameraVideo) {
        if (success) {
            AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
            success(asset, nil, self, nil);
        }
        return 0;
    }
//    [[PHImageManager defaultManager] cancelImageRequest:self.iCloudRequestID];
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
    options.networkAccessAllowed = NO;
    PHImageRequestID requestId = 0;
    self.iCloudDownloading = YES;
    HXWeakSelf
    requestId = [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        [weakSelf requestDataWithResult:asset info:info size:CGSizeZero resultClass:[AVAsset class] orientation:0 audioMix:audioMix startRequestICloud:startRequestICloud progressHandler:progressHandler success:^(id result, NSDictionary *info, UIImageOrientation orientation, AVAudioMix *audioMix) {
            if (success) {
                success(result, audioMix, weakSelf, info);
            }
        } failed:failed];
    }];
    self.iCloudRequestID = requestId;
    return requestId;
}
- (PHImageRequestID)requestAVAssetExportSessionStartRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                                  progressHandler:(HXModelProgressHandler)progressHandler
                                                          success:(HXModelAVExportSessionSuccessBlock)success
                                                           failed:(HXModelFailedBlock)failed {
    if (self.type == HXPhotoModelMediaTypeCameraVideo) {
        AVAssetExportSession *export = [AVAssetExportSession exportSessionWithAsset:[AVAsset assetWithURL:self.videoURL] presetName:AVAssetExportPresetHighestQuality];
        if (success) {
            success(export, self, nil);
        }
        return 0;
    }
//    [[PHImageManager defaultManager] cancelImageRequest:self.iCloudRequestID];
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
    options.networkAccessAllowed = NO;
    PHImageRequestID requestId = 0;
    self.iCloudDownloading = YES;
    
    HXWeakSelf
    requestId = [[PHImageManager defaultManager] requestExportSessionForVideo:self.asset options:options exportPreset:AVAssetExportPresetHighestQuality resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
        [weakSelf requestDataWithResult:exportSession info:info size:CGSizeZero resultClass:[AVAssetExportSession class] orientation:0 audioMix:nil startRequestICloud:startRequestICloud progressHandler:progressHandler success:^(id result, NSDictionary *info, UIImageOrientation orientation, AVAudioMix *audioMix) {
            if (success) {
                success(result, weakSelf, info);
            }
        } failed:failed];
    }];
    return requestId;
}

- (PHImageRequestID)requestAVPlayerItemStartRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                          progressHandler:(HXModelProgressHandler)progressHandler
                                                  success:(HXModelAVPlayerItemSuccessBlock)success
                                                   failed:(HXModelFailedBlock)failed {
    if (self.type == HXPhotoModelMediaTypeCameraVideo) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.videoURL];
        if (success) {
            success(playerItem, self, nil);
        }
        return 0;
    }
//    [[PHImageManager defaultManager] cancelImageRequest:self.iCloudRequestID];
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
    options.networkAccessAllowed = NO;
    PHImageRequestID requestId = 0;
    self.iCloudDownloading = YES;
    HXWeakSelf
    requestId = [[PHImageManager defaultManager] requestPlayerItemForVideo:self.asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
        [weakSelf requestDataWithResult:playerItem info:info size:CGSizeZero resultClass:[AVPlayerItem class] orientation:0 audioMix:nil startRequestICloud:startRequestICloud progressHandler:progressHandler success:^(id result, NSDictionary *info, UIImageOrientation orientation, AVAudioMix *audioMix) {
            if (success) {
                success(result, weakSelf, info);
            }
        } failed:failed];
    }];
    return requestId;
}

- (void)requestDataWithResult:(id)results
                         info:(NSDictionary *)info
                         size:(CGSize)size
                  resultClass:(Class)resultClass
                  orientation:(UIImageOrientation)orientation
                     audioMix:(AVAudioMix *)audioMix
           startRequestICloud:(HXModelStartRequestICloud)startRequestICloud
              progressHandler:(HXModelProgressHandler)progressHandler
                      success:(void (^)(id result, NSDictionary *info, UIImageOrientation orientation, AVAudioMix *audioMix))success
                       failed:(HXModelFailedBlock)failed {
    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
    if (downloadFinined && results) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            self.isICloud = NO;
            self.iCloudDownloading = NO;
            if (success) {
                success(results, info, orientation, audioMix);
            }
        });
        return;
    }else {
        HXWeakSelf
        if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
            PHImageRequestID iCloudRequestId = 0;
            if ([resultClass isEqual:[UIImage class]]) {
                PHImageRequestOptions *iCloudOption = [self imageHighQualityRequestOptions];
                iCloudOption.networkAccessAllowed = YES;
                iCloudOption.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.iCloudProgress = progress;
                        if (progressHandler) {
                            progressHandler(progress, weakSelf);
                        }
                    });
                };
                iCloudRequestId = [weakSelf requestImageWithOptions:iCloudOption targetSize:size resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && result) {
                        dispatch_async(dispatch_get_main_queue(), ^{
//                            weakSelf.isICloud = NO;
                            weakSelf.iCloudDownloading = NO;
                            if (success) {
                                success(result, info, 0, nil);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                                weakSelf.iCloudDownloading = NO;
                            }
                            if (failed) {
                                failed(info, weakSelf);
                            }
                        });
                    }
                }];
            }else if ([resultClass isEqual:[PHLivePhoto class]]) {
                PHLivePhotoRequestOptions *iCloudOption = [[PHLivePhotoRequestOptions alloc] init];
                iCloudOption.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                iCloudOption.networkAccessAllowed = YES;
                iCloudOption.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.iCloudProgress = progress;
                        if (progressHandler) {
                            progressHandler(progress, weakSelf);
                        }
                    });
                };
                iCloudRequestId = [[PHImageManager defaultManager] requestLivePhotoForAsset:self.asset targetSize:size contentMode:PHImageContentModeAspectFill options:iCloudOption resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && livePhoto) {
                        dispatch_async(dispatch_get_main_queue(), ^{
//                            weakSelf.isICloud = NO;
                            weakSelf.iCloudDownloading = NO;
                            if (success) {
                                success(livePhoto, info, 0, nil);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                                weakSelf.iCloudDownloading = NO;
                            }
                            if (failed) {
                                failed(info, weakSelf);
                            }
                        });
                    }
                }];
            }else if ([resultClass isEqual:[NSData class]]) {
                PHImageRequestOptions *iCloudOption = [self imageHighQualityRequestOptions];
                iCloudOption.networkAccessAllowed = YES;
                if (self.type == HXPhotoModelMediaTypePhotoGif) {
                    iCloudOption.version = PHImageRequestOptionsVersionOriginal;
                }
                iCloudOption.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.iCloudProgress = progress;
                        if (progressHandler) {
                            progressHandler(progress, weakSelf);
                        }
                    });
                };
                iCloudRequestId = [[PHImageManager defaultManager] requestImageDataForAsset:self.asset options:iCloudOption resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && imageData) {
                        dispatch_async(dispatch_get_main_queue(), ^{
//                            weakSelf.isICloud = NO;
                            weakSelf.iCloudDownloading = NO;
                            if (success) {
                                success(imageData, info, orientation, nil);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                                weakSelf.iCloudDownloading = NO;
                            }
                            if (failed) {
                                failed(info, weakSelf);
                            }
                        });
                    }
                }];
            }else if ([resultClass isEqual:[AVAsset class]]) {
                PHVideoRequestOptions *iCloudOptions = [[PHVideoRequestOptions alloc] init];
//                iCloudOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
                iCloudOptions.networkAccessAllowed = YES;
                iCloudOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.iCloudProgress = progress;
                        if (progressHandler) {
                            progressHandler(progress, weakSelf);
                        }
                    });
                };
                iCloudRequestId = [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:iCloudOptions resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && asset) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            weakSelf.iCloudDownloading = NO;
//                            weakSelf.isICloud = NO;
                            if (success) {
                                success(asset, info, 0, audioMix);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                                weakSelf.iCloudDownloading = NO;
                            }
                            if (failed) {
                                failed(info, weakSelf);
                            }
                        });
                    }
                }];
            }else if ([resultClass isEqual:[AVAssetExportSession class]]) {
                PHVideoRequestOptions *iCloudOptions = [[PHVideoRequestOptions alloc] init];
//                iCloudOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
                iCloudOptions.networkAccessAllowed = YES;
                iCloudOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.iCloudProgress = progress;
                        if (progressHandler) {
                            progressHandler(progress, weakSelf);
                        }
                    });
                };
                iCloudRequestId = [[PHImageManager defaultManager] requestExportSessionForVideo:self.asset options:iCloudOptions exportPreset:AVAssetExportPresetHighestQuality resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && exportSession) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            weakSelf.iCloudDownloading = NO;
//                            weakSelf.isICloud = NO;
                            if (success) {
                                success(exportSession, info, 0, nil);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                                weakSelf.iCloudDownloading = NO;
                            }
                            if (failed) {
                                failed(info, weakSelf);
                            }
                        });
                    }
                }];
            }else if ([resultClass isEqual:[AVPlayerItem class]]) {
                PHVideoRequestOptions *iCloudOptions = [[PHVideoRequestOptions alloc] init];
//                iCloudOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
                iCloudOptions.networkAccessAllowed = YES;
                iCloudOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.iCloudProgress = progress;
                        if (progressHandler) {
                            progressHandler(progress, weakSelf);
                        }
                    });
                };
                iCloudRequestId = [[PHImageManager defaultManager] requestPlayerItemForVideo:self.asset options:iCloudOptions resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && playerItem) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            weakSelf.iCloudDownloading = NO;
//                            weakSelf.isICloud = NO;
                            if (success) {
                                success(playerItem, info, 0, nil);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                                weakSelf.iCloudDownloading = NO;
                            }
                            if (failed) {
                                failed(info, weakSelf);
                            }
                        });
                    }
                }];
            }else if ([resultClass isEqual:[PHContentEditingInput class]]) {
                
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.iCloudRequestID = iCloudRequestId;
                if (startRequestICloud) {
                    startRequestICloud(iCloudRequestId, weakSelf);
                }
            });
            return;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
            self.iCloudDownloading = NO;
        }
        if (failed) {
            failed(info, self);
        }
    });
}

- (PHImageRequestID)requestImageWithOptions:(PHImageRequestOptions *)options targetSize:(CGSize)targetSize resultHandler:(void (^)(UIImage *__nullable result, NSDictionary *__nullable info))resultHandler {
    
    return [[PHImageManager defaultManager] requestImageForAsset:self.asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (resultHandler) {
            resultHandler(result, info);
        }
    }];
}
- (void)exportVideoWithPresetName:(NSString *)presetName
               startRequestICloud:(HXModelStartRequestICloud)startRequestICloud
            iCloudProgressHandler:(HXModelProgressHandler)iCloudProgressHandler
            exportProgressHandler:(HXModelExportVideoProgressHandler)exportProgressHandler
                          success:(HXModelExportVideoSuccessBlock)success
                           failed:(HXModelFailedBlock)failed {
    if (self.type == HXPhotoModelMediaTypeCameraVideo) {
        if (success) {
            success(self.videoURL, self);
        }
        return;
    }
    HXWeakSelf
    [self requestAVAssetStartRequestICloud:startRequestICloud progressHandler:iCloudProgressHandler success:^(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info) {
        HXStrongSelf
        NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
        if ([presets containsObject:presetName]) {
            AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:presetName];
            NSString *fileName = [[NSString hx_fileName] stringByAppendingString:@".mp4"];
            NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
            NSURL *videoURL = [NSURL fileURLWithPath:fullPathToFile];
            session.outputURL = videoURL;
            session.shouldOptimizeForNetworkUse = YES;
            
            NSArray *supportedTypeArray = session.supportedFileTypes;
            if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
                session.outputFileType = AVFileTypeMPEG4;
            } else if (supportedTypeArray.count == 0) {
                if (failed) {
                    failed(nil, model);
                }
                if (HXShowLog) NSSLog(@"不支持导入该类型视频");
                return;
            }else {
                session.outputFileType = [supportedTypeArray objectAtIndex:0];
            }
            
            NSTimer *timer = [NSTimer hx_scheduledTimerWithTimeInterval:0.1f block:^{
                if (exportProgressHandler) {
                    exportProgressHandler(session.progress, strongSelf);
                }
            } repeats:YES];
            
            [session exportAsynchronouslyWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([session status] == AVAssetExportSessionStatusCompleted) {
                        if (HXShowLog) NSSLog(@"视频导出完成");
                        [timer invalidate];
                        if (success) {
                            success(videoURL, strongSelf);
                        }
                    }else if ([session status] == AVAssetExportSessionStatusFailed){
                        if (HXShowLog) NSSLog(@"视频导出失败");
                        [timer invalidate];
                        if (failed) {
                            failed(nil, strongSelf);
                        }
                    }else if ([session status] == AVAssetExportSessionStatusCancelled) {
                        if (HXShowLog) NSSLog(@"视频导出被取消");
                        [timer invalidate];
                        if (failed) {
                            failed(nil, strongSelf);
                        }
                    }
                });
            }];
        }else {
            if (HXShowLog) NSSLog(@"该设备不支持:%@",presetName);
        }
    } failed:failed];
//    [self requestAVAssetExportSessionStartRequestICloud:startRequestICloud
//                                        progressHandler:iCloudProgressHandler
//                                             completion:^(AVAssetExportSession *assetExportSession, HXPhotoModel *model, NSDictionary *info) {
//
//        NSString *fileName = [[NSString hx_fileName] stringByAppendingString:@".mp4"];
//        NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
//        NSURL *videoURL = [NSURL fileURLWithPath:fullPathToFile];
//        assetExportSession.outputURL = videoURL;
//        assetExportSession.shouldOptimizeForNetworkUse = YES;
//
//        NSArray *supportedTypeArray = assetExportSession.supportedFileTypes;
//        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
//            assetExportSession.outputFileType = AVFileTypeMPEG4;
//        } else if (supportedTypeArray.count == 0) {
//            if (failed) {
//                failed(nil, model);
//            }
//            if (HXShowLog) NSSLog(@"不支持导入该类型视频");
//            return;
//        }else {
//            assetExportSession.outputFileType = [supportedTypeArray objectAtIndex:0];
//        }
//
//        NSTimer *timer = [NSTimer hx_scheduledTimerWithTimeInterval:0.1f block:^{
//            if (exportProgressHandler) {
//                exportProgressHandler(assetExportSession.progress, weakSelf);
//            }
//        } repeats:YES];
//
//        [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if ([assetExportSession status] == AVAssetExportSessionStatusCompleted) {
//                    if (HXShowLog) NSSLog(@"视频导出完成");
//                    [timer invalidate];
//                    if (success) {
//                        success(videoURL, weakSelf);
//                    }
//                }else if ([assetExportSession status] == AVAssetExportSessionStatusFailed){
//                    if (HXShowLog) NSSLog(@"视频导出失败");
//                    [timer invalidate];
//                    if (failed) {
//                        failed(nil, weakSelf);
//                    }
//                }else if ([assetExportSession status] == AVAssetExportSessionStatusCancelled) {
//                    if (HXShowLog) NSSLog(@"视频导出被取消");
//                    [timer invalidate];
//                    if (failed) {
//                        failed(nil, weakSelf);
//                    }
//                }
//            });
//        }];
//    } failed:failed];
}
- (PHContentEditingInputRequestID)requestImageURLStartRequestICloud:(void (^)(PHContentEditingInputRequestID iCloudRequestId, HXPhotoModel *model))startRequestICloud
                                                     progressHandler:(HXModelProgressHandler)progressHandler
                                                             success:(HXModelImageURLSuccessBlock)success
                                                              failed:(HXModelFailedBlock)failed {
    if (self.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (failed) {
            failed(nil, self);
        }
//        if (self.networkPhotoUrl) {
//            if (success) {
//                success(self.networkPhotoUrl, self, nil);
//            }
//        }else {
//            //
//
//        }
        return 0;
    }
    
    PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
    options.networkAccessAllowed = NO;
    HXWeakSelf
    return [self.asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
        BOOL downloadFinined = (![[info objectForKey:PHContentEditingInputCancelledKey] boolValue] && ![info objectForKey:PHContentEditingInputErrorKey]);
        
        if (downloadFinined && contentEditingInput.fullSizeImageURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    success(contentEditingInput.fullSizeImageURL, weakSelf, info);
                }
            });
        }else {
            if ([[info objectForKey:PHContentEditingInputResultIsInCloudKey] boolValue] && ![[info objectForKey:PHContentEditingInputCancelledKey] boolValue] && ![info objectForKey:PHContentEditingInputErrorKey]) {
                PHContentEditingInputRequestOptions *iCloudOptions = [[PHContentEditingInputRequestOptions alloc] init];
                iCloudOptions.networkAccessAllowed = YES;
                iCloudOptions.progressHandler = ^(double progress, BOOL * _Nonnull stop) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress, weakSelf);
                        }
                    });
                };
                
                PHContentEditingInputRequestID iCloudRequestID = [weakSelf.asset requestContentEditingInputWithOptions:iCloudOptions completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
                    BOOL downloadFinined = (![[info objectForKey:PHContentEditingInputCancelledKey] boolValue] && ![info objectForKey:PHContentEditingInputErrorKey]);
                    
                    if (downloadFinined && contentEditingInput.fullSizeImageURL) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (success) {
                                success(contentEditingInput.fullSizeImageURL, weakSelf, nil);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failed) {
                                failed(info, weakSelf);
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (startRequestICloud) {
                        startRequestICloud(iCloudRequestID, weakSelf);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed(info, weakSelf);
                    }
                });
            }
        }
    }];
}
@end

@implementation HXPhotoDateModel
- (NSString *)dateString {
    if (!_dateString) {
        NSDateComponents *modelComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay   |
                                        NSCalendarUnitMonth |
                                        NSCalendarUnitYear
                                                                       fromDate:self.date];
        NSUInteger modelMonth = [modelComponents month];
        NSUInteger modelYear  = [modelComponents year];
        NSUInteger modelDay   = [modelComponents day];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%lu-%lu-%lu",
                                                      (unsigned long)modelYear,
                                                      (unsigned long)modelMonth,
                                                      (unsigned long)modelDay]];
        
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay   |
                                        NSCalendarUnitMonth |
                                        NSCalendarUnitYear
                                                                       fromDate:[NSDate date]];
        NSUInteger month = [components month];
        NSUInteger year  = [components year];
        NSUInteger day   = [components day];
        
        HXPhotoLanguageType type = [HXPhotoCommon photoCommon].languageType;
        NSLocale *locale;
        switch (type) {
            case HXPhotoLanguageTypeEn:
                locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
                break;
            case HXPhotoLanguageTypeSc:
                locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-Hans"];
                break;
            case HXPhotoLanguageTypeTc:
                locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-Hant"];
                break;
            case HXPhotoLanguageTypeJa:
                locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ja"];
                break;
            case HXPhotoLanguageTypeKo:
                locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ko"];
                break;
            default: {
                NSString *localization = [NSBundle mainBundle].preferredLocalizations.firstObject;
                locale = [[NSLocale alloc] initWithLocaleIdentifier:localization];
            }
                break;
        }
        
        dateFormatter.locale    = locale;
        dateFormatter.dateStyle = kCFDateFormatterLongStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        
        if (year == modelYear) {
            NSString *longFormatWithoutYear = [NSDateFormatter dateFormatFromTemplate:@"MMMM d"
                                                                              options:0
                                                                               locale:locale];
            [dateFormatter setDateFormat:longFormatWithoutYear];
        }
        NSString *resultString = [dateFormatter stringFromDate:date];
        
        if (year == modelYear && month == modelMonth)
        {
            if (day == modelDay)
            {
                resultString = [NSBundle hx_localizedStringForKey:@"今天"];
            }
            else if (day - 1 == modelDay)
            {
                resultString = [NSBundle hx_localizedStringForKey:@"昨天"];
            }else if ([self.date hx_isSameWeek]) {
                resultString = [self.date hx_getNowWeekday];
            }
        }
        _dateString = resultString;
    }
    return _dateString;
}
- (NSMutableArray *)locationList {
    if (!_locationList) {
        _locationList = [NSMutableArray array];
    }
    return _locationList;
}

@end
