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
#import "HXCameraViewController.h"
#import "UIView+HXExtension.h"

#define Spacing 3 // 每个item的间距
#define LineNum 3 // 每行个数
@interface HXPhotoView ()<HXCollectionViewDataSource,HXCollectionViewDelegate,HXPhotoViewControllerDelegate,HXPhotoSubViewCellDelegate,UIActionSheetDelegate,HXCameraViewControllerDelegate,UIAlertViewDelegate>
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

+ (instancetype)photoManager:(HXPhotoManager *)manager
{
    return [[self alloc] initWithManager:manager];
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

- (instancetype)initWithManager:(HXPhotoManager *)manager
{
    self = [super init];
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
    if (self.manager.outerCamera) {
        self.manager.openCamera = NO;
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"相机",@"相册", nil];
        
        [sheet showInView:self];
        return;
    }
    HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
    vc.manager = self.manager;
    vc.delegate = self;
    [[self viewController:self] presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [[self viewController:self].view showImageHUDText:@"此设备不支持相机!"];
            return;
        }
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在设置-隐私-相机中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
            [alert show];
            return;
        }
        HXCameraViewController *vc = [[HXCameraViewController alloc] init];
        vc.delegate = self;
        if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
            if (self.videos.count >= self.manager.videoMaxNum && self.photos.count < self.manager.photoMaxNum) {
                vc.type = HXCameraTypePhoto;
            }else if (self.photos.count >= self.manager.photoMaxNum && self.videos.count < self.manager.videoMaxNum) {
                vc.type = HXCameraTypeVideo;
            }else if (self.photos.count + self.videos.count >= self.manager.maxNum) {
                [[self viewController:self].view showImageHUDText:@"已达最大数!"];
                return;
            }else {
                vc.type = HXCameraTypePhotoAndVideo;
            }
        }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
            if (self.photos.count >= self.manager.photoMaxNum) {
                [[self viewController:self].view showImageHUDText:@"照片已达最大数"];
                return;
            }
            vc.type = HXCameraTypePhoto;
        }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
            if (self.videos.count >= self.manager.videoMaxNum) {
                [[self viewController:self].view showImageHUDText:@"视频已达最大数!"];
                return;
            }
            vc.type = HXCameraTypeVideo;
        }
       [[self viewController:self] presentViewController:vc animated:YES completion:nil];
    }else if (buttonIndex == 1){
        HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
        vc.manager = self.manager;
        vc.delegate = self;
        [[self viewController:self] presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

- (void)cameraDidNextClick:(HXPhotoModel *)model
{
    // 判断类型
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        [self.manager.endCameraPhotos addObject:model];
        // 当选择图片个数没有达到最大个数时就添加到选中数组中
        if (self.manager.endSelectedPhotos.count != self.manager.photoMaxNum) {
            if (!self.manager.selectTogether) {
                if (self.manager.endSelectedList.count > 0) {
                    HXPhotoModel *phMd = self.manager.endSelectedList.firstObject;
                    if ((phMd.type == HXPhotoModelMediaTypePhoto || phMd.type == HXPhotoModelMediaTypeLivePhoto) || (phMd.type == HXPhotoModelMediaTypePhotoGif || phMd.type == HXPhotoModelMediaTypeCameraPhoto)) {
                        [self.manager.endSelectedCameraPhotos insertObject:model atIndex:0];
                        [self.manager.endSelectedPhotos addObject:model];
                        [self.manager.endSelectedList addObject:model];
                        [self.manager.endSelectedCameraList addObject:model];
                        model.selected = YES;
                    }
                }else {
                    [self.manager.endSelectedCameraPhotos insertObject:model atIndex:0];
                    [self.manager.endSelectedPhotos addObject:model];
                    [self.manager.endSelectedList addObject:model];
                    [self.manager.endSelectedCameraList addObject:model];
                    model.selected = YES;
                }
            }else {
                [self.manager.endSelectedCameraPhotos insertObject:model atIndex:0];
                [self.manager.endSelectedPhotos addObject:model];
                [self.manager.endSelectedList addObject:model];
                [self.manager.endSelectedCameraList addObject:model];
                model.selected = YES;
            }
        }
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.manager.endCameraVideos addObject:model];
        // 当选中视频个数没有达到最大个数时就添加到选中数组中
        if (self.manager.endSelectedVideos.count != self.manager.videoMaxNum) {
            if (!self.manager.selectTogether) {
                if (self.manager.endSelectedList.count > 0) {
                    HXPhotoModel *phMd = self.manager.endSelectedList.firstObject;
                    if (phMd.type == HXPhotoModelMediaTypeVideo || phMd.type == HXPhotoModelMediaTypeCameraVideo) {
                        [self.manager.endSelectedCameraVideos insertObject:model atIndex:0];
                        [self.manager.endSelectedVideos addObject:model];
                        [self.manager.endSelectedList addObject:model];
                        [self.manager.endSelectedCameraList addObject:model];
                        model.selected = YES;
                    }
                }else {
                    
                    [self.manager.endSelectedCameraVideos insertObject:model atIndex:0];
                    [self.manager.endSelectedVideos addObject:model];
                    [self.manager.endSelectedList addObject:model];
                    [self.manager.endSelectedCameraList addObject:model];
                    model.selected = YES;
                }
            }else {
                [self.manager.endSelectedCameraVideos insertObject:model atIndex:0];
                [self.manager.endSelectedVideos addObject:model];
                [self.manager.endSelectedList addObject:model];
                [self.manager.endSelectedCameraList addObject:model];
                model.selected = YES;
            }
        }
    }
    [self.manager.endCameraList addObject:model];
    NSInteger cameraIndex = self.manager.openCamera ? 1 : 0;
    
    int index = 0;
    for (NSInteger i = self.manager.endCameraPhotos.count - 1; i >= 0; i--) {
        HXPhotoModel *photoMD = self.manager.endCameraPhotos[i];
        photoMD.photoIndex = index;
        photoMD.albumListIndex = index + cameraIndex;
        index++;
    }
    index = 0;
    for (NSInteger i = self.manager.endCameraVideos.count - 1; i >= 0; i--) {
        HXPhotoModel *photoMD = self.manager.endCameraVideos[i];
        photoMD.videoIndex = index;
        index++;
    }
    index = 0;
    for (NSInteger i = self.manager.endCameraList.count - 1; i>= 0; i--) {
        HXPhotoModel *photoMD = self.manager.endCameraList[i];
        photoMD.albumListIndex = index + cameraIndex;
        index++;
    }
    [self photoViewControllerDidNext:self.manager.endSelectedList.mutableCopy Photos:self.manager.endSelectedPhotos.mutableCopy Videos:self.manager.endSelectedVideos.mutableCopy Original:self.manager.endIsOriginal];
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
