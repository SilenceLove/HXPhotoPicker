//
//  HXAlbumModel.h
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface HXAlbumModel : NSObject
/// 相册名称
@property (copy, nonatomic) NSString *albumName;
/// 照片数量
@property (assign, nonatomic) NSUInteger count;
/// 在获取照片数据之后的真实数量
@property (assign, nonatomic) NSUInteger realCount;
@property (strong, nonatomic) PHAsset *realCoverAsset;
/// 需要重新加载数量
@property (assign, nonatomic) BOOL needReloadCount;
/// 选择类型
@property (assign, nonatomic) NSInteger selectType;
/// 资源集合
@property (strong, nonatomic) PHFetchResult *assetResult;
/// 下标
@property (assign, nonatomic) NSUInteger index;
/// 选中的个数
@property (assign, nonatomic) NSUInteger selectedCount;
/// 本地图片数量
@property (assign, nonatomic) NSUInteger cameraCount;
/// 如果相册里没有资源则用本地图片代替
@property (strong, nonatomic) UIImage *tempImage;

- (instancetype)initWithCollection:(PHAssetCollection *)collection
                           options:(PHFetchOptions *)options;
- (NSString *)localIdentifier;
- (PHAssetCollection *)collection;
- (void)fetchAssetResult;
- (void)getResultWithCompletion:(void (^)(HXAlbumModel *albumModel))completion;

@end
