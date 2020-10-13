//
//  HXPhotoModel.m
//  HXPhotoPicker-Demo
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
#import <SDWebImage/SDImageCache.h>
#elif __has_include("UIImageView+WebCache.h")
#import "UIImageView+WebCache.h"
#import "SDWebImageManager.h"
#import "SDImageCache.h"
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

#import "HXMECancelBlock.h"

#import "HXPhotoEdit.h"

@implementation HXPhotoModel
- (void)setSelectIndexStr:(NSString *)selectIndexStr {
    _selectIndexStr = selectIndexStr;
    self.selectedIndex = selectIndexStr.integerValue - 1;
}
- (NSUInteger)assetByte {
    if (_assetByte > 0) {
        return _assetByte;
    }
    NSUInteger byte = 0;
    if (self.photoEdit) {
        NSData *imageData = HX_UIImagePNGRepresentation(self.photoEdit.editPreviewImage);
        if (!imageData) {
            //返回为png图像。
            imageData = HX_UIImageJPEGRepresentation(self.photoEdit.editPreviewImage);
        }
        byte = imageData.length;
        _assetByte = byte;
        return _assetByte;
    }
    if (self.asset) {
        if (self.type == HXPhotoModelMediaTypeLivePhoto) {
            NSArray *resources = [PHAssetResource assetResourcesForAsset:self.asset];
            for (PHAssetResource *resource in resources) {
                id fileSize = [resource valueForKey:@"fileSize"];
                if (fileSize && ![fileSize isKindOfClass:[NSNull class]]) {
                    byte += [fileSize unsignedIntegerValue];
                }
            }
        }else {
            id fileSize = [[[PHAssetResource assetResourcesForAsset:self.asset] firstObject] valueForKey:@"fileSize"];
            if (fileSize && ![fileSize isKindOfClass:[NSNull class]]) {
                byte = [fileSize unsignedIntegerValue];
            }
        }
    }else {
        if (self.type == HXPhotoModelMediaTypeCameraPhoto) {
            if (self.networkPhotoUrl || self.networkThumbURL) {
                byte = 0;
            }else {
//                NSData *imageData;
                NSData *imageData = HX_UIImagePNGRepresentation(self.photoEdit.editPreviewImage);
                if (!imageData) {
                    //返回为png图像。
                    imageData = HX_UIImageJPEGRepresentation(self.photoEdit.editPreviewImage);
                }
//                if (UIImagePNGRepresentation(self.thumbPhoto)) {
//                    //返回为png图像。
//                    imageData = UIImagePNGRepresentation(self.thumbPhoto);
//                }else {
//                    //返回为JPEG图像。
//                    imageData = UIImageJPEGRepresentation(self.thumbPhoto, 0.7);
//                }
                byte = imageData.length;
            }
        }else if (self.type == HXPhotoModelMediaTypeCameraVideo) {
            if (self.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                byte = 0;
            }else {
                AVURLAsset* urlAsset = [AVURLAsset assetWithURL:self.videoURL];
                NSNumber *size;
                [urlAsset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
                byte = size.unsignedIntegerValue;
            }
        }
    }
    return byte;
}
- (HXPhotoModelFormat)photoFormat {
    if (self.subType == HXPhotoModelMediaSubTypePhoto) {
        if (self.photoEdit) {
            return HXPhotoModelFormatJPG;
        }
        if (self.asset) {
            if (self.type == HXPhotoModelMediaTypePhotoGif) {
                return HXPhotoModelFormatGIF;
            }
            if ([[self.asset valueForKey:@"filename"] hasSuffix:@"PNG"]) {
                return HXPhotoModelFormatPNG;
            }
            if ([[self.asset valueForKey:@"filename"] hasSuffix:@"JPG"]) {
                return HXPhotoModelFormatJPG;
            }
            if ([[self.asset valueForKey:@"filename"] hasSuffix:@"HEIC"]) {
                return HXPhotoModelFormatHEIC;
            }
            if ([[self.asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                return HXPhotoModelFormatGIF;
            }
        }else {
            if (self.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalGif ||
                self.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif) {
                    return HXPhotoModelFormatGIF;
            }
            if (self.thumbPhoto) {
                if (UIImagePNGRepresentation(self.thumbPhoto)) {
                    return HXPhotoModelFormatPNG;
                }else {
                    return HXPhotoModelFormatJPG;
                }
            }
            if (self.networkPhotoUrl) {
                if ([[self.networkPhotoUrl.absoluteString lowercaseString] hasSuffix:@"png"]) {
                    return HXPhotoModelFormatPNG;
                }
                if ([[self.networkPhotoUrl.absoluteString lowercaseString] hasSuffix:@"jpg"]) {
                    return HXPhotoModelFormatJPG;
                }
                if ([[self.networkPhotoUrl.absoluteString lowercaseString] hasSuffix:@"gif"]) {
                    return HXPhotoModelFormatGIF;
                }
            }
        }
    }
    return HXPhotoModelFormatUnknown;
}
- (BOOL)isEqualToPhotoModel:(HXPhotoModel *)photoModel {
    if (!photoModel) {
        return NO;
    }
    if (self == photoModel ){
        return YES;
    }
    
    if (self.localIdentifier &&
        photoModel.localIdentifier &&
        [self.localIdentifier isEqualToString:photoModel.localIdentifier]) {
        return YES;
    }
    if (self.thumbPhoto && photoModel.thumbPhoto &&
        self.thumbPhoto == photoModel.thumbPhoto) {
        return YES;
    }
    if (self.previewPhoto && photoModel.previewPhoto &&
        self.previewPhoto == photoModel.previewPhoto) {
        return YES;
    }
    if (self.thumbPhoto && photoModel.previewPhoto &&
        self.thumbPhoto == photoModel.previewPhoto) {
        return YES;
    }
    if (self.previewPhoto && photoModel.thumbPhoto &&
        self.previewPhoto == photoModel.thumbPhoto) {
        return YES;
    }
    if (self.videoURL && photoModel.videoURL &&
        [self.videoURL.absoluteString isEqualToString:photoModel.videoURL.absoluteString]) {
        return YES;
    }
    if (self.networkPhotoUrl && photoModel.networkPhotoUrl &&
        [self.networkPhotoUrl.absoluteString isEqualToString:photoModel.networkPhotoUrl.absoluteString]) {
        return YES;
    }
    if (self.livePhotoVideoURL && photoModel.livePhotoVideoURL &&
        [self.livePhotoVideoURL.absoluteString isEqualToString:photoModel.livePhotoVideoURL.absoluteString]) {
        return YES;
    }
    return NO;
}


/// 重写 isEqual 方法 会因为 isEqualToPhotoModel 这个在选择照片的时候导致一点点卡顿所以屏蔽
/// 想要判断两个model是否相容请在需要的时候调用 isEqualToPhotoModel 方法来判断
//- (BOOL)isEqual:(id)object {
//    if (self == object) {
//        return YES;
//    }
//    if (![self isKindOfClass:[HXPhotoModel class]]) {
//        return NO;
//    }
//    return [self isEqualToPhotoModel:object];
//}

- (NSDate *)creationDate {
    if (self.type == HXPhotoModelMediaTypeCameraPhoto || self.type == HXPhotoModelMediaTypeCameraVideo) {
        return _creationDate ?: [NSDate date];
    }
    if (self.asset) {
        return [self.asset valueForKey:@"creationDate"];
    }
    return _creationDate;
}

- (NSDate *)modificationDate {
    if (self.type == HXPhotoModelMediaTypeCameraPhoto || self.type == HXPhotoModelMediaTypeCameraVideo) {
            return [NSDate date];
    }
    return [self.asset valueForKey:@"modificationDate"];
} 
- (CLLocation *)location {
    if (self.asset) {
        return [self.asset valueForKey:@"location"];
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

- (UIImage *)thumbPhoto {
    if (self.photoEdit) {
        return self.photoEdit.editPreviewImage;
    }
    return _thumbPhoto;
}
- (UIImage *)previewPhoto {
    if (self.photoEdit) {
        return self.photoEdit.editPreviewImage;
    }
    return _previewPhoto;
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

+ (instancetype)photoModelWithNetworkVideoURL:(NSURL *)videoURL videoCoverURL:(NSURL *)videoCoverURL videoDuration:(NSTimeInterval)videoDuration {
    return [[self alloc] initWithNetworkVideoURL:videoURL videoCoverURL:videoCoverURL videoDuration:videoDuration];
}

+ (instancetype _Nullable)photoModelWithLivePhotoImage:(UIImage * _Nullable)image
                                              videoURL:(NSURL * _Nullable)videoURL {
    return [[self alloc] initLivePhotoWithImage:image videoURL:videoURL];
}

+ (instancetype _Nullable)photoModelWithLivePhotoNetWorkImage:(NSURL * _Nullable)imageURL
                                              netWorkVideoURL:(NSURL * _Nullable)videoURL {
    return [[self alloc] initLivePhotoModelWithNetWorkImage:imageURL netWorkVideoURL:videoURL];
}

- (instancetype _Nullable)initLivePhotoModelWithNetWorkImage:(NSURL * _Nullable)imageURL
                                             netWorkVideoURL:(NSURL * _Nullable)videoURL {
    if (self = [super init]) {
        self.type = HXPhotoModelMediaTypeCameraPhoto;
        self.subType = HXPhotoModelMediaSubTypePhoto;
        self.cameraPhotoType = HXPhotoModelMediaTypeCameraPhotoTypeNetWorkLivePhoto;
        self.networkPhotoUrl = imageURL;
        self.networkThumbURL = imageURL;
        self.livePhotoVideoURL = videoURL;
        self.loadOriginalImage = YES;
        self.thumbPhoto = [UIImage hx_imageNamed:@"hx_qz_photolist_picture_fail"];
        self.previewPhoto = self.thumbPhoto;
        self.imageSize = self.thumbPhoto.size;
    }
    return self;
}

- (instancetype)initLivePhotoWithImage:(UIImage * _Nullable)image
                              videoURL:(NSURL * _Nullable)videoURL {
    if (self = [super init]) {
        self.type = HXPhotoModelMediaTypeCameraPhoto;
        self.subType = HXPhotoModelMediaSubTypePhoto;
        self.cameraPhotoType = HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto;
        self.thumbPhoto = image;
        self.previewPhoto = image;
        self.videoURL = videoURL;
        self.imageSize = self.thumbPhoto.size;
    }
    return self;
}

- (instancetype)initWithNetworkVideoURL:(NSURL *)videoURL videoCoverURL:(NSURL *)videoCoverURL videoDuration:(NSTimeInterval)videoDuration {
    if (self = [super init]) {
        self.type = HXPhotoModelMediaTypeCameraVideo;
        self.subType = HXPhotoModelMediaSubTypeVideo;
        self.cameraVideoType = HXPhotoModelMediaTypeCameraVideoTypeNetWork;
        if (videoDuration <= 0) {
            videoDuration = 1;
        }
        NSString *time = [HXPhotoTools transformVideoTimeToString:videoDuration];
        self.videoDuration = videoDuration;
        self.videoURL = videoURL;
        self.videoTime = time;
        self.thumbPhoto = [UIImage hx_imageNamed:@"hx_qz_photolist_picture_fail"];
        self.previewPhoto = self.thumbPhoto;
        self.imageSize = self.thumbPhoto.size;
        self.networkPhotoUrl = videoCoverURL;
        self.networkThumbURL = videoCoverURL;
        self.loadOriginalImage = YES;
    }
    return self;
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
        if (image.images.count) {
            self.cameraPhotoType = HXPhotoModelMediaTypeCameraPhotoTypeLocalGif;
        }else {
            self.cameraPhotoType = HXPhotoModelMediaTypeCameraPhotoTypeLocal;
        }
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
- (void)setPhotoEdit:(HXPhotoEdit *)photoEdit {
    _photoEdit = photoEdit;
    if (!photoEdit) {
        _imageSize = CGSizeZero;
    }
}
- (CGSize)imageSize {
    if (self.photoEdit) {
        _imageSize = self.photoEdit.editPreviewImage.size;
    }
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
        NSThread *thread = [NSThread currentThread];
        UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
        if (thread.isMainThread) {
            orientation = [[UIApplication sharedApplication] statusBarOrientation];
        }
        if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
            w = height / self.imageSize.height * imgWidth;
            h = height;
        }else {
            imgHeight = width / imgWidth * imgHeight;
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
        if ([HXPhotoCommon photoCommon].isHapticTouch) {
            if (_previewViewSize.height > height * 0.6f) {
                _previewViewSize.height = height * 0.6f;
            }
        }else {
            if (_previewViewSize.height > height + 20) {
                _previewViewSize.height = height;
            }
        }
    }
    return _previewViewSize;
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
        self.imageURL = [aDecoder decodeObjectForKey:@"imageURL"];
        self.livePhotoVideoURL = [aDecoder decodeObjectForKey:@"livePhotoVideoURL"];
        self.networkPhotoUrl = [aDecoder decodeObjectForKey:@"networkPhotoUrl"];
        self.networkThumbURL = [aDecoder decodeObjectForKey:@"networkThumbURL"];
        self.creationDate = [aDecoder decodeObjectForKey:@"creationDate"];
        self.modificationDate = [aDecoder decodeObjectForKey:@"modificationDate"];
        self.location = [aDecoder decodeObjectForKey:@"location"];
        self.videoTime = [aDecoder decodeObjectForKey:@"videoTime"];
        self.selectIndexStr = [aDecoder decodeObjectForKey:@"videoTime"];
        self.cameraIdentifier = [aDecoder decodeObjectForKey:@"cameraIdentifier"];
        self.cameraPhotoType = [aDecoder decodeIntegerForKey:@"cameraPhotoType"];
        self.cameraVideoType = [aDecoder decodeIntegerForKey:@"cameraVideoType"];
        self.photoEdit = [aDecoder decodeObjectForKey:@"photoEdit"];
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
    [aCoder encodeInteger:self.cameraPhotoType forKey:@"cameraPhotoType"];
    [aCoder encodeInteger:self.cameraVideoType forKey:@"cameraVideoType"];
    [aCoder encodeFloat:self.videoDuration forKey:@"videoDuration"];
    [aCoder encodeBool:self.selected forKey:@"selected"];
    [aCoder encodeObject:self.videoURL forKey:@"videoURL"];
    [aCoder encodeObject:self.imageURL forKey:@"imageURL"];
    [aCoder encodeObject:self.livePhotoVideoURL forKey:@"livePhotoVideoURL"];
    [aCoder encodeObject:self.networkPhotoUrl forKey:@"networkPhotoUrl"];
    [aCoder encodeObject:self.networkThumbURL forKey:@"networkThumbURL"];
    [aCoder encodeObject:self.creationDate forKey:@"creationDate"];
    [aCoder encodeObject:self.modificationDate forKey:@"modificationDate"]; 
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeObject:self.videoTime forKey:@"videoTime"];
    [aCoder encodeObject:self.selectIndexStr forKey:@"selectIndexStr"];
    [aCoder encodeObject:self.cameraIdentifier forKey:@"cameraIdentifier"];
    [aCoder encodeObject:self.photoEdit forKey:@"photoEdit"];
}
#pragma mark - < Request >

+ (id)requestImageWithURL:(NSURL *)url progress:(void (^ _Nullable)(NSInteger, NSInteger))progress completion:(void (^ _Nullable)(UIImage * _Nullable, NSURL * _Nullable, NSError * _Nullable))completion {
#if HasSDWebImage
    SDWebImageCombinedOperation *operation = [[SDWebImageManager sharedManager] loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        if (completion) {
            completion(image, url, error);
        }
    }];
    return operation;
#elif HasYYKitOrWebImage
    YYWebImageOperation *operation = [[YYWebImageManager sharedManager] requestImageWithURL:url options:0 progress:progress transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
        if (completion) {
            completion(image, url, error);
        }
    }];
    return operation;
#endif
    return nil;
}
+ (CGSize)getAssetTargetSizeWithAsset:(PHAsset *)asset width:(CGFloat)width {
    CGFloat initialWidth = width;
    CGFloat scale;
    if (asset.pixelWidth < width) {
        scale = 0.5f;
        width = asset.pixelWidth * 0.5f;
    }else {
        scale = asset.pixelWidth / width;
    }
    CGFloat height = asset.pixelHeight / scale;
    CGFloat sixteenHeight = width / 9 * 20;
    if (height > sixteenHeight) {
        width = sixteenHeight / height * width;
        height = sixteenHeight;
    }
    if (height < initialWidth) {
        width = initialWidth / height * width;
        height = initialWidth;
    }
    CGSize size = CGSizeMake(width, height);
    return size;
}
+ (PHImageRequestID)requestThumbImageWithPHAsset:(PHAsset *)asset width:(CGFloat)width completion:(void (^)(UIImage * _Nullable, PHAsset * _Nullable))completion {
    if (!asset) {
        if (completion) {
            completion(nil, nil);
        }
        return 0;
    }
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:[self getAssetTargetSizeWithAsset:asset width:width] contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(result, asset);
            });
        }
    }];
}
- (PHImageRequestID)requestThumbImageCompletion:(HXModelImageSuccessBlock)completion {
    return [self requestThumbImageWithWidth:[HXPhotoCommon photoCommon].requestWidth completion:completion];
}
- (PHImageRequestID)highQualityRequestThumbImageWithWidth:(CGFloat)width completion:(HXModelImageSuccessBlock)completion {
    if (self.photoEdit) {
        if (completion) completion(self.photoEdit.editPreviewImage, self, nil);
        return 0;
    }
    PHImageRequestOptions *options = [self imageHighQualityRequestOptions];
    return [self requestThumbImageWithOptions:options width:width completion:completion];
}
- (PHImageRequestID)requestThumbImageWithWidth:(CGFloat)width completion:(HXModelImageSuccessBlock)completion {
    if (self.photoEdit) {
        if (completion) completion(self.photoEdit.editPosterImage, self, nil);
        return 0;
    }
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
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
//    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    return [self requestThumbImageWithOptions:options width:width completion:completion];
}

- (PHImageRequestID)requestThumbImageWithOptions:(PHImageRequestOptions * _Nullable)options
                                           width:(CGFloat)width
                                      completion:(HXModelImageSuccessBlock _Nullable)completion {
    CGFloat initialWidth = width;
    CGFloat scale;
    if (self.asset.pixelWidth < width) {
        scale = 0.5f;
        width = self.asset.pixelWidth * scale;
    }else {
        if (self.asset.pixelHeight < self.asset.pixelWidth * 2 &&
            self.asset.pixelHeight > self.asset.pixelWidth * 0.5f) {
            width *= 0.7f;
            initialWidth = width;
        }
        scale = self.asset.pixelWidth / width;
    }
    CGFloat height = self.asset.pixelHeight / scale;
    CGFloat sixteenHeight = width / 9 * 20;
    if (height > sixteenHeight) {
        width = sixteenHeight / height * width;
        height = sixteenHeight;
    }
    if (height < initialWidth && width >= initialWidth) {
        width = initialWidth / height * width;
        height = initialWidth;
    }
    CGSize size = CGSizeMake(width, height);
    HXWeakSelf
    return [self requestImageWithOptions:options contentMode:PHImageContentModeAspectFill targetSize:size  resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
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
    if (self.photoEdit) {
        if (success) success(self.photoEdit.editPreviewImage, self, nil);
        return 0;
    }
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
                weakSelf.thumbPhoto = result;
                weakSelf.previewPhoto = result;
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


- (void)requestLocalLivePhotoWithReqeustID:(void (^)(PHLivePhotoRequestID requestID))requestID
                                    header:(void (^)(AVAssetWriter *, AVAssetReader *, AVAssetReader *))header
                                completion:(HXModelLivePhotoSuccessBlock)completion {

    __block BOOL writeImageSuccess = NO;
    __block BOOL writeVideoSuccess = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.imageURL && !self.videoURL) {
            if (completion) {
                completion(nil, self, nil);
            }
            return;
        }
        NSURL *tempImageURL;
        if (!self.imageURL) {
            NSString *fileName = [self.videoURL.lastPathComponent.stringByDeletingPathExtension stringByAppendingString:@"_local_img"];
            fileName = HXDiskCacheFileNameForKey(fileName, NO);
            fileName = [HXPhotoPickerLivePhotoImagesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", fileName]];
            tempImageURL = [NSURL fileURLWithPath:fileName];
        }else {
            tempImageURL = self.imageURL;
        }
        BOOL hasVideoURL = [HXPhotoTools fileExistsAtLivePhotoVideoURL:self.videoURL];
        BOOL hasImageURL = [HXPhotoTools fileExistsAtLivePhotoImageURL:tempImageURL];

        NSURL *toImageURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@.jpg", [HXPhotoTools getLivePhotoImageURLFilePath:tempImageURL]]];
        NSURL *toVideoURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@.mov", [HXPhotoTools getLivePhotoVideoURLFilePath:self.videoURL]]];
        if (!hasVideoURL || !hasImageURL) {
            hasVideoURL = NO;
            hasImageURL = NO;
            [[NSFileManager defaultManager] removeItemAtURL:toImageURL error:nil];
            [[NSFileManager defaultManager] removeItemAtURL:toVideoURL error:nil];
        }
        HXWeakSelf
        if (!hasImageURL) {
            if (!self.imageURL) {
                if (![[NSFileManager defaultManager] fileExistsAtPath:tempImageURL.path]) {
                    NSData *imageData = UIImageJPEGRepresentation(self.thumbPhoto, 1);
                    [imageData writeToURL:tempImageURL atomically:YES];
                }
                self.imageURL = tempImageURL;
            }
            [HXPhotoTools writeToFileWithOriginJPGPath:self.imageURL TargetWriteFilePath:toImageURL completion:^(BOOL success) {
                writeImageSuccess = YES;
                if (writeVideoSuccess) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (success) {
                            PHLivePhotoRequestID requestId = [weakSelf writeAfterCompletionRequestWithCompletion:completion];
                            if (requestID) {
                                requestID(requestId);
                            }
                        }else {
                            if (completion) {
                                completion(nil, weakSelf, nil);
                            }
                        }
                    });
                }
            }];
        }else {
            if (!self.imageURL) {
                self.imageURL = tempImageURL;
            }
            writeImageSuccess = YES;
        }
        if (!hasVideoURL) {
            [HXPhotoTools writeToFileWithOriginMovPath:self.videoURL TargetWriteFilePath:toVideoURL header:header completion:^(BOOL success) {
                writeVideoSuccess = YES;
                if (writeImageSuccess) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (success) {
                            PHLivePhotoRequestID requestId = [weakSelf writeAfterCompletionRequestWithCompletion:completion];
                            if (requestID) {
                                requestID(requestId);
                            }
                        }else {
                            if (completion) {
                                completion(nil, weakSelf, nil);
                            }
                        }
                    });
                }
            }];
        }else {
            writeVideoSuccess = YES;
            if (writeImageSuccess) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    PHLivePhotoRequestID requestId = [self writeAfterCompletionRequestWithCompletion:completion];
                    if (requestID) {
                        requestID(requestId);
                    }
                });
            }
        }
    });
}
- (PHLivePhotoRequestID)writeAfterCompletionRequestWithCompletion:(HXModelLivePhotoSuccessBlock _Nullable)completion{
    HXWeakSelf
    NSURL *imageURL = [NSURL fileURLWithPath:[[HXPhotoTools getLivePhotoImageURLFilePath:self.imageURL] stringByAppendingString:@".jpg"]];
    NSURL *videoURL = [NSURL fileURLWithPath:[[HXPhotoTools getLivePhotoVideoURLFilePath:self.videoURL] stringByAppendingString:@".mov"]];
    return [PHLivePhoto requestLivePhotoWithResourceFileURLs:[NSArray arrayWithObjects:videoURL, imageURL, nil] placeholderImage:self.thumbPhoto targetSize:CGSizeZero contentMode:PHImageContentModeAspectFill resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nonnull info) {
//        BOOL downloadFinined = (![[info objectForKey:PHLivePhotoInfoCancelledKey] boolValue] && ![info objectForKey:PHLivePhotoInfoErrorKey]);
        BOOL isDegraded = [[info objectForKey:PHLivePhotoInfoIsDegradedKey] boolValue];
        if (!isDegraded) {
            if (completion) {
                completion(livePhoto, weakSelf, info);
            }
        }
    }];
}
- (PHImageRequestID)requestImageDataStartRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                       progressHandler:(HXModelProgressHandler)progressHandler
                                               success:(HXModelImageDataSuccessBlock)success
                                                failed:(HXModelFailedBlock)failed {
    if (self.photoEdit) {
        if (success) success(self.photoEdit.editPreviewData, self.photoEdit.editPreviewImage.imageOrientation, self, nil);
        return 0;
    }
    HXWeakSelf
    if (self.type == HXPhotoModelMediaTypeCameraPhoto && self.networkPhotoUrl) {
#if HasSDWebImage
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
#elif HasYYKitOrWebImage
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
    return [self requestAVAssetStartRequestICloud:startRequestICloud deliveryMode:PHVideoRequestOptionsDeliveryModeFastFormat progressHandler:progressHandler success:success failed:failed];
}

- (PHImageRequestID)requestAVAssetStartRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                        deliveryMode:(PHVideoRequestOptionsDeliveryMode)deliveryMode
                                     progressHandler:(HXModelProgressHandler)progressHandler
                                             success:(HXModelAVAssetSuccessBlock)success
                                              failed:(HXModelFailedBlock)failed
 {
    if (self.type == HXPhotoModelMediaTypeCameraVideo) {
        if (success) {
            AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
            success(asset, nil, self, nil);
        }
        return 0;
    }
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = deliveryMode;
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
    return [self requestImageWithOptions:options contentMode:PHImageContentModeAspectFill targetSize:targetSize resultHandler:resultHandler];
}

- (PHImageRequestID)requestImageWithOptions:(PHImageRequestOptions *)options contentMode:(PHImageContentMode)contentMode targetSize:(CGSize)targetSize resultHandler:(void (^)(UIImage *__nullable result, NSDictionary *__nullable info))resultHandler {
    if (self.photoEdit) {
        if (resultHandler) {
            resultHandler(self.photoEdit.editPreviewImage, nil);
        }
        return 0;
    }
    return [[PHImageManager defaultManager] requestImageForAsset:self.asset targetSize:targetSize contentMode:contentMode options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
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
    if (!presetName) {
        presetName = AVAssetExportPresetMediumQuality;
    }
    HXWeakSelf
    PHVideoRequestOptionsDeliveryMode mode = [presetName isEqualToString:AVAssetExportPresetHighestQuality] ? PHVideoRequestOptionsDeliveryModeHighQualityFormat : PHVideoRequestOptionsDeliveryModeFastFormat;
    [self requestAVAssetStartRequestICloud:startRequestICloud deliveryMode:mode progressHandler:iCloudProgressHandler success:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
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
                        strongSelf.videoURL = videoURL;
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
            if (failed) {
                failed(nil, strongSelf);
            }
            if (HXShowLog) NSSLog(@"该设备不支持:%@",presetName);
        }
    } failed:failed];
}
- (PHContentEditingInputRequestID)requestImageURLStartRequestICloud:(void (^)(PHContentEditingInputRequestID iCloudRequestId, HXPhotoModel *model))startRequestICloud
                                                    progressHandler:(HXModelProgressHandler)progressHandler
                                                            success:(HXModelImageURLSuccessBlock)success
                                                             failed:(HXModelFailedBlock)failed {
    if (self.photoEdit) {
//        HXWeakSelf
        [self getCameraImageURLWithSuccess:^(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
            if (success) {
                success(imageURL, model, nil);
            }
        } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
            if (failed) {
                failed(info, model);
            }
        }];
        return 0;
    }
    if (self.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (self.imageURL) {
            if (success) {
                success(self.imageURL, self, nil);
            }
        }else {
            if (failed) {
                failed(nil, self);
            }
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
            NSURL *imageURL;
            if ([[contentEditingInput.fullSizeImageURL pathExtension] isEqualToString:@"GIF"] && weakSelf.type != HXPhotoModelMediaTypePhotoGif) {
                // 虽然是gif图片，但是没有开启显示gif 所以这里处理一下
                NSData *imageData = UIImageJPEGRepresentation(contentEditingInput.displaySizeImage, 1);
                NSString *fileName = [[NSString hx_fileName] stringByAppendingString:@".jpg"];
                NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                imageURL = [NSURL fileURLWithPath:fullPathToFile];
                if (![imageData writeToURL:imageURL atomically:YES]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (failed) {
                            failed(info, weakSelf);
                        }
                    });
                    return;
                }
            }else {
                imageURL = contentEditingInput.fullSizeImageURL;
            }
            weakSelf.imageURL = imageURL;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    success(imageURL, weakSelf, info);
                }
            });
        }else {
            if ([[info objectForKey:PHContentEditingInputResultIsInCloudKey] boolValue] &&
                ![[info objectForKey:PHContentEditingInputCancelledKey] boolValue]) {
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
                        NSURL *imageURL;
                        if ([[contentEditingInput.fullSizeImageURL pathExtension] isEqualToString:@"GIF"] && weakSelf.type != HXPhotoModelMediaTypePhotoGif) {
                            // 虽然是gif图片，但是没有开启显示gif 所以这里处理一下
                            NSData *imageData = UIImageJPEGRepresentation(contentEditingInput.displaySizeImage, 1);

                            NSString *fileName = [[NSString hx_fileName] stringByAppendingString:@".jpg"];
                            NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                            imageURL = [NSURL fileURLWithPath:fullPathToFile];
                            if (![imageData writeToURL:imageURL atomically:YES]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (failed) {
                                        failed(info, weakSelf);
                                    }
                                });
                                return;
                            }
                        }else {
                            imageURL = contentEditingInput.fullSizeImageURL;
                        }
                        weakSelf.imageURL = imageURL;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (success) {
                                success(imageURL, weakSelf, nil);
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

- (void)requestLivePhotoAssetsWithSuccess:(HXModelLivePhotoAssetsSuccessBlock _Nullable)success
                                   failed:(HXModelFailedBlock _Nullable)failed {
    if (self.photoEdit) {
        [self getCameraImageURLWithSuccess:^(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
            if (success) {
                success(imageURL, nil, NO, model);
            }
        } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
            if (failed) {
                failed(info, model);
            }
        }];
        return;
    }
    if (self.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto) {
        if (success) {
            success(self.imageURL, self.videoURL, NO, self);
        }
        return;
    }else if (self.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkLivePhoto) {
        if (success) {
            success(self.networkPhotoUrl, self.livePhotoVideoURL, YES, self);
        }
        return;
//        if (self.imageURL && self.videoURL) {
//            if (success) {
//                success(self.imageURL, self.videoURL, self);
//            }
//            return;
//        }
    }
    HXWeakSelf
    [self requestLivePhotoWithSize:PHImageManagerMaximumSize startRequestICloud:nil progressHandler:nil success:^(PHLivePhoto * _Nullable livePhoto, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakSelf requestLivePhotoAssetResourcesWithLivePhoto:livePhoto success:^(NSURL * _Nullable imageURL, NSURL * _Nullable videoURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.imageURL = imageURL;
                    weakSelf.videoURL = videoURL;
                    if (success) {
                        success(imageURL, videoURL, NO, weakSelf);
                    }
                });
            } failed:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed(info, model);
                    }
                });
            }];
        });
    } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
        if (failed) {
            failed(info, model);
        }
    }];
}
- (void)requestLivePhotoAssetResourcesWithLivePhoto:(PHLivePhoto *)livePhoto success:(void (^ _Nullable)(NSURL * _Nullable imageURL, NSURL * _Nullable videoURL))success failed:(void (^ _Nullable)(void))failed {
    NSArray *resoures = [PHAssetResource assetResourcesForLivePhoto:livePhoto];
    // resoures 里面有两个 PHAssetResource 一个图片，一个视频
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    
    NSString *fileName = [[NSString hx_fileName] stringByAppendingString:@".mp4"];
    NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    // 导出livePhoto视频的本地地址
    NSURL *videoURL = [NSURL fileURLWithPath:fullPathToFile];
    NSString *videoFullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSString hx_fileName] stringByAppendingString:@".jpg"]];
    NSURL *imageURL = [NSURL fileURLWithPath:videoFullPathToFile];
    
    __block BOOL requestImageURLCompletion = NO;
    __block BOOL requestVideoURLCompletion = NO;
    for (PHAssetResource *assetResource in resoures) {
        if (assetResource.type == PHAssetResourceTypePhoto) {
            // LivePhoto的封面
            [[PHAssetResourceManager defaultManager] requestDataForAssetResource:assetResource options:options dataReceivedHandler:^(NSData * _Nonnull data) {
                BOOL writeSuccesss = [data writeToURL:imageURL atomically:YES];
                if (writeSuccesss) {
                    if (success && requestVideoURLCompletion) {
                        success(imageURL, videoURL);
                    }
                }else {
                    if (failed) {
                        failed();
                    }
                }
            } completionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    requestImageURLCompletion = YES;
                }else {
                    if (failed) {
                        failed();
                    }
                }
            }];
        }else if (assetResource.type == PHAssetResourceTypePairedVideo) {
            // LivePhoto的视频内容
            [[PHAssetResourceManager defaultManager] writeDataForAssetResource:assetResource toFile:videoURL options:options completionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    requestVideoURLCompletion = YES;
                    if (success && requestImageURLCompletion) {
                        success(imageURL, videoURL);
                    }
                }else {
                    if (failed) {
                        failed();
                    }
                }
            }];
        }
    }
}
- (void)getCameraImageURLWithSuccess:(HXModelImageURLSuccessBlock _Nullable)success
                              failed:(HXModelFailedBlock _Nullable)failed {
                                    HXWeakSelf
    if (self.photoEdit) {
        [self getImageURLWithImage:self.photoEdit.editPreviewImage success:^(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
            weakSelf.imageURL = imageURL;
            if (success) {
                success(imageURL, weakSelf, nil);
            }
        } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
            if (failed) {
                failed(nil, weakSelf);
            }
        }];
        return;
    }
    if (self.type != HXPhotoModelMediaTypeCameraPhoto) {
        if (failed) {
            failed(nil, self);
        }
        return;
    }
    if (self.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto) {
        if (success) {
            success(self.imageURL, self, nil);
        }
        return;
    }
    [self getImageURLWithImage:self.thumbPhoto success:^(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
        weakSelf.imageURL = imageURL;
        if (success) {
            success(imageURL, weakSelf, nil);
        }
    } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
        if (failed) {
            failed(nil, weakSelf);
        }
    }];
}
- (void)getImageWithSuccess:(HXModelImageSuccessBlock _Nullable)success
                     failed:(HXModelFailedBlock _Nullable)failed {
    if (self.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto) {
        if (self.thumbPhoto) {
            if (success) {
                success(self.thumbPhoto, self, nil);
            }
            return;
        }else if (self.imageURL) {
            UIImage *image = [UIImage imageWithContentsOfFile:self.imageURL.path];
            if (image && success) {
                self.thumbPhoto = image;
                self.previewPhoto = image;
                success(image, self, nil);
                return;
            }
        }
    }
    [self requestPreviewImageWithSize:PHImageManagerMaximumSize startRequestICloud:nil progressHandler:nil success:success failed:failed];
}
- (void)getImageURLWithImage:(UIImage *)image
                     success:(HXModelImageURLSuccessBlock _Nullable)success
                      failed:(HXModelFailedBlock _Nullable)failed{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData;
        NSString *suffix;
        if (self.photoEdit) {
            imageData = self.photoEdit.editPreviewData;
            suffix = @"jpeg";
        }else {
            if (UIImagePNGRepresentation(image)) {
                //返回为png图像。
                imageData = UIImagePNGRepresentation(image);
                suffix = @"png";
            }else {
                //返回为JPEG图像。
                imageData = UIImageJPEGRepresentation(image, 0.8);
                suffix = @"jpeg";
            }
        }
        NSString *fileName = [[NSString hx_fileName] stringByAppendingString:[NSString stringWithFormat:@".%@",suffix]];
        NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        
        if ([imageData writeToFile:fullPathToFile atomically:YES]) {
            NSURL *imageURL = [NSURL fileURLWithPath:fullPathToFile];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    success(imageURL, self, nil);
                }
            });
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failed) {
                    failed(nil, self);
                }
            });
        }
    });
}
- (void)getAssetURLWithSuccess:(HXModelURLHandler)success
                        failed:(HXModelFailedBlock)failed {
    [self getAssetURLWithVideoPresetName:nil success:success failed:failed];
}

- (void)getAssetURLWithVideoPresetName:(NSString * _Nullable)presetName
                               success:(HXModelURLHandler _Nullable)success
                                failed:(HXModelFailedBlock _Nullable)failed {
    HXWeakSelf
    if (self.photoEdit) {
        [self getCameraImageURLWithSuccess:^(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
            if (success) {
                success(imageURL, HXPhotoModelMediaSubTypePhoto, NO, weakSelf);
            }
        } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
            if (failed) {
                failed(nil, weakSelf);
            }
        }];
        return;
    }
    if (self.subType == HXPhotoModelMediaSubTypePhoto) {
        if (self.type == HXPhotoModelMediaTypeCameraPhoto) {
            if (self.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWork ||
                self.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif) {
                    if (success) {
                        success(self.networkPhotoUrl, HXPhotoModelMediaSubTypePhoto, YES, self);
                    }
            }else {
                [self getCameraImageURLWithSuccess:^(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                    if (success) {
                        success(imageURL, HXPhotoModelMediaSubTypePhoto, NO, weakSelf);
                    }
                } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                    if (failed) {
                        failed(nil, weakSelf);
                    }
                }];
            }
        }else {
            [self requestImageURLStartRequestICloud:nil progressHandler:nil success:^(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                if (success) {
                    success(imageURL, HXPhotoModelMediaSubTypePhoto, NO, weakSelf);
                }
            } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                if (failed) {
                    failed(nil, weakSelf);
                }
            }];
        }
    }else if (self.subType == HXPhotoModelMediaSubTypeVideo) {
        if (self.type == HXPhotoModelMediaTypeCameraVideo) {
            if (self.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeLocal) {
                if (success) {
                    success(self.videoURL, HXPhotoModelMediaSubTypeVideo, NO, self);
                }
            }else if (self.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                if (success) {
                    success(self.videoURL, HXPhotoModelMediaSubTypeVideo, YES, self);
                }
            }
        }else {
            [self exportVideoWithPresetName:presetName startRequestICloud:nil iCloudProgressHandler:nil exportProgressHandler:nil success:^(NSURL * _Nullable videoURL, HXPhotoModel * _Nullable model) {
                if (success) {
                    success(videoURL, HXPhotoModelMediaSubTypeVideo, NO, weakSelf);
                }
            } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                if (failed) {
                    failed(nil, weakSelf);
                }
            }];
        }
    }
}
@end
