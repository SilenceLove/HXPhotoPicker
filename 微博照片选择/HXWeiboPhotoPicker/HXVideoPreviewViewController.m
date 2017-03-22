//
//  HXVideoPreviewViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/9.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXVideoPreviewViewController.h"
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>
#import "HXTransition.h"
#import "UIView+HXExtension.h"
#import "UIButton+HXExtension.h"
#import "HXPresentTransition.h"
@interface HXVideoPreviewViewController ()<UIViewControllerTransitioningDelegate>
@property (strong, nonatomic) UIButton *rightBtn;
@property (strong, nonatomic) UIButton *selectedBtn;
@end

@implementation HXVideoPreviewViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setup];
}

- (void)setup
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBtn];
    if (self.manager.selectedList.count > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [self.rightBtn setTitle:[NSString stringWithFormat:@"下一步(%ld)",self.manager.selectedList.count] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1]];
        self.rightBtn.layer.borderWidth = 0;
        CGFloat rightBtnH = self.rightBtn.frame.size.height;
        CGFloat rightBtnW = [HXPhotoTools getTextWidth:self.rightBtn.currentTitle withHeight:rightBtnH fontSize:14];
        self.rightBtn.frame = CGRectMake(0, 0, rightBtnW + 20, rightBtnH);
    }else {
        [self.rightBtn setTitle:@"下一步" forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1]];
        self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
        self.rightBtn.layer.borderWidth = 0;
        if (self.model.asset.duration < 3) {
            self.rightBtn.enabled = NO;
            [self.rightBtn setBackgroundColor:[UIColor whiteColor]];
            self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
            self.rightBtn.layer.borderWidth = 0.5;
        }
    }
    if (!self.isTouch) {
        [self.view addSubview:self.maskView];
    }
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    if (self.isCamera) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.model.videoURL];
        self.playVideo = [AVPlayer playerWithPlayerItem:playerItem];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.playVideo];
        playerLayer.frame = CGRectMake(0, 64, width, height - 64);
        if (!self.isTouch) {
            [self.playVideo play];
        }
        [self.view.layer insertSublayer:playerLayer atIndex:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playVideo.currentItem];
        self.playBtn.frame = CGRectMake(0, 64, width, height - 64);
        [self.view addSubview:self.playBtn];
        self.selectedBtn.selected = self.model.selected;
        [self.view addSubview:self.selectedBtn];
    }else {
        [[PHImageManager defaultManager] requestPlayerItemForVideo:self.model.asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.playVideo = [AVPlayer playerWithPlayerItem:playerItem];
                AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.playVideo];
                playerLayer.frame = CGRectMake(0, 64, width, height - 64);
                if (!self.isTouch) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.playVideo play];
                    });
                }
                [self.view.layer insertSublayer:playerLayer atIndex:0];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playVideo.currentItem];
                self.playBtn.frame = CGRectMake(0, 64, width, height - 64);
                [self.view addSubview:self.playBtn];
                self.selectedBtn.selected = self.model.selected;
                [self.view addSubview:self.selectedBtn];
            });
        }];
    }
    if (self.selectedComplete) {
        self.rightBtn.hidden = YES;
        self.selectedBtn.hidden = YES;
        UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, 64)];
        [self.view addSubview:navBar];
        UINavigationItem *navItem = [[UINavigationItem alloc] init];
        [navBar pushNavigationItem:navItem animated:NO];
        
        navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismissClick)];
        navBar.tintColor = [UIColor blackColor];
    }
}

- (void)dismissClick
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pausePlayerAndShowNaviBar {
    [self.playVideo pause];
    self.playBtn.selected = NO;
    [self.playVideo.currentItem seekToTime:CMTimeMake(0, 1)];
}

- (void)didPlayBtnClick:(UIButton *)button
{
    button.selected = !button.selected;
    
    if (button.selected) {
        [self.playVideo play];
    }else {
        [self.playVideo pause];
    }
}

- (UIButton *)playBtn
{
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamed:@"multimedia_videocard_play@2x.png"] forState:UIControlStateNormal];
        [_playBtn setImage:[[UIImage alloc] init] forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(didPlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _playBtn.selected = YES;
    }
    return _playBtn;
}

- (UIButton *)selectedBtn
{
    if (!_selectedBtn) {
        CGFloat width = self.view.frame.size.width;
        _selectedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectedBtn setImage:[UIImage imageNamed:@"compose_guide_check_box_default@2x.png"] forState:UIControlStateNormal];
        [_selectedBtn setImage:[UIImage imageNamed:@"compose_guide_check_box_right@2x.png"] forState:UIControlStateSelected];
        CGFloat selectedBtnW = _selectedBtn.currentImage.size.width;
        CGFloat selectedBtnH = _selectedBtn.currentImage.size.height;
        _selectedBtn.frame = CGRectMake(width - 30 - selectedBtnW, 84, selectedBtnW, selectedBtnH);
        [_selectedBtn addTarget:self action:@selector(didSelectedClick:) forControlEvents:UIControlEventTouchUpInside];
        [_selectedBtn setEnlargeEdgeWithTop:20 right:20 bottom:20 left:20];
    }
    return _selectedBtn;
}

- (void)selectClick
{
    if (!self.selectedBtn.selected) {
        [self didSelectedClick:self.selectedBtn];
    }
}

- (void)didSelectedClick:(UIButton *)button
{
    HXPhotoModel *model = self.model;
    if (!button.selected) {
        if (self.manager.selectedList.count == self.manager.maxNum) {
            // 已经达到最大选择数
            [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld个",self.manager.maxNum]];
            return;
        }
        if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
            if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
                if (self.manager.photoMaxNum > 0) {
                    if (!self.manager.selectTogether) { // 是否支持图片视频同时选择
                        if (self.manager.selectedPhotos.count > 0 ) {
                            // 已经选择了图片,不能再选视频
                            [self.view showImageHUDText:@"视频不能和图片同时选择"];
                            return;
                        }
                    }
                }
                if (self.manager.selectedVideos.count == self.manager.videoMaxNum) {
                    // 已经达到视频最大选择数
                    [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld个视频",self.manager.videoMaxNum]];
                    return;
                }
            }
        }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
            if (self.manager.selectedVideos.count == self.manager.videoMaxNum) {
                // 已经达到视频最大选择数
                [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld个视频",self.manager.videoMaxNum]];
                return;
            }
        }
        if (model.type == HXPhotoModelMediaTypeVideo) {
            if (model.asset.duration < 3) {
                [self.view showImageHUDText:@"视频少于3秒,暂不支持"];
                return;
            }
        }
        if (model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) {
            [self.manager.selectedPhotos addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeVideo) {
            [self.manager.selectedVideos addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            [self.manager.selectedPhotos addObject:model];
            [self.manager.selectedCameraPhotos addObject:model];
            [self.manager.selectedCameraList addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            [self.manager.selectedVideos addObject:model];
            [self.manager.selectedCameraVideos addObject:model];
            [self.manager.selectedCameraList addObject:model];
        }
        [self.manager.selectedList addObject:model];
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        anim.duration = 0.25;
        anim.values = @[@(1.2),@(0.8),@(1.1),@(0.9),@(1.0)];
        [button.layer addAnimation:anim forKey:@""];
    }else {
        int i = 0;
        for (HXPhotoModel *subModel in self.manager.selectedList) {
            if ([subModel.asset.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                if (model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) {
                    [self.manager.selectedPhotos removeObject:subModel];
                }else if (model.type == HXPhotoModelMediaTypeVideo) {
                    [self.manager.selectedVideos removeObject:subModel];
                }
                [self.manager.selectedList removeObjectAtIndex:i];
                break;
            }else if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo){
                if ([subModel.cameraIdentifier isEqualToString:model.cameraIdentifier]) {
                    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                        [self.manager.selectedPhotos removeObject:subModel];
                        [self.manager.selectedCameraPhotos removeObject:subModel];
                    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                        [self.manager.selectedVideos removeObject:subModel];
                        [self.manager.selectedCameraVideos removeObject:subModel];
                    }
                    [self.manager.selectedList removeObjectAtIndex:i];
                    [self.manager.selectedCameraList removeObject:subModel];
                    break;
                }
            }
            i++;
        }
    }
    button.selected = !button.selected;
    model.selected = button.selected;
    if (self.manager.selectedList.count > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [self.rightBtn setTitle:[NSString stringWithFormat:@"下一步(%ld)",self.manager.selectedList.count] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1]];
        self.rightBtn.layer.borderWidth = 0;
        CGFloat rightBtnH = self.rightBtn.frame.size.height;
        CGFloat rightBtnW = [HXPhotoTools getTextWidth:self.rightBtn.currentTitle withHeight:rightBtnH fontSize:14];
        self.rightBtn.frame = CGRectMake(0, 0, rightBtnW + 20, rightBtnH);
    }else {
        [self.rightBtn setTitle:@"下一步" forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1]];
        self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
        self.rightBtn.layer.borderWidth = 0;
    }
    
    if ([self.delegate respondsToSelector:@selector(previewVideoDidSelectedClick:)]) {
        [self.delegate previewVideoDidSelectedClick:model];
    }
}

- (UIButton *)rightBtn
{
    if (!_rightBtn) {
        _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightBtn setTitle:@"下一步" forState:UIControlStateNormal];
        [_rightBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_rightBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [_rightBtn setTitleColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        _rightBtn.layer.masksToBounds = YES;
        _rightBtn.layer.cornerRadius = 2;
        _rightBtn.layer.borderWidth = 0.5;
        _rightBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
        [_rightBtn setBackgroundColor:[UIColor whiteColor]];
        [_rightBtn addTarget:self action:@selector(didNextClick:) forControlEvents:UIControlEventTouchUpInside];
        _rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _rightBtn.frame = CGRectMake(0, 0, 60, 25);
    }
    return _rightBtn;
}

- (void)didNextClick:(UIButton *)button
{
    BOOL max = NO;
    if (self.manager.selectedList.count == self.manager.maxNum) {
        // 已经达到最大选择数
        max = YES;
    }
    if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
        if (self.model.type == HXPhotoModelMediaTypeVideo || self.model.type == HXPhotoModelMediaTypeCameraVideo) {
            if (self.manager.photoMaxNum > 0) {
                if (!self.manager.selectTogether) { // 是否支持图片视频同时选择
                    if (self.manager.selectedPhotos.count > 0 ) {
                        // 已经选择了图片,不能再选视频
                        max = YES;
                    }
                }
            }
            if (self.manager.selectedVideos.count == self.manager.videoMaxNum) {
                // 已经达到视频最大选择数
                max = YES;
            }
        }
    }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
        if (self.manager.selectedVideos.count == self.manager.videoMaxNum) {
            // 已经达到视频最大选择数
            max = YES;
        }
    }
    if (self.model.type == HXPhotoModelMediaTypeVideo) {
        if (self.model.asset.duration < 3) {
            max = YES;
        }
    }
    if (!self.selectedBtn.selected && !max) {
        self.model.selected = YES;
        [self.manager.selectedList addObject:self.model];
        [self.manager.selectedVideos addObject:self.model];
    }
    if ([self.delegate respondsToSelector:@selector(previewVideoDidNextClick)]) {
        [self.delegate previewVideoDidNextClick];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.playVideo pause];
    self.playBtn.selected = NO;
}

- (UIView *)maskView
{
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.view.bounds];
        _maskView.backgroundColor = [UIColor whiteColor];
    }
    return _maskView;
}


- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC{
    if (operation == UINavigationControllerOperationPush) {
        return [HXTransition transitionWithType:HXTransitionTypePush VcType:HXTransitionVcTypeVideo];
    }else {
        return [HXTransition transitionWithType:HXTransitionTypePop VcType:HXTransitionVcTypeVideo];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [HXPresentTransition transitionWithTransitionType:HXPresentTransitionTypePresent VcType:HXPresentTransitionVcTypeVideo];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [HXPresentTransition transitionWithTransitionType:HXPresentTransitionTypeDismiss VcType:HXPresentTransitionVcTypeVideo];
}


@end
