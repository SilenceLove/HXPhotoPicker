//
//  LFVideoPlayerLayerView.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/18.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LFVideoPlayerLayerView : UIImageView

@property (nonatomic, readonly) AVPlayer *player;

- (void)setPlayer:(AVPlayer*)player;

@end
