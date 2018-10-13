//
//  LFVideoPlayer.m
//  VideoPlayDemo
//
//  Created by LamTsanFeng on 2016/11/17.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFVideoPlayer.h"
enum
{
    kCMPersistentTrackID_Orignail_Invalid = 90
};

@interface LFVideoPlayer ()

/** 视频播放对象 */
@property (strong) AVPlayerItem* mPlayerItem;

/** 视频播放器 */
@property (strong) AVPlayer* player;

@property (nonatomic ,strong) AVMutableAudioMix *audioMix;

@end

static void *LFPlayerRateObservationContext = &LFPlayerRateObservationContext;
static void *LFPlayerStatusObservationContext = &LFPlayerStatusObservationContext;
static void *LFPlayerCurrentItemObservationContext = &LFPlayerCurrentItemObservationContext;

@implementation LFVideoPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _size = CGSizeZero;
    }
    return self;
}

- (void)dealloc
{
    [self removePlayerTimeObserver];
    
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.player removeObserver:self forKeyPath:@"currentItem"];
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.mPlayerItem];
    
    [self.player pause];
}


#pragma mark Asset URL

- (void)setURL:(NSURL*)URL
{
    if (mURL != URL)
    {
        mURL = [URL copy];
        
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         Load the values for the asset key "playable".
         */
        self.asset = [AVURLAsset URLAssetWithURL:mURL options:nil];
        
        
    }
}

- (NSURL*)URL
{
    return mURL;
}

- (void)setAsset:(AVAsset *)asset
{
    _asset = asset;
    self.muteOriginalSound = NO;
    
    /** size */
    CGSize videoSize = CGSizeZero;
    NSArray *assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (assetVideoTracks.count > 0)
    {
        // Insert the tracks in the composition's tracks
        AVAssetTrack *track = [assetVideoTracks firstObject];
        
        CGSize dimensions = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
        videoSize = CGSizeMake(fabs(dimensions.width), fabs(dimensions.height));
    } else {
        NSLog(@"Error reading the transformed video track");
    }
    _size = videoSize;
    
    
    NSArray *requestedKeys = @[@"playable"];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
     ^{
         dispatch_async( dispatch_get_main_queue(),
                        ^{
                            /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                            [self prepareToPlayAsset:asset withKeys:requestedKeys];
                        });
     }];
}

#pragma mark Asset audioMix
- (void)setAsset:(AVAsset *)asset audioUrls:(NSArray <NSURL *>*)audioUrls
{
    self.audioMix = nil;
    _audioUrls = audioUrls;
    if (audioUrls.count && asset) {
        
        AVAssetTrack *assetVideoTrack = nil;
        AVAssetTrack *assetAudioTrack = nil;
        // Check if the asset contains video and audio tracks
        if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
            assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
        }
        if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
            assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
        }
        
        CMTime insertionPoint = kCMTimeZero;
        
        // Step 1
        // Create a composition with the given asset and insert audio and video tracks into it from the asset
        // Check if a composition already exists, else create a composition using the input asset
        
        AVMutableComposition *composition = [[AVMutableComposition alloc] init];
        
        // Insert the video and audio tracks from AVAsset
        if (assetVideoTrack != nil) {
            // 视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
            AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            // 视频方向
            [compositionVideoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
            // 把视频轨道数据加入到可变轨道中 这部分可以做视频裁剪TimeRange
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:assetVideoTrack atTime:insertionPoint error:nil];
        }
        
        if (assetAudioTrack != nil) {
            AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Orignail_Invalid];
            [compositionAudioTrack setPreferredTransform:assetAudioTrack.preferredTransform];
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:assetAudioTrack atTime:insertionPoint error:nil];
        }
        
        /** 创建额外音轨特效 */
        NSMutableArray<AVAudioMixInputParameters *> *inputParameters = [@[] mutableCopy];
        for (NSURL *audioUrl in audioUrls) {
            /** 声音采集 */
            AVURLAsset *audioAsset =[[AVURLAsset alloc]initWithURL:audioUrl options:nil];
            AVAssetTrack *additional_assetAudioTrack = nil;
            /** 检查是否有效音轨 */
            if ([[audioAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
                additional_assetAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
            }
            if (additional_assetAudioTrack) {
                AVMutableCompositionTrack *additional_compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                [additional_compositionAudioTrack setPreferredTransform:additional_assetAudioTrack.preferredTransform];
                [additional_compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, composition.duration) ofTrack:additional_assetAudioTrack atTime:insertionPoint error:nil];
                
                AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:additional_compositionAudioTrack];
                CMTimeRange timeRange = self.endTime > 0 ? CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(self.endTime, composition.duration.timescale)) : CMTimeRangeMake(kCMTimeZero, composition.duration);
                [mixParameters setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:timeRange];
                [inputParameters addObject:mixParameters];
            }
            if (inputParameters.count) {
                AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
                [audioMix setInputParameters:inputParameters];
                [self.mPlayerItem setAudioMix:audioMix];
                self.audioMix = audioMix;
            }
        }
        self.asset = composition;
    } else {
        self.asset = asset;
    }
    
}

- (void)setMuteOriginalSound:(BOOL)muteOriginalSound
{
    if (_muteOriginalSound != muteOriginalSound) {
        _muteOriginalSound = muteOriginalSound;
        [self mute:NO];
        if ([self.asset isKindOfClass:[AVMutableComposition class]]) {
            self.endTime = self.endTime;
        } else {
            self.audioMix = nil;
            [self mute:muteOriginalSound];
        }
    }
}

- (void)setEndTime:(CGFloat)endTime
{
    _endTime = endTime;
    if ([self.asset isKindOfClass:[AVMutableComposition class]]) {
        NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
        NSMutableArray *allAudioParams = [NSMutableArray array];
        CMTimeRange timeRange = self.endTime > 0 ? CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(self.endTime, self.asset.duration.timescale)) : CMTimeRangeMake(kCMTimeZero, self.asset.duration);
        for (AVAssetTrack *track in audioTracks) {
            AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
            if ([track trackID] == kCMPersistentTrackID_Orignail_Invalid) {
                [audioInputParams setVolume:(self.muteOriginalSound ? 0 : 1) atTime:kCMTimeZero];
            } else {
                [audioInputParams setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:timeRange];
            }
            [allAudioParams addObject:audioInputParams];
        }
        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        [audioMix setInputParameters:allAudioParams];
        [self.mPlayerItem setAudioMix:audioMix];
        self.audioMix = audioMix;
    }
}

#pragma mark
#pragma mark Button Action Methods

- (void)play
{
    /* If we are at the end of the movie, we must seek to the beginning first
     before starting playback. */
    if (YES == seekToZeroBeforePlay)
    {
        seekToZeroBeforePlay = NO;
        [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
    
    [self.player play];
}

- (void)pause
{
    [self.player pause];
}

/** 静音 */
- (void)mute:(BOOL)mute
{
    self.player.muted = mute;
}

- (void)resetDisplay
{
    seekToZeroBeforePlay = NO;
    [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

/** 跳转到某帧 */
- (void)seekToTime:(CGFloat)time
{
    [self.player seekToTime:CMTimeMakeWithSeconds(time, self.mPlayerItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark -
#pragma mark Movie scrubber control

/* ---------------------------------------------------------
 **  Methods to handle manipulation of the movie scrubber control
 ** ------------------------------------------------------- */

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
-(void)initScrubberTimer
{
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        CGFloat progressWidth = [UIScreen mainScreen].bounds.size.width;
        if ([self.delegate respondsToSelector:@selector(LFVideoPlayerSyncScrub:)]) {
            UISlider *slider = [self.delegate LFVideoPlayerSyncScrub:self];
            if ([slider isKindOfClass:[UISlider class]]) {
                progressWidth = CGRectGetWidth(slider.frame);
            }
        } else if ([self.delegate respondsToSelector:@selector(LFVideoPlayerSyncScrubProgressWidth:)]) {
            progressWidth = [self.delegate LFVideoPlayerSyncScrubProgressWidth:self];
        }
        CGFloat width = progressWidth;
        interval = 0.5f * duration / width;
    }
    
    /* Update the scrubber during normal playback. */
    __weak typeof(self) weakSelf = self;
    mTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                              queue:NULL /* If you pass NULL, the main queue is used. */
                                                         usingBlock:^(CMTime time)
                     {
                         [weakSelf syncScrubber];
                     }];
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        if ([self.delegate respondsToSelector:@selector(LFVideoPlayerSyncScrub:)]) {
            UISlider *slider = [self.delegate LFVideoPlayerSyncScrub:self];
            if ([slider isKindOfClass:[UISlider class]]) {
                slider.value = 0.0;
            }
        } else if (self.player.status == AVPlayerStatusReadyToPlay && [self.delegate respondsToSelector:@selector(LFVideoPlayerSyncScrub:duration:)]) {
            [self.delegate LFVideoPlayerSyncScrub:self duration:0.0];
        }
        return;
    }
    
    double totalDuration = CMTimeGetSeconds(playerDuration);
    if (isfinite(totalDuration))
    {
        _duration = CMTimeGetSeconds([self.player currentTime]);
        
        if ([self.delegate respondsToSelector:@selector(LFVideoPlayerSyncScrub:)]) {
            UISlider *slider = [self.delegate LFVideoPlayerSyncScrub:self];
            if ([slider isKindOfClass:[UISlider class]]) {
                float minValue = slider.minimumValue;
                float maxValue = slider.maximumValue;
                
                float value = (maxValue - minValue) * _duration / totalDuration + minValue;
                slider.value = value;
            }
        } else if (self.player.status == AVPlayerStatusReadyToPlay &&[self.delegate respondsToSelector:@selector(LFVideoPlayerSyncScrub:duration:)]) {
            [self.delegate LFVideoPlayerSyncScrub:self duration:_duration];
        }
    }
    
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (void)beginScrubbing
{
    mRestoreAfterScrubbingRate = [self.player rate];
    [self.player setRate:0.f];
    
    /* Remove previous timer. */
    [self removePlayerTimeObserver];
}

/* Set the player current time to match the scrubber position. */
- (void)scrub:(UISlider *)slider
{
    if ([slider isKindOfClass:[UISlider class]] && !isSeeking)
    {
        isSeeking = YES;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            float minValue = slider.minimumValue;
            float maxValue = slider.maximumValue;
            float value = slider.value;
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            NSLog(@"%f", time);
            [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    isSeeking = NO;
                });
            }];
        }
    }
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (void)endScrubbing
{
    if (!mTimeObserver)
    {
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration))
        {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            CGFloat progressWidth = [UIScreen mainScreen].bounds.size.width;
            if ([self.delegate respondsToSelector:@selector(LFVideoPlayerSyncScrub:)]) {
                UISlider *slider = [self.delegate LFVideoPlayerSyncScrub:self];
                if ([slider isKindOfClass:[UISlider class]]) {
                    progressWidth = CGRectGetWidth(slider.frame);
                }
            } else if ([self.delegate respondsToSelector:@selector(LFVideoPlayerSyncScrubProgressWidth:)]) {
                progressWidth = [self.delegate LFVideoPlayerSyncScrubProgressWidth:self];
            }
            CGFloat width = progressWidth;
            double tolerance = 0.5f * duration / width;
            
            __weak typeof(self) weakSelf = self;
            mTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:NULL usingBlock:
                             ^(CMTime time)
                             {
                                 [weakSelf syncScrubber];
                             }];
        }
    }
    
    if (mRestoreAfterScrubbingRate)
    {
        [self.player setRate:mRestoreAfterScrubbingRate];
        mRestoreAfterScrubbingRate = 0.f;
    }
}

- (BOOL)isScrubbing
{
    return mRestoreAfterScrubbingRate != 0.f;
}

#pragma mark Player Item

- (BOOL)isPlaying
{
    return mRestoreAfterScrubbingRate != 0.f || [self.player rate] != 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    /* After the movie has played to its end time, seek back to time zero
     to play it again. */
    seekToZeroBeforePlay = YES;
    if ([self.delegate respondsToSelector:@selector(LFVideoPlayerPlayDidReachEnd:)]) {
        [self.delegate LFVideoPlayerPlayDidReachEnd:self];
    }
}

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem.
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = [self.player currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return([playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}


/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
    if (mTimeObserver)
    {
        [self.player removeTimeObserver:mTimeObserver];
        mTimeObserver = nil;
    }
}

#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 **
 **  1) values of asset keys did not load successfully,
 **  2) the asset keys did load successfully, but the asset is not
 **     playable
 **  3) the item did not become ready to play.
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    
    if ([self.delegate respondsToSelector:@selector(LFVideoPlayerFailedToPrepare:error:)]) {
        [self.delegate LFVideoPlayerFailedToPrepare:self error:error];
    }
    
    /* Display the error. */
    //    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
    //                                                        message:[error localizedFailureReason]
    //                                                       delegate:nil
    //                                              cancelButtonTitle:@"OK"
    //                                              otherButtonTitles:nil];
    //    [alertView show];
}


#pragma mark Prepare to play asset, URL

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.mPlayerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.mPlayerItem removeObserver:self forKeyPath:@"status"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.mPlayerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.mPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.mPlayerItem.audioMix = self.audioMix;
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.mPlayerItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:LFPlayerStatusObservationContext];
    
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.mPlayerItem];
    
    seekToZeroBeforePlay = NO;
    
    /* Create new player, if we don't already have one. */
    if (!self.player)
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        self.player = [AVPlayer playerWithPlayerItem:self.mPlayerItem];
        
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:@"currentItem"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:LFPlayerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:LFPlayerRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.mPlayerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur
         
         If needed, configure player item here (example: adding outputs, setting text style rules,
         selecting media options) before associating it with a player
         */
        [self.player replaceCurrentItemWithPlayerItem:self.mPlayerItem];
    }
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" property value observer. */
    if (context == LFPlayerStatusObservationContext)
    {
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerItemStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self syncScrubber];
            }
                break;
                
            case AVPlayerItemStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                [self initScrubberTimer];
                
                if ([self.delegate respondsToSelector:@selector(LFVideoPlayerReadyToPlay:duration:)]) {
                    double duration = 0.0;
                    CMTime playerDuration = [self playerItemDuration];
                    if (!CMTIME_IS_INVALID(playerDuration))
                    {
                        duration = CMTimeGetSeconds(playerDuration);
                    }
                    _totalDuration = duration;
                    [self.delegate LFVideoPlayerReadyToPlay:self duration:duration];
                }
            }
                break;
                
            case AVPlayerItemStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
        }
    }
    /* AVPlayer "rate" property value observer. */
    else if (context == LFPlayerRateObservationContext)
    {
        
    }
    /* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
    else if (context == LFPlayerCurrentItemObservationContext)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            
        }
        else /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            
            /* Specifies that the player should preserve the video’s aspect ratio and
             fit the video within the layer’s bounds. */
            
            /** AVLayerVideoGravityResizeAspect */
            if ([self.delegate respondsToSelector:@selector(LFVideoPlayerLayerDisplay:avplayer:)]) {
                [self.delegate LFVideoPlayerLayerDisplay:self avplayer:self.player];
            }
        }
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

#pragma mark - fix video orientation
+ (AVMutableVideoComposition *)fixVideoOrientationWithAsset:(AVAsset *)asset
{
    AVMutableVideoComposition *videoComposition = nil;
    AVAssetTrack *assetVideoTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    
    if (assetVideoTrack != nil) {
        UIImageOrientation orientation = [self orientationFromAVAssetTrack:assetVideoTrack];
        
        if (orientation != UIImageOrientationUp) {
            videoComposition = [AVMutableVideoComposition videoComposition];
            videoComposition.frameDuration = asset.duration;
            
            CGAffineTransform transform = CGAffineTransformIdentity;
            CGSize renderSize = assetVideoTrack.naturalSize;
            
            switch (orientation) {
                case UIImageOrientationLeft:
                    //顺时针旋转270°
                    //            NSLog(@"视频旋转270度，home按键在右");
                    transform = CGAffineTransformTranslate(transform, 0.0, assetVideoTrack.naturalSize.width);
                    transform = CGAffineTransformRotate(transform,M_PI_2*3.0);
                    renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
                    break;
                case UIImageOrientationRight:
                    //顺时针旋转90°
                    //            NSLog(@"视频旋转90度,home按键在左");
                    transform = CGAffineTransformTranslate(transform, assetVideoTrack.naturalSize.height, 0.0);
                    transform = CGAffineTransformRotate(transform,M_PI_2);
                    renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
                    break;
                case UIImageOrientationDown:
                    //顺时针旋转180°
                    //            NSLog(@"视频旋转180度，home按键在上");
                    transform = CGAffineTransformTranslate(transform, assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
                    transform = CGAffineTransformRotate(transform,M_PI);
                    renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
                    break;
                default:
                    break;
            }
            
            videoComposition.renderSize = renderSize;
            
            AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
            AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
            
            [roateLayerInstruction setTransform:transform atTime:kCMTimeZero];
            
            roateInstruction.layerInstructions = @[roateLayerInstruction];
            //将视频方向旋转加入到视频处理中
            videoComposition.instructions = @[roateInstruction];
        }
        
    }
    
    return videoComposition;
}

+ (UIImageOrientation)orientationFromAVAssetTrack:(AVAssetTrack *)videoTrack
{
    UIImageOrientation orientation = UIImageOrientationUp;
    CGAffineTransform t = videoTrack.preferredTransform;
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
        // Portrait
        //        degress = 90;
        orientation = UIImageOrientationRight;
    }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
        // PortraitUpsideDown
        //        degress = 270;
        orientation = UIImageOrientationLeft;
    }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
        // LandscapeRight
        //        degress = 0;
        orientation = UIImageOrientationUp;
    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
        // LandscapeLeft
        //        degress = 180;
        orientation = UIImageOrientationDown;
    }
    
    return orientation;
}


@end

