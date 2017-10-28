//
//  HXDatePhotoPreviewViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoPreviewViewController.h"
#import "UIImage+HXExtension.h"
#import "HXDatePhotoPreviewBottomView.h"
#import "UIButton+HXExtension.h"
#import "HXDatePhotoViewTransition.h"
#import "HXDatePhotoInteractiveTransition.h"
#import "HXDatePhotoViewPresentTransition.h"
#import "HXPhotoCustomNavigationBar.h"

@interface HXDatePhotoPreviewViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,HXDatePhotoPreviewBottomViewDelegate>
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) HXPhotoModel *currentModel;
@property (strong, nonatomic) UIView *customTitleView;
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) UILabel *subTitleLb;
@property (strong, nonatomic) HXDatePhotoPreviewViewCell *tempCell;
@property (strong, nonatomic) UIButton *selectBtn;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) NSInteger beforeOrientationIndex;
@property (strong, nonatomic) HXDatePhotoInteractiveTransition *interactiveTransition;
@property (strong, nonatomic) HXPhotoCustomNavigationBar *navBar;
@property (strong, nonatomic) UINavigationItem *navItem;
@end

@implementation HXDatePhotoPreviewViewController
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
    // Do any additional setup after loading the view.
    [self setupUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    //初始化手势过渡的代理
    self.interactiveTransition = [[HXDatePhotoInteractiveTransition alloc] init];
    //给当前控制器的视图添加手势
    [self.interactiveTransition addPanGestureForViewController:self];
}
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC{
    if (operation == UINavigationControllerOperationPush) {
        return [HXDatePhotoViewTransition transitionWithType:HXDatePhotoViewTransitionTypePush];
    }else {
        return [HXDatePhotoViewTransition transitionWithType:HXDatePhotoViewTransitionTypePop];
    }
}
- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController{
    return self.interactiveTransition.interation ? self.interactiveTransition : nil;
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [HXDatePhotoViewPresentTransition transitionWithTransitionType:HXDatePhotoViewPresentTransitionTypePresent photoView:self.photoView];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [HXDatePhotoViewPresentTransition transitionWithTransitionType:HXDatePhotoViewPresentTransitionTypeDismiss photoView:self.photoView];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        self.orientationDidChange = NO;
        [self changeSubviewFrame];
    }
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.beforeOrientationIndex = self.currentModelIndex;
    self.orientationDidChange = YES;
}
- (HXDatePhotoPreviewViewCell *)currentPreviewCell:(HXPhotoModel *)model {
    if (!model) {
        return nil;
    }
    return (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
}
- (void)changeSubviewFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        self.titleLb.hidden = NO;
        self.customTitleView.frame = CGRectMake(0, 0, 150, 44);
        self.titleLb.frame = CGRectMake(0, 9, 150, 14);
        self.subTitleLb.frame = CGRectMake(0, CGRectGetMaxY(self.titleLb.frame) + 4, 150, 12);
        self.titleLb.text = model.barTitle;
        self.subTitleLb.text = model.barSubTitle;
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        self.customTitleView.frame = CGRectMake(0, 0, 200, 30);
        self.titleLb.hidden = YES;
        self.subTitleLb.frame = CGRectMake(0, 0, 200, 30);
        self.subTitleLb.text = [NSString stringWithFormat:@"%@  %@",model.barTitle,model.barSubTitle];
    }
    CGFloat bottomMargin = kBottomMargin;
//    CGFloat leftMargin = 0;
//    CGFloat rightMargin = 0;
    CGFloat width = self.view.hx_w;
    CGFloat itemMargin = 20;
    if (kDevice_Is_iPhoneX && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        bottomMargin = 21;
//        leftMargin = 35;
//        rightMargin = 35;
//        width = self.view.hx_w - 70;
    }
    self.flowLayout.itemSize = CGSizeMake(width, self.view.hx_h - kTopMargin - bottomMargin);
    self.flowLayout.minimumLineSpacing = itemMargin;
    
    [self.collectionView setCollectionViewLayout:self.flowLayout];
    
//    self.collectionView.contentInset = UIEdgeInsetsMake(0, leftMargin, 0, rightMargin);
    if (self.outside) {
        self.navBar.frame = CGRectMake(0, 0, self.view.hx_w, kNavigationBarHeight);
    }
    self.collectionView.frame = CGRectMake(-(itemMargin / 2), kTopMargin,self.view.hx_w + itemMargin, self.view.hx_h - kTopMargin - bottomMargin);
    self.collectionView.contentSize = CGSizeMake(self.modelArray.count * (self.view.hx_w + itemMargin), 0);
    
    [self.collectionView setContentOffset:CGPointMake(self.beforeOrientationIndex * (self.view.hx_w + itemMargin), 0)];
    
    [UIView performWithoutAnimation:^{
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.beforeOrientationIndex inSection:0]]];
    }];

    self.bottomView.frame = CGRectMake(0, self.view.hx_h - 50 - bottomMargin, self.view.hx_w, 50 + bottomMargin);
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    self.currentModel = model;
    HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    if (!cell) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            HXDatePhotoPreviewViewCell *tempCell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
            self.tempCell = tempCell;
            [tempCell requestHDImage];
        });
    }else { 
        self.tempCell = cell;
        [cell requestHDImage];
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    [cell cancelRequest];
}
- (void)setupUI {
    self.navigationItem.titleView = self.customTitleView;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.bottomView];
    self.beforeOrientationIndex = self.currentModelIndex;
    [self changeSubviewFrame];
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    if (!self.outside) {
        self.bottomView.selectCount = self.manager.selectedList.count;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.selectBtn];
        self.selectBtn.selected = model.selected;
        [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
        self.selectBtn.backgroundColor = self.selectBtn.selected ? self.view.tintColor : nil;
        if ([self.manager.selectedList containsObject:model]) {
            self.bottomView.currentIndex = [self.manager.selectedList indexOfObject:model];
        }else {
            [self.bottomView deselected];
        }
    }else {
        self.bottomView.selectCount = self.manager.endSelectedList.count;
        if ([self.manager.endSelectedList containsObject:model]) {
            self.bottomView.currentIndex = [self.manager.endSelectedList indexOfObject:model];
        }else {
            [self.bottomView deselected];
        }
        [self.view addSubview:self.navBar];
    }
}
- (void)didSelectClick:(UIButton *)button {
    if (self.modelArray.count <= 0 || self.outside) {
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"没有照片可选!"]];
        return;
    }
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    if (button.selected) {
        button.selected = NO;
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
        model.selectIndexStr = @"";
    }else {
        NSString *str = [HXPhotoTools maximumOfJudgment:model manager:self.manager];
        if (str) {
            [self.view showImageHUDText:str];
            return;
        }
        HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        if (model.type == HXPhotoModelMediaTypePhotoGif) {
            if (cell.imageView.image.images.count > 0) {
                model.thumbPhoto = cell.imageView.image.images.firstObject;
                model.previewPhoto = cell.imageView.image.images.firstObject;
            }else {
                model.thumbPhoto = cell.imageView.image;
                model.previewPhoto = cell.imageView.image;
            }
        }else {
            model.thumbPhoto = cell.imageView.image;
            model.previewPhoto = cell.imageView.image;
        }
        if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) { // 为图片时
            [self.manager.selectedPhotos addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeVideo) { // 为视频时
            [self.manager.selectedVideos addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            // 为相机拍的照片时
            [self.manager.selectedPhotos addObject:model];
            [self.manager.selectedCameraPhotos addObject:model];
            [self.manager.selectedCameraList addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            // 为相机录的视频时
            [self.manager.selectedVideos addObject:model];
            [self.manager.selectedCameraVideos addObject:model];
            [self.manager.selectedCameraList addObject:model];
        }
        [self.manager.selectedList addObject:model];
        button.selected = YES;
        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.selectedList indexOfObject:model] + 1];
        [button setTitle:model.selectIndexStr forState:UIControlStateSelected];
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        anim.duration = 0.25;
        anim.values = @[@(1.2),@(0.8),@(1.1),@(0.9),@(1.0)];
        [button.layer addAnimation:anim forKey:@""];
    }
    model.selected = button.selected;
    button.backgroundColor = button.selected ? self.view.tintColor : nil;
    if ([self.delegate respondsToSelector:@selector(datePhotoPreviewControllerDidSelect:model:)]) {
        [self.delegate datePhotoPreviewControllerDidSelect:self model:model];
    }
    self.bottomView.selectCount = self.manager.selectedList.count;
    if (button.selected) {
        [self.bottomView insertModel:model];
    }else {
        [self.bottomView deleteModel:model];
    }
    if (self.selectPreview) {
//        [self.tempCell cancelRequest];
//        [self.collectionView reloadData];
//        if (self.modelArray.count == 0) {
//            self.titleLb.text = nil;
//            self.subTitleLb.text = nil;
//            self.selectBtn.hidden = YES;
//        }
//        [self.collectionView setContentOffset:CGPointMake(0, 0)];
//        HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
//        self.tempCell = cell;
//        if (self.modelArray.count > 0) {
//            self.currentModelIndex = 0;
//            HXPhotoModel *model = self.modelArray[self.currentModelIndex];
//            self.currentModel = model;
//        }
//        [cell requestHDImage];
    }
}
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.modelArray count];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXDatePhotoPreviewViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DatePreviewCellId" forIndexPath:indexPath];
    HXPhotoModel *model = self.modelArray[indexPath.item]; 
    cell.model = model;
    __weak typeof(self) weakSelf = self;
    [cell setCellTapClick:^{
        BOOL hide = NO;
        if (weakSelf.bottomView.alpha == 1) {
            hide = YES;
        }
        if (!hide) {
            [weakSelf.navigationController setNavigationBarHidden:hide animated:NO];
        }
        [[UIApplication sharedApplication] setStatusBarHidden:hide withAnimation:UIStatusBarAnimationFade];
        weakSelf.bottomView.userInteractionEnabled = !hide;
        [UIView animateWithDuration:0.15 animations:^{
            weakSelf.navigationController.navigationBar.alpha = hide ? 0 : 1;
            if (weakSelf.outside) {
                weakSelf.navBar.alpha = hide ? 0 : 1;
            }
            weakSelf.view.backgroundColor = hide ? [UIColor blackColor] : [UIColor whiteColor];
            weakSelf.collectionView.backgroundColor = hide ? [UIColor blackColor] : [UIColor whiteColor];
            weakSelf.bottomView.alpha = hide ? 0 : 1;
        } completion:^(BOOL finished) {
            if (hide) {
                [weakSelf.navigationController setNavigationBarHidden:hide animated:NO];
            }
        }];
    }];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(HXDatePhotoPreviewViewCell *)cell resetScale];
}
#pragma mark - < UICollectionViewDelegate >
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.tempCell.dragging) {
        [self.tempCell cancelRequest];
        self.tempCell.dragging = YES;
    }
    if (scrollView != self.collectionView) {
        return;
    }
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat offsetx = self.collectionView.contentOffset.x;
    NSInteger currentIndex = (offsetx + (width + 20) * 0.5) / (width + 20);
    if (currentIndex > self.modelArray.count - 1) {
        currentIndex = self.modelArray.count - 1;
    }
    if (currentIndex < 0) {
        currentIndex = 0;
    }
    if (self.modelArray.count > 0) {
        HXPhotoModel *model = self.modelArray[currentIndex];
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
            self.titleLb.text = model.barTitle;
            self.subTitleLb.text = model.barSubTitle;
        }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
            self.subTitleLb.text = [NSString stringWithFormat:@"%@  %@",model.barTitle,model.barSubTitle];
        }
        self.selectBtn.selected = model.selected;
        [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
        self.selectBtn.backgroundColor = self.selectBtn.selected ? self.view.tintColor : nil;
        if (self.outside) {
            if ([self.manager.endSelectedList containsObject:model]) {
                self.bottomView.currentIndex = [self.manager.endSelectedList indexOfObject:model];
            }else {
                [self.bottomView deselected];
            }
        }else {
            if ([self.manager.selectedList containsObject:model]) {
                self.bottomView.currentIndex = [self.manager.selectedList indexOfObject:model];
            }else {
                [self.bottomView deselected];
            }
        }
    }
    self.currentModelIndex = currentIndex;
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.modelArray.count > 0) {
        HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        self.tempCell = cell;
        HXPhotoModel *model = self.modelArray[self.currentModelIndex];
        self.currentModel = model;
        [cell requestHDImage];
    }
    self.tempCell.dragging = NO;
}
- (void)datePhotoPreviewBottomViewDidItem:(HXPhotoModel *)model currentIndex:(NSInteger)currentIndex beforeIndex:(NSInteger)beforeIndex {
    if ([self.modelArray containsObject:model]) {
        NSInteger index = [self.modelArray indexOfObject:model];
        if (self.currentModelIndex == index) {
            return;
        }
        self.currentModelIndex = index;
        [self.collectionView setContentOffset:CGPointMake(self.currentModelIndex * (self.view.hx_w + 20), 0) animated:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self scrollViewDidEndDecelerating:self.collectionView];
        });
    }else {
        if (beforeIndex == -1) {
            [self.bottomView deselectedWithIndex:currentIndex];
        }
        self.bottomView.currentIndex = beforeIndex;
    }
}
- (void)datePhotoPreviewBottomViewDidDone:(HXDatePhotoPreviewBottomView *)bottomView {
    if (self.outside) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    if (self.modelArray.count == 0) {
        [self.view showImageHUDText:@"没有照片可选!"];
        return;
    }
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    BOOL max = NO;
    if (self.manager.selectedList.count == self.manager.maxNum) {
        // 已经达到最大选择数
        max = YES;
    }
    if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            if (self.manager.videoMaxNum > 0) {
                if (!self.manager.selectTogether) { // 是否支持图片视频同时选择
                    if (self.manager.selectedVideos.count > 0 ) {
                        // 已经选择了视频,不能再选图片
                        max = YES;
                    }
                }
            }
            if (self.manager.selectedPhotos.count == self.manager.photoMaxNum) {
                max = YES;
                // 已经达到图片最大选择数
            }
        }
    }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
        if (self.manager.selectedPhotos.count == self.manager.photoMaxNum) {
            // 已经达到图片最大选择数
            max = YES;
        }
    }
    if (self.manager.selectedList.count == 0) {
        if (!self.selectBtn.selected && !max && self.modelArray.count > 0) {
            model.selected = YES;
            HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
            if (model.type == HXPhotoModelMediaTypePhotoGif) {
                if (cell.imageView.image.images.count > 0) {
                    model.thumbPhoto = cell.imageView.image.images.firstObject;
                    model.previewPhoto = cell.imageView.image.images.firstObject;
                }else {
                    model.thumbPhoto = cell.imageView.image;
                    model.previewPhoto = cell.imageView.image;
                }
            }else {
                model.thumbPhoto = cell.imageView.image;
                model.previewPhoto = cell.imageView.image;
            }
            if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) { // 为图片时
                [self.manager.selectedPhotos addObject:model];
            }else if (model.type == HXPhotoModelMediaTypeVideo) { // 为视频时
                [self.manager.selectedVideos addObject:model];
            }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                // 为相机拍的照片时
                [self.manager.selectedPhotos addObject:model];
                [self.manager.selectedCameraPhotos addObject:model];
                [self.manager.selectedCameraList addObject:model];
            }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                // 为相机录的视频时
                [self.manager.selectedVideos addObject:model];
                [self.manager.selectedCameraVideos addObject:model];
                [self.manager.selectedCameraList addObject:model];
            }
            [self.manager.selectedList addObject:model];
            model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.selectedList indexOfObject:model] + 1];
        }
    }
    if ([self.delegate respondsToSelector:@selector(datePhotoPreviewControllerDidDone:)]) {
        [self.delegate datePhotoPreviewControllerDidDone:self];
    }
}
#pragma mark - < 懒加载 >
- (HXPhotoCustomNavigationBar *)navBar {
    if (!_navBar) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _navBar = [[HXPhotoCustomNavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, kNavigationBarHeight)];
        _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_navBar pushNavigationItem:self.navItem animated:NO];
//        _navBar.tintColor = self.manager.UIManager.navLeftBtnTitleColor;
//        if (self.manager.UIManager.navBackgroundImageName) {
//            [_navBar setBackgroundImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.navBackgroundImageName] forBarMetrics:UIBarMetricsDefault];
//        }else if (self.manager.UIManager.navBackgroundColor) {
//            [_navBar setBackgroundColor:self.manager.UIManager.navBackgroundColor];
//        }
    }
    return _navBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
//
//        _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissClick)];
        _navItem.titleView = self.customTitleView;
    }
    return _navItem;
}
- (UIView *)customTitleView {
    if (!_customTitleView) {
        _customTitleView = [[UIView alloc] init];
        [_customTitleView addSubview:self.titleLb];
        [_customTitleView addSubview:self.subTitleLb];
    }
    return _customTitleView;
}
- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.textAlignment = NSTextAlignmentCenter;
        if (iOS8_2Later) {
            _titleLb.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        }else {
            _titleLb.font = [UIFont systemFontOfSize:14];
        }
        _titleLb.textColor = [UIColor blackColor];
    }
    return _titleLb;
}
- (UILabel *)subTitleLb {
    if (!_subTitleLb) {
        _subTitleLb = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.titleLb.frame) + 4, 150, 12)];
        _subTitleLb.textAlignment = NSTextAlignmentCenter;
        if (iOS8_2Later) {
            _subTitleLb.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
        }else {
            _subTitleLb.font = [UIFont systemFontOfSize:11];
        }
        _subTitleLb.textColor = [UIColor blackColor];
    }
    return _subTitleLb;
}
- (HXDatePhotoPreviewBottomView *)bottomView {
    if (!_bottomView) {
        if (self.outside) {
            _bottomView = [[HXDatePhotoPreviewBottomView alloc] initWithFrame:CGRectMake(0, self.view.hx_h - 50 - kBottomMargin, self.view.hx_w, 50 + kBottomMargin) modelArray:self.manager.endSelectedList];
        }else {
            _bottomView = [[HXDatePhotoPreviewBottomView alloc] initWithFrame:CGRectMake(0, self.view.hx_h - 50 - kBottomMargin, self.view.hx_w, 50 + kBottomMargin) modelArray:self.manager.selectedList];
        }
        _bottomView.delagate = self;
    }
    return _bottomView;
}
- (UIButton *)selectBtn {
    if (!_selectBtn) {
        _selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectBtn setBackgroundImage:[HXPhotoTools hx_imageNamed:@"compose_guide_check_box_default111@2x.png"] forState:UIControlStateNormal];
        [_selectBtn setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateSelected];
        [_selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        _selectBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _selectBtn.adjustsImageWhenDisabled = YES;
        [_selectBtn addTarget:self action:@selector(didSelectClick:) forControlEvents:UIControlEventTouchUpInside];
        _selectBtn.hx_size = CGSizeMake(24, 24);
        [_selectBtn setEnlargeEdgeWithTop:0 right:0 bottom:20 left:20];
        _selectBtn.layer.cornerRadius = 12;
    }
    return _selectBtn;
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-10, kTopMargin,self.view.hx_w + 20, self.view.hx_h - kTopMargin - kBottomMargin) collectionViewLayout:self.flowLayout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
//        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.pagingEnabled = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
//        _collectionView.contentSize = CGSizeMake(self.modelArray.count * (self.view.hx_w + 20), 0);
        [_collectionView registerClass:[HXDatePhotoPreviewViewCell class] forCellWithReuseIdentifier:@"DatePreviewCellId"];
//        [_collectionView setContentOffset:CGPointMake(self.currentModelIndex * (self.view.hx_w + 20), 0) animated:NO];
        #ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        #else
            if ((NO)) {
        #endif
            } else {
                self.automaticallyAdjustsScrollViewInsets = NO;
        }
        }
    return _collectionView;
}
- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
//        _flowLayout.itemSize = CGSizeMake(self.view.hx_w, self.view.hx_h - kTopMargin - kBottomMargin);
        _flowLayout.minimumInteritemSpacing = 0;
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        if (self.outside) {
            _flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
        }else {
        #ifdef __IPHONE_11_0
            if (@available(iOS 11.0, *)) {
        #else
                if ((NO)) {
        #endif
                    _flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
                }else {
                    _flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
                }
            }
        }
    return _flowLayout;
}
- (NSMutableArray *)modelArray {
    if (!_modelArray) {
        _modelArray = [NSMutableArray array];
    }
    return _modelArray;
}
- (void)dealloc {
    HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    [cell cancelRequest];
    if ([UIApplication sharedApplication].statusBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    NSSLog(@"dealloc");
}
@end
    
@interface HXDatePhotoPreviewViewCell ()<UIScrollViewDelegate,PHLivePhotoViewDelegate>
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) CGPoint imageCenter;
@property (strong, nonatomic) UIImage *gifImage;
@property (strong, nonatomic) UIImage *gifFirstFrame;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (assign, nonatomic) BOOL livePhotoAnimating;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) UIButton *videoPlayBtn;
@end

@implementation HXDatePhotoPreviewViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.requestID = -1;
        [self setup];
    }
    return self;
}
- (void)setup {
    [self.contentView addSubview:self.scrollView];
    [self.scrollView addSubview:self.imageView];
    [self.contentView.layer addSublayer:self.playerLayer];
    [self.contentView addSubview:self.videoPlayBtn];
//    [self.scrollView addSubview:self.livePhotoView];
}
- (void)resetScale {
    [self.scrollView setZoomScale:1.0 animated:NO];
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    [self cancelRequest];
    self.playerLayer.player = nil;
    self.player = nil;
    
    [self resetScale];
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGFloat w;
    CGFloat h;
    
    imgHeight = width / imgWidth * imgHeight;
    if (imgHeight > height) {
        w = height / self.model.imageSize.height * imgWidth;
        h = height;
        self.scrollView.maximumZoomScale = width / w + 0.5;
    }else {
        w = width;
        h = imgHeight;
        self.scrollView.maximumZoomScale = 2.5;
    }
    self.imageView.frame = CGRectMake(0, 0, w, h);
    self.imageView.center = CGPointMake(width / 2, height / 2);
    
    self.imageView.hidden = NO;
    __weak typeof(self) weakSelf = self;
    if (model.type == HXPhotoModelMediaTypePhotoGif) {
        if (model.tempImage) {
            self.imageView.image = model.tempImage;
        }
        self.requestID = [HXPhotoTools FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
            UIImage *gifImage = [UIImage animatedGIFWithData:imageData];
            if (gifImage.images.count == 0) {
                weakSelf.gifFirstFrame = gifImage;
                weakSelf.imageView.image = gifImage;
            }else {
                weakSelf.gifFirstFrame = gifImage.images.firstObject;
                weakSelf.imageView.image = weakSelf.gifFirstFrame;
            }
            weakSelf.model.tempImage = nil;
            weakSelf.gifImage = gifImage;
        }];
    }else {
        if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
            self.imageView.image = model.thumbPhoto;
            model.tempImage = nil;
        }else {
            if (model.type == HXPhotoModelMediaTypeLivePhoto) {
                if (model.tempImage) {
                    self.imageView.image = model.tempImage;
                    model.tempImage = nil;
                }else {
                    self.requestID = [HXPhotoTools getPhotoForPHAsset:model.asset size:CGSizeMake(self.hx_w * 0.5, self.hx_h * 0.5) completion:^(UIImage *image, NSDictionary *info) {
                        weakSelf.imageView.image = image;
                    }];
                }
            }else {
                if (model.previewPhoto) {
                    self.imageView.image = model.previewPhoto;
                    model.tempImage = nil;
                }else {
                    if (model.tempImage) {
                        self.imageView.image = model.tempImage;
                        model.tempImage = nil;
                    }else {
                        PHImageRequestID requestID;
                        if (imgHeight > imgWidth / 9 * 17) {
                            requestID = [HXPhotoTools getPhotoForPHAsset:model.asset size:CGSizeMake(self.hx_w * 0.6, self.hx_h * 0.6) completion:^(UIImage *image, NSDictionary *info) {
                                weakSelf.imageView.image = image;
                            }];
                        }else {
                            requestID = [HXPhotoTools getPhotoForPHAsset:model.asset size:CGSizeMake(model.endImageSize.width * 0.8, model.endImageSize.height * 0.8) completion:^(UIImage *image, NSDictionary *info) {
                                weakSelf.imageView.image = image;
                            }];
                        }
//                        if (self.requestID != requestID) {
//                            [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
//                        }
                        self.requestID = requestID;
                    }
                }
            }
        }
    }
    if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        self.playerLayer.hidden = NO;
        self.videoPlayBtn.hidden = NO;
    }else {
        self.playerLayer.hidden = YES;
        self.videoPlayBtn.hidden = YES;
    }
}
- (void)requestHDImage {
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGSize size;
    __weak typeof(self) weakSelf = self;
    if (imgHeight > imgWidth / 9 * 17) {
        size = CGSizeMake(width, height);
    }else {
        size = CGSizeMake(_model.endImageSize.width * 2.0, _model.endImageSize.height * 2.0);
    }
    if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
        if (self.model.isCloseLivePhoto) {
            return;
        }
        self.requestID = [HXPhotoTools FetchLivePhotoForPHAsset:self.model.asset Size:self.model.endImageSize Completion:^(PHLivePhoto *livePhoto, NSDictionary *info) {
            weakSelf.livePhotoView.frame = weakSelf.imageView.frame;
            [weakSelf.scrollView addSubview:weakSelf.livePhotoView];
            weakSelf.imageView.hidden = YES;
            weakSelf.livePhotoView.livePhoto = livePhoto;
            [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        }];
    }else if (self.model.type == HXPhotoModelMediaTypePhoto) {
        self.requestID = [HXPhotoTools getHighQualityFormatPhoto:self.model.asset size:size startRequestIcloud:^(PHImageRequestID cloudRequestId) {
//            weakSelf.longRequestId = cloudRequestId;
//            weakSelf.progressView.hidden = NO;
        } progressHandler:^(double progress) {
//            weakSelf.progressView.hidden = NO;
//            weakSelf.progressView.progress = progress;
        } completion:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
//                weakSelf.progressView.hidden = YES;
                weakSelf.imageView.image = image;
            });
        } failed:^(NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
//                weakSelf.progressView.hidden = YES;
            });
        }];
    }else if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
        if (self.gifImage) {
            self.imageView.image = self.gifImage;
        }else {
            self.requestID = [HXPhotoTools FetchPhotoDataForPHAsset:self.model.asset completion:^(NSData *imageData, NSDictionary *info) {
                UIImage *gifImage = [UIImage animatedGIFWithData:imageData];
                weakSelf.imageView.image = gifImage;
                weakSelf.gifImage = gifImage;
            }];
        }
    }
    if (self.player != nil) return;
    if (self.model.type == HXPhotoModelMediaTypeVideo) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
        options.networkAccessAllowed = NO;
//        self.requestID = [[PHImageManager defaultManager] requestAVAssetForVideo:self.model.asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
//            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
//            if (downloadFinined && asset) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    weakSelf.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
//                    weakSelf.playerLayer.player = weakSelf.player;
//                    [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:weakSelf.player.currentItem];
//                });
//            }
//        }];
        self.requestID = [[PHImageManager defaultManager] requestPlayerItemForVideo:self.model.asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            if (downloadFinined && playerItem) {
//                __strong typeof(weakSelf) strongSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.player = [AVPlayer playerWithPlayerItem:playerItem];
                    weakSelf.playerLayer.player = weakSelf.player;
                    [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:weakSelf.player.currentItem];;
                });
            }
        }];
    }else if (self.model.type == HXPhotoModelMediaTypeCameraVideo ) {
        self.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithURL:self.model.videoURL]];
        self.playerLayer.player = self.player;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    }
}
- (void)pausePlayerAndShowNaviBar {
    [self.player pause];
    self.videoPlayBtn.selected = NO;
    [self.player.currentItem seekToTime:CMTimeMake(0, 1)];
}
- (void)cancelRequest {
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
    if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
        if (_livePhotoView) {
            self.livePhotoView.livePhoto = nil;
            [self.livePhotoView removeFromSuperview];
            self.imageView.hidden = NO;
            [self stopLivePhoto];
        }
    }else if (self.model.type == HXPhotoModelMediaTypePhoto) {
        
    }else if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
        self.imageView.image = nil;
        self.gifImage = nil;
        self.imageView.image = self.gifFirstFrame;
    }
    if (self.model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (self.player != nil) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
            [self.player pause];
            self.videoPlayBtn.selected = NO;
            [self.player seekToTime:kCMTimeZero];
            self.playerLayer.player = nil;
            self.player = nil;
        }
    }
}
- (void)singleTap:(UITapGestureRecognizer *)tap {
    if (self.cellTapClick) {
        self.cellTapClick();
    }
}
- (void)doubleTap:(UITapGestureRecognizer *)tap {
    if (_scrollView.zoomScale > 1.0) {
        [_scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGFloat width = self.frame.size.width;
        CGFloat height = self.frame.size.height;
        CGPoint touchPoint;
        if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
            touchPoint = [tap locationInView:self.livePhotoView];
        }else {
            touchPoint = [tap locationInView:self.imageView];
        }
        CGFloat newZoomScale = self.scrollView.maximumZoomScale;
        CGFloat xsize = width / newZoomScale;
        CGFloat ysize = height / newZoomScale;
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}
#pragma mark - < PHLivePhotoViewDelegate >
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    self.livePhotoAnimating = YES;
}
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    [self stopLivePhoto];
}
- (void)stopLivePhoto {
    self.livePhotoAnimating = NO;
    [self.livePhotoView stopPlayback];
}
#pragma mark - < UIScrollViewDelegate >
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
        return self.livePhotoView;
    }else {
        return self.imageView;
    }
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.frame.size.width > scrollView.contentSize.width) ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.frame.size.height > scrollView.contentSize.height) ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
        self.livePhotoView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
    }else {
        self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
    }
}
- (void)didPlayBtnClick:(UIButton *)button {
    button.selected = !button.selected;
    if (button.selected) {
        [self.player play];
    }else {
        [self.player pause];
    }
    if (self.cellTapClick) {
        self.cellTapClick();
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.scrollView.frame = self.bounds;
    self.playerLayer.frame = self.bounds;
    self.scrollView.contentSize = CGSizeMake(self.hx_w, self.hx_h);
}
#pragma mark - < 懒加载 >
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.bouncesZoom = YES;
        _scrollView.minimumZoomScale = 1;
        _scrollView.multipleTouchEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.delaysContentTouches = NO;
        _scrollView.canCancelContentTouches = YES;
        _scrollView.alwaysBounceVertical = NO;
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [_scrollView addGestureRecognizer:tap1];
        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        tap2.numberOfTapsRequired = 2;
        [tap1 requireGestureRecognizerToFail:tap2];
        [_scrollView addGestureRecognizer:tap2];
    }
    return _scrollView;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}
- (PHLivePhotoView *)livePhotoView {
    if (!_livePhotoView) {
        _livePhotoView = [[PHLivePhotoView alloc] init];
        _livePhotoView.clipsToBounds = YES;
        _livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
        _livePhotoView.delegate = self;
    }
    return _livePhotoView;
}
- (UIButton *)videoPlayBtn {
    if (!_videoPlayBtn) {
        _videoPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_videoPlayBtn setImage:[HXPhotoTools hx_imageNamed:@"multimedia_videocard_play@2x.png"] forState:UIControlStateNormal];
        [_videoPlayBtn setImage:[[UIImage alloc] init] forState:UIControlStateSelected];
        [_videoPlayBtn addTarget:self action:@selector(didPlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _videoPlayBtn.frame = self.bounds;
        _videoPlayBtn.hidden = YES;
    }
    return _videoPlayBtn;
}
- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [[AVPlayerLayer alloc] init];
        _playerLayer.hidden = YES;
    }
    return _playerLayer;
}
- (void)dealloc {
    [self cancelRequest];
}
@end
