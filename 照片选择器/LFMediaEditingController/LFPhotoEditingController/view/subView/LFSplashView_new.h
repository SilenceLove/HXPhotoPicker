//
//  LFSplashView_new.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/6/7.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFMediaEditingType.h"

@interface LFSplashView_new : UIView

/** 数据 */
@property (nonatomic, strong) NSDictionary *data;

@property (nonatomic, copy) void(^splashBegan)(void);
@property (nonatomic, copy) void(^splashEnded)(void);
/** 绘画颜色 */
@property (nonatomic, copy) UIColor *(^splashColor)(CGPoint point);

/** 改变模糊状态 */
@property (nonatomic, assign) LFSplashStateType state;

/** 是否可撤销 */
- (BOOL)canUndo;

//撤销
- (void)undo;

@end
