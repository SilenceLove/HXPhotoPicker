//
//  LFVideoEdit.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LFVideoEdit : NSObject

/** 编辑封面 */
@property (nonatomic, readonly) UIImage *editPosterImage;
/** 编辑预览图片 */
@property (nonatomic, readonly) UIImage *editPreviewImage;
/** 编辑视频路径(最终) */
@property (nonatomic, readonly) NSURL *editFinalURL;
/** 编辑视频 */
@property (nonatomic, readonly) AVAsset *editAsset;
/** 编辑数据 */
@property (nonatomic, readonly) NSDictionary *editData;
/** 视频时间 */
@property (nonatomic, readonly) NSTimeInterval duration;

/** 初始化 */
- (instancetype)initWithEditAsset:(AVAsset *)editAsset editFinalURL:(NSURL *)editFinalURL data:(NSDictionary *)data;
@end
