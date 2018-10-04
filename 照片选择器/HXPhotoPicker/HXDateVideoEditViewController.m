//
//  HXDateVideoEditViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/12/31.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDateVideoEditViewController.h"

#define hxItemHeight ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown) ? 40 : 50
#define hxItemWidth hxItemHeight/16*9

@interface HXDateVideoEditViewController ()
<
HXDataVideoEditBottomViewDelegate
>
@property (strong, nonatomic) HXDataVideoEditBottomView *bottomView;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) PHImageRequestID requestId;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayer *player;
@end

@implementation HXDateVideoEditViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [self stopTimer];
    [[PHImageManager defaultManager] cancelImageRequest:self.requestId];
    [self.navigationController setNavigationBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        self.orientationDidChange = NO;
        [self changeSubviewFrame];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
    [self changeSubviewFrame];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationWillChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.orientationDidChange = YES;
}
- (void)deviceOrientationWillChanged:(NSNotification *)notify {
//    [self stopTimer];
}
- (void)changeSubviewFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat itemH;
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        itemH = 40;
    }else {
        itemH = 50;
    }
    CGFloat bottomMargin = hxBottomMargin;
    CGFloat width = self.view.hx_w;
    CGFloat bottomX = 0;
    CGFloat videoX = 5;
    CGFloat videoY = hxTopMargin;
    CGFloat videoH;
    CGFloat bottomH = itemH + 5 + 50;
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        bottomX = hxBottomMargin;
        videoY = 0;
        videoX = 30;
        bottomH = itemH;
    }
    videoH = self.view.hx_h - bottomH - videoY - bottomMargin;
    self.bottomView.frame = CGRectMake(bottomX, self.view.hx_h - bottomH - bottomMargin, self.view.hx_w - bottomX * 2, bottomH + bottomMargin);
    self.playerLayer.frame = CGRectMake(videoX, videoY, width - videoX * 2, videoH);
}
- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithRed:31.f / 255.f green:31.f / 255.f blue:31.f / 255.f alpha:1.0f];
    [self.view.layer addSublayer:self.playerLayer];
    [self.view addSubview:self.bottomView];
    
    [self getVideo];
}
- (void)getVideo {
    [self.view showLoadingHUDText:[NSBundle hx_localizedStringForKey:@"加载中"]];
    __weak typeof(self) weakSelf = self;
    self.requestId = [HXPhotoTools getAVAssetWithModel:self.model startRequestIcloud:^(HXPhotoModel *model, PHImageRequestID cloudRequestId) {
        weakSelf.requestId = cloudRequestId;
    } progressHandler:^(HXPhotoModel *model, double progress) {
        
    } completion:^(HXPhotoModel *model, AVAsset *asset) {
        [weakSelf getVideoEachFrame:asset];
    } failed:^(HXPhotoModel *model, NSDictionary *info) {
        [weakSelf.view handleLoading];
    }];
}
- (void)getVideoEachFrame:(AVAsset *)asset {
    __weak typeof(self) weakSelf = self;
    CGFloat itemHeight = 0;
    CGFloat itemWidth = 0;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        itemHeight = 40;
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        itemHeight = 50;
    }
    itemWidth = itemHeight / 16 * 9;
    NSInteger total = (self.view.hx_w - 10) / itemWidth;
    [HXPhotoTools getVideoEachFrameWithAsset:asset total:total size:CGSizeMake(itemWidth * 5, itemHeight * 5) complete:^(AVAsset *asset, NSArray<UIImage *> *images) {
        [weakSelf.view handleLoading];
        weakSelf.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
        weakSelf.playerLayer.player = weakSelf.player;
        [weakSelf.player play];
        weakSelf.bottomView.dataArray = [NSMutableArray arrayWithArray:images];
    }]; 
}
#pragma mark - < HXDataVideoEditBottomViewDelegate >
- (void)videoEditBottomViewDidCancelClick:(HXDataVideoEditBottomView *)bottomView {
    
    if (self.outside) {
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    [self.navigationController popViewControllerAnimated:NO];
}
- (void)videoEditBottomViewDidDoneClick:(HXDataVideoEditBottomView *)bottomView {
    
    if (self.outside) {
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    [self.navigationController popViewControllerAnimated:NO];
}
#pragma mark - < 懒加载 >
- (HXDataVideoEditBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[HXDataVideoEditBottomView alloc] initWithManager:self.manager];
        _bottomView.delegate = self;
    }
    return _bottomView;
}
- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [[AVPlayerLayer alloc] init];
        _playerLayer.backgroundColor = [UIColor colorWithRed:31.f / 255.f green:31.f / 255.f blue:31.f / 255.f alpha:1.0f].CGColor;
    }
    return _playerLayer;
}
@end

@interface HXDataVideoEditBottomView ()
<
UICollectionViewDataSource,
UICollectionViewDelegate
>
@property (strong, nonatomic) UIButton *cancelBtn;
@property (strong, nonatomic) UIButton *doneBtn;
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) HXPhotoManager *manager;
@end

@implementation HXDataVideoEditBottomView
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
        [self setup];
    }
    return self;
}
- (void)setup {
    [self addSubview:self.cancelBtn];
    [self addSubview:self.doneBtn];
    [self addSubview:self.collectionView];
}
- (void)setDataArray:(NSMutableArray *)dataArray {
    _dataArray = dataArray;
    [self.collectionView reloadData];
    [self layoutSubviews];
}
- (void)didCancelBtnClick {
    if ([self.delegate respondsToSelector:@selector(videoEditBottomViewDidCancelClick:)]) {
        [self.delegate videoEditBottomViewDidCancelClick:self];
    }
}
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXDataVideoEditBottomViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CellId" forIndexPath:indexPath];
    cell.imageView.image = self.dataArray[indexPath.item];
    return cell;
}
- (void)layoutSubviews {
    self.cancelBtn.hx_x = 12;
    self.cancelBtn.hx_h = hxItemHeight;
    self.cancelBtn.hx_w = hxItemHeight;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat collectionViewX = 0.0;
    CGFloat collectionViewY = 5;
    CGFloat itemH = hxItemHeight;
    CGFloat itemW = hxItemWidth;
    CGFloat collectionViewW = 0;
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        collectionViewY = 10;
        self.cancelBtn.hx_y = self.hx_h - self.cancelBtn.hx_h - hxBottomMargin;
        collectionViewX = 5;
        collectionViewW = self.hx_w - collectionViewX * 2;
    }else {
        collectionViewX = CGRectGetMaxX(self.cancelBtn.frame);
        collectionViewW = self.hx_w - collectionViewX * 2;
        self.cancelBtn.hx_y = self.hx_h - self.cancelBtn.hx_h - hxBottomMargin + 5;
    }
    if (self.dataArray.count) {
        itemW = collectionViewW / self.dataArray.count;
    }
    self.flowLayout.itemSize = CGSizeMake(itemW, itemH);
    self.collectionView.frame = CGRectMake(collectionViewX, collectionViewY, collectionViewW, hxItemHeight);
}
#pragma mark - < 懒加载 >
- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_cancelBtn setTitle:[NSBundle hx_localizedStringForKey:@"取消"] forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        [_cancelBtn addTarget:self action:@selector(didCancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}
- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        
    }
    return _doneBtn;
}
- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _flowLayout.minimumInteritemSpacing = 0;
        _flowLayout.minimumLineSpacing = 0;
    }
    return _flowLayout;
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[HXDataVideoEditBottomViewCell class] forCellWithReuseIdentifier:@"CellId"];
    }
    return _collectionView;
}
@end

@implementation HXDataVideoEditBottomViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageView];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}
@end
