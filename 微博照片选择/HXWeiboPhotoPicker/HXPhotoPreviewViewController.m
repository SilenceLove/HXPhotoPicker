//
//  HXPhotoPreviewViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/9.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoPreviewViewController.h"
#import "HXPhotoPreviewViewCell.h"
#import "HXTransition.h"
#import "UIView+HXExtension.h"
#import "UIButton+HXExtension.h"
#import "HXPresentTransition.h"
@interface HXPhotoPreviewViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIViewControllerTransitioningDelegate>
@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) UIButton *selectedBtn;
@property (strong, nonatomic) UIButton *rightBtn;
@property (strong, nonatomic) HXPhotoPreviewViewCell *livePhotoCell;
@end

@implementation HXPhotoPreviewViewController

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
    
    [self setup];
}

- (void)setup
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.titleView = self.titleLb;
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
    }
    
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(width, height - 64);
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 20;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-10, 64, width + 20, height - 64) collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor whiteColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.pagingEnabled = YES;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.contentSize = CGSizeMake(self.modelList.count * (width + 20), 0);
    [collectionView registerClass:[HXPhotoPreviewViewCell class] forCellWithReuseIdentifier:@"cellId"];
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    [collectionView setContentOffset:CGPointMake(self.index * (width + 20), 0) animated:NO];
    [self.view addSubview:self.selectedBtn];
    HXPhotoModel *model = self.modelList[self.index];
    self.selectedBtn.selected = model.selected;
    
    if (self.selectedComplete) {
        self.rightBtn.hidden = YES;
        self.selectedBtn.hidden = YES;
        UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, 64)];
        [self.view addSubview:navBar];
        UINavigationItem *navItem = [[UINavigationItem alloc] init];
        [navBar pushNavigationItem:navItem animated:NO];
        
        navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismissClick)];
        navBar.tintColor = [UIColor blackColor];
        navItem.titleView = self.titleLb;
    }
}

- (void)dismissClick
{
    if (self.livePhotoCell) {
        [self.livePhotoCell stopLivePhoto];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.modelList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HXPhotoPreviewViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellId" forIndexPath:indexPath];
    cell.model = self.modelList[indexPath.item];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat width = self.view.frame.size.width;
    CGFloat offsetx = scrollView.contentOffset.x;
    NSInteger currentIndex = (offsetx + (width + 20) * 0.5) / (width + 20);
    self.titleLb.text = [NSString stringWithFormat:@"%ld/%ld",currentIndex + 1,self.modelList.count];
    HXPhotoModel *model = self.modelList[currentIndex];
    self.selectedBtn.selected = model.selected;
    self.index = currentIndex;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    HXPhotoModel *model = self.modelList[self.index];
    if (model.isCloseLivePhoto) {
        return;
    }
    if (self.livePhotoCell) {
        [self.livePhotoCell stopLivePhoto];
    }
    if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.index inSection:0]];
        [cell startLivePhoto];
        self.livePhotoCell = cell;
    }
}

- (UILabel *)titleLb
{
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
        _titleLb.textColor = [UIColor blackColor];
        _titleLb.font = [UIFont boldSystemFontOfSize:17];
        _titleLb.textAlignment = NSTextAlignmentCenter;
        _titleLb.text = [NSString stringWithFormat:@"%ld/%ld",self.index + 1,self.modelList.count];
    }
    return _titleLb;
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
    HXPhotoModel *model = self.modelList[self.index];
    if (!button.selected) {
        if (self.manager.selectedList.count == self.manager.maxNum) {
            // 已经达到最大选择数
            [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld个",self.manager.maxNum]];
            return;
        }
        if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
            if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
                if (self.manager.videoMaxNum > 0) {
                    if (!self.manager.selectTogether) { // 是否支持图片视频同时选择
                        if (self.manager.selectedVideos.count > 0 ) {
                            // 已经选择了视频,不能再选图片
                            [self.view showImageHUDText:@"图片不能和视频同时选择"];
                            return;
                        }
                    }
                }
                if (self.manager.selectedPhotos.count == self.manager.photoMaxNum) {
                    [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld张图片",self.manager.photoMaxNum]];
                    // 已经达到图片最大选择数
                    return;
                }
            }
        }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
            if (self.manager.selectedPhotos.count == self.manager.photoMaxNum) {
                // 已经达到图片最大选择数
                [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld张图片",self.manager.photoMaxNum]];
                return;
            }
        }
        if (model.type == HXPhotoModelMediaTypeVideo) {
            if (model.asset.duration < 3) {
                [self.view showImageHUDText:@"视频少于3秒,暂不支持"];
                return;
            }
        }
        if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) {
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
                if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) {
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
    
    if ([self.delegate respondsToSelector:@selector(didSelectedClick:AddOrDelete:)]) {
        [self.delegate didSelectedClick:model AddOrDelete:button.selected];
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
    HXPhotoModel *model = self.modelList[self.index];
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
    if (!self.selectedBtn.selected && !max) {
        model.selected = YES;
        [self.manager.selectedList addObject:model];
        [self.manager.selectedPhotos addObject:model];
    }
    if ([self.delegate respondsToSelector:@selector(previewDidNextClick)]) {
        [self.delegate previewDidNextClick];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    HXPhotoModel *model = self.modelList[self.index];
    if (model.isCloseLivePhoto) {
        return;
    }
    if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.index inSection:0]];
        [cell startLivePhoto];
        self.livePhotoCell = cell;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC{
    if (operation == UINavigationControllerOperationPush) {
        return [HXTransition transitionWithType:HXTransitionTypePush VcType:HXTransitionVcTypePhoto];
    }else {
        return [HXTransition transitionWithType:HXTransitionTypePop VcType:HXTransitionVcTypePhoto];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [HXPresentTransition transitionWithTransitionType:HXPresentTransitionTypePresent VcType:HXPresentTransitionVcTypePhoto];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [HXPresentTransition transitionWithTransitionType:HXPresentTransitionTypeDismiss VcType:HXPresentTransitionVcTypePhoto];
}

@end
