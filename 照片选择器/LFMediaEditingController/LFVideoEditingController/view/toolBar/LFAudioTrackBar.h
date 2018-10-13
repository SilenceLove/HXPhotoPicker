//
//  LFAudioTrackBar.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/8/10.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LFAudioItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) BOOL isOriginal;
@property (nonatomic, assign) BOOL isEnable;

+ (instancetype)defaultAudioItem;

@end

@protocol LFAudioTrackBarDelegate;

@interface LFAudioTrackBar : UIView

@property (nonatomic, strong) NSArray <LFAudioItem *> *audioUrls;

/** 代理 */
@property (nonatomic, weak) UIViewController <LFAudioTrackBarDelegate> *delegate;

- (instancetype)initWithFrame:(CGRect)frame layout:(void (^)(LFAudioTrackBar *audioTrackBar))layoutBlock;

/** 样式 */
@property (nonatomic, strong) UIColor *oKButtonTitleColorNormal;
@property (nonatomic, strong) UIColor *cancelButtonTitleColorNormal;
@property (nonatomic, copy) NSString *oKButtonTitle;
@property (nonatomic, copy) NSString *cancelButtonTitle;
@property (nonatomic, assign) CGFloat customTopbarHeight;
@property (nonatomic, assign) CGFloat naviHeight;
@property (nonatomic, assign) CGFloat customToolbarHeight;

@end

@protocol LFAudioTrackBarDelegate <NSObject>

/** 完成回调 */
- (void)lf_audioTrackBar:(LFAudioTrackBar *)audioTrackBar didFinishAudioUrls:(NSArray <LFAudioItem *> *)audioUrls;
/** 取消回调 */
- (void)lf_audioTrackBarDidCancel:(LFAudioTrackBar *)audioTrackBar;

@end
