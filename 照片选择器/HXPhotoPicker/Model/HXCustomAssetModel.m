//
//  HXCustomAssetModel.m
//  照片选择器
//
//  Created by 洪欣 on 2018/7/25.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "HXCustomAssetModel.h"

@interface HXCustomAssetModel ()
@property (copy, nonatomic) NSString *localImageName;
@end

@implementation HXCustomAssetModel

+ (instancetype)assetWithNetworkVideoURL:(NSURL *)videoURL videoCoverURL:(NSURL *)videoCoverURL videoDuration:(NSTimeInterval)videoDuration selected:(BOOL)selected {
    return [[self alloc] initNetworkVideoWithURL:videoURL videoCoverURL:videoCoverURL videoDuration:videoDuration selected:selected];
}

- (instancetype)initNetworkVideoWithURL:(NSURL *)videoURL videoCoverURL:(NSURL *)videoCoverURL videoDuration:(NSTimeInterval)videoDuration selected:(BOOL)selected {
    self = [super init];
    if (self) {
        self.type = HXCustomAssetModelTypeNetWorkVideo;
        self.networkVideoURL = videoURL;
        self.networkImageURL = videoCoverURL;
        self.networkThumbURL = videoCoverURL;
        self.videoDuration = videoDuration;
        self.selected = selected;
    }
    return self;
}

+ (instancetype)assetWithLocaImageName:(NSString *)imageName selected:(BOOL)selected {
    return [[self alloc] initAssetWithLocaImageName:imageName selected:selected];
}

- (instancetype)initAssetWithLocaImageName:(NSString *)imageName selected:(BOOL)selected {
    self = [super init];
    if (self) {
        self.type = HXCustomAssetModelTypeLocalImage;
        self.localImageName = imageName;
        self.localImage = [UIImage imageNamed:imageName];
        self.selected = selected;
    }
    return self;
}

+ (instancetype)assetWithLocalImage:(UIImage *)image selected:(BOOL)selected {
    return [[self alloc] initAssetWithLocalImage:image selected:selected];
}

- (instancetype)initAssetWithLocalImage:(UIImage *)image selected:(BOOL)selected {
    self = [super init];
    if (self) {
        self.type = HXCustomAssetModelTypeLocalImage;
        self.localImage = image;
        self.selected = selected;
    }
    return self;
}

+ (instancetype)assetWithNetworkImageURL:(NSURL *)imageURL selected:(BOOL)selected {
    return [[self alloc] initAssetWithNetworkImageURL:imageURL networkThumbURL:imageURL selected:selected];
}

+ (instancetype)assetWithNetworkImageURL:(NSURL *)imageURL networkThumbURL:(NSURL *)thumbURL selected:(BOOL)selected {
    return [[self alloc] initAssetWithNetworkImageURL:imageURL networkThumbURL:thumbURL selected:selected];
}

- (instancetype)initAssetWithNetworkImageURL:(NSURL *)imageURL networkThumbURL:(NSURL *)thumbURL selected:(BOOL)selected {
    self = [super init];
    if (self) {
        self.type = HXCustomAssetModelTypeNetWorkImage;
        self.networkImageURL = imageURL;
        self.networkThumbURL = thumbURL;
        self.selected = selected;
    }
    return self;
}

+ (instancetype)assetWithLocalVideoURL:(NSURL *)videoURL selected:(BOOL)selected {
    return [[self alloc] initAssetWithLocalVideoURL:videoURL selected:selected];
}

- (instancetype)initAssetWithLocalVideoURL:(NSURL *)videoURL selected:(BOOL)selected {
    self = [super init];
    if (self) {
        self.type = HXCustomAssetModelTypeLocalVideo;
        self.localVideoURL = videoURL;
        self.selected = selected;
    }
    return self;
}

+ (instancetype)livePhotoAssetWithLocalImagePath:(NSURL *)imagePath localVideoURL:(NSURL *)videoURL selected:(BOOL)selected {
    return [[self alloc] initLivePhotoAssetWithLocalImagePath:imagePath localVideoURL:videoURL selected:selected];
}

- (instancetype)initLivePhotoAssetWithLocalImagePath:(NSURL *)imagePath localVideoURL:(NSURL *)videoURL selected:(BOOL)selected {
    self = [super init];
    if (self) {
        self.type = HXCustomAssetModelTypeLivePhoto;
        self.localVideoURL = videoURL;
        self.localImagePath = imagePath;
        self.localImage = [UIImage imageWithContentsOfFile:imagePath.path];
        self.selected = selected;
    }
    return self;
}
@end
