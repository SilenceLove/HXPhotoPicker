//
//  HXPhotoEditChartletModel.h
//  photoEditDemo
//
//  Created by Silence on 2020/7/2.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HXPhotoEditChartletModelType) {
    HXPhotoEditChartletModelType_Image,         // UIImage
    HXPhotoEditChartletModelType_ImageNamed,    // NSString
    HXPhotoEditChartletModelType_NetworkURL     // NSURL
};

@interface HXPhotoEditChartletModel : NSObject
/// 当前资源类型
@property (assign, nonatomic) HXPhotoEditChartletModelType type;
/// 图片对象
@property (strong, nonatomic) UIImage *image;
/// 图片名
@property (copy, nonatomic) NSString *imageNamed;
/// 网络图片地址
@property (strong, nonatomic) NSURL *networkURL;

+ (instancetype)modelWithImage:(UIImage *)image;
+ (instancetype)modelWithImageNamed:(NSString *)imageNamed;
+ (instancetype)modelWithNetworkNURL:(NSURL *)networkURL;


// other
@property (assign, nonatomic) BOOL loadCompletion;
@end


@interface HXPhotoEditChartletTitleModel : HXPhotoEditChartletModel
// 贴图数组
@property (copy, nonatomic) NSArray<HXPhotoEditChartletModel *> *models;

// other
@property (assign, nonatomic) BOOL selected;
@end

NS_ASSUME_NONNULL_END
