//
//  HXPhotoEdit.h
//  photoEditDemo
//
//  Created by 洪欣 on 2020/7/1.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoEdit : NSObject<NSCoding>
/// 编辑封面
@property (nonatomic, readonly) UIImage *editPosterImage;
/// 编辑预览图片
@property (nonatomic, readonly) UIImage *editPreviewImage;
/// 编辑图片数据
@property (nonatomic, readonly) NSData *editPreviewData;
/// 编辑原图片
@property (nonatomic, readonly) UIImage *editImage;
/// 编辑数据
@property (nonatomic, readonly) NSDictionary *editData;

- (instancetype)initWithEditImage:(UIImage *)image previewImage:(UIImage *)previewImage data:(NSDictionary *)data;

- (void)clearData;
@end

NS_ASSUME_NONNULL_END
