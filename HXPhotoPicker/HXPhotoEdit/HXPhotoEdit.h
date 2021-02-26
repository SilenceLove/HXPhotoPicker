//
//  HXPhotoEdit.h
//  photoEditDemo
//
//  Created by Silence on 2020/7/1.
//  Copyright © 2020 Silence. All rights reserved.
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
/// 编辑原图片本地临时地址
@property (nonatomic, readonly) NSString *imagePath;
/// 编辑数据
@property (nonatomic, readonly) NSDictionary *editData;

- (instancetype)initWithEditImagePath:(NSString *)imagePath previewImage:(UIImage *)previewImage data:(NSDictionary *)data;

- (void)clearData;
@end

NS_ASSUME_NONNULL_END
