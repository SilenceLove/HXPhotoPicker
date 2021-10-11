//
//  HXPhotoView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/17.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXPhotoView.h"
#import "UIView+HXExtension.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+HXExtension.h"
#import "HXAlbumListViewController.h"
#import "HXPhotoPreviewViewController.h"
#import "HXCustomNavigationController.h"
#import "HXCustomCameraViewController.h"
#import "HXPhotoViewController.h"
#import "HXPhotoBottomSelectView.h"
#import "UIColor+HXExtension.h"

@interface HXPhotoView ()<HXCollectionViewDataSource,HXCollectionViewDelegate, UICollectionViewDelegateFlowLayout,HXPhotoSubViewCellDelegate,UIAlertViewDelegate,HXAlbumListViewControllerDelegate,HXCustomCameraViewControllerDelegate,HXPhotoPreviewViewControllerDelegate, HXPhotoViewControllerDelegate, HXCustomNavigationControllerDelegate>
@property (strong, nonatomic) NSMutableArray *dataList;
@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *videos;
@property (strong, nonatomic) HXPhotoModel *addModel;
@property (assign, nonatomic) BOOL isAddModel;
@property (assign, nonatomic) BOOL original;
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (assign, nonatomic) NSInteger numOfLinesOld; 
@property (assign, nonatomic) BOOL downLoadComplete;
@property (strong, nonatomic) UIImage *tempCameraImage;
@property (strong, nonatomic) UIImagePickerController* imagePickerController;
@property (strong, nonatomic) HXPhotoSubViewCell *addCell;
@property (assign, nonatomic) BOOL tempShowAddCell;
@property (assign, nonatomic) CGFloat lastWidth;
@end

@implementation HXPhotoView
@synthesize addImageName = _addImageName;
@synthesize addDarkImageName = _addDarkImageName;
@synthesize manager = _manager;

- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.scrollDirection = self.scrollDirection;
    }
    return _flowLayout;
}

- (NSMutableArray *)dataList {
    if (!_dataList) {
        _dataList = [NSMutableArray array];
    }
    return _dataList;
}
- (HXPhotoModel *)addModel {
    if (!_addModel) {
        _addModel = [[HXPhotoModel alloc] init];
        _addModel.type = HXPhotoModelMediaTypeCamera;
        _addModel.thumbPhoto = [UIImage hx_imageNamed:self.addImageName];
        _addModel.previewPhoto = [UIImage hx_imageNamed:self.addDarkImageName];
    }
    return _addModel;
} 
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] init];
    }
    return _manager;
}
+ (instancetype)photoManager:(HXPhotoManager *)manager {
    return [[self alloc] initWithManager:manager];
}
+ (instancetype)photoManager:(HXPhotoManager *)manager scrollDirection:(UICollectionViewScrollDirection)scrollDirection {
    return [[self alloc] initWithManager:manager scrollDirection:scrollDirection];
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self setup];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame manager:(HXPhotoManager *)manager {
    return [self initWithFrame:frame manager:manager scrollDirection:UICollectionViewScrollDirectionVertical];
}
- (instancetype)initWithFrame:(CGRect)frame manager:(HXPhotoManager *)manager scrollDirection:(UICollectionViewScrollDirection)scrollDirection {
    self = [super initWithFrame:frame];
    if (self) {
        self.scrollDirection = scrollDirection;
        _manager = manager;
        [self setup];
    }
    return self;
}
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    return [self initWithManager:manager scrollDirection:UICollectionViewScrollDirectionVertical];
}
- (instancetype)initWithManager:(HXPhotoManager *)manager scrollDirection:(UICollectionViewScrollDirection)scrollDirection {
    self = [super init];
    if (self) {
        self.scrollDirection = scrollDirection;
        _manager = manager;
        [self setup];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}
- (HXCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[HXCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        if (self.scrollDirection != UICollectionViewScrollDirectionHorizontal) {
            _collectionView.scrollEnabled = NO;
        }
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = self.backgroundColor;
        [_collectionView registerClass:[HXPhotoSubViewCell class] forCellWithReuseIdentifier:@"HXPhotoSubViewCellId"];
        [_collectionView registerClass:[HXPhotoSubViewCell class] forCellWithReuseIdentifier:@"addCell"];
    }
    return _collectionView;
}
- (NSInteger)lineCount {
    if (!_lineCount) {
        _lineCount = 3;
    }
    return _lineCount;
}
- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection {
    _scrollDirection = scrollDirection;
    if (scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        self.collectionView.scrollEnabled = YES;
    }else {
        self.collectionView.scrollEnabled = NO;
    }
    self.flowLayout.scrollDirection = scrollDirection;
}
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.collectionView.backgroundColor = backgroundColor;
    [super setBackgroundColor:backgroundColor];
}
- (void)setup {
    self.maximumHeight = HX_ScreenHeight;
    self.lastWidth = 0;
    if (_manager) {
        _manager.configuration.specialModeNeedHideVideoSelectBtn = YES;
    }
    self.spacing = 3;
    self.lineCount = 3;
    self.numOfLinesOld = 0;
    self.tag = 9999;
    _showAddCell = YES;
    self.tempShowAddCell = YES;
    self.previewShowBottomPageControl = YES;
    self.adaptiveDarkness = YES;
    
    self.flowLayout.minimumLineSpacing = self.spacing;
    self.flowLayout.minimumInteritemSpacing = self.spacing;
    [self addSubview:self.collectionView];
    
    if (_manager.afterSelectedArray.count > 0) {
        if ([self.delegate respondsToSelector:@selector(photoListViewControllerDidDone:allList:photos:videos:original:)]) {
            [self.delegate photoListViewControllerDidDone:self allList:self.manager.afterSelectedArray.copy photos:self.manager.afterSelectedPhotoArray.copy videos:self.manager.afterSelectedVideoArray.copy original:self.manager.afterOriginal];
        }
        [self setupDataWithAllList:self.manager.afterSelectedArray.copy photos:self.manager.afterSelectedPhotoArray.copy videos:self.manager.afterSelectedVideoArray.copy original:self.manager.afterOriginal];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView) name:@"HXPhotoViewNeedReloadNotification" object:nil];
}
- (void)jumpPreviewViewControllerWithModel:(HXPhotoModel *)model {
    if (![self.manager.afterSelectedArray containsObject:model]) {
        NSSLog(@"model有误!!!");
        return;
    }
    HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
    vc.disableaPersentInteractiveTransition = self.disableaInteractiveTransition;
    vc.outside = YES;
    vc.manager = self.manager;
    vc.exteriorPreviewStyle = self.previewStyle;
    vc.delegate = self;
    vc.modelArray = [NSMutableArray arrayWithArray:self.manager.afterSelectedArray];
    vc.currentModelIndex = [self.manager.afterSelectedArray indexOfObject:model];
    vc.previewShowDeleteButton = self.previewShowDeleteButton;
    vc.showBottomPageControl = self.previewShowBottomPageControl;
    vc.photoView = self;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalPresentationCapturesStatusBarAppearance = YES;
    [[self hx_viewController] presentViewController:vc animated:YES completion:nil];
}
- (void)jumpPreviewViewControllerWithIndex:(NSInteger)index {
    if (index >= 0 && index < self.manager.afterSelectedArray.count) {
        HXPhotoModel *model = self.manager.afterSelectedArray[index];
        [self jumpPreviewViewControllerWithModel:model];
    }else {
        NSSLog(@"越界啦!!!");
    }
}
- (HXPhotoSubViewCell *)previewingContextViewWithPoint:(CGPoint)point {
    CGPoint cPoint = [self convertPoint:point toView:self.collectionView]; 
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:cPoint];
    if (indexPath) {
        HXPhotoSubViewCell *cell = (HXPhotoSubViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (cell.model.type == HXPhotoModelMediaTypeCamera) {
            return nil;
        }
        return cell;
    }
    return nil;
}
- (HXPhotoSubViewCell *)collectionViewCellWithIndex:(NSInteger)index {
    if (index < 0 || index > self.dataList.count - 1 || !self.dataList.count) {
        return nil;
    }
    HXPhotoSubViewCell *cell = (HXPhotoSubViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    if (cell.model.type == HXPhotoModelMediaTypeCamera) {
        return nil;
    }
    return cell;
}
- (void)setEditEnabled:(BOOL)editEnabled {
    _editEnabled = editEnabled;
    self.collectionView.editEnabled = editEnabled;
}

- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
    manager.configuration.specialModeNeedHideVideoSelectBtn = YES;
    if (self.manager.afterSelectedArray.count > 0) {
        if ([self.delegate respondsToSelector:@selector(photoListViewControllerDidDone:allList:photos:videos:original:)]) {
            [self.delegate photoListViewControllerDidDone:self allList:self.manager.afterSelectedArray.copy photos:self.manager.afterSelectedPhotoArray.copy videos:self.manager.afterSelectedVideoArray.copy original:self.manager.afterOriginal];
        }
        [self setupDataWithAllList:self.manager.afterSelectedArray.copy photos:self.manager.afterSelectedPhotoArray.copy videos:self.manager.afterSelectedVideoArray.copy original:self.manager.afterOriginal];
    }
}

- (void)setHideDeleteButton:(BOOL)hideDeleteButton {
    _hideDeleteButton = hideDeleteButton;
    [self.collectionView reloadData];
}
- (void)setShowAddCell:(BOOL)showAddCell {
    _showAddCell = showAddCell;
    self.tempShowAddCell = showAddCell;
    if (self.manager.afterSelectedArray.count > 0) {
        [self setupDataWithAllList:self.manager.afterSelectedArray.copy photos:self.manager.afterSelectedPhotoArray.copy videos:self.manager.afterSelectedVideoArray.copy original:self.manager.afterOriginal];
    }
}
- (NSString *)addImageName {
    if (!_addImageName) {
        _addImageName = @"hx_list_add_img";
    }
    return _addImageName;
}
- (NSString *)addDarkImageName {
    if (!_addDarkImageName) {
        _addDarkImageName = @"hx_list_add_dark_img";
    }
    return _addDarkImageName;
}
- (void)setAddImageName:(NSString *)addImageName {
    _addImageName = addImageName;
    self.addModel.thumbPhoto = [UIImage hx_imageNamed:addImageName];
    if (self.tempShowAddCell) {
        [self.collectionView reloadData];
    }
}
- (void)setAddDarkImageName:(NSString *)addDarkImageName {
    _addDarkImageName = addDarkImageName;
    self.addModel.previewPhoto = [UIImage hx_imageNamed:addDarkImageName];
    if (self.tempShowAddCell) {
        [self.collectionView reloadData];
    }
}
- (void)setDeleteImageName:(NSString *)deleteImageName {
    _deleteImageName = deleteImageName;
    [self.collectionView reloadData];
}
/**
 刷新视图
 */
- (void)refreshView {
    if (!self.manager.configuration.singleSelected) {
        [self setupDataWithAllList:self.manager.afterSelectedArray.copy photos:self.manager.afterSelectedPhotoArray.copy videos:self.manager.afterSelectedVideoArray.copy original:self.manager.afterOriginal];
    }
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.tempShowAddCell ? self.dataList.count + 1 : self.dataList.count;
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tempShowAddCell) {
        if (indexPath.item == self.dataList.count) {
            HXPhotoSubViewCell *addCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"addCell" forIndexPath:indexPath];
            addCell.index = indexPath.item;
            addCell.model = self.addModel;
            return addCell;
        }
    }
    HXPhotoSubViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoSubViewCellId" forIndexPath:indexPath];
    cell.index = indexPath.item;
    cell.customProtocol = self.cellCustomProtocol;
    cell.delegate = self;
    cell.canEdit = self.collectionView.editEnabled;
    if (self.deleteImageName) {
        cell.deleteImageName = self.deleteImageName;
    }
    cell.model = self.dataList[indexPath.item];
    cell.showDeleteNetworkPhotoAlert = self.showDeleteNetworkPhotoAlert;
    cell.deleteCellShowAlert = self.deleteCellShowAlert;
    cell.hideDeleteButton = self.hideDeleteButton;
    return cell;
}
 
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath { 
    if (self.tempShowAddCell && indexPath.item == self.dataList.count) {
        return YES; 
    }
    BOOL canSelect = YES;
    if ([self.delegate respondsToSelector:@selector(photoView:collectionViewShouldSelectItemAtIndexPath:model:)]) {
        HXPhotoModel *model = self.dataList[indexPath.item];
        canSelect = [self.delegate photoView:self collectionViewShouldSelectItemAtIndexPath:indexPath model:model];
    }
    return canSelect;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tempShowAddCell) {
        if (indexPath.item == self.dataList.count) {
            if ([self.delegate respondsToSelector:@selector(photoViewDidAddCellClick:)]) {
                [self.delegate photoViewDidAddCellClick:self];
            }
            if (self.didAddCellBlock) {
                self.didAddCellBlock(self);
            }
            if (self.interceptAddCellClick) {
                return;
            }
            [self goPhotoViewController];
            return;
        }
    }
    self.currentIndexPath = indexPath;
    HXPhotoModel *model = self.dataList[indexPath.item];
    if (model.networkPhotoUrl) {
        if (model.downloadError) {
            HXPhotoSubViewCell *cell = (HXPhotoSubViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [cell againDownload];
            return;
        }
    }
    if (model.type == HXPhotoModelMediaTypeCamera) {
        if ([self.delegate respondsToSelector:@selector(photoViewDidAddCellClick:)]) {
            [self.delegate photoViewDidAddCellClick:self];
        }
        if (self.didAddCellBlock) {
            self.didAddCellBlock(self);
        }
        if (self.interceptAddCellClick) {
            return;
        }
        [self goPhotoViewController];
    }else {
        HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
        vc.disableaPersentInteractiveTransition = self.disableaInteractiveTransition;
        vc.outside = YES;
        vc.manager = self.manager;
        vc.exteriorPreviewStyle = self.previewStyle;
        vc.delegate = self;
        vc.modelArray = [NSMutableArray arrayWithArray:self.dataList];
        vc.currentModelIndex = [self.dataList indexOfObject:model];
        vc.previewShowDeleteButton = self.previewShowDeleteButton;
        vc.showBottomPageControl = self.previewShowBottomPageControl;
        vc.photoView = self;
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
        vc.modalPresentationCapturesStatusBarAppearance = YES;
        [[self hx_viewController] presentViewController:vc animated:YES completion:nil];
    }
}
#if HXPhotoViewCustomItemSize || HXPhotoViewCustomItemSizeEnable
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isAddItem = NO;
    if (self.tempShowAddCell && indexPath.item == self.dataList.count) {
        isAddItem =  YES;
    }
    CGSize size = CGSizeMake(100, 100);
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:isAddItem:photoView:)]) {
        size = [self.delegate collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath isAddItem:isAddItem photoView:self];
    }
    return size;
}
#endif
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:photoView:)]) {
        return [self.delegate collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section photoView:self];
    }
    return self.spacing;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:photoView:)]) {
        return [self.delegate collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section photoView:self];
    }
    return self.spacing;
}

#pragma mark - < HXPhotoPreviewViewControllerDelegate >
- (void)photoPreviewControllerDidCancel:(HXPhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    if ([self.delegate respondsToSelector:@selector(photoViewPreviewDismiss:)]) {
        [self.delegate photoViewPreviewDismiss:self];
    }
}
- (void)photoPreviewCellDownloadImageComplete:(HXPhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    if (!model.loadOriginalImage) {
        NSIndexPath *indexPath = [self currentModelIndexPath:model];
        HXPhotoSubViewCell *cell = (HXPhotoSubViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell resetNetworkImage]; 
    }
}
- (void)photoPreviewDidDeleteClick:(HXPhotoPreviewViewController *)previewController deleteModel:(HXPhotoModel *)model deleteIndex:(NSInteger)index {
    [self deleteModelWithIndex:index];
}
- (void)photoPreviewSelectLaterDidEditClick:(HXPhotoPreviewViewController *)previewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel {
    if (self.manager.configuration.useWxPhotoEdit && afterModel.subType == HXPhotoModelMediaSubTypePhoto) {
        [self.collectionView reloadData];
        [self dragCellCollectionViewCellEndMoving:self.collectionView];
        return;
    }
    [self.manager afterSelectedArrayReplaceModelAtModel:beforeModel withModel:afterModel];
    [self.manager afterSelectedListAddEditPhotoModel:afterModel];
    
    [self.photos removeAllObjects];
    [self.videos removeAllObjects];
    NSInteger i = 0;
    for (HXPhotoModel *model in self.manager.afterSelectedArray) {
        model.selectIndexStr = [NSString stringWithFormat:@"%ld",i + 1];
        if (model.subType == HXPhotoModelMediaSubTypePhoto) {
            [self.photos addObject:model];
        }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            [self.videos addObject:model];
        }
        i++;
    }
    [self.manager setAfterSelectedPhotoArray:self.photos];
    [self.manager setAfterSelectedVideoArray:self.videos];
    [self.dataList replaceObjectAtIndex:[self.dataList indexOfObject:beforeModel] withObject:afterModel];
    [self.collectionView reloadData];
    [self dragCellCollectionViewCellEndMoving:self.collectionView];
}

/**
 添加按钮点击事件
 */
- (void)goPhotoViewController {
    if (self.outerCamera) {
        HXPhotoBottomViewModel *shootingModel = [[HXPhotoBottomViewModel alloc] init];
        shootingModel.subTitleDarkColor = [UIColor hx_colorWithHexStr:@"#999999"];
        if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
            if (self.manager.configuration.photoMaxNum > 0) {
                self.manager.configuration.maxNum = self.manager.configuration.photoMaxNum;
            }
            shootingModel.title = [NSBundle hx_localizedStringForKey:@"拍照"];
        }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
            if (self.manager.configuration.videoMaxNum > 0) {
                self.manager.configuration.maxNum = self.manager.configuration.videoMaxNum;
            }
            shootingModel.title = [NSBundle hx_localizedStringForKey:@"摄像"];
        }else {
            shootingModel.title = [NSBundle hx_localizedStringForKey:@"拍摄"];
            if (self.manager.configuration.photoMaxNum > 0 &&
                self.manager.configuration.videoMaxNum > 0) {
                self.manager.configuration.maxNum = self.manager.configuration.videoMaxNum + self.manager.configuration.photoMaxNum;
            }
            if (!self.manager.configuration.selectTogether) {
                if (self.manager.afterSelectedPhotoArray.count) {
                    shootingModel.title = [NSBundle hx_localizedStringForKey:@"拍照"];
                }else if (self.manager.afterSelectedVideoArray.count) {
                    shootingModel.title = [NSBundle hx_localizedStringForKey:@"摄像"];
                }else {
                    shootingModel.subTitle = [NSBundle hx_localizedStringForKey:@"照片或视频"];
                    shootingModel.cellHeight = 65.f;
                }
            }else {
                shootingModel.subTitle = [NSBundle hx_localizedStringForKey:@"照片或视频"];
                shootingModel.cellHeight = 65.f;
            }
        }
        HXPhotoBottomViewModel *selectModel = [[HXPhotoBottomViewModel alloc] init];
        selectModel.title = [NSBundle hx_localizedStringForKey:@"从手机相册选择"];
        
        HXWeakSelf
        HXPhotoBottomSelectView *selectView = [HXPhotoBottomSelectView showSelectViewWithModels:@[shootingModel, selectModel] headerView:nil showTopLineView:NO cancelTitle:nil selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
            if (index == 0) {
                [weakSelf goCameraViewController];
            }else if (index == 1) {
                [weakSelf directGoPhotoViewController];
            }
        } cancelClick:nil];
        selectView.adaptiveDarkness = self.adaptiveDarkness;
        return;
    }
    [self directGoPhotoViewController];
}

- (void)directGoPhotoViewController {
    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithManager:self.manager delegate:self];
    nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
    nav.modalPresentationCapturesStatusBarAppearance = YES;
    [[self hx_viewController] presentViewController:nav animated:YES completion:nil]; 
}
#pragma mark - < HXCustomNavigationControllerDelegate >
- (void)photoNavigationViewController:(HXCustomNavigationController *)photoNavigationViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    
    if ([self.delegate respondsToSelector:@selector(photoListViewControllerDidDone:allList:photos:videos:original:)]) {
        [self.delegate photoListViewControllerDidDone:self allList:allList photos:photoList videos:videoList original:original];
    }
    if ([self.delegate respondsToSelector:@selector(photoViewCurrentSelected:photos:videos:original:)]) {
        NSMutableArray *allModel = [NSMutableArray array];
        NSMutableArray *photoModels = [NSMutableArray array];
        NSMutableArray *videoModels = [NSMutableArray array];
        NSMutableArray *tempAll = allList.mutableCopy;
        for (HXPhotoModel *pModel in self.dataList) {
            for (HXPhotoModel *subPModel in tempAll) {
                if ([pModel isEqualToPhotoModel:subPModel]) {
                    [tempAll removeObject:subPModel];
                    break;
                }
            }
        }
        for (HXPhotoModel *photoModel in tempAll) {
            if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                [photoModels addObject:photoModel];
            }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                [videoModels addObject:photoModel];
            }
            [allModel addObject:photoModel];
        }
        [self.delegate photoViewCurrentSelected:allModel.copy photos:photoModels.copy videos:videoModels.copy original:original];
    }
    [self setupDataWithAllList:allList photos:photoList videos:videoList original:original];
}
- (void)photoNavigationViewControllerDidCancel:(HXCustomNavigationController *)photoNavigationViewController {
    if ([self.delegate respondsToSelector:@selector(photoViewDidCancel:)]) {
        [self.delegate photoViewDidCancel:self];
    }
    if (self.didCancelBlock) {
        self.didCancelBlock();
    }
}

/**
 前往相机
 */
- (void)goCameraViewController {
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [[self hx_viewController].view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法使用相机!"]];
        return;
    }
    HXWeakSelf
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                if (weakSelf.manager.configuration.replaceCameraViewController) {
                    HXPhotoConfigurationCameraType cameraType;
                    if (weakSelf.manager.type == HXPhotoManagerSelectedTypePhoto) {
                        cameraType = HXPhotoConfigurationCameraTypePhoto;
                    }else if (weakSelf.manager.type == HXPhotoManagerSelectedTypeVideo) {
                        cameraType = HXPhotoConfigurationCameraTypeVideo;
                    }else {
                        if (!weakSelf.manager.configuration.selectTogether) {
                            if (weakSelf.manager.afterSelectedPhotoArray.count > 0) {
                                cameraType = HXPhotoConfigurationCameraTypePhoto;
                            }else if (weakSelf.manager.afterSelectedVideoArray.count > 0) {
                                cameraType = HXPhotoConfigurationCameraTypeVideo;
                            }else {
                                cameraType = HXPhotoConfigurationCameraTypePhotoAndVideo;
                            }
                        }else {
                            cameraType = HXPhotoConfigurationCameraTypePhotoAndVideo;
                        }
                    }
                    switch (weakSelf.manager.configuration.customCameraType) {
                        case HXPhotoCustomCameraTypePhoto:
                            cameraType = HXPhotoConfigurationCameraTypePhoto;
                            break;
                        case HXPhotoCustomCameraTypeVideo:
                            cameraType = HXPhotoConfigurationCameraTypeVideo;
                            break;
                        case HXPhotoCustomCameraTypePhotoAndVideo:
                            cameraType = HXPhotoConfigurationCameraTypePhotoAndVideo;
                            break;
                        default:
                            break;
                    }
                    if (weakSelf.manager.configuration.shouldUseCamera) {
                        weakSelf.manager.configuration.shouldUseCamera([weakSelf hx_viewController], cameraType, weakSelf.manager);
                    }
                    weakSelf.manager.configuration.useCameraComplete = ^(HXPhotoModel *model) {
                        [weakSelf customCameraViewController:nil didDone:model];
                    };
                    return;
                }
                HXCustomCameraViewController *vc = [[HXCustomCameraViewController alloc] init];
                vc.delegate = weakSelf;
                vc.manager = weakSelf.manager;
                vc.isOutside = YES;
                HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
                nav.isCamera = YES;
                nav.supportRotation = weakSelf.manager.configuration.supportRotation;
                nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
                nav.modalPresentationCapturesStatusBarAppearance = YES;
                [[weakSelf hx_viewController] presentViewController:nav animated:YES completion:nil];
            }else {
                [HXPhotoTools showUnusableCameraAlert:weakSelf.hx_viewController];
            }
        });
    }];
}

- (void)customCameraViewController:(HXCustomCameraViewController *)viewController didDone:(HXPhotoModel *)model {
    [self cameraDidNextClick:model];
}
/**
 相机拍完之后的代理

 @param model 照片模型
 */
- (void)cameraDidNextClick:(HXPhotoModel *)model {
    // 判断类型
    if (self.manager.shouldSelectModel) {
        NSString *str = self.manager.shouldSelectModel(model);
        if (str) {
            [[self hx_viewController].view hx_showImageHUDText:str];
            return;
        }
    }
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
            [[self hx_viewController].view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"图片不能和视频同时选择"]];
            return;
        }
        // 当选择图片个数没有达到最大个数时就添加到选中数组中
        if ([self.manager afterSelectPhotoCountIsMaximum]) {
            NSInteger maxCount = self.manager.configuration.photoMaxNum > 0 ? self.manager.configuration.photoMaxNum : self.manager.configuration.maxNum;
            [[self hx_viewController].view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld张图片"],maxCount]];
            return;
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
            [[self hx_viewController].view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"视频不能和图片同时选择"]];
            return;
        }
        // 当选中视频个数没有达到最大个数时就添加到选中数组中 
        if (round(model.videoDuration) < self.manager.configuration.videoMinimumSelectDuration) {
            
            [[self hx_viewController].view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频少于%ld秒，无法选择"], self.manager.configuration.videoMinimumSelectDuration]];
            return;
        }else if (round(model.videoDuration) >= self.manager.configuration.videoMaximumSelectDuration + 1) {
            [[self hx_viewController].view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频大于%ld秒，无法选择"], self.manager.configuration.videoMaximumSelectDuration]];
            return;
        }else if ([self.manager afterSelectVideoCountIsMaximum]) {
            NSInteger maxCount = self.manager.configuration.videoMaxNum > 0 ? self.manager.configuration.videoMaxNum : self.manager.configuration.maxNum;
            [[self hx_viewController].view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个视频"],maxCount]];
            return;
        }
    }
    [self.manager afterListAddCameraTakePicturesModel:model];
    if ([self.delegate respondsToSelector:@selector(photoViewCameraTakePictureCompletion:model:)]) {
        [self.delegate photoViewCameraTakePictureCompletion:self model:model];
    }
    if ([self.delegate respondsToSelector:@selector(photoListViewControllerDidDone:allList:photos:videos:original:)]) {
        [self.delegate photoListViewControllerDidDone:self allList:self.manager.afterSelectedArray.copy photos:self.manager.afterSelectedPhotoArray.copy videos:self.manager.afterSelectedVideoArray.copy original:self.manager.afterOriginal];
    }
    [self setupDataWithAllList:self.manager.afterSelectedArray.copy photos:self.manager.afterSelectedPhotoArray.copy videos:self.manager.afterSelectedVideoArray.copy original:self.manager.afterOriginal];
}

- (void)deleteModelWithIndex:(NSInteger)index {
    if (index < 0) {
        index = 0;
    }
    if (index > self.manager.afterSelectedArray.count - 1) {
        index = self.manager.afterSelectedArray.count - 1;
    }
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    if (cell) {
        [self cellDidDeleteClcik:cell];
    }else {
        if (HXShowLog) NSSLog(@"删除失败 - cell为空");
    }
}
/**
 cell删除按钮的代理

 @param cell 被删的cell
 */
- (void)cellDidDeleteClcik:(UICollectionViewCell *)cell {
    if (!cell) {
        return;
    }
    [(HXPhotoSubViewCell *)cell imageView].image = nil;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    HXPhotoModel *model = self.dataList[indexPath.item];
    model.photoEdit = nil;
    [self.manager afterSelectedListdeletePhotoModel:model];
    if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        [self.photos removeObject:model];
    }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.videos removeObject:model];
    }
    
    UIView *mirrorView = [cell snapshotViewAfterScreenUpdates:NO];
    mirrorView.frame = cell.frame;
    [self.collectionView insertSubview:mirrorView atIndex:0];
    cell.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        mirrorView.transform = CGAffineTransformMakeScale(0.0001, 0.0001);
    } completion:^(BOOL finished) {
        cell.hidden = NO;
        HXPhotoSubViewCell *myCell = (HXPhotoSubViewCell *)cell;
        myCell.imageView.image = nil;
        [mirrorView removeFromSuperview];
    }];
    [self.dataList removeObjectAtIndex:indexPath.item];

    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        BOOL collectionReload = YES;
        if (self.showAddCell) {
            if (!self.tempShowAddCell) {
                self.tempShowAddCell = YES;
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                [self.collectionView reloadData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CATransaction commit];
                });
                collectionReload = NO;
            }
        }
        if (self.cellCustomProtocol && collectionReload) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            [self.collectionView reloadData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [CATransaction commit];
            });
        }
        [self setupNewFrame];
    }];
    [self changeSelectedListModelIndex];
    if (model.networkPhotoUrl) {
        if ([self.delegate respondsToSelector:@selector(photoView:deleteNetworkPhoto:)]) {
            [self.delegate photoView:self deleteNetworkPhoto:model.networkPhotoUrl.absoluteString];
        }
        if (self.deleteNetworkPhotoBlock) {
            self.deleteNetworkPhotoBlock(model.networkPhotoUrl.absoluteString);
        }
    }
    if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
        [self.delegate photoView:self changeComplete:self.dataList.copy photos:self.photos.copy videos:self.videos.copy original:self.original];
    }
    
    if ([self.delegate respondsToSelector:@selector(photoListViewControllerDidDone:allList:photos:videos:original:)]) {
        [self.delegate photoListViewControllerDidDone:self allList:self.manager.afterSelectedArray.copy photos:self.manager.afterSelectedPhotoArray.copy videos:self.manager.afterSelectedVideoArray.copy original:self.manager.afterOriginal];
    }
    if ([self.delegate respondsToSelector:@selector(photoViewChangeComplete:allAssetList:photoAssets:videoAssets:original:)]) {
        NSMutableArray *allAsset = [NSMutableArray array];
        NSMutableArray *photoAssets = [NSMutableArray array];
        NSMutableArray *videoAssets = [NSMutableArray array];
        for (HXPhotoModel *phMd in self.dataList) {
            if (phMd.asset) {
                if (phMd.subType == HXPhotoModelMediaSubTypePhoto) {
                    [photoAssets addObject:phMd.asset];
                }else {
                    [videoAssets addObject:phMd.asset];
                }
                [allAsset addObject:phMd.asset];
            }
        }
        [self.delegate photoViewChangeComplete:self allAssetList:allAsset photoAssets:photoAssets videoAssets:videoAssets original:self.original];
    }
    if (self.changeCompleteBlock) {
        self.changeCompleteBlock(self.dataList.copy, self.photos.copy, self.videos.copy, self.original);
    }
    if ([self.delegate respondsToSelector:@selector(photoView:currentDeleteModel:currentIndex:)]) {
        [self.delegate photoView:self currentDeleteModel:model currentIndex:indexPath.item];
    }
    if (self.currentDeleteModelBlock) {
        self.currentDeleteModelBlock(model, indexPath.item);
    }
    if (model.type != HXPhotoModelMediaTypeCameraPhoto &&
        model.type != HXPhotoModelMediaTypeCameraVideo) {
        model.thumbPhoto = nil;
        model.previewPhoto = nil;
        model = nil;
    }
}

- (void)changeSelectedListModelIndex {
    int i = 0;
    for (HXPhotoModel *model in self.dataList) {
        model.selectedIndex = i;
        model.selectIndexStr = [NSString stringWithFormat:@"%d",i + 1];
        i++;
    }
}
- (void)setupDataWithAllList:(NSArray *)allList photos:(NSArray *)photos videos:(NSArray *)videos original:(BOOL)original {
    
    self.original = original;
    NSMutableArray *tempAllArray = [NSMutableArray array];
    NSMutableArray *tempPhotoArray = [NSMutableArray array];
    [tempAllArray addObjectsFromArray:allList];
    [tempPhotoArray addObjectsFromArray:photos];
    allList = tempAllArray;
    photos = tempPhotoArray;
    
    self.photos = [NSMutableArray arrayWithArray:photos];
    self.videos = [NSMutableArray arrayWithArray:videos];
    [self.dataList removeAllObjects];
    [self.dataList addObjectsFromArray:allList];
    if (self.showAddCell) {
        self.tempShowAddCell = YES;
        if (self.manager.configuration.selectTogether) {
            if (self.manager.configuration.maxNum == allList.count) {
                self.tempShowAddCell = NO;
            }
        }else {
            if (photos.count > 0) {
                NSInteger maxCount = self.manager.configuration.photoMaxNum > 0 ? self.manager.configuration.photoMaxNum : self.manager.configuration.maxNum;
                if (photos.count == maxCount) {
                    if (maxCount > 0) {
                        self.tempShowAddCell = NO;
                    }
                }
            }else if (videos.count > 0) {
                NSInteger maxCount = self.manager.configuration.videoMaxNum > 0 ? self.manager.configuration.videoMaxNum : self.manager.configuration.maxNum;
                if (videos.count == maxCount) {
                    if (maxCount > 0) {
                        self.tempShowAddCell = NO;
                    }
                }
            }
        }
    }
    [self changeSelectedListModelIndex];
    [self.collectionView reloadData];
    if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
        [self.delegate photoView:self changeComplete:allList.copy photos:photos.copy videos:videos.copy original:original];
    }
    if ([self.delegate respondsToSelector:@selector(photoViewChangeComplete:allAssetList:photoAssets:videoAssets:original:)]) {
        NSMutableArray *allAsset = [NSMutableArray array];
        NSMutableArray *photoAssets = [NSMutableArray array];
        NSMutableArray *videoAssets = [NSMutableArray array];
        for (HXPhotoModel *phMd in allList) {
            if (phMd.asset) {
                if (phMd.subType == HXPhotoModelMediaSubTypePhoto) {
                    [photoAssets addObject:phMd.asset];
                }else {
                    [videoAssets addObject:phMd.asset];
                }
                [allAsset addObject:phMd.asset];
            }
        }
        [self.delegate photoViewChangeComplete:self allAssetList:allAsset photoAssets:photoAssets videoAssets:videoAssets original:original];
    }
    if (self.changeCompleteBlock) {
        self.changeCompleteBlock(allList.copy, photos.copy, videos.copy, original);
    }
    [self layoutSubviews];
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal &&
        self.dataList.count) {
        NSInteger currentItem = self.tempShowAddCell ? self.dataList.count : self.dataList.count - 1;
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentItem inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
    }
}
- (NSArray *)dataSourceArrayOfCollectionView:(HXCollectionView *)collectionView {
    return self.dataList;
}
- (void)dragCellCollectionView:(HXCollectionView *)collectionView newDataArrayAfterMove:(NSArray *)newDataArray {
    self.dataList = [NSMutableArray arrayWithArray:newDataArray];
}
- (void)dragCellCollectionView:(HXCollectionView *)collectionView moveCellFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    HXPhotoModel *fromModel = self.dataList[fromIndexPath.item];
    HXPhotoModel *toModel = self.dataList[toIndexPath.item];
    
    [self.manager afterSelectedArraySwapPlacesWithFromModel:fromModel fromIndex:fromIndexPath.item toModel:toModel toIndex:toIndexPath.item];

    [self.photos removeAllObjects];
    [self.videos removeAllObjects];
    NSInteger i = 0;
    for (HXPhotoModel *model in self.manager.afterSelectedArray) {
        model.selectIndexStr = [NSString stringWithFormat:@"%ld",i + 1];
        if (model.subType == HXPhotoModelMediaSubTypePhoto) {
            [self.photos addObject:model];
        }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            [self.videos addObject:model];
        }
        i++;
    }
    [self.manager setAfterSelectedPhotoArray:self.photos];
    [self.manager setAfterSelectedVideoArray:self.videos];
}

- (void)dragCellCollectionViewCellEndMoving:(HXCollectionView *)collectionView {
    if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
        [self.delegate photoView:self changeComplete:self.dataList.copy photos:self.photos.copy videos:self.videos.copy original:self.original];
    }
    if ([self.delegate respondsToSelector:@selector(photoListViewControllerDidDone:allList:photos:videos:original:)]) {
        [self.delegate photoListViewControllerDidDone:self allList:self.manager.afterSelectedArray.copy photos:self.manager.afterSelectedPhotoArray.copy videos:self.manager.afterSelectedVideoArray.copy original:self.manager.afterOriginal];
    }
    if ([self.delegate respondsToSelector:@selector(photoViewChangeComplete:allAssetList:photoAssets:videoAssets:original:)]) {
        NSMutableArray *allAsset = [NSMutableArray array];
        NSMutableArray *photoAssets = [NSMutableArray array];
        NSMutableArray *videoAssets = [NSMutableArray array];
        for (HXPhotoModel *phMd in self.dataList) {
            if (phMd.asset) {
                if (phMd.subType == HXPhotoModelMediaSubTypePhoto) {
                    [photoAssets addObject:phMd.asset];
                }else {
                    [videoAssets addObject:phMd.asset];
                }
                [allAsset addObject:phMd.asset];
            }
        }
        [self.delegate photoViewChangeComplete:self allAssetList:allAsset photoAssets:photoAssets videoAssets:videoAssets original:self.original];
    }
    if (self.changeCompleteBlock) {
        self.changeCompleteBlock(self.dataList.copy, self.photos.copy, self.videos.copy, self.original);
    }
}
- (void)collectionViewNeedReloadData:(UICollectionView *)collectionView {
    if (self.cellCustomProtocol) {
        [self.collectionView reloadData];
    }
}
- (BOOL)collectionViewShouldDeleteCurrentMoveItem:(UICollectionView *)collectionView gestureRecognizer:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(photoViewShouldDeleteCurrentMoveItem:gestureRecognizer:indexPath:)]) {
        return [self.delegate photoViewShouldDeleteCurrentMoveItem:self gestureRecognizer:longPgr indexPath:indexPath];
    }
    if (self.shouldDeleteCurrentMoveItemBlock) {
        return self.shouldDeleteCurrentMoveItemBlock(longPgr, indexPath);
    }
    return NO;
}
- (void)collectionView:(UICollectionView *)collectionView gestureRecognizerBegan:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    if (indexPath) {
        if ([self.delegate respondsToSelector:@selector(photoView:gestureRecognizerBegan:indexPath:)]) {
            [self.delegate photoView:self gestureRecognizerBegan:longPgr indexPath:indexPath];
        }
        if (self.longGestureRecognizerBeganBlock) {
            self.longGestureRecognizerBeganBlock(longPgr, indexPath);
        }
    }
}
- (void)collectionView:(UICollectionView *)collectionView gestureRecognizerChange:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    if (indexPath) {
        HXPhotoSubViewCell *cell = (HXPhotoSubViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (cell.model.type == HXPhotoModelMediaTypeCamera) {
            return;
        }
        if ([self.delegate respondsToSelector:@selector(photoView:gestureRecognizerChange:indexPath:)]) {
            [self.delegate photoView:self gestureRecognizerChange:longPgr indexPath:indexPath];
        }
        if (self.longGestureRecognizerChangeBlock) {
            self.longGestureRecognizerChangeBlock(longPgr, indexPath);
        }
    }
}
- (void)collectionView:(UICollectionView *)collectionView gestureRecognizerEnded:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    if (indexPath) {
        if ([self.delegate respondsToSelector:@selector(photoView:gestureRecognizerEnded:indexPath:)]) {
            [self.delegate photoView:self gestureRecognizerEnded:longPgr indexPath:indexPath];
        }
        if (self.longGestureRecognizerEndedBlock) {
            self.longGestureRecognizerEndedBlock(longPgr, indexPath);
        }
    }
}
 
- (NSIndexPath *)currentModelIndexPath:(HXPhotoModel *)model {
    if ([self.dataList containsObject:model]) {
        return [NSIndexPath indexPathForItem:[self.dataList indexOfObject:model] inSection:0];
    }
    return [NSIndexPath indexPathForItem:0 inSection:0];
}
#pragma mark - < 更新高度 >
- (void)setupNewFrame {
    BOOL needUpdateFrame = NO;
    if (self.lastWidth) {
        if (self.lastWidth != self.hx_w) {
            needUpdateFrame = YES;
        }
    }
    UIEdgeInsets insets = self.collectionView.contentInset;
    CGFloat itemW = (NSInteger)((self.hx_w - self.spacing * (self.lineCount - 1) - insets.left - insets.right) / self.lineCount);
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal &&
        itemW > 20) {
        itemW -= 10;
    }
    if (itemW <= 0) {
        itemW = 100;
    }
#if HXPhotoViewCustomItemSizeEnable
    itemW = 100;
#else
    if (!HXPhotoViewCustomItemSize) {
        self.flowLayout.itemSize = CGSizeMake(itemW, itemW);
    }else {
        itemW = 100;
    }
#endif

    NSInteger dataCount = self.tempShowAddCell ? self.dataList.count + 1 : self.dataList.count;
    NSInteger numOfLinesNew = 0;
    if (self.lineCount != 0) numOfLinesNew = (dataCount / self.lineCount) + 1;
    if (dataCount % self.lineCount == 0) numOfLinesNew -= 1;
    self.flowLayout.minimumLineSpacing = self.spacing;
    self.flowLayout.minimumInteritemSpacing = self.spacing;
    
    if (numOfLinesNew != self.numOfLinesOld || needUpdateFrame) {
        self.numOfLinesOld = numOfLinesNew;
        CGFloat newHeight;
        if ([self.delegate respondsToSelector:@selector(photoViewHeight:)] ||
            [self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:isAddItem:photoView:)]) {
            if (![self.delegate respondsToSelector:@selector(photoViewHeight:)]) {
                NSAssert(NO, @"请实现此代理 - (CGFloat)photoViewHeight:(HXPhotoView *)photoView");
            }
            newHeight = [self.delegate photoViewHeight:self];
            if (newHeight <= 0) {
                newHeight = 0;
                self.numOfLinesOld = 0;
            }
            self.hx_h = newHeight;
        }else {
            newHeight = numOfLinesNew * itemW + self.spacing * (numOfLinesNew - 1);
            if (newHeight <= 0) {
                newHeight = 0;
                self.numOfLinesOld = 0;
            }
            if (newHeight > self.maximumHeight) {
                newHeight = self.maximumHeight;
                _collectionView.scrollEnabled = YES;
            }else {
                if (self.scrollDirection != UICollectionViewScrollDirectionHorizontal) {
                    _collectionView.scrollEnabled = NO;
                }
            }
            if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
                self.hx_h = itemW;
            }else {
                self.hx_h = newHeight;
            }
        }
        if ([self.delegate respondsToSelector:@selector(photoView:updateFrame:)]) {
            [self.delegate photoView:self updateFrame:self.frame]; 
        }
        BOOL hasConstraints = self.constraints.count;
        if (hasConstraints) {
            self.collectionView.frame = self.bounds;
        }
        if (self.updateFrameBlock) {
            self.updateFrameBlock(self.frame);
        }
    }
    self.lastWidth = self.hx_w;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.hx_w <= 0) {
        return;
    }
    if (self.lineCount <= 0) self.lineCount = 1;
    NSInteger dataCount = self.tempShowAddCell ? self.dataList.count + 1 : self.dataList.count;
    
    [self setupNewFrame];
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    BOOL hasConstraints = self.constraints.count;
    
    if (dataCount == 1) {
        if ([self.delegate respondsToSelector:@selector(photoViewHeight:)] ||
                   [self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:isAddItem:photoView:)]) {
            if (![self.delegate respondsToSelector:@selector(photoViewHeight:)]) {
                NSAssert(NO, @"请实现此代理 - (CGFloat)photoViewHeight:(HXPhotoView *)photoView");
            }
            if (self.constraints.count) {
                NSAssert(NO, @"自定义HXPhotoView高度时，请不要使用约束布局");
            }
            CGFloat height = [self.delegate photoViewHeight:self];
            if (height != self.hx_h) {
                self.hx_h = height;
            }
        }else {
            UIEdgeInsets insets = self.collectionView.contentInset;
            CGFloat itemW = (width - self.spacing * (self.lineCount - 1) - insets.left - insets.right) / self.lineCount;
            CGFloat roundH = roundf(height);
            CGFloat roundW = roundf(itemW);
            if (roundH != roundW && fabs(height - itemW) >= 2) {
                if (itemW != self.hx_h && !hasConstraints) {
                    self.hx_h = itemW;
                }
            }
        }
    }
    if (!hasConstraints) {
        self.collectionView.frame = self.bounds;
        if (self.collectionView.hx_h <= 0) {
            self.numOfLinesOld = 0;
            [self setupNewFrame];
            self.collectionView.frame = self.bounds;
        }
    }
}
- (void)dealloc {
    if (HXShowLog) NSSLog(@"dealloc");
}

@end
