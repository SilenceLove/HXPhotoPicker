//
//  HXDatePhotoViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoViewController.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoCustomNavigationBar.h"
#import "HXPhoto3DTouchViewController.h"
#import "HXDatePhotoPreviewViewController.h"
#import "UIButton+HXExtension.h"

@interface HXDatePhotoViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UIViewControllerPreviewingDelegate,HXDatePhotoViewCellDelegate,HXDatePhotoBottomViewDelegate,HXDatePhotoPreviewViewControllerDelegate>
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) UICollectionView *collectionView;


@property (strong, nonatomic) NSMutableArray *allArray;
@property (strong, nonatomic) NSMutableArray *previewArray;
@property (strong, nonatomic) NSMutableArray *photoArray;
@property (strong, nonatomic) NSMutableArray *videoArray;
@property (strong, nonatomic) NSMutableArray *dateArray;

@property (assign, nonatomic) NSInteger currentSectionIndex;
@property (strong, nonatomic) UICollectionReusableView *currentHeaderView;
@property (weak, nonatomic) id<UIViewControllerPreviewing> previewingContext;

@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) BOOL needChangeViewFrame;
@property (strong, nonatomic) NSIndexPath *beforeOrientationIndexPath;
@end

@implementation HXDatePhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self changeSubviewFrame];
    [self.view showLoadingHUDText:@"加载中"];
    [self getPhotoList];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.needChangeViewFrame) { 
        self.needChangeViewFrame = NO;
    }
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        [self changeSubviewFrame];
        self.orientationDidChange = NO;
    }
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.beforeOrientationIndexPath = [self.collectionView indexPathsForVisibleItems].firstObject; 
    self.orientationDidChange = YES;
    if (self.navigationController.topViewController != self) {
        self.needChangeViewFrame = YES;
    }
}
- (void)changeSubviewFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = kNavigationBarHeight;
    NSInteger lineCount = self.manager.rowCount;
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        navBarHeight = kNavigationBarHeight;
        lineCount = self.manager.rowCount;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        if ([UIApplication sharedApplication].statusBarHidden) {
            navBarHeight = self.navigationController.navigationBar.hx_h;
        }else {
            navBarHeight = self.navigationController.navigationBar.hx_h + 20;
        }
        lineCount = self.manager.horizontalRowCount;
    }
    CGFloat bottomMargin = kBottomMargin;
    CGFloat leftMargin = 0;
    CGFloat rightMargin = 0;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    CGFloat viewWidth = [UIScreen mainScreen].bounds.size.width;
    
    if (!CGRectEqualToRect(self.view.bounds, [UIScreen mainScreen].bounds)) {
        self.view.frame = CGRectMake(0, 0, viewWidth, height);
    }
    if (kDevice_Is_iPhoneX && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        bottomMargin = 21;
        leftMargin = 35;
        rightMargin = 35;
        width = [UIScreen mainScreen].bounds.size.width - 70;
    }
    CGFloat itemWidth = (width - (lineCount - 1)) / lineCount;
    CGFloat itemHeight = itemWidth;
    self.flowLayout.itemSize = CGSizeMake(itemWidth, itemHeight);
    
    
    self.collectionView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, bottomMargin, rightMargin);
    if (!self.manager.singleSelected) {
        self.collectionView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, 50 + bottomMargin, rightMargin);
    } else {
        self.collectionView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, bottomMargin, rightMargin);
    }
    self.collectionView.scrollIndicatorInsets = _collectionView.contentInset;
    
    if (self.orientationDidChange) {
        [self.collectionView scrollToItemAtIndexPath:self.beforeOrientationIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }
    
    self.bottomView.frame = CGRectMake(0, height - 50 - bottomMargin, viewWidth, 50 + bottomMargin);
}
- (void)setupUI {
    self.currentSectionIndex = 0;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(didCancelClick)];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    if (!self.manager.singleSelected) {
        [self.view addSubview:self.bottomView];
        self.bottomView.selectCount = self.manager.selectedList.count;
    }
}
- (void)didCancelClick {
    if ([self.delegate respondsToSelector:@selector(datePhotoViewControllerDidCancel:)]) {
        [self.delegate datePhotoViewControllerDidCancel:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (HXDatePhotoViewCell *)currentPreviewCell:(HXPhotoModel *)model {
    if (!model || ![self.allArray containsObject:model]) {
        return nil;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:model.dateItem inSection:model.dateSection];
    return (HXDatePhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
}
- (BOOL)scrollToModel:(HXPhotoModel *)model {
    if ([self.allArray containsObject:model]) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:model.dateItem inSection:model.dateSection] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:model.dateItem inSection:model.dateSection]]];
    }
    return [self.allArray containsObject:model];
}
- (void)scrollToPoint:(HXDatePhotoViewCell *)cell rect:(CGRect)rect {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = kNavigationBarHeight;
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        navBarHeight = kNavigationBarHeight;
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        if ([UIApplication sharedApplication].statusBarHidden) {
            navBarHeight = self.navigationController.navigationBar.hx_h;
        }else {
            navBarHeight = self.navigationController.navigationBar.hx_h + 20;
        }
    }
    if (self.manager.showDateHeaderSection) {
        navBarHeight += 50;
    }
    if (rect.origin.y < navBarHeight) {
        [self.collectionView setContentOffset:CGPointMake(0, cell.frame.origin.y - navBarHeight)];
    }else if (rect.origin.y + rect.size.height > self.view.hx_h - 50.5 - kBottomMargin) {
        [self.collectionView setContentOffset:CGPointMake(0, cell.frame.origin.y - self.view.hx_h + 50.5 + kBottomMargin + rect.size.height)];
    }
}
- (void)getPhotoList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak typeof(self) weakSelf = self;
        [self.manager getPhotoListWithAlbumModel:self.albumModel complete:^(NSArray *allList, NSArray *previewList, NSArray *photoList, NSArray *videoList, NSArray *dateList, HXPhotoModel *firstSelectModel) {
            weakSelf.dateArray = [NSMutableArray arrayWithArray:dateList];
            weakSelf.photoArray = [NSMutableArray arrayWithArray:photoList];
            weakSelf.videoArray = [NSMutableArray arrayWithArray:videoList];
            weakSelf.allArray = [NSMutableArray arrayWithArray:allList];
            weakSelf.previewArray = [NSMutableArray arrayWithArray:previewList];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view handleLoading];
                CATransition *transition = [CATransition animation];
                transition.type = kCATransitionPush;
                transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                transition.fillMode = kCAFillModeForwards;
                transition.duration = 0.05;
                transition.subtype = kCATransitionFade;
                [[weakSelf.collectionView layer] addAnimation:transition forKey:@""];
                [weakSelf.collectionView reloadData];
                if (!weakSelf.manager.reverseDate) {
                    if (weakSelf.manager.showDateHeaderSection && weakSelf.dateArray.count > 0) {
                        HXPhotoDateModel *dateModel = weakSelf.dateArray.lastObject;
                        if (dateModel.photoModelArray.count > 0) {
                            if (firstSelectModel) {
                                [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:firstSelectModel.dateItem inSection:firstSelectModel.dateSection] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                            }else {
                                [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:dateModel.photoModelArray.count - 1 inSection:weakSelf.dateArray.count - 1] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
                            }
                        }
                    }else {
                        if (weakSelf.allArray.count > 0) {
                            if (firstSelectModel) {
                                [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[weakSelf.allArray indexOfObject:firstSelectModel] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                            }else {
                                [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:weakSelf.allArray.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
                            }
                        }
                    }
                }else {
                    if (firstSelectModel) {
                        if (weakSelf.manager.showDateHeaderSection) {
                            [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:firstSelectModel.dateItem inSection:firstSelectModel.dateSection] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                        }else {
                            [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[weakSelf.allArray indexOfObject:firstSelectModel] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                        }
                    }
                }
            });
        }];
    });
}
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.manager.showDateHeaderSection) {
        return [self.dateArray count];
    }
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.manager.showDateHeaderSection) {
        HXPhotoDateModel *dateModel = [self.dateArray objectAtIndex:section];
        return [dateModel.photoModelArray count];
    }
    return self.allArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXDatePhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DateCellId" forIndexPath:indexPath];
    cell.delegate = self;
    HXPhotoModel *model;
    if (self.manager.showDateHeaderSection) {
        HXPhotoDateModel *dateModel = [self.dateArray objectAtIndex:indexPath.section];
        model = dateModel.photoModelArray[indexPath.item];
    }else {
        model = self.allArray[indexPath.item];
    }
    model.rowCount = self.manager.rowCount;
    model.dateSection = indexPath.section;
    model.dateItem = indexPath.item;
    model.dateCellIsVisible = YES;
    cell.model = model;
    return cell;
}
#pragma mark - < UICollectionViewDelegate >
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationController.topViewController != self) {
        return;
    }
    HXDatePhotoViewCell *cell = (HXDatePhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell.model.isIcloud) {
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"尚未从iCloud上下载，请至相册下载完毕后选择"]];
        return;
    }
    NSInteger currentIndex = [self.previewArray indexOfObject:cell.model];
    HXDatePhotoPreviewViewController *previewVC = [[HXDatePhotoPreviewViewController alloc] init];
    previewVC.delegate = self;
    previewVC.modelArray = self.previewArray;
    previewVC.manager = self.manager;
    previewVC.currentModelIndex = currentIndex;
    self.navigationController.delegate = previewVC;
    [self.navigationController pushViewController:previewVC animated:YES];
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader] && self.manager.showDateHeaderSection) {
        HXDatePhotoViewSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionHeaderId" forIndexPath:indexPath];
        headerView.model = self.dateArray[indexPath.section];
        return headerView;
    }
    return nil;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (self.manager.showDateHeaderSection) {
        return CGSizeMake(self.view.hx_w, 50);
    }
    return CGSizeZero;
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    self.currentHeaderView.backgroundColor = [UIColor whiteColor];
//    UICollectionReusableView *headerView = [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.currentSectionIndex]];
//    headerView.backgroundColor = [UIColor colorWithRed:234/255.0 green:234/255.0 blue:234/255.0 alpha:1];
//    self.currentHeaderView = headerView;
//    CGRect frame = [headerView.superview convertRect:headerView.frame toView:[UIApplication sharedApplication].keyWindow];
//    if (frame.origin.y <= 0 && self.currentSectionIndex < self.dateArray.count - 1) {
//        self.currentSectionIndex++;
//        if (self.currentSectionIndex > self.dateArray.count - 1) {
//            self.currentSectionIndex = self.dateArray.count - 1;
//        }
//        self.currentHeaderView.backgroundColor = [UIColor whiteColor];
//    }else if (frame.origin.y > kNavigationBarHeight + 50 && self.currentSectionIndex > 0) {
//        self.currentSectionIndex--;
//        if (self.currentSectionIndex < 0) {
//            self.currentSectionIndex = 0;
//        }
//        self.currentHeaderView.backgroundColor = [UIColor whiteColor];
//    }
//    NSSLog(@"%f",frame.origin.y);
//}
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (!indexPath) {
        return nil;
    }
    HXDatePhotoViewCell *cell = (HXDatePhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell || cell.model.type == HXPhotoModelMediaTypeCamera || cell.model.isIcloud) {
        return nil;
    }
    //设置突出区域
    previewingContext.sourceRect = [self.collectionView cellForItemAtIndexPath:indexPath].frame;
    HXPhotoModel *model = cell.model;
    HXPhoto3DTouchViewController *vc = [[HXPhoto3DTouchViewController alloc] init];
    vc.model = model;
    vc.indexPath = indexPath;
    vc.image = cell.imageView.image;
    vc.preferredContentSize = model.endImageSize;
    return vc;
}
- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    HXPhoto3DTouchViewController *vc = (HXPhoto3DTouchViewController *)viewControllerToCommit;
    HXDatePhotoPreviewViewController *previewVC = [[HXDatePhotoPreviewViewController alloc] init];
    previewVC.delegate = self;
    previewVC.modelArray = self.previewArray;
    previewVC.manager = self.manager;
    HXDatePhotoViewCell *cell = (HXDatePhotoViewCell *)[self.collectionView cellForItemAtIndexPath:vc.indexPath];
    cell.model.tempImage = vc.imageView.image;
    NSInteger currentIndex = [self.previewArray indexOfObject:cell.model];
    previewVC.currentModelIndex = currentIndex;
    self.navigationController.delegate = previewVC;
    [self.navigationController pushViewController:previewVC animated:YES];
}
#pragma mark - < HXDatePhotoViewCellDelegate >
- (void)datePhotoViewCell:(HXDatePhotoViewCell *)cell didSelectBtn:(UIButton *)selectBtn {
    if (selectBtn.selected) {
        if (cell.model.type != HXPhotoModelMediaTypeCameraVideo && cell.model.type != HXPhotoModelMediaTypeCameraPhoto) {
            cell.model.thumbPhoto = nil;
            cell.model.previewPhoto = nil;
        }
        if ((cell.model.type == HXPhotoModelMediaTypePhoto || cell.model.type == HXPhotoModelMediaTypePhotoGif) || (cell.model.type == HXPhotoModelMediaTypeVideo || cell.model.type == HXPhotoModelMediaTypeLivePhoto)) {
            if (cell.model.type == HXPhotoModelMediaTypePhoto || cell.model.type == HXPhotoModelMediaTypePhotoGif || cell.model.type == HXPhotoModelMediaTypeLivePhoto) {
                [self.manager.selectedPhotos removeObject:cell.model];
            }else if (cell.model.type == HXPhotoModelMediaTypeVideo) {
                [self.manager.selectedVideos removeObject:cell.model];
            }
        }else if (cell.model.type == HXPhotoModelMediaTypeCameraPhoto || cell.model.type == HXPhotoModelMediaTypeCameraVideo) {
            if (cell.model.type == HXPhotoModelMediaTypeCameraPhoto) {
                [self.manager.selectedPhotos removeObject:cell.model];
                [self.manager.selectedCameraPhotos removeObject:cell.model];
            }else if (cell.model.type == HXPhotoModelMediaTypeCameraVideo) {
                [self.manager.selectedVideos removeObject:cell.model];
                [self.manager.selectedCameraVideos removeObject:cell.model];
            }
            [self.manager.selectedCameraList removeObject:cell.model];
        }
        [self.manager.selectedList removeObject:cell.model];
        cell.model.selectIndexStr = @"";
        cell.selectMaskLayer.hidden = YES;
        selectBtn.selected = NO;
    }else {
        NSString *str = [HXPhotoTools maximumOfJudgment:cell.model manager:self.manager];
        if (str) {
            [self.view showImageHUDText:str];
            return;
        }
        if (cell.model.type != HXPhotoModelMediaTypeCameraVideo && cell.model.type != HXPhotoModelMediaTypeCameraPhoto) {
            cell.model.thumbPhoto = cell.imageView.image;
        }
        if (cell.model.type == HXPhotoModelMediaTypePhoto || (cell.model.type == HXPhotoModelMediaTypePhotoGif || cell.model.type == HXPhotoModelMediaTypeLivePhoto)) { // 为图片时
            [self.manager.selectedPhotos addObject:cell.model];
        }else if (cell.model.type == HXPhotoModelMediaTypeVideo) { // 为视频时
            [self.manager.selectedVideos addObject:cell.model];
        }else if (cell.model.type == HXPhotoModelMediaTypeCameraPhoto) {
            // 为相机拍的照片时
            [self.manager.selectedPhotos addObject:cell.model];
            [self.manager.selectedCameraPhotos addObject:cell.model];
            [self.manager.selectedCameraList addObject:cell.model];
        }else if (cell.model.type == HXPhotoModelMediaTypeCameraVideo) {
            // 为相机录的视频时
            [self.manager.selectedVideos addObject:cell.model];
            [self.manager.selectedCameraVideos addObject:cell.model];
            [self.manager.selectedCameraList addObject:cell.model];
        }
        [self.manager.selectedList addObject:cell.model];
        cell.selectMaskLayer.hidden = NO;
        selectBtn.selected = YES;
        cell.model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.selectedList indexOfObject:cell.model] + 1];
        [selectBtn setTitle:cell.model.selectIndexStr forState:UIControlStateSelected];
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        anim.duration = 0.25;
        anim.values = @[@(1.2),@(0.8),@(1.1),@(0.9),@(1.0)];
        [selectBtn.layer addAnimation:anim forKey:@""];
    }
    cell.model.selected = selectBtn.selected;
    selectBtn.backgroundColor = selectBtn.selected ? self.view.tintColor : nil;
    if (!selectBtn.selected) {
        NSMutableArray *indexPathList = [NSMutableArray array];
        NSInteger index = 0;
        for (HXPhotoModel *model in self.manager.selectedList) {
            model.selectIndexStr = [NSString stringWithFormat:@"%ld",index + 1];
            if (model.dateCellIsVisible) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:model.dateItem inSection:model.dateSection];
                [indexPathList addObject:indexPath];
            }
            index++;
        }
        [self.collectionView reloadItemsAtIndexPaths:indexPathList];
    }
    self.bottomView.selectCount = self.manager.selectedList.count;
    if ([self.delegate respondsToSelector:@selector(datePhotoViewControllerDidChangeSelect:selected:)]) {
        [self.delegate datePhotoViewControllerDidChangeSelect:cell.model selected:selectBtn.selected];
    }
}
#pragma mark - < HXDatePhotoPreviewViewControllerDelegate >
- (void)datePhotoPreviewControllerDidSelect:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    if (model.currentAlbumIndex == self.albumModel.index) {
        NSMutableArray *indexPathList = [NSMutableArray array];
        [indexPathList addObject:[NSIndexPath indexPathForItem:model.dateItem inSection:model.dateSection]];
        if (!model.selected) {
            NSInteger index = 0;
            for (HXPhotoModel *model in self.manager.selectedList) {
                if ([self.allArray containsObject:model]) {
                    model.selectIndexStr = [NSString stringWithFormat:@"%ld",index + 1];
                    if (model.dateCellIsVisible) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:model.dateItem inSection:model.dateSection];
                        [indexPathList addObject:indexPath];
                    }
                    index++;
                }
            }
        }
        [self.collectionView reloadItemsAtIndexPaths:indexPathList];
    }
    self.bottomView.selectCount = self.manager.selectedList.count;
    if ([self.delegate respondsToSelector:@selector(datePhotoViewControllerDidChangeSelect:selected:)]) {
        [self.delegate datePhotoViewControllerDidChangeSelect:model selected:model.selected];
    }
}
#pragma mark - < HXDatePhotoBottomViewDelegate >
- (void)datePhotoBottomViewDidPreviewBtn {
    if (self.navigationController.topViewController != self || self.manager.selectedList.count == 0) {
        return;
    }
    HXDatePhotoPreviewViewController *previewVC = [[HXDatePhotoPreviewViewController alloc] init];
    previewVC.delegate = self;
    previewVC.modelArray = [NSMutableArray arrayWithArray:self.manager.selectedList];
    previewVC.manager = self.manager;
    previewVC.currentModelIndex = 0;
    previewVC.selectPreview = YES;
    self.navigationController.delegate = previewVC;
    [self.navigationController pushViewController:previewVC animated:YES];
}
- (void)datePhotoPreviewControllerDidDone:(HXDatePhotoPreviewViewController *)previewController {
    [self datePhotoBottomViewDidDoneBtn];
}
- (void)datePhotoBottomViewDidDoneBtn {
    [self cleanSelectedList];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)sortSelectList {
    int i = 0, j = 0, k = 0;
    for (HXPhotoModel *model in self.manager.selectedList) {
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            model.endIndex = i++;
        }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
            model.videoIndex = j++;
        }
        model.endCollectionIndex = k++;
    }
}

- (void)cleanSelectedList {
    [self sortSelectList];
    // 如果通过相机拍的数组为空 则清空所有关于相机的数组
    if (self.manager.deleteTemporaryPhoto) {
        if (self.manager.selectedCameraList.count == 0) {
            [self.manager.cameraList removeAllObjects];
            [self.manager.cameraVideos removeAllObjects];
            [self.manager.cameraPhotos removeAllObjects];
        }
    }
    if (!self.manager.singleSelected) {
        // 记录这次操作的数据
        self.manager.endSelectedList = [NSMutableArray arrayWithArray:self.manager.selectedList];
        self.manager.endSelectedPhotos = [NSMutableArray arrayWithArray:self.manager.selectedPhotos];
        self.manager.endSelectedVideos = [NSMutableArray arrayWithArray:self.manager.selectedVideos];
        self.manager.endCameraList = [NSMutableArray arrayWithArray:self.manager.cameraList];
        self.manager.endCameraPhotos = [NSMutableArray arrayWithArray:self.manager.cameraPhotos];
        self.manager.endCameraVideos = [NSMutableArray arrayWithArray:self.manager.cameraVideos];
        self.manager.endSelectedCameraList = [NSMutableArray arrayWithArray:self.manager.selectedCameraList];
        self.manager.endSelectedCameraPhotos = [NSMutableArray arrayWithArray:self.manager.selectedCameraPhotos];
        self.manager.endSelectedCameraVideos = [NSMutableArray arrayWithArray:self.manager.selectedCameraVideos];
        self.manager.endIsOriginal = self.manager.isOriginal;
        self.manager.endPhotosTotalBtyes = self.manager.photosTotalBtyes;
        
        if ([self.delegate respondsToSelector:@selector(datePhotoViewController:didDoneAllList:photos:videos:original:)]) {
            [self.delegate datePhotoViewController:self didDoneAllList:self.manager.endSelectedList.mutableCopy photos:self.manager.endSelectedPhotos.mutableCopy videos:self.manager.endSelectedVideos.mutableCopy original:self.manager.endIsOriginal];
        }
    }else {
        if ([self.delegate respondsToSelector:@selector(datePhotoViewController:didDoneAllList:photos:videos:original:)]) {
            [self.delegate datePhotoViewController:self didDoneAllList:self.manager.selectedList.mutableCopy photos:self.manager.selectedPhotos.mutableCopy videos:self.manager.selectedVideos.mutableCopy original:self.manager.isOriginal];
        }
    }
}
#pragma mark - < 懒加载 >
- (HXDatePhotoBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[HXDatePhotoBottomView alloc] initWithFrame:CGRectMake(0, self.view.hx_h - 50 - kBottomMargin, self.view.hx_w, 50 + kBottomMargin)];
        _bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _bottomView.delegate = self;
    }
    return _bottomView;
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.hx_w, self.view.hx_h) collectionViewLayout:self.flowLayout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.alwaysBounceVertical = YES;
        [_collectionView registerClass:[HXDatePhotoViewCell class] forCellWithReuseIdentifier:@"DateCellId"];
        [_collectionView registerClass:[HXDatePhotoViewSectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"sectionHeaderId"];
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
        if ((NO)) {
#endif
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        if (self.manager.open3DTouchPreview) {
            if ([self respondsToSelector:@selector(traitCollection)]) {
                if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
                    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:_collectionView];
                    }
                }
            }
        }
//        _collectionView.contentInset = UIEdgeInsetsMake(kNavigationBarHeight, 0, kBottomMargin, 0);
//        if (!self.manager.singleSelected) {
//            _collectionView.contentInset = UIEdgeInsetsMake(kNavigationBarHeight, 0, 50 + kBottomMargin, 0);
//        } else {
//            _collectionView.contentInset = UIEdgeInsetsMake(kNavigationBarHeight, 0, kBottomMargin, 0);
//        }
//        _collectionView.scrollIndicatorInsets = _collectionView.contentInset;
    }
    return _collectionView;
}
- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
//        CGFloat itemWidth = (self.view.hx_w - 3) / 4;
//        CGFloat itemHeight = itemWidth;
//        _flowLayout.itemSize = CGSizeMake(itemWidth, itemHeight);
        _flowLayout.minimumLineSpacing = 0.5;
        _flowLayout.minimumInteritemSpacing = 0.5;
        _flowLayout.sectionInset = UIEdgeInsetsMake(0.5, 0, 0.5, 0);
        if (iOS9_Later) {
            _flowLayout.sectionHeadersPinToVisibleBounds = YES;
        }
    }
    return _flowLayout;
}
- (NSMutableArray *)allArray {
    if (!_allArray) {
        _allArray = [NSMutableArray array];
    }
    return _allArray;
}
- (NSMutableArray *)photoArray {
    if (!_photoArray) {
        _photoArray = [NSMutableArray array];
    }
    return _photoArray;
}
- (NSMutableArray *)videoArray {
    if (!_videoArray) {
        _videoArray = [NSMutableArray array];
    }
    return _videoArray;
}
- (NSMutableArray *)previewArray {
    if (!_previewArray) {
        _previewArray = [NSMutableArray array];
    }
    return _previewArray;
}
- (NSMutableArray *)dateArray {
    if (!_dateArray) {
        _dateArray = [NSMutableArray array];
    }
    return _dateArray;
}
- (void)dealloc {
    [self.collectionView.layer removeAllAnimations];
    [self unregisterForPreviewingWithContext:self.previewingContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
@end

@interface HXDatePhotoViewCell ()
@property (strong, nonatomic) UIImageView *imageView;
@property (copy, nonatomic) NSString *localIdentifier;
@property (assign, nonatomic) int32_t requestID;
@property (strong, nonatomic) UILabel *stateLb;
@property (strong, nonatomic) CAGradientLayer *bottomMaskLayer;
@property (strong, nonatomic) UIButton *selectBtn;
@end

@implementation HXDatePhotoViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.stateLb];
    [self.contentView addSubview:self.selectBtn];
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    if (model.type == HXPhotoModelMediaTypeCamera || model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
        self.imageView.image = model.thumbPhoto;
    }else {
        self.localIdentifier = model.asset.localIdentifier;
        __weak typeof(self) weakSelf = self;
        int32_t requestID = [HXPhotoTools fetchPhotoWithAsset:model.asset photoSize:model.requestSize completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.model.type != HXPhotoModelMediaTypeCamera && strongSelf.model.type != HXPhotoModelMediaTypeCameraPhoto && strongSelf.model.type != HXPhotoModelMediaTypeCameraVideo) {
                strongSelf.imageView.image = photo;
            }else {
                if (strongSelf.requestID) {
                    [[PHImageManager defaultManager] cancelImageRequest:strongSelf.requestID];
                    strongSelf.requestID = -1;
                }
            }
        }];
        if (requestID && self.requestID && requestID != self.requestID) {
            [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        }
        self.requestID = requestID;
    }
    if (model.type == HXPhotoModelMediaTypePhotoGif) {
        self.stateLb.text = @"GIF";
        self.stateLb.hidden = NO;
        self.bottomMaskLayer.hidden = NO;
    }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        self.stateLb.text = @"Live";
        self.stateLb.hidden = NO;
        self.bottomMaskLayer.hidden = NO;
    }else {
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            self.stateLb.text = model.videoTime;
            self.stateLb.hidden = NO;
            self.bottomMaskLayer.hidden = NO;
        }else {
            self.stateLb.hidden = YES;
            self.bottomMaskLayer.hidden = YES;
        }
    }
    self.selectMaskLayer.hidden = !model.selected;
    self.selectBtn.selected = model.selected;
    [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
    self.selectBtn.backgroundColor = model.selected ? self.tintColor :nil;
    if (model.isIcloud) {
        self.selectBtn.userInteractionEnabled = NO;
    }else {
        self.selectBtn.userInteractionEnabled = YES;
    }
}
- (void)didSelectClick:(UIButton *)button {
    if (self.model.type == HXPhotoModelMediaTypeCamera) {
        return;
    }
    if (self.model.isIcloud) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(datePhotoViewCell:didSelectBtn:)]) {
        [self.delegate datePhotoViewCell:self didSelectBtn:button];
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.stateLb.frame = CGRectMake(0, self.hx_h - 18, self.hx_w - 4, 18);
    self.bottomMaskLayer.frame = CGRectMake(0, self.hx_h - 25, self.hx_w, 25);
    self.selectBtn.frame = CGRectMake(self.hx_w - 27, 2, 25, 25);
    self.selectMaskLayer.frame = self.bounds;
}
#pragma mark - < 懒加载 >
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [_imageView.layer addSublayer:self.bottomMaskLayer];
        [_imageView.layer addSublayer:self.selectMaskLayer];
    }
    return _imageView;
}
- (CALayer *)selectMaskLayer {
    if (!_selectMaskLayer) {
        _selectMaskLayer = [CALayer layer];
        _selectMaskLayer.hidden = YES;
        _selectMaskLayer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
    }
    return _selectMaskLayer;
}
- (UILabel *)stateLb {
    if (!_stateLb) {
        _stateLb = [[UILabel alloc] init];
        _stateLb.textColor = [UIColor whiteColor];
        _stateLb.textAlignment = NSTextAlignmentRight;
        _stateLb.font = [UIFont systemFontOfSize:12];
    }
    return _stateLb;
}
- (CAGradientLayer *)bottomMaskLayer {
    if (!_bottomMaskLayer) {
        _bottomMaskLayer = [CAGradientLayer layer];
        _bottomMaskLayer.colors = @[
                                 (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor,
                                 (id)[[UIColor blackColor] colorWithAlphaComponent:0.35].CGColor
                                 ];
        _bottomMaskLayer.startPoint = CGPointMake(0, 0);
        _bottomMaskLayer.endPoint = CGPointMake(0, 1);
        _bottomMaskLayer.locations = @[@(0.15f),@(0.9f)];
        _bottomMaskLayer.borderWidth  = 0.0;
    }
    return _bottomMaskLayer;
}
- (UIButton *)selectBtn {
    if (!_selectBtn) {
        _selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectBtn setBackgroundImage:[HXPhotoTools hx_imageNamed:@"compose_guide_check_box_default@2x.png"] forState:UIControlStateNormal];
        [_selectBtn setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateSelected];
        [_selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        _selectBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _selectBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        [_selectBtn addTarget:self action:@selector(didSelectClick:) forControlEvents:UIControlEventTouchUpInside];
        [_selectBtn setEnlargeEdgeWithTop:0 right:0 bottom:10 left:10];
        _selectBtn.layer.cornerRadius = 25 / 2;
    }
    return _selectBtn;
}
@end

@interface HXDatePhotoViewSectionHeaderView ()
@property (strong, nonatomic) UILabel *dateLb;
@end

@implementation HXDatePhotoViewSectionHeaderView 
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.dateLb];
}
- (void)setModel:(HXPhotoDateModel *)model {
    _model = model;
    self.dateLb.text = model.dateString;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.dateLb.frame = CGRectMake(6, 0, self.hx_w - 12, 50);
}
- (UILabel *)dateLb {
    if (!_dateLb) {
        _dateLb = [[UILabel alloc] init];
        _dateLb.textColor = [UIColor blackColor];
        _dateLb.font = [UIFont hx_pingFangFontOfSize:14];
    }
    return _dateLb;
}
@end

@interface HXDatePhotoBottomView ()
@property (strong, nonatomic) UIToolbar *bgView;
@property (strong, nonatomic) UIButton *previewBtn;
@property (strong, nonatomic) UIButton *doneBtn;
@end

@implementation HXDatePhotoBottomView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self addSubview:self.bgView];
    [self addSubview:self.previewBtn];
    [self addSubview:self.doneBtn];
    [self changeDoneBtnFrame];
}

- (void)setSelectCount:(NSInteger)selectCount {
    _selectCount = selectCount;
    if (selectCount <= 0) {
        self.previewBtn.enabled = NO;
        self.doneBtn.enabled = NO;
        [self.doneBtn setTitle:@"完成" forState:UIControlStateNormal];
    }else {
        self.previewBtn.enabled = YES;
        self.doneBtn.enabled = YES;
        [self.doneBtn setTitle:[NSString stringWithFormat:@"完成(%ld)",selectCount] forState:UIControlStateNormal];
    }
    self.doneBtn.backgroundColor = self.doneBtn.enabled ? self.tintColor : [self.tintColor colorWithAlphaComponent:0.5];
    [self changeDoneBtnFrame];
}
- (void)changeDoneBtnFrame {
    CGFloat width = [HXPhotoTools getTextWidth:self.doneBtn.currentTitle height:30 fontSize:14];
    self.doneBtn.hx_w = width + 20;
    if (self.doneBtn.hx_w < 50) {
        self.doneBtn.hx_w = 50;
    }
    self.doneBtn.hx_x = self.hx_w - 12 - self.doneBtn.hx_w;
}
- (void)didDoneBtnClick {
    if ([self.delegate respondsToSelector:@selector(datePhotoBottomViewDidDoneBtn)]) {
        [self.delegate datePhotoBottomViewDidDoneBtn];
    }
}
- (void)didPreviewClick {
    if ([self.delegate respondsToSelector:@selector(datePhotoBottomViewDidPreviewBtn)]) {
        [self.delegate datePhotoBottomViewDidPreviewBtn];
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.bgView.frame = self.bounds;
    self.previewBtn.frame = CGRectMake(12, 0, 50, 50);
    self.previewBtn.center = CGPointMake(self.previewBtn.center.x, 25);
    self.doneBtn.frame = CGRectMake(0, 0, 50, 30);
    self.doneBtn.center = CGPointMake(self.doneBtn.center.x, 25);
    [self changeDoneBtnFrame];
}
- (UIToolbar *)bgView {
    if (!_bgView) {
        _bgView = [[UIToolbar alloc] init];
    }
    return _bgView;
}
- (UIButton *)previewBtn {
    if (!_previewBtn) {
        _previewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_previewBtn setTitle:@"预览" forState:UIControlStateNormal];
        [_previewBtn setTitleColor:self.tintColor forState:UIControlStateNormal];
        [_previewBtn setTitleColor:[self.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
        _previewBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _previewBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_previewBtn addTarget:self action:@selector(didPreviewClick) forControlEvents:UIControlEventTouchUpInside];
        _previewBtn.enabled = NO;
    }
    return _previewBtn;
}
- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_doneBtn setTitle:@"完成" forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
//        _doneBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _doneBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _doneBtn.layer.cornerRadius = 3;
        _doneBtn.enabled = NO;
        _doneBtn.backgroundColor = [self.tintColor colorWithAlphaComponent:0.5];
        [_doneBtn addTarget:self action:@selector(didDoneBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneBtn;
}
@end
    
