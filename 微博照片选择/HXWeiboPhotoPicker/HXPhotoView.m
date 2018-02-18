//
//  HXPhotoView.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoView.h"
#import "HXPhotoSubViewCell.h"
#import "UIView+HXExtension.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+HXExtension.h"
#import "HXAlbumListViewController.h"
#import "HXDatePhotoPreviewViewController.h"
#import "HXCustomNavigationController.h"
#import "HXCustomCameraViewController.h"

#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)

#define Spacing 3 // 每个item的间距  !! 这个宏已经没用了, 请用HXPhotoView 的 spacing 这个属性来控制

#define LineNum 3 // 每行个数  !! 这个宏已经没用了, 请用HXPhotoView 的 lineCount 这个属性来控制

static NSString *HXPhotoSubViewCellId = @"photoSubViewCellId";
@interface HXPhotoView ()<HXCollectionViewDataSource,HXCollectionViewDelegate,HXPhotoSubViewCellDelegate,UIActionSheetDelegate,UIAlertViewDelegate,HXAlbumListViewControllerDelegate,HXCustomCameraViewControllerDelegate,HXDatePhotoPreviewViewControllerDelegate>
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
@property (assign, nonatomic) BOOL isDeleteAddModel;
@end

@implementation HXPhotoView
- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
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
//        if (self.manager.UIManager.photoViewAddImageName) {
//            _addModel.thumbPhoto = [HXPhotoTools hx_imageNamed:self.manager.UIManager.photoViewAddImageName];
//        }else {
            _addModel.thumbPhoto = [HXPhotoTools hx_imageNamed:@"compose_pic_add@2x.png"];
//        }
    }
    return _addModel;
}

+ (instancetype)photoManager:(HXPhotoManager *)manager {
    return [[self alloc] initWithManager:manager];
}
- (instancetype)initWithFrame:(CGRect)frame manager:(HXPhotoManager *)manager {
    self = [super initWithFrame:frame];
    if (self) {
        self.spacing = 3;
        self.lineCount = 3;
        self.numOfLinesOld = 0;
        self.manager = manager;
        [self setup];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame WithManager:(HXPhotoManager *)manager {
    self = [super initWithFrame:frame];
    if (self) {
        self.spacing = 3;
        self.lineCount = 3;
        self.numOfLinesOld = 0;
        self.manager = manager;
        [self setup];
    }
    return self;
}

- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.spacing = 3;
        self.lineCount = 3;
        self.numOfLinesOld = 0;
        self.manager = manager;
        [self setup];
    }
    return self;
}

/**  不要使用 "initWithFrame" 这个方法初始化  */
//- (instancetype)initWithFrame:(CGRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//        [self setup];
//    }
//    return self;
//}

- (void)deleteAddBtn {
    [self.dataList removeObject:self.addModel];
    self.isDeleteAddModel = YES;
}

- (void)setup {
    self.tag = 9999;
    [self.dataList addObject:self.addModel];
    
    self.flowLayout.minimumLineSpacing = self.spacing;
    self.flowLayout.minimumInteritemSpacing = self.spacing;
    self.collectionView = [[HXCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
    self.collectionView.tag = 8888;
    self.collectionView.scrollEnabled = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = self.backgroundColor;
    [self.collectionView registerClass:[HXPhotoSubViewCell class] forCellWithReuseIdentifier:HXPhotoSubViewCellId];
    [self addSubview:self.collectionView]; 
    if (self.manager.afterSelectedArray.count > 0) {
        [self photoViewControllerDidNext:self.manager.afterSelectedArray.mutableCopy Photos:self.manager.afterSelectedPhotoArray.mutableCopy Videos:self.manager.afterSelectedVideoArray.mutableCopy Original:self.manager.afterOriginal];
    }
}

- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
    if (self.manager.afterSelectedArray.count > 0) {
        [self photoViewControllerDidNext:self.manager.afterSelectedArray.mutableCopy Photos:self.manager.afterSelectedPhotoArray.mutableCopy Videos:self.manager.afterSelectedVideoArray.mutableCopy Original:self.manager.afterOriginal];
    }
}

/**
 刷新视图
 */
- (void)refreshView {
    [self photoViewControllerDidNext:self.manager.afterSelectedArray.mutableCopy Photos:self.manager.afterSelectedPhotoArray.mutableCopy Videos:self.manager.afterSelectedVideoArray.mutableCopy Original:self.manager.afterOriginal];
}
- (NSString *)videoOutFutFileName {
    NSString *fileName = @"";
    NSDate *nowDate = [NSDate date];
    NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
    NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
    fileName = [fileName stringByAppendingString:dateStr];
    fileName = [fileName stringByAppendingString:numStr];
    return fileName;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoSubViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:HXPhotoSubViewCellId forIndexPath:indexPath];
    cell.delegate = self;
    cell.model = self.dataList[indexPath.item];
    cell.showDeleteNetworkPhotoAlert = self.manager.configuration.showDeleteNetworkPhotoAlert;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
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
        [self goPhotoViewController];
    }else {
        HXDatePhotoPreviewViewController *vc = [[HXDatePhotoPreviewViewController alloc] init];
        vc.outside = YES;
        vc.manager = self.manager;
        vc.delegate = self;
        vc.modelArray = [NSMutableArray arrayWithArray:self.manager.afterSelectedArray];
        vc.currentModelIndex = [self.manager.afterSelectedArray indexOfObject:model];
        vc.photoView = self;
        
//            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
//            nav.transitioningDelegate = vc;
//            nav.modalPresentationStyle = UIModalPresentationCustom;
        [[self viewController] presentViewController:vc animated:YES completion:nil];
    }
}

#pragma mark - < HXDatePhotoPreviewViewControllerDelegate >
- (void)datePhotoPreviewSelectLaterDidEditClick:(HXDatePhotoPreviewViewController *)previewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel {
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
//        self.manager.openCamera = NO;
            if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
                self.manager.configuration.maxNum = self.manager.configuration.photoMaxNum;
            }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
                self.manager.configuration.maxNum = self.manager.configuration.videoMaxNum;
            }else {
                // 防错
                if (self.manager.configuration.videoMaxNum + self.manager.configuration.photoMaxNum != self.manager.configuration.maxNum) {
                    self.manager.configuration.maxNum = self.manager.configuration.videoMaxNum + self.manager.configuration.photoMaxNum;
                }
            }
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"相机"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self goCameraViewController];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"相册"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self directGoPhotoViewController];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIAlertActionStyleCancel handler:nil]];
        [self.viewController presentViewController:alertController animated:YES completion:nil];
//        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:[NSBundle hx_localizedStringForKey:@"取消"] destructiveButtonTitle:nil otherButtonTitles:[NSBundle hx_localizedStringForKey:@"相机"],[NSBundle hx_localizedStringForKey:@"相册"], nil];
//
//        [sheet showInView:self];
        return;
    }
    [self directGoPhotoViewController];
}

- (void)directGoPhotoViewController {
    HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] init];
    vc.manager = self.manager;
    vc.delegate = self;
    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
    nav.supportRotation = self.manager.configuration.supportRotation;
    [[self viewController] presentViewController:nav animated:YES completion:nil];
}

/**
 前往相机
 */
- (void)goCameraViewController {
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [[self viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法使用相机!"]];
        return;
    }
    __weak typeof(self) weakSelf = self;
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
                                cameraType = HXPhotoConfigurationCameraTypeTypePhotoAndVideo;
                            }
                        }else {
                            cameraType = HXPhotoConfigurationCameraTypeTypePhotoAndVideo;
                        }
                    }
                    weakSelf.manager.configuration.shouldUseCamera([weakSelf viewController], cameraType, weakSelf.manager);
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
                [[weakSelf viewController] presentViewController:nav animated:YES completion:nil];
            }else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSBundle hx_localizedStringForKey:@"无法使用相机"] message:[NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问相机"] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIAlertActionStyleDefault handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"设置"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }]];
                [[weakSelf viewController] presentViewController:alert animated:YES completion:nil];
            }
        });
    }];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self goCameraViewController];
    }else if (buttonIndex == 1){
        [self directGoPhotoViewController];
    }
}

/**
 前往设置开启权限
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
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
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        // 当选择图片个数没有达到最大个数时就添加到选中数组中
        if ([self.manager afterSelectPhotoCountIsMaximum]) {
            [[self viewController].view showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld张图片"],self.manager.configuration.photoMaxNum]];
            return;
        }
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        // 当选中视频个数没有达到最大个数时就添加到选中数组中 
        if (model.videoDuration < 3) {
            [[self viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"视频少于3秒,无法选择"]];
            return;
        }else if (model.videoDuration > self.manager.configuration.videoMaxDuration) {
            [[self viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"视频过大,无法选择"]];
            return;
        }else if ([self.manager afterSelectVideoCountIsMaximum]) {
            [[self viewController].view showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个视频"],self.manager.configuration.videoMaxNum]];
            return;
        }
    }
    [self.manager afterListAddCameraTakePicturesModel:model];
    [self photoViewControllerDidNext:self.manager.afterSelectedArray.mutableCopy Photos:self.manager.afterSelectedPhotoArray.mutableCopy Videos:self.manager.afterSelectedVideoArray.mutableCopy Original:self.manager.afterOriginal];
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
        NSSLog(@"删除失败 - cell为空");
    }
}
/**
 cell删除按钮的代理

 @param cell 被删的cell
 */
- (void)cellDidDeleteClcik:(UICollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    HXPhotoModel *model = self.dataList[indexPath.item];
    [self.manager afterSelectedListdeletePhotoModel:model];
    if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        [self.photos removeObject:model];
    }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.videos removeObject:model];
    }
    model.thumbPhoto = nil;
    model.previewPhoto = nil; 
    model = nil;
    
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
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    [self changeSelectedListModelIndex];
    if (self.isAddModel) {
        if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
            [self.delegate photoView:self changeComplete:self.dataList photos:self.photos videos:self.videos original:self.original];
        }
        self.isAddModel = NO;
        [self.dataList addObject:self.addModel];
        [self.collectionView reloadData];
    }else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.dataList.mutableCopy];
        [array removeLastObject];
        if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
            [self.delegate photoView:self changeComplete:array photos:self.photos.mutableCopy videos:self.videos.mutableCopy original:self.original];
        }
    }
    [self setupNewFrame];
}

- (void)changeSelectedListModelIndex {
    NSMutableArray *array;
    if (self.isAddModel) {
        array = self.dataList;
    }else {
        array = self.dataList.mutableCopy;
        [array removeLastObject];
    }
    int i = 0;
    for (HXPhotoModel *model in array) {
        model.selectIndexStr = [NSString stringWithFormat:@"%d",i + 1];
        i++;
    }
}
#pragma mark - < HXAlbumListViewControllerDelegate >
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    [self photoViewControllerDidNext:allList Photos:photoList Videos:videoList Original:original];
}
- (void)photoViewControllerDidNext:(NSArray<HXPhotoModel *> *)allList Photos:(NSArray<HXPhotoModel *> *)photos Videos:(NSArray<HXPhotoModel *> *)videos Original:(BOOL)original {
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
    [self.dataList addObject:self.addModel];
    if (self.manager.configuration.selectTogether) {
        if (self.manager.configuration.maxNum == allList.count) {
            [self.dataList removeLastObject];
            self.isAddModel = YES;
        }
    }else {
        if (photos.count > 0) {
            if (photos.count == self.manager.configuration.photoMaxNum) {
                if (self.manager.configuration.photoMaxNum > 0) {
                    [self.dataList removeLastObject];
                    self.isAddModel = YES;
                }
            }
        }else if (videos.count > 0) {
            if (videos.count == self.manager.configuration.videoMaxNum) {
                if (self.manager.configuration.videoMaxNum > 0) {
                    [self.dataList removeLastObject];
                    self.isAddModel = YES;
                }
            }
        }
    }
    [self changeSelectedListModelIndex];
    [self.collectionView reloadData];
    
    if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
        [self.delegate photoView:self changeComplete:allList.copy photos:photos.copy videos:videos.copy original:original];
    }
    [self setupNewFrame];
}

- (void)photoViewControllerDidCancel {
    
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
    
//    [self.manager.endSelectedList removeObject:toModel];
//    [self.manager.endSelectedList insertObject:toModel atIndex:toIndexPath.item];
//    [self.manager.endSelectedList removeObject:fromModel];
//    [self.manager.endSelectedList insertObject:fromModel atIndex:fromIndexPath.item];
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
//    int i = 0, j = 0, k = 0;
//    for (HXPhotoModel *model in self.manager.endSelectedList) {
//        model.selectIndexStr = [NSString stringWithFormat:@"%d",k + 1];
//        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
//            model.endIndex = i++;
//            [self.photos addObject:model];
//        }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
//            model.endIndex = j++;
//            [self.videos addObject:model];
//        }
//        model.endCollectionIndex = k++;
//    }
//    self.manager.endSelectedPhotos = [NSMutableArray arrayWithArray:self.photos];
//    self.manager.endSelectedVideos = [NSMutableArray arrayWithArray:self.videos];
}

- (void)dragCellCollectionViewCellEndMoving:(HXCollectionView *)collectionView {
    if (self.isAddModel) {
        if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
            [self.delegate photoView:self changeComplete:self.dataList.mutableCopy photos:self.photos.mutableCopy videos:self.videos.mutableCopy original:self.original];
        }
    }else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.dataList.mutableCopy];
        [array removeLastObject];
        if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
            [self.delegate photoView:self changeComplete:array photos:self.photos.mutableCopy videos:self.videos.mutableCopy original:self.original];
        }
    }
}
 
- (NSIndexPath *)currentModelIndexPath:(HXPhotoModel *)model {
    if ([self.dataList containsObject:model]) {
        return [NSIndexPath indexPathForItem:[self.dataList indexOfObject:model] inSection:0];
    }
    return [NSIndexPath indexPathForItem:0 inSection:0];
}
/**
 更新高度
 */
- (void)setupNewFrame {
    double x = self.frame.origin.x;
    double y = self.frame.origin.y;
    CGFloat width = self.frame.size.width;
    
    CGFloat itemW = (width - self.spacing * (self.lineCount - 1)) / self.lineCount;
    if (itemW > 0) {
        self.flowLayout.itemSize = CGSizeMake(itemW, itemW);
    }
    
    NSInteger dataCount = self.dataList.count;
    NSInteger numOfLinesNew = 0;
    if (self.lineCount != 0) {
        numOfLinesNew = (dataCount / self.lineCount) + 1;
    }
    
    if (dataCount % self.lineCount == 0) {
        numOfLinesNew -= 1;
    }
    self.flowLayout.minimumLineSpacing = self.spacing;
    
    if (numOfLinesNew != self.numOfLinesOld) {
        CGFloat newHeight = numOfLinesNew * itemW + self.spacing * (numOfLinesNew - 1);
        if (newHeight < 0) {
            newHeight = 0;
        }
        self.frame = CGRectMake(x, y, width, newHeight);
        self.numOfLinesOld = numOfLinesNew;
        if (newHeight <= 0) {
            self.numOfLinesOld = 0;
        }
        if ([self.delegate respondsToSelector:@selector(photoView:updateFrame:)]) {
            [self.delegate photoView:self updateFrame:self.frame]; 
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSInteger dataCount = self.dataList.count;
    NSInteger numOfLinesNew = (dataCount / self.lineCount) + 1;
    
    [self setupNewFrame];
    CGFloat x = self.frame.origin.x;
    CGFloat y = self.frame.origin.y;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    if (dataCount == 1) {
        CGFloat itemW = (width - self.spacing * (self.lineCount - 1)) / self.lineCount;
        if ((int)height != (int)itemW) {
            self.frame = CGRectMake(x, y, width, itemW);
        }
    }
    if (dataCount % self.lineCount == 0) {
        numOfLinesNew -= 1;
    }
    CGFloat cWidth = self.frame.size.width;
    CGFloat cHeight = self.frame.size.height;
    self.collectionView.frame = CGRectMake(0, 0, cWidth, cHeight);
    if (cHeight <= 0) {
        self.numOfLinesOld = 0;
        [self setupNewFrame];
        CGFloat cWidth = self.frame.size.width;
        CGFloat cHeight = self.frame.size.height;
        self.collectionView.frame = CGRectMake(0, 0, cWidth, cHeight);
    }
}
- (void)dealloc {
    NSSLog(@"dealloc");
}

@end
