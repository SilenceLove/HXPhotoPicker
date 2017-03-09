//
//  HXPhotoView.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoView.h"
#import "HXCollectionView.h"
#import "HXPhotoSubViewCell.h"
#import "HXPhotoViewController.h"
#import "HXPhotoPreviewViewController.h"
#import "HXVideoPreviewViewController.h"

#define Spacing 3 // 每个item的间距
#define LineNum 3 // 每行个数
@interface HXPhotoView ()<HXCollectionViewDataSource,HXCollectionViewDelegate,HXPhotoViewControllerDelegate,HXPhotoSubViewCellDelegate>
@property (strong, nonatomic) NSMutableArray *dataList;
@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *videos;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) HXCollectionView *collectionView;
@property (strong, nonatomic) HXPhotoModel *addModel;
@property (assign, nonatomic) BOOL isAddModel;
@property (assign, nonatomic) BOOL original;
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (assign, nonatomic) NSInteger numOfLinesOld;
@end

@implementation HXPhotoView
- (UICollectionViewFlowLayout *)flowLayout
{
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
    }
    return _flowLayout;
}

- (NSMutableArray *)dataList
{
    if (!_dataList) {
        _dataList = [NSMutableArray array];
    }
    return _dataList;
}

- (HXPhotoModel *)addModel
{
    if (!_addModel) {
        _addModel = [[HXPhotoModel alloc] init];
        _addModel.type = HXPhotoModelMediaTypeCamera;
        _addModel.thumbPhoto = [UIImage imageNamed:@"compose_pic_add@2x.png"];
    }
    return _addModel;
}

- (instancetype)initWithFrame:(CGRect)frame WithManager:(HXPhotoManager *)manager
{
    self = [super initWithFrame:frame];
    if (self) {
        self.manager = manager;
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.numOfLinesOld = 0;
    self.tag = 9999;
    [self.dataList addObject:self.addModel];
    
    self.flowLayout.minimumLineSpacing = Spacing;
    self.flowLayout.minimumInteritemSpacing = Spacing;
    HXCollectionView *collectionView = [[HXCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
    collectionView.tag = 8888;
    collectionView.scrollEnabled = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = self.backgroundColor;
    [collectionView registerClass:[HXPhotoSubViewCell class] forCellWithReuseIdentifier:@"cellId"];
    [self addSubview:collectionView];
    self.collectionView = collectionView;
    
    if (self.manager.endSelectedList.count > 0) {
        [self photoViewControllerDidNext:self.manager.endSelectedList.mutableCopy Photos:self.manager.endSelectedPhotos.mutableCopy Videos:self.manager.endSelectedVideos.mutableCopy Original:self.manager.endIsOriginal];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HXPhotoSubViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellId" forIndexPath:indexPath];
    cell.model = self.dataList[indexPath.item];
    cell.delegate = self;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentIndexPath = indexPath;
    HXPhotoModel *model = self.dataList[indexPath.item];
    if (model.type == HXPhotoModelMediaTypeCamera) {
        [self goPhotoViewController];
    }else if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
        vc.selectedComplete = YES;
        vc.modelList = self.photos;
        vc.index = model.endIndex;
        vc.manager = self.manager;
        [[self viewController:self] presentViewController:vc animated:YES completion:nil];
    }else if (model.type == HXPhotoModelMediaTypeVideo){
        HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
        vc.manager = self.manager;
        vc.model = model;
        vc.selectedComplete = YES;
        [[self viewController:self] presentViewController:vc animated:YES completion:nil];
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
        vc.manager = self.manager;
        vc.model = model;
        vc.isCamera = YES;
        vc.selectedComplete = YES;
        [[self viewController:self] presentViewController:vc animated:YES completion:nil];
    }
}

- (void)goCamera
{
    self.manager.goCamera = YES;
    [self goPhotoViewController];
}

- (void)goPhotoViewController
{
    HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
    vc.manager = self.manager;
    vc.delegate = self;
    [[self viewController:self] presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
}

- (void)cellDidDeleteClcik:(UICollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    HXPhotoModel *model = self.dataList[indexPath.item];
    [self.manager deleteSpecifiedModel:model];
    
    if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        [self.photos removeObject:model];
    }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.videos removeObject:model];
    }
    [self changeSelectedListModelIndex];
    
    UIView *mirrorView = [cell snapshotViewAfterScreenUpdates:NO];
    mirrorView.frame = cell.frame;
    [self.collectionView insertSubview:mirrorView atIndex:0];
    cell.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        mirrorView.transform = CGAffineTransformMakeScale(0.0001, 0.0001);
    } completion:^(BOOL finished) {
        cell.hidden = NO;
        [mirrorView removeFromSuperview];
    }];
    [self.dataList removeObjectAtIndex:indexPath.item];
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    if (self.isAddModel) {
        if ([self.delegate respondsToSelector:@selector(photoViewChangeComplete:Photos:Videos:Original:)]) {
            [self.delegate photoViewChangeComplete:self.dataList.mutableCopy Photos:self.photos.mutableCopy Videos:self.videos.mutableCopy Original:self.original];
        }
        self.isAddModel = NO;
        [self.dataList addObject:self.addModel];
        [self.collectionView reloadData];
    }else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.dataList.mutableCopy];
        [array removeLastObject];
        if ([self.delegate respondsToSelector:@selector(photoViewChangeComplete:Photos:Videos:Original:)]) {
            [self.delegate photoViewChangeComplete:array Photos:self.photos.mutableCopy Videos:self.videos.mutableCopy Original:self.original];
        }
    }
    [self setupNewFrame];
}

- (void)changeSelectedListModelIndex
{
    int i = 0, j = 0, k = 0;
    for (HXPhotoModel *model in self.manager.endSelectedList) {
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            model.endIndex = i++;
        }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
            model.endIndex = j++;
        }
        model.endCollectionIndex = k++;
    }
}

- (void)photoViewControllerDidNext:(NSArray *)allList Photos:(NSArray *)photos Videos:(NSArray *)videos Original:(BOOL)original
{
    self.original = original;
    self.photos = [NSMutableArray arrayWithArray:photos];
    self.videos = [NSMutableArray arrayWithArray:videos];
    [self.dataList removeAllObjects];
//    if (self.manager.separate) {
//        [self.dataList addObjectsFromArray:photos];
//    }else {
        [self.dataList addObjectsFromArray:allList];
//    }
    [self.dataList addObject:self.addModel];
    if (self.manager.selectTogether) {
        if (self.manager.maxNum == allList.count) {
            [self.dataList removeLastObject];
            self.isAddModel = YES;
        }
    }else {
        if (photos.count == self.manager.photoMaxNum) {
            [self.dataList removeLastObject];
            self.isAddModel = YES;
        }else if (videos.count == self.manager.videoMaxNum) {
            [self.dataList removeLastObject];
            self.isAddModel = YES;
        }
    }
    [self changeSelectedListModelIndex];
    [self.collectionView reloadData];
    
    if ([self.delegate respondsToSelector:@selector(photoViewChangeComplete:Photos:Videos:Original:)]) {
        [self.delegate photoViewChangeComplete:allList.copy Photos:photos.copy Videos:videos.copy Original:original];
    }
    [self setupNewFrame];
}

- (void)photoViewControllerDidCancel
{
    
}

- (NSArray *)dataSourceArrayOfCollectionView:(HXCollectionView *)collectionView
{
    return self.dataList;
}

- (void)dragCellCollectionView:(HXCollectionView *)collectionView newDataArrayAfterMove:(NSArray *)newDataArray
{
    self.dataList = [NSMutableArray arrayWithArray:newDataArray];
}

- (void)dragCellCollectionView:(HXCollectionView *)collectionView moveCellFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    HXPhotoModel *fromModel = self.dataList[fromIndexPath.item];
    HXPhotoModel *toModel = self.dataList[toIndexPath.item];
    [self.manager.endSelectedList removeObject:toModel];
    [self.manager.endSelectedList insertObject:toModel atIndex:toIndexPath.item];
    [self.manager.endSelectedList removeObject:fromModel];
    [self.manager.endSelectedList insertObject:fromModel atIndex:fromIndexPath.item];
    [self.photos removeAllObjects];
    [self.videos removeAllObjects];
    int i = 0, j = 0, k = 0;
    for (HXPhotoModel *model in self.manager.endSelectedList) {
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            model.endIndex = i++;
            [self.photos addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
            model.endIndex = j++;
            [self.videos addObject:model];
        }
        model.endCollectionIndex = k++;
    }
    self.manager.endSelectedPhotos = [NSMutableArray arrayWithArray:self.photos];
    self.manager.endSelectedVideos = [NSMutableArray arrayWithArray:self.videos];
}

- (void)dragCellCollectionViewCellEndMoving:(HXCollectionView *)collectionView
{
    if (self.isAddModel) {
        if ([self.delegate respondsToSelector:@selector(photoViewChangeComplete:Photos:Videos:Original:)]) {
            [self.delegate photoViewChangeComplete:self.dataList.mutableCopy Photos:self.photos.mutableCopy Videos:self.videos.mutableCopy Original:self.original];
        }
    }else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.dataList.mutableCopy];
        [array removeLastObject];
        if ([self.delegate respondsToSelector:@selector(photoViewChangeComplete:Photos:Videos:Original:)]) {
            [self.delegate photoViewChangeComplete:array Photos:self.photos.mutableCopy Videos:self.videos.mutableCopy Original:self.original];
        }
    }
}

- (UIViewController*)viewController:(UIView *)view {
    for (UIView* next = [view superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UINavigationController class]] || [nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

- (void)setupNewFrame
{
    CGFloat x = self.frame.origin.x;
    CGFloat y = self.frame.origin.y;
    CGFloat width = self.frame.size.width;
    
    CGFloat itemW = (width - Spacing * (LineNum - 1)) / LineNum;
    self.flowLayout.itemSize = CGSizeMake(itemW, itemW);
    
    NSInteger dataCount = self.dataList.count;
    NSInteger numOfLinesNew = (dataCount / LineNum) + 1;
    
    if (dataCount % LineNum == 0) {
        numOfLinesNew -= 1;
    }
    self.flowLayout.minimumLineSpacing = Spacing;
    
    if (numOfLinesNew != self.numOfLinesOld) {
        CGFloat newHeight = numOfLinesNew * itemW + Spacing * (numOfLinesNew - 1);
        self.frame = CGRectMake(x, y, width, newHeight);
        self.numOfLinesOld = numOfLinesNew;
        if ([self.delegate respondsToSelector:@selector(photoViewUpdateFrame:WithView:)]) {
            [self.delegate photoViewUpdateFrame:self.frame WithView:self];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    NSInteger dataCount = self.dataList.count;
    NSInteger numOfLinesNew = (dataCount / LineNum) + 1;
    
    [self setupNewFrame];
    CGFloat x = self.frame.origin.x;
    CGFloat y = self.frame.origin.y;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    if (dataCount == 1) {
        CGFloat itemW = (width - Spacing * (LineNum - 1)) / LineNum;
        if ((int)height != (int)itemW) {
            self.frame = CGRectMake(x, y, width, itemW);
        }
    }
    if (dataCount % LineNum == 0) {
        numOfLinesNew -= 1;
    }
    CGFloat cWidth = self.frame.size.width;
    CGFloat cHeight = self.frame.size.height;
    self.collectionView.frame = CGRectMake(0, 0, cWidth, cHeight);
}

@end
