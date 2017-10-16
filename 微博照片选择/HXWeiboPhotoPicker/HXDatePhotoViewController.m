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

@interface HXDatePhotoViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UIViewControllerPreviewingDelegate>
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray *allArray;
@property (strong, nonatomic) NSMutableArray *photoArray;
@property (strong, nonatomic) NSMutableArray *videoArray;
@property (strong, nonatomic) NSMutableArray *dateArray;

@property (assign, nonatomic) NSInteger currentSectionIndex;
@property (strong, nonatomic) UICollectionReusableView *currentHeaderView;
@property (weak, nonatomic) id<UIViewControllerPreviewing> previewingContext;
@end

@implementation HXDatePhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self.view showLoadingHUDText:@"加载中"];
    [self getPhotoList];
}
- (void)setupUI {
    self.currentSectionIndex = 0;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
}
- (void)getPhotoList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak typeof(self) weakSelf = self;
        [self.manager getPhotoListWithAlbumModel:self.albumModel complete:^(NSArray *allList, NSArray *photoList, NSArray *videoList, NSArray *dateList) {
            weakSelf.dateArray = [NSMutableArray arrayWithArray:dateList];
            weakSelf.photoArray = [NSMutableArray arrayWithArray:photoList];
            weakSelf.videoArray = [NSMutableArray arrayWithArray:videoList];
            weakSelf.allArray = [NSMutableArray arrayWithArray:allList];
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
            });
        }];
    });
}
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.dateArray count];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    HXPhotoDateModel *dateModel = [self.dateArray objectAtIndex:section];
    return [dateModel.photoModelArray count];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXDatePhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DateCellId" forIndexPath:indexPath];
    HXPhotoDateModel *dateModel = [self.dateArray objectAtIndex:indexPath.section];
    HXPhotoModel *model = dateModel.photoModelArray[indexPath.item];
    model.rowCount = self.manager.rowCount;
    cell.model = model;
    return cell;
}
#pragma mark - < UICollectionViewDelegate >
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationController.topViewController != self) {
        return;
    }
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        HXDatePhotoViewSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionHeaderId" forIndexPath:indexPath];
        headerView.model = self.dateArray[indexPath.section];
        return headerView;
    }
    return nil;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(self.view.hx_w, 40);
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
//    }else if (frame.origin.y > kNavigationBarHeight + 40 && self.currentSectionIndex > 0) {
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
#pragma mark - < 懒加载 >
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
        _collectionView.contentInset = UIEdgeInsetsMake(kNavigationBarHeight, 0, 0, 0);
        _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(kNavigationBarHeight, 0, 0, 0);
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
    }
    return _collectionView;
}
- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemWidth = (self.view.hx_w - 3) / 4;
        CGFloat itemHeight = itemWidth;
        _flowLayout.itemSize = CGSizeMake(itemWidth, itemHeight);
        _flowLayout.minimumLineSpacing = 1;
        _flowLayout.minimumInteritemSpacing = 1;
        _flowLayout.sectionInset = UIEdgeInsetsMake(1, 0, 1, 0);
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
- (NSMutableArray *)dateArray {
    if (!_dateArray) {
        _dateArray = [NSMutableArray array];
    }
    return _dateArray;
}
- (void)dealloc {
    [self.collectionView.layer removeAllAnimations];
    [self unregisterForPreviewingWithContext:self.previewingContext];
}
@end

@interface HXDatePhotoViewCell ()
@property (strong, nonatomic) UIImageView *imageView;
@property (copy, nonatomic) NSString *localIdentifier;
@property (assign, nonatomic) int32_t requestID;
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
} 
#pragma mark - < 懒加载 >
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.frame = self.bounds;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
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

- (UILabel *)dateLb {
    if (!_dateLb) {
        _dateLb = [[UILabel alloc] initWithFrame:CGRectMake(6, 0, self.hx_w, 40)];
        _dateLb.textColor = [UIColor blackColor];
        _dateLb.font = [UIFont hx_pingFangFontOfSize:14];
    }
    return _dateLb;
}

@end
