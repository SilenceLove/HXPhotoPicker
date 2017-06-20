//
//  HXCameraPreviewViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXCameraPreviewViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface HXCameraPreviewViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@property (strong, nonatomic) UITableView *tableView;
@end

@implementation HXCameraPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setup];
}

- (void)setup
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
//    self.view.backgroundColor = [UIColor whiteColor];
//    CGFloat width = self.view.frame.size.width;
//    self.playerItem = [AVPlayerItem playerItemWithURL:self.videoURL];
//    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
//    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
//    self.playerLayer.frame = CGRectMake(0, 64, width, width);
//    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    [self.player play];
//    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.images.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"cellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.imageView.image = self.images[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 375;
}


- (void)pausePlayerAndShowNaviBar {
    [self.player pause];
    [self.player.currentItem seekToTime:CMTimeMake(0, 1)];
}

@end
