//
//  HXAlbumModel.h
//  HXPhotoPicker-Demo
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
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
@property (assign, nonatomic) BOOL needReloadCount;
/// 选择类型
@property (assign, nonatomic) NSInteger selectType;
/// 是否按创建时间排序
@property (assign, nonatomic) BOOL creationDateSort;
/// 唯一标识符
@property (copy, nonatomic) NSString *localIdentifier;
/// 资源集合
@property (strong, nonatomic) PHFetchResult *assetResult;
/// 下标
@property (assign, nonatomic) NSUInteger index;
/// 选中的个数
@property (assign, nonatomic) NSUInteger selectedCount;
/// 本地图片数量
@property (assign, nonatomic) NSUInteger cameraCount;
@property (strong, nonatomic) UIImage *tempImage;

@property (copy, nonatomic) NSString *fetchOptionsPredicate;

- (void)fetchAssetResult;
- (void)getResultWithCompletion:(void (^)(HXAlbumModel *albumModel))completion;

@end
