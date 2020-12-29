//
//  HXPreviewVideoView.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/11/15.
//  Copyright © 2019 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HXPreviewVideoSliderType) {
    HXPreviewVideoSliderTypeTouchDown       = 0,    //!< 按下
    HXPreviewVideoSliderTypeTouchUpInSide   = 1,    //!< 抬起
    HXPreviewVideoSliderTypeChanged         = 2,    //!< 改变
};

@class HXPhotoModel;
@interface HXPreviewVideoView : UIView

@property (copy, nonatomic) void (^ downloadICloudAssetComplete)(void);
@property (copy, nonatomic) void (^ shouldPlayVideo)(void);
@property (assign, nonatomic) BOOL stopCancel;
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) AVAsset *avAsset;

/// 是否正在播放
@property (assign, nonatomic) BOOL isPlayer;
@property (assign, nonatomic) BOOL playBtnDidPlay;

@property (assign, nonatomic) BOOL playBtnHidden;

@property (copy, nonatomic) void (^ gotVideoDuration)(NSTimeInterval duration);
@property (copy, nonatomic) void (^ gotVideoBufferEmptyValue)(CGFloat value);
@property (copy, nonatomic) void (^ changePlayBtnState)(BOOL isSelected);
@property (copy, nonatomic) void (^ changeValue)(CGFloat value ,BOOL animaiton);
@property (copy, nonatomic) void (^ gotVideoCurrentTime)(NSTimeInterval currentTime);
@property (copy, nonatomic) void (^ playBtnDidClick)(BOOL isPlay);
- (void)didPlayBtnClickWithSelected:(BOOL)isSelected;
- (void)changePlayerTimeWithValue:(CGFloat)value type:(HXPreviewVideoSliderType)type;

- (void)showOtherView;
- (void)hideOtherView:(BOOL)animatoin;

- (void)cancelPlayer;
@end

@interface HXPreviewVideoSliderView : UIView
@property (assign, nonatomic) BOOL playBtnSelected;
@property (copy, nonatomic) NSString *currentTime;
@property (copy, nonatomic) NSString *totalTime;
@property (assign, nonatomic) CGFloat currentValue;
@property (assign, nonatomic) CGFloat progressValue;
@property (copy, nonatomic) void (^ didPlayBtnBlock)(BOOL isPlay);
@property (copy, nonatomic) void (^ sliderChangedValueBlock)(CGFloat value, HXPreviewVideoSliderType type);

- (void)show;
- (void)hide;
- (void)setCurrentValue:(CGFloat)currentValue animation:(BOOL)isAnimation;
@end

@interface HXSlider: UIView
@property (copy, nonatomic) void (^ sliderChanged)(CGFloat value);
@property (copy, nonatomic) void (^ sliderTouchDown)(CGFloat value);
@property (copy, nonatomic) void (^ sliderTouchUpInSide)(CGFloat value);
@property (assign, nonatomic) CGFloat currentValue;

- (void)setCurrentValue:(CGFloat)currentValue animation:(BOOL)isAnimation;
@end

@interface HXPanGestureRecognizer: UIPanGestureRecognizer

@end
NS_ASSUME_NONNULL_END
