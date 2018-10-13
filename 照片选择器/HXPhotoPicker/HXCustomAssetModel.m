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
@end
