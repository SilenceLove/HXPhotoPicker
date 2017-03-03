//
//  HXCameraPreviewViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXCameraPreviewViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface HXCameraPreviewViewController ()
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@end

@implementation HXCameraPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setup];
}

- (void)setup
{
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat width = self.view.frame.size.width;
    self.playerItem = [AVPlayerItem playerItemWithURL:self.videoURL];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 64, width, width);
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.player play];
    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)pausePlayerAndShowNaviBar {
    [self.player pause];
    [self.player.currentItem seekToTime:CMTimeMake(0, 1)];
}

@end
