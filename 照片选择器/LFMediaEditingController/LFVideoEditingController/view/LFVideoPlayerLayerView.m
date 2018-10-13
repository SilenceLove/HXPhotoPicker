//
//  LFVideoPlayerLayerView.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/18.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoPlayerLayerView.h"

@implementation LFVideoPlayerLayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.masksToBounds = YES;
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    return self;
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer*)player
{
    [(AVPlayerLayer*)[self layer] setPlayer:player];
    [(AVPlayerLayer*)[self layer] setVideoGravity:AVLayerVideoGravityResizeAspect];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer*)[self layer] player];
}

@end
