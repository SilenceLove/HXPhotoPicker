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
#import "HXPhotoCustomNavigationBar.h"
@interface HXVideoPreviewViewController ()<UIViewControllerTransitioningDelegate>
@property (strong, nonatomic) UIButton *rightBtn;
@property (assign, nonatomic) BOOL isDelete;
@property (strong, nonatomic) HXPhotoCustomNavigationBar *navBar;
@property (strong, nonatomic) UINavigationItem *navItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@end

@implementation HXVideoPreviewViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isDelete = NO;
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    [self setup];
}
- (HXPhotoCustomNavigationBar *)navBar {
    if (!_navBar) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _navBar = [[HXPhotoCustomNavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, kNavigationBarHeight)];
        _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_navBar pushNavigationItem:self.navItem animated:NO];
        _navBar.tintColor = self.manager.UIManager.navLeftBtnTitleColor;
        if (self.manager.UIManager.navBackgroundImageName) {
            [_navBar setBackgroundImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.navBackgroundImageName] forBarMetrics:UIBarMetricsDefault];
        }else if (self.manager.UIManager.navBackgroundColor) {
            [_navBar setBackgroundColor:self.manager.UIManager.navBackgroundColor];
        }
    }
    return _navBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
        
        _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissClick)];
        _navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBtn];
    }
    return _navItem;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}
- (void)setup {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    [self setupNavRightBtn];
    // 自定义转场动画 添加的一层遮罩
    [self.view addSubview:self.maskView];
    if (self.isCamera) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.model.videoURL];
        self.playVideo = [AVPlayer playerWithPlayerItem:playerItem];
    }else {
        self.playVideo = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.model.avAsset]]; 
    }
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.playVideo];
    self.playerLayer.frame = CGRectMake(0, kNavigationBarHeight, width, height - kNavigationBarHeight);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.playVideo play];
    });
    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playVideo.currentItem];
    self.playBtn.frame = CGRectMake(0, kNavigationBarHeight, width, height - kNavigationBarHeight);
    [self.view addSubview:self.playBtn];
    if (!self.manager.singleSelected) {
        self.selectedBtn.selected = self.model.selected;
        [self.view addSubview:self.selectedBtn];
    }
    if (self.selectedComplete) {
        self.rightBtn.hidden = YES;
        self.selectedBtn.hidden = YES;
    }
    __weak typeof(self) weakSelf = self;
    [self.manager setPhotoLibraryDidChangeWithVideoViewController:^(NSArray *collectionChanges){
        [weakSelf systemAlbumDidChange:collectionChanges];
    }];
    [self.view addSubview:self.navBar];
    if (self.manager.UIManager.navBar) {
        self.manager.UIManager.navBar(self.navBar);
    }
    if (self.manager.UIManager.navItem) {
        self.manager.UIManager.navItem(self.navItem);
    }
    if (self.manager.UIManager.navRightBtn) {
        self.manager.UIManager.navRightBtn(self.rightBtn);
    }
}
- (void)setupNavRightBtn {
    if (self.manager.selectedList.count > 0) {
        self.navItem.rightBarButtonItem.enabled = YES;
        [self.rightBtn setTitle:[NSString stringWithFormat:@"%@(%ld)",[NSBundle hx_localizedStringForKey:@"下一步"],self.manager.selectedList.count] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnNormalBgColor];
        self.rightBtn.layer.borderWidth = 0;
        CGFloat rightBtnH = self.rightBtn.frame.size.height;
        CGFloat rightBtnW = [HXPhotoTools getTextWidth:self.rightBtn.currentTitle height:rightBtnH fontSize:14];
        self.rightBtn.frame = CGRectMake(0, 0, rightBtnW + 20, rightBtnH);
    }else {
        [self.rightBtn setTitle:[NSBundle hx_localizedStringForKey:@"下一步"] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnNormalBgColor];
        self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
        self.rightBtn.layer.borderWidth = 0;
        if (self.model.asset.duration < 3) {
            self.navItem.rightBarButtonItem.enabled = NO;
            [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnDisabledBgColor];
            self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
            self.rightBtn.layer.borderWidth = 0.5;
        }
    }
}
- (void)systemAlbumDidChange:(NSArray *)list {
    if (list.count > 0) {
        NSDictionary *dic = list.firstObject;
        PHFetchResultChangeDetails *collectionChanges = dic[@"collectionChanges"];
        if (collectionChanges) {
            if ([collectionChanges hasIncrementalChanges]) {
                if (collectionChanges.removedObjects.count > 0) {
                    if ([collectionChanges.removedObjects containsObject:self.model.asset]) {
                        self.isDelete = YES;
                        [self setupNavRightBtn];
                        self.selectedBtn.selected = NO;
                    }
                }
            }
        }
    }
}

- (void)dismissClick {
    [self.playVideo pause];
    self.playBtn.selected = NO;
    if (self.selectedComplete) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)pausePlayerAndShowNaviBar {
    [self.playVideo pause];
    self.playBtn.selected = NO;
    [self.playVideo.currentItem seekToTime:CMTimeMake(0, 1)];
}

- (void)didPlayBtnClick:(UIButton *)button {
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
        [_playBtn setImage:[HXPhotoTools hx_imageNamed:@"multimedia_videocard_play@2x.png"] forState:UIControlStateNormal];
        [_playBtn setImage:[[UIImage alloc] init] forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(didPlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _playBtn.selected = YES;
    }
    return _playBtn;
}

- (UIButton *)selectedBtn {
    if (!_selectedBtn) {
        CGFloat width = self.view.frame.size.width;
        _selectedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectedBtn setImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.cellSelectBtnNormalImageName] forState:UIControlStateNormal];
        [_selectedBtn setImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.cellSelectBtnSelectedImageName] forState:UIControlStateSelected];
        CGFloat selectedBtnW = _selectedBtn.currentImage.size.width;
        CGFloat selectedBtnH = _selectedBtn.currentImage.size.height;
        _selectedBtn.frame = CGRectMake(width - 30 - selectedBtnW, kNavigationBarHeight + 20, selectedBtnW, selectedBtnH);
        [_selectedBtn addTarget:self action:@selector(didSelectedClick:) forControlEvents:UIControlEventTouchUpInside];
        [_selectedBtn setEnlargeEdgeWithTop:20 right:20 bottom:20 left:20];
    }
    return _selectedBtn;
}

- (void)selectClick {
    if (!self.selectedBtn.selected && !self.model.selected) {
        [self didSelectedClick:self.selectedBtn];
    }
}

- (void)didSelectedClick:(UIButton *)button {
    if (self.isDelete) {
        [self.view showImageHUDText:@"视频已被删除!"];
        return;
    }
    HXPhotoModel *model = self.model;
    if (!button.selected) {
        NSString *str = [HXPhotoTools maximumOfJudgment:model manager:self.manager];
        if (str) {
            [self.view showImageHUDText:str];
            return;
        }
        if (model.type != HXPhotoModelMediaTypeCameraVideo && model.type != HXPhotoModelMediaTypeCameraPhoto) {
            model.thumbPhoto = self.coverImage;
            model.previewPhoto = self.coverImage;
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
        if (model.type != HXPhotoModelMediaTypeCameraVideo && model.type != HXPhotoModelMediaTypeCameraPhoto) {
            model.thumbPhoto = nil;
            model.previewPhoto = nil;
        }
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            if (model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto) {
                [self.manager.selectedPhotos removeObject:model];
            }else if (model.type == HXPhotoModelMediaTypeVideo) {
                [self.manager.selectedVideos removeObject:model];
            }
        }else if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
            if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                [self.manager.selectedPhotos removeObject:model];
                [self.manager.selectedCameraPhotos removeObject:model];
            }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                [self.manager.selectedVideos removeObject:model];
                [self.manager.selectedCameraVideos removeObject:model];
            }
            [self.manager.selectedCameraList removeObject:model];
        }
        [self.manager.selectedList removeObject:model];
    }
    button.selected = !button.selected;
    model.selected = button.selected;
    if (self.manager.selectedList.count > 0) {
        self.navItem.rightBarButtonItem.enabled = YES;
        [self.rightBtn setTitle:[NSString stringWithFormat:@"%@(%ld)",[NSBundle hx_localizedStringForKey:@"下一步"],self.manager.selectedList.count] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnNormalBgColor];
        self.rightBtn.layer.borderWidth = 0;
        CGFloat rightBtnH = self.rightBtn.frame.size.height;
        CGFloat rightBtnW = [HXPhotoTools getTextWidth:self.rightBtn.currentTitle height:rightBtnH fontSize:14];
        self.rightBtn.frame = CGRectMake(0, 0, rightBtnW + 20, rightBtnH);
    }else {
        [self.rightBtn setTitle:[NSBundle hx_localizedStringForKey:@"下一步"] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnNormalBgColor];
        self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
        self.rightBtn.layer.borderWidth = 0;
    }
    
    if ([self.delegate respondsToSelector:@selector(previewVideoDidSelectedClick:)]) {
        [self.delegate previewVideoDidSelectedClick:model];
    }
}

- (UIButton *)rightBtn {
    if (!_rightBtn) {
        _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightBtn setTitle:[NSBundle hx_localizedStringForKey:@"下一步"] forState:UIControlStateNormal];
        [_rightBtn setTitleColor:self.manager.UIManager.navRightBtnNormalTitleColor forState:UIControlStateNormal];
        [_rightBtn setTitleColor:self.manager.UIManager.navRightBtnDisabledTitleColor forState:UIControlStateDisabled];
        [_rightBtn setTitleColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        _rightBtn.layer.masksToBounds = YES;
        _rightBtn.layer.cornerRadius = 2;
        _rightBtn.layer.borderWidth = 0.5;
        _rightBtn.layer.borderColor = self.manager.UIManager.navRightBtnBorderColor.CGColor;
        [_rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnDisabledBgColor];
        [_rightBtn addTarget:self action:@selector(didNextClick:) forControlEvents:UIControlEventTouchUpInside];
        _rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _rightBtn.frame = CGRectMake(0, 0, 60, 25);
    }
    return _rightBtn;
}

- (void)didNextClick:(UIButton *)button {
    [self.playVideo pause];
    self.playVideo = nil;
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
//    if (!self.isPreview) {
        if (self.manager.selectedList.count == 0) {
            if (!self.selectedBtn.selected && !max) {
                self.model.thumbPhoto = self.coverImage;
                self.model.previewPhoto = self.coverImage;
                self.model.selected = YES;
                [self.manager.selectedList addObject:self.model];
                [self.manager.selectedVideos addObject:self.model];
            }
        }
//    }
    if ([self.delegate respondsToSelector:@selector(previewVideoDidNextClick)]) {
        [self.delegate previewVideoDidNextClick];
    }
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.view.bounds];
        _maskView.backgroundColor = [UIColor whiteColor];
    }
    return _maskView;
}

- (void)dealloc {
    [self.playVideo pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer.player = nil;
    NSSLog(@"dealloc");
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC{
    if (operation == UINavigationControllerOperationPush) {
        return [HXTransition transitionWithType:HXTransitionTypePush VcType:HXTransitionVcTypeVideo];
    }else {
        return [HXTransition transitionWithType:HXTransitionTypePop VcType:HXTransitionVcTypeVideo];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [HXPresentTransition transitionWithTransitionType:HXPresentTransitionTypePresent VcType:HXPresentTransitionVcTypeVideo withPhotoView:self.photoView];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [HXPresentTransition transitionWithTransitionType:HXPresentTransitionTypeDismiss VcType:HXPresentTransitionVcTypeVideo withPhotoView:self.photoView];
}


@end
