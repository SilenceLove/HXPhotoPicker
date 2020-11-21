//
//  SettingViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2019/2/2.
//  Copyright © 2019年 洪欣. All rights reserved.
//

#import "SettingViewController.h"
#import "HXPhotoManager.h"

@interface SettingViewController ()<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *photoMaxNum;
@property (weak, nonatomic) IBOutlet UITextField *videoMaxNum;
@property (weak, nonatomic) IBOutlet UITextField *totalMaxNum;
@property (weak, nonatomic) IBOutlet UITextField *photoListCount;
@property (weak, nonatomic) IBOutlet UITextField *clarityScale;
@property (weak, nonatomic) IBOutlet UISwitch *downloadICloudAsset;
@property (weak, nonatomic) IBOutlet UISwitch *filtrationICloudAsset;
@property (weak, nonatomic) IBOutlet UISwitch *open3DTouchPreview;
@property (weak, nonatomic) IBOutlet UISwitch *singleJumpEdit;
@property (weak, nonatomic) IBOutlet UISwitch *singleSelected;
@property (weak, nonatomic) IBOutlet UITextField *videoMinimumSelectDuration;
@property (weak, nonatomic) IBOutlet UITextField *videoMaximumSelectDuration;
@property (weak, nonatomic) IBOutlet UITextField *customAlbumName;
@property (weak, nonatomic) IBOutlet UISwitch *saveSystemAblum;
@property (weak, nonatomic) IBOutlet UISwitch *deleteTemporaryPhoto;
@property (weak, nonatomic) IBOutlet UITextField *videoMaximumDuration;
@property (weak, nonatomic) IBOutlet UISwitch *selectTogether;
@property (weak, nonatomic) IBOutlet UISwitch *lookLivePhoto;
@property (weak, nonatomic) IBOutlet UISwitch *lookGifPhoto;
@property (weak, nonatomic) IBOutlet UISwitch *openCamera;
@property (weak, nonatomic) IBOutlet UITextField *horizontalRowCount;
@property (weak, nonatomic) IBOutlet UISwitch *reverseDate;
@property (weak, nonatomic) IBOutlet UISwitch *showDateSectionHeader;
@property (weak, nonatomic) IBOutlet UISwitch *cameraCellShowPreview;
@property (weak, nonatomic) IBOutlet UISwitch *sectionHeaderShowPhotoClocation;
@property (weak, nonatomic) IBOutlet UISwitch *hideOriginalBtn;
@property (weak, nonatomic) IBOutlet UIView *themeColor;
@property (weak, nonatomic) IBOutlet UISwitch *navigationTitleSynchColor;
@property (weak, nonatomic) IBOutlet UISwitch *sectionHeaderTransluc;
@property (weak, nonatomic) IBOutlet UISwitch *supportRotation;
@property (weak, nonatomic) IBOutlet UISwitch *doneBtnShowDetail;
@property (weak, nonatomic) IBOutlet UISwitch *showBottomPhotoDetail;
@property (weak, nonatomic) IBOutlet UISwitch *replaceCameraViewController;
@property (weak, nonatomic) IBOutlet UISwitch *movableCrop;
@property (weak, nonatomic) IBOutlet UISwitch *movableCropBoxEditSize;
@property (weak, nonatomic) IBOutlet UITextField *movableCropBoxCustomRatioX;
@property (weak, nonatomic) IBOutlet UITextField *movableCropBoxCustomRationY;
@property (weak, nonatomic) IBOutlet UISwitch *photoCanEdit;
@property (weak, nonatomic) IBOutlet UISwitch *videoCanEdit;
@property (weak, nonatomic) IBOutlet UISegmentedControl *albumShowMode;
@property (weak, nonatomic) IBOutlet UISwitch *creationDateSort;
@property (weak, nonatomic) IBOutlet UITextField *maxVideoClippingTime;
@property (weak, nonatomic) IBOutlet UITextField *minVideoClippingTime;
@property (weak, nonatomic) IBOutlet UISegmentedControl *languageType;
@property (weak, nonatomic) IBOutlet UISegmentedControl *photoStyleSegmented;
@property (weak, nonatomic) IBOutlet UISegmentedControl *customCameraTypeSegmented;
@property (weak, nonatomic) IBOutlet UISegmentedControl *selectTypeSegmented;

@end

@implementation SettingViewController

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        [self preferredStatusBarUpdateAnimation];
        [self changeStatus];
    }
#endif
}
- (UIStatusBarStyle)preferredStatusBarStyle {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return UIStatusBarStyleLightContent;
        }
    }
#endif
    return UIStatusBarStyleDefault;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self changeStatus];
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
- (void)changeStatus {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            return;
        }
    }
#endif
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}
#pragma clang diagnostic pop
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(didSaveClick)];
    
    self.photoMaxNum.text = @(self.manager.configuration.photoMaxNum).stringValue;
    self.videoMaxNum.text = @(self.manager.configuration.videoMaxNum).stringValue;
    self.totalMaxNum.text = @(self.manager.configuration.maxNum).stringValue;
    self.photoListCount.text = @(self.manager.configuration.rowCount).stringValue;
    self.clarityScale.text = @(self.manager.configuration.clarityScale).stringValue;
//    self.downloadICloudAsset.on = self.manager.configuration.downloadICloudAsset;
//    self.filtrationICloudAsset.on = self.manager.configuration.filtrationICloudAsset;
    self.open3DTouchPreview.on = self.manager.configuration.open3DTouchPreview;
    self.singleJumpEdit.on = self.manager.configuration.singleJumpEdit;
    self.singleSelected.on = self.manager.configuration.singleSelected;
    self.videoMinimumSelectDuration.text = @(self.manager.configuration.videoMinimumSelectDuration).stringValue;
    self.videoMaximumSelectDuration.text = @(self.manager.configuration.videoMaximumSelectDuration).stringValue;
    self.customAlbumName.text = self.manager.configuration.customAlbumName;
    self.saveSystemAblum.on = self.manager.configuration.saveSystemAblum;
    self.deleteTemporaryPhoto.on = self.manager.configuration.deleteTemporaryPhoto;
    self.videoMaximumDuration.text = @(self.manager.configuration.videoMaximumDuration).stringValue;
    self.selectTogether.on = self.manager.configuration.selectTogether;
    self.lookLivePhoto.on = self.manager.configuration.lookLivePhoto;
    self.lookGifPhoto.on = self.manager.configuration.lookGifPhoto;
    self.openCamera.on = self.manager.configuration.openCamera;
    self.horizontalRowCount.text = @(self.manager.configuration.horizontalRowCount).stringValue;
    self.reverseDate.on = self.manager.configuration.reverseDate;
    self.showDateSectionHeader.on = self.manager.configuration.showDateSectionHeader;
    self.cameraCellShowPreview.on = self.manager.configuration.cameraCellShowPreview;
//    self.sectionHeaderShowPhotoClocation.on = self.manager.configuration.sectionHeaderShowPhotoLocation;
    self.hideOriginalBtn.on = self.manager.configuration.hideOriginalBtn;
    self.themeColor.backgroundColor = self.manager.configuration.themeColor;
    self.navigationTitleSynchColor.on = self.manager.configuration.navigationTitleSynchColor;
//    self.sectionHeaderTransluc.on = self.manager.configuration.sectionHeaderTranslucent;
    self.supportRotation.on = self.manager.configuration.supportRotation;
    self.doneBtnShowDetail.on = self.manager.configuration.doneBtnShowDetail;
    self.showBottomPhotoDetail.on = self.manager.configuration.showBottomPhotoDetail;
    self.replaceCameraViewController.on = self.manager.configuration.replaceCameraViewController;
    self.movableCrop.on = self.manager.configuration.movableCropBox;
    self.movableCropBoxEditSize.on = self.manager.configuration.movableCropBoxEditSize;
    self.movableCropBoxCustomRatioX.text = @(self.manager.configuration.movableCropBoxCustomRatio.x).stringValue;
    self.movableCropBoxCustomRationY.text = @(self.manager.configuration.movableCropBoxCustomRatio.y).stringValue;
    self.photoCanEdit.on = self.manager.configuration.photoCanEdit;
    self.videoCanEdit.on = self.manager.configuration.videoCanEdit;
    self.albumShowMode.selectedSegmentIndex = self.manager.configuration.albumShowMode;
    self.creationDateSort.on = self.manager.configuration.creationDateSort;
    self.maxVideoClippingTime.text = @(self.manager.configuration.maxVideoClippingTime).stringValue;
    self.minVideoClippingTime.text = @(self.manager.configuration.minVideoClippingTime).stringValue;
    self.languageType.selectedSegmentIndex = self.manager.configuration.languageType;
    self.photoStyleSegmented.selectedSegmentIndex = self.manager.configuration.photoStyle;
    self.customCameraTypeSegmented.selectedSegmentIndex = self.manager.configuration.customCameraType;
    self.selectTypeSegmented.selectedSegmentIndex = self.manager.type;
}
- (void)didSaveClick {
    self.manager.configuration.photoMaxNum = self.photoMaxNum.text.integerValue;
    self.manager.configuration.videoMaxNum = self.videoMaxNum.text.integerValue;
    self.manager.configuration.maxNum = self.totalMaxNum.text.integerValue;
    self.manager.configuration.rowCount = self.photoListCount.text.integerValue;
    self.manager.configuration.clarityScale = self.clarityScale.text.floatValue;
//    self.manager.configuration.downloadICloudAsset = self.downloadICloudAsset.on;
//    self.manager.configuration.filtrationICloudAsset = self.filtrationICloudAsset.on;
    self.manager.configuration.open3DTouchPreview = self.open3DTouchPreview.on;
    self.manager.configuration.singleJumpEdit = self.singleJumpEdit.on;
    self.manager.configuration.singleSelected = self.singleSelected.on;
    self.manager.configuration.videoMinimumSelectDuration = self.videoMinimumSelectDuration.text.integerValue;
    self.manager.configuration.videoMaximumSelectDuration = self.videoMaximumSelectDuration.text.integerValue; 
    self.manager.configuration.customAlbumName = self.customAlbumName.text;
    self.manager.configuration.saveSystemAblum = self.saveSystemAblum.on;
    self.manager.configuration.deleteTemporaryPhoto = self.deleteTemporaryPhoto.on;
    self.manager.configuration.videoMaximumDuration = self.videoMaximumDuration.text.floatValue;
    self.manager.configuration.selectTogether = self.selectTogether.on;
    self.manager.configuration.lookLivePhoto = self.lookLivePhoto.on;
    self.manager.configuration.lookGifPhoto = self.lookGifPhoto.on;
    self.manager.configuration.openCamera = self.openCamera.on;
    self.manager.configuration.horizontalRowCount = self.horizontalRowCount.text.integerValue;
    self.manager.configuration.reverseDate = self.reverseDate.on;
    self.manager.configuration.showDateSectionHeader = self.showDateSectionHeader.on;
    self.manager.configuration.cameraCellShowPreview = self.cameraCellShowPreview.on;
//    self.manager.configuration.sectionHeaderShowPhotoLocation = self.sectionHeaderShowPhotoClocation.on;
    self.manager.configuration.hideOriginalBtn = self.hideOriginalBtn.on;
    self.manager.configuration.themeColor = self.themeColor.backgroundColor;
//    self.manager.configuration.sectionHeaderTranslucent = self.sectionHeaderTransluc.on;
    self.manager.configuration.navigationTitleSynchColor = self.navigationTitleSynchColor.on;
    self.manager.configuration.supportRotation = self.supportRotation.on;
    self.manager.configuration.doneBtnShowDetail = self.doneBtnShowDetail.on;
    self.manager.configuration.showBottomPhotoDetail = self.showBottomPhotoDetail.on;
    self.manager.configuration.replaceCameraViewController = self.replaceCameraViewController.on;
    self.manager.configuration.movableCropBox = self.movableCrop.on;
    self.manager.configuration.movableCropBoxEditSize = self.movableCropBoxEditSize.on;
    self.manager.configuration.movableCropBoxCustomRatio = CGPointMake(self.movableCropBoxCustomRatioX.text.integerValue, self.movableCropBoxCustomRationY.text.integerValue);
    self.manager.configuration.photoCanEdit = self.photoCanEdit.on;
    self.manager.configuration.videoCanEdit = self.videoCanEdit.on;
    self.manager.configuration.albumShowMode = self.albumShowMode.selectedSegmentIndex;
    self.manager.configuration.creationDateSort = self.creationDateSort.on;
    self.manager.configuration.minVideoClippingTime = self.minVideoClippingTime.text.integerValue;
    self.manager.configuration.maxVideoClippingTime = self.maxVideoClippingTime.text.integerValue;
    self.manager.configuration.languageType = self.languageType.selectedSegmentIndex;
    self.manager.configuration.photoStyle = self.photoStyleSegmented.selectedSegmentIndex;
    if (self.selectTypeSegmented.selectedSegmentIndex != self.manager.type) {
        [self.manager clearSelectedList];
    }

    self.manager.type = self.selectTypeSegmented.selectedSegmentIndex;
    self.manager.configuration.customCameraType = self.customCameraTypeSegmented.selectedSegmentIndex;
    
    
    if (self.saveCompletion) {
        self.saveCompletion(self.manager);
    }
    [self.navigationController popViewControllerAnimated:YES];
} 
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}
@end
