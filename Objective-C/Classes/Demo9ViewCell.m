//
//  Demo9ViewCell.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2018/2/14.
//  Copyright © 2018年 Silence. All rights reserved.
//

#import "Demo9ViewCell.h"
#import "HXPhotoPicker.h"
#define HasMasonry (__has_include(<Masonry/Masonry.h>) || __has_include("Masonry.h"))

#if HasMasonry
#import <Masonry/Masonry.h>
#endif

@interface Demo9ViewCell ()<HXPhotoViewDelegate>
/**  照片管理  */
@property (nonatomic, strong) HXPhotoManager *manager;
@end

@implementation Demo9ViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.photoView];
#if HasMasonry
    [self.photoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.contentView).mas_offset(0);
        make.left.mas_equalTo(self.contentView).mas_offset(12);
        make.right.mas_equalTo(self.contentView).mas_offset(-12);
        make.height.mas_equalTo(0);
    }];
#endif
}
- (void)setModel:(Demo9Model *)model {
    _model = model;
    
    [self.manager changeAfterCameraArray:model.endCameraList];
    [self.manager changeAfterCameraPhotoArray:model.endCameraPhotos];
    [self.manager changeAfterCameraVideoArray:model.endCameraVideos];
    [self.manager changeAfterSelectedCameraArray:model.endSelectedCameraList];
    [self.manager changeAfterSelectedCameraPhotoArray:model.endSelectedCameraPhotos];  
    [self.manager changeAfterSelectedCameraVideoArray:model.endSelectedCameraVideos];
    [self.manager changeAfterSelectedArray:model.endSelectedList];
    [self.manager changeAfterSelectedPhotoArray:model.endSelectedPhotos];
    [self.manager changeAfterSelectedVideoArray:model.endSelectedVideos];
    [self.manager changeICloudUploadArray:model.iCloudUploadArray]; 
    
    // 这些操作需要放在manager赋值的后面，不然会出现重用..
    if (model.section == 0) {
        self.manager.configuration.albumShowMode = HXPhotoAlbumShowModePopup;
        self.photoView.previewStyle = HXPhotoViewPreViewShowStyleDark;
        self.photoView.collectionView.editEnabled = NO;
        self.photoView.hideDeleteButton = YES;
        self.photoView.showAddCell = NO;
        if (!model.addCustomAssetComplete && model.customAssetModels.count) {
            [self.manager addCustomAssetModel:model.customAssetModels];
            model.addCustomAssetComplete = YES;
        }
        HXWeakSelf
        self.manager.configuration.previewRespondsToLongPress = ^(UILongPressGestureRecognizer *longPress, HXPhotoModel *photoModel, HXPhotoManager *manager, HXPhotoPreviewViewController *previewViewController) {
            HXPhotoBottomViewModel *saveModel = [[HXPhotoBottomViewModel alloc] init];
            saveModel.title = @"保存";
            saveModel.customData = photoModel.tempImage;
            [HXPhotoBottomSelectView showSelectViewWithModels:@[saveModel] selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {

                if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                    if (photoModel.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWork ||
                        photoModel.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif) {
                        NSSLog(@"需要自行保存网络图片");
                        return;
                    }
                }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                    if (photoModel.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                        NSSLog(@"需要自行保存网络视频");
                        return;
                    }
                }
                [previewViewController.view hx_showLoadingHUDText:@"保存中"];
                if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                    [HXPhotoTools savePhotoToCustomAlbumWithName:weakSelf.manager.configuration.customAlbumName photo:model.customData location:nil complete:^(HXPhotoModel * _Nullable model, BOOL success) {
                        [previewViewController.view hx_handleLoading];
                        if (success) {
                            [previewViewController.view hx_showImageHUDText:@"保存成功"];
                        }else {
                            [previewViewController.view hx_showImageHUDText:@"保存失败"];
                        }
                    }];
                }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                    if (photoModel.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                        [[HXPhotoCommon photoCommon] downloadVideoWithURL:photoModel.videoURL progress:nil downloadSuccess:^(NSURL * _Nullable filePath, NSURL * _Nullable videoURL) {
                            [HXPhotoTools saveVideoToCustomAlbumWithName:nil videoURL:filePath location:nil complete:^(HXPhotoModel * _Nullable model, BOOL success) {
                                [previewViewController.view hx_handleLoading];
                                if (success) {
                                    [previewViewController.view hx_showImageHUDText:@"保存成功"];
                                }else {
                                    [previewViewController.view hx_showImageHUDText:@"保存失败"];
                                }
                            }];
                        } downloadFailure:^(NSError * _Nullable error, NSURL * _Nullable videoURL) {
                            [previewViewController.view hx_handleLoading];
                            [previewViewController.view hx_showImageHUDText:@"保存失败"];
                        }];
                        return;
                    }
                    [HXPhotoTools saveVideoToCustomAlbumWithName:nil videoURL:photoModel.videoURL location:nil complete:^(HXPhotoModel * _Nullable model, BOOL success) {
                        [previewViewController.view hx_handleLoading];
                        if (success) {
                            [previewViewController.view hx_showImageHUDText:@"保存成功"];
                        }else {
                            [previewViewController.view hx_showImageHUDText:@"保存失败"];
                        }
                    }];
                }
            } cancelClick:nil];
            
//            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//                PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
//                [request addResourceWithType:PHAssetResourceTypePhoto fileURL:imageURL options:nil];
//                [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:videoURL options:nil];
//            } completionHandler:^(BOOL success, NSError * _Nullable error) {
//                NSSLog(@"保存livePhoto - > %d, %@", success, error)
//            }];
        };
    }else {
        self.manager.configuration.previewRespondsToLongPress = nil;
        self.manager.configuration.albumShowMode = HXPhotoAlbumShowModeDefault;
        self.photoView.previewStyle = HXPhotoViewPreViewShowStyleDefault;
        self.photoView.collectionView.editEnabled = YES;
        self.photoView.hideDeleteButton = NO;
        self.photoView.showAddCell = YES;
    }
    
    [self.photoView refreshView];
}
- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    if (photoView == self.photoView) {
        self.model.endCameraList = self.manager.afterCameraArray.mutableCopy;
        self.model.endCameraPhotos = self.manager.afterCameraPhotoArray.mutableCopy;
        self.model.endCameraVideos = self.manager.afterCameraVideoArray.mutableCopy;
        self.model.endSelectedCameraList = self.manager.afterSelectedCameraArray.mutableCopy;
        self.model.endSelectedCameraPhotos = self.manager.afterSelectedCameraPhotoArray.mutableCopy;
        self.model.endSelectedCameraVideos = self.manager.afterSelectedCameraVideoArray.mutableCopy;
        self.model.endSelectedList = self.manager.afterSelectedArray.mutableCopy;
        self.model.endSelectedPhotos = self.manager.afterSelectedPhotoArray.mutableCopy;
        self.model.endSelectedVideos = self.manager.afterSelectedVideoArray.mutableCopy;
        self.model.iCloudUploadArray = self.manager.afterICloudUploadArray.mutableCopy;
    }
}
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    if (photoView != self.photoView) {
        return;
    }
    if (frame.size.height == self.model.photoViewHeight) {
        for (NSLayoutConstraint *heightConstraint in self.photoView.constraints) {
            if (heightConstraint.firstAttribute != NSLayoutAttributeHeight) {
                continue;
            }
            if (heightConstraint.constant != frame.size.height) {
                // 如果高度约束不对，在这里修正高度的约束
                heightConstraint.constant = frame.size.height;
                return;
            }
        }
        return;
    }
#if HasMasonry
    [self.photoView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(frame.size.height);
    }];
#endif
    self.model.photoViewHeight = frame.size.height;
    if (self.photoViewChangeHeightBlock) {
        self.photoViewChangeHeightBlock(self);
    }
}
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.selectTogether = YES;
    }
    return _manager;
}
- (HXPhotoView *)photoView {
    if (!_photoView) {
        _photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(12, 0, [UIScreen mainScreen].bounds.size.width - 24, 0) manager:self.manager]; 
        _photoView.delegate = self;
    }
    return _photoView;
}
@end
