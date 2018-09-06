//
//  HXAlbumModel.h
//  照片选择器
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

/**
 *  每个相册的模型
 */

@interface HXAlbumModel : NSObject

/**
 相册名称
 */
@property (copy, nonatomic) NSString *albumName;

/**
 照片数量
 */
@property (assign, nonatomic) NSInteger count;

/**
 封面Asset
 */
@property (strong, nonatomic) PHAsset *asset;
/**  单选时的第二个资源  */
@property (strong, nonatomic) PHAsset *asset2;
/**  单选时的第三个资源  */
@property (strong, nonatomic) PHAsset *asset3;

/**
 照片集合对象
 */
@property (strong, nonatomic) PHFetchResult *result;

/**
 标记
 */
@property (assign, nonatomic) NSInteger index;

/**
 选中的个数
 */
@property (assign, nonatomic) NSInteger selectedCount;

@property (assign, nonatomic) NSUInteger cameraCount;

@property (strong, nonatomic) UIImage *tempImage;
@end
