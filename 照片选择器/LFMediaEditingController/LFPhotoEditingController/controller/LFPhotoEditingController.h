//
//  LFPhotoEditingController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/22.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFBaseEditingController.h"
#import "LFPhotoEdit.h"

typedef NS_ENUM(NSUInteger, LFPhotoEditOperationType) {
    /** 绘画 */
    LFPhotoEditOperationType_draw = 1 << 0,
    /** 贴图 */
    LFPhotoEditOperationType_sticker = 1 << 1,
    /** 文本 */
    LFPhotoEditOperationType_text = 1 << 2,
    /** 模糊 */
    LFPhotoEditOperationType_splash = 1 << 3,
    /** 滤镜 */
    LFPhotoEditOperationType_filter = 1 << 4,
    /** 修剪 */
    LFPhotoEditOperationType_crop = 1 << 5,
    /** 所有 */
    LFPhotoEditOperationType_All = ~0UL,
};

@protocol LFPhotoEditingControllerDelegate;

@interface LFPhotoEditingController : LFBaseEditingController
/** 设置编辑图片->重新初始化（图片方向必须为正方向） */
@property (nonatomic, strong) UIImage *editImage;
/** 设置编辑对象->重新编辑 */
@property (nonatomic, strong) LFPhotoEdit *photoEdit;

/** 设置操作类型 default is LFPhotoEditOperationType_All */
@property (nonatomic, assign) LFPhotoEditOperationType operationType;

/** 自定义贴图资源 */
@property (nonatomic, strong) NSString *stickerPath;

/** 代理 */
@property (nonatomic, weak) id<LFPhotoEditingControllerDelegate> delegate;

@end

@protocol LFPhotoEditingControllerDelegate <NSObject>

- (void)lf_PhotoEditingController:(LFPhotoEditingController *)photoEditingVC didCancelPhotoEdit:(LFPhotoEdit *)photoEdit;
- (void)lf_PhotoEditingController:(LFPhotoEditingController *)photoEditingVC didFinishPhotoEdit:(LFPhotoEdit *)photoEdit;

@end
