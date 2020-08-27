//
//  HXAlbumModel.h
//  HXPhotoPicker-Demo
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
/**  相册名称  */
@property (copy, nonatomic) NSString *albumName;
/**  照片数量  */
@property (assign, nonatomic) NSInteger count;

@property (assign, nonatomic) NSInteger selectType;
@property (assign, nonatomic) BOOL creationDateSort;

@property (copy, nonatomic) NSString *localIdentifier;
@property (strong, nonatomic) PHAssetCollection *assetCollection;
@property (strong, nonatomic) PHFetchResult *assetResult;

@property (strong, nonatomic) PHFetchOptions *option;
/**  标记  */
@property (assign, nonatomic) NSInteger index;
/**  选中的个数  */
@property (assign, nonatomic) NSInteger selectedCount;
@property (assign, nonatomic) NSUInteger cameraCount;
@property (strong, nonatomic) UIImage *tempImage;

- (void)fetchAssetResult;
- (void)getResultWithCompletion:(void (^)(HXAlbumModel *albumModel))completion;

@end
