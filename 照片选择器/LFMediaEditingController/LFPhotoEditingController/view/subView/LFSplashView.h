//
//  LFSplashView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/28.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFMediaEditingType.h"

@interface LFSplashView : UIView

/** 设置图片 */
- (void)setImage:(UIImage *)image mosaicLevel:(NSUInteger)level;

/** 原图 */
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSUInteger level;

/** 数据 */
@property (nonatomic, strong) NSDictionary *data;

@property (nonatomic, copy) void(^splashBegan)(void);
@property (nonatomic, copy) void(^splashEnded)(void);

/** 改变模糊状态 */
@property (nonatomic, assign) LFSplashStateType state;

/** 是否可撤销 */
- (BOOL)canUndo;

//撤销
- (void)undo;

@end
