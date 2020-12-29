//
//  HXPhotoEditDrawView.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/23.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoEditDrawView : UIView

@property (assign, nonatomic) CGFloat lineWidth;
@property (strong, nonatomic) UIColor *lineColor;
@property (copy, nonatomic) void (^ beganDraw)(void);
@property (copy, nonatomic) void (^ endDraw)(void);

/** 正在绘画 */
@property (nonatomic, readonly) BOOL isDrawing;
/** 图层数量 */
@property (nonatomic, readonly) NSUInteger count;
/// 显示界面的缩放率
@property (nonatomic, assign) CGFloat screenScale;

@property (assign, nonatomic) BOOL enabled;

/** 数据 */
@property (nonatomic, strong, nullable) NSDictionary *data;

/// 是否可以撤销
- (BOOL)canUndo;

/// 撤销
- (void)undo;
- (void)clearCoverage;
@end

NS_ASSUME_NONNULL_END
