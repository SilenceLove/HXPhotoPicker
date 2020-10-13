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
@property (assign, nonatomic) NSInteger count;
/// 选择类型
@property (assign, nonatomic) NSInteger selectType;
/// 是否按创建时间排序
@property (assign, nonatomic) BOOL creationDateSort;
/// 唯一标识符
@property (copy, nonatomic) NSString *localIdentifier;
/// 资源集合
@property (strong, nonatomic) PHFetchResult *assetResult;
/// 下标
@property (assign, nonatomic) NSInteger index;
/// 选中的个数
@property (assign, nonatomic) NSInteger selectedCount;
/// 本地图片数量
@property (assign, nonatomic) NSUInteger cameraCount;
@property (strong, nonatomic) UIImage *tempImage;

- (void)fetchAssetResult;
- (void)getResultWithCompletion:(void (^)(HXAlbumModel *albumModel))completion;

@end
