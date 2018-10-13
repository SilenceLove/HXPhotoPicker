//
//  LFVideoTrimmerGridView.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/18.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LFVideoTrimmerGridViewDelegate;

@interface LFVideoTrimmerGridView : UIView

@property (nonatomic, assign) CGRect gridRect;
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated;

/** 最小尺寸 */
@property (nonatomic, assign) CGFloat controlMinWidth;
/** 最大尺寸 */
@property (nonatomic, assign) CGFloat controlMaxWidth;

/** 进度 */
@property (nonatomic, assign) double progress;
- (void)setHiddenProgress:(BOOL)hidden;

@property (nonatomic, weak) id<LFVideoTrimmerGridViewDelegate> delegate;

@end

@protocol LFVideoTrimmerGridViewDelegate <NSObject>

- (void)lf_videoTrimmerGridViewDidBeginResizing:(LFVideoTrimmerGridView *)gridView;
- (void)lf_videoTrimmerGridViewDidResizing:(LFVideoTrimmerGridView *)gridView;
- (void)lf_videoTrimmerGridViewDidEndResizing:(LFVideoTrimmerGridView *)gridView;

@end
