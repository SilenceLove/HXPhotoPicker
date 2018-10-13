//
//  LFVideoEditingView.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "LFEditingProtocol.h"

@class LFAudioItem;

@interface LFVideoEditingView : UIView <LFEditingProtocol>

/** 音频数据 */
@property (nonatomic, strong) NSArray <LFAudioItem *>*audioUrls;

/** 开关剪辑模式 */
@property (nonatomic, assign) BOOL isClipping;
- (void)setIsClipping:(BOOL)isClipping animated:(BOOL)animated;

/** 允许剪辑的最小时长 1秒 */
@property (nonatomic, assign) double minClippingDuration;

/** 取消剪辑 */
- (void)cancelClipping:(BOOL)animated;

/** 数据 */
- (void)setVideoAsset:(AVAsset *)asset placeholderImage:(UIImage *)image;

/** 剪辑视频 */
- (void)exportAsynchronouslyWithTrimVideo:(void (^)(NSURL *trimURL, NSError *error))complete;

/** 播放 */
- (void)playVideo;
/** 暂停 */
- (void)pauseVideo;
/** 重置视频 */
- (void)resetVideoDisplay;

@end
