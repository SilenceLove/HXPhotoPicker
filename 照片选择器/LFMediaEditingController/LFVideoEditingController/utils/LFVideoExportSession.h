//
//  LFVideoExportSession.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/26.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LFVideoExportSession : NSObject

/** 初始化 */
- (id)initWithAsset:(AVAsset *)asset;
- (id)initWithURL:(NSURL *)url;

/** 输出路径 */
@property (nonatomic, copy) NSURL *outputURL;
/** 视频剪辑 */
@property (nonatomic, assign) CMTimeRange timeRange;
/** 是否需要原音频 default is YES */
@property (nonatomic, assign) BOOL isOrignalSound;
/** 添加音频 */
@property (nonatomic, strong) NSArray <NSURL *>*audioUrls;
/** 水印层 */
@property (nonatomic, strong) UIView *overlayView;

/** 处理视频 */
- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(NSError *error))handler;
- (void)cancelExport;

@end
