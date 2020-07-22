//
//  HXPhotoEditChartletModel.m
//  photoEditDemo
//
//  Created by 洪欣 on 2020/7/2.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "HXPhotoEditChartletModel.h"

@implementation HXPhotoEditChartletModel

+ (instancetype)modelWithImage:(UIImage *)image {
    HXPhotoEditChartletModel *model = [[self alloc] init];
    model.type = HXPhotoEditChartletModelType_Image;
    model.image = image;
    return model;
}
+ (instancetype)modelWithImageNamed:(NSString *)imageNamed {
    HXPhotoEditChartletModel *model = [[self alloc] init];
    model.type = HXPhotoEditChartletModelType_ImageNamed;
    model.imageNamed = imageNamed;
    return model;
}
+ (instancetype)modelWithNetworkNURL:(NSURL *)networkURL {
    HXPhotoEditChartletModel *model = [[self alloc] init];
    model.type = HXPhotoEditChartletModelType_NetworkURL;
    model.networkURL = networkURL;
    return model;
}
@end

@implementation HXPhotoEditChartletTitleModel

@end
