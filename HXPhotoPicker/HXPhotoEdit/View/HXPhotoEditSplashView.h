//
//  HXPhotoEditSplashView.h
//  photoEditDemo
//
//  Created by Silence on 2020/7/1.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HXPhotoEditSplashStateType) {
    /** 马赛克 */
    HXPhotoEditSplashStateType_Mosaic,
    /** 高斯模糊 */
    HXPhotoEditSplashStateType_Blurry,
    /** 画笔涂抹 */
    HXPhotoEditSplashStateType_Paintbrush,
};

@interface HXPhotoEditSplashView : UIView

/// 显示界面的缩放率
@property (nonatomic, assign) CGFloat screenScale;

/** 数据 */
@property (nonatomic, strong, nullable) NSDictionary *data;

@property (nonatomic, copy) void(^splashBegan)(void);
@property (nonatomic, copy) void(^splashEnded)(void);
/** 绘画颜色 */
@property (nonatomic, copy) UIColor *(^splashColor)(CGPoint point);

/** 改变模糊状态 */
@property (nonatomic, assign) HXPhotoEditSplashStateType state;

/** 是否可撤销 */
- (BOOL)canUndo;

//撤销
- (void)undo;
- (void)clearCoverage;
@end

NS_ASSUME_NONNULL_END
