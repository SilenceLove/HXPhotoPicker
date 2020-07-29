//
//  HXPhotoConfiguration.m
//  照片选择器
//
//  Created by 洪欣 on 2017/11/21.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoConfiguration.h"
#import "HXPhotoTools.h"
#import "UIColor+HXExtension.h"

@implementation HXPhotoConfiguration

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup { 
    self.changeAlbumListContentView = YES;
    self.open3DTouchPreview = YES;
    self.openCamera = YES;
    self.lookLivePhoto = NO;
    self.lookGifPhoto = YES;
    self.selectTogether = NO;
    self.showOriginalBytesLoading = NO;
    self.exportVideoURLForHighestQuality = NO;
    self.maxNum = 10;
    self.photoMaxNum = 9;
    self.videoMaxNum = 1;
    self.showBottomPhotoDetail = YES;
//    self.reverseDate = YES;
    if ([UIScreen mainScreen].bounds.size.width == 320) {
        self.rowCount = 3;
        self.sectionHeaderShowPhotoLocation = NO;
    }else {
        if ([HXPhotoTools isIphone6]) {
            self.rowCount = 3;
            self.sectionHeaderShowPhotoLocation = NO;
        }else {
            self.sectionHeaderShowPhotoLocation = YES;
            self.rowCount = 4;
        }
    }
    self.downloadICloudAsset = YES;
    self.videoMaximumSelectDuration = 3 * 60.f;
    self.videoMinimumSelectDuration = 0.f;
    self.videoMaximumDuration = 60.f;
    
//    self.creationDateSort = YES;
    
    //    self.saveSystemAblum = NO;
//    self.deleteTemporaryPhoto = YES;
//    self.showDateSectionHeader = YES; 
    if ([UIScreen mainScreen].bounds.size.width != 320 && [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.cameraCellShowPreview = YES;
    }
    //    self.horizontalHideStatusBar = NO;
    self.customAlbumName = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
    self.horizontalRowCount = 6;
    self.sectionHeaderTranslucent = YES;
    self.supportRotation = YES;
    
    self.pushTransitionDuration = 0.45f;
    self.popTransitionDuration = 0.35f;
    self.popInteractiveTransitionDuration = 0.35f;
    
    if (HX_IS_IPhoneX_All) {
        self.clarityScale = 3;
    }else if ([UIScreen mainScreen].bounds.size.width == 320) {
        self.clarityScale = 1.2;
    }else if ([UIScreen mainScreen].bounds.size.width == 375) {
        self.clarityScale = 1.8;
    }else {
        self.clarityScale = 2.0;
    }
    
    self.doneBtnShowDetail = YES;
    self.videoCanEdit = YES;
//    self.singleJumpEdit = YES;
    self.photoCanEdit = YES;
    self.localFileName = @"HXPhotoPickerModelArray";
    
    self.popupTableViewCellHeight = 65.f;
    if (HX_IS_IPhoneX_All) {
        self.editVideoExportPresetName = AVAssetExportPresetHighestQuality;
        self.popupTableViewHeight = 450;
    }else {
        self.editVideoExportPresetName = AVAssetExportPresetMediumQuality;
        self.popupTableViewHeight = 350;
    }
    self.popupTableViewHorizontalHeight = 250; 
//    self.albumShowMode = HXPhotoAlbumShowModePopup;
    
    
    self.cellDarkSelectTitleColor = [UIColor whiteColor];
    self.cellDarkSelectBgColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
    self.previewDarkSelectBgColor = [UIColor whiteColor];
    self.previewDarkSelectTitleColor = [UIColor blackColor];
    [HXPhotoCommon photoCommon].photoStyle = HXPhotoStyleDefault;
    self.defaultFrontCamera = NO;
    
    self.popupTableViewBgColor = [UIColor whiteColor];
    self.albumListViewBgColor = [UIColor whiteColor];
    self.photoListViewBgColor = [UIColor whiteColor];
    self.previewPhotoViewBgColor = [UIColor whiteColor];
    self.albumListViewCellBgColor = [UIColor whiteColor];
    self.albumListViewCellTextColor = [UIColor blackColor];
    self.albumListViewCellSelectBgColor = nil;
    self.albumListViewCellLineColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.15];
    self.photoListBottomPhotoCountTextColor = [UIColor colorWithRed:51.f / 255.f green:51.f / 255.f blue:51.f / 255.f alpha:1];
    
    self.limitPhotoSize = 0;
    self.limitVideoSize = 0;
    self.selectPhotoLimitSize = NO;
    self.selectVideoLimitSize = NO;
    self.navBarTranslucent = YES;
    self.bottomViewTranslucent = YES;
    self.selectVideoBeyondTheLimitTimeAutoEdit = NO;
    self.videoAutoPlayType = HXVideoAutoPlayTypeWiFi;
    self.previewSelectedBtnBgColor = self.themeColor;
    
    self.changeOriginalTinColor = YES;
    self.downloadNetworkVideo = YES;
    self.cameraCanLocation = YES;
    self.editAssetSaveSystemAblum = NO;
    self.photoEditCustomRatios = @[@{@"原始值" : @"{0, 0}"}, @{@"正方形" : @"{1, 1}"}, @{@"2:3" : @"{2, 3}"}, @{@"3:4" : @"{3, 4}"}, @{@"9:16" : @"{9, 16}"}, @{@"16:9" : @"{16, 9}"}];
    
    self.useWxPhotoEdit = YES;
}
- (void)setShowDateSectionHeader:(BOOL)showDateSectionHeader {
    _showDateSectionHeader = showDateSectionHeader;
    if (showDateSectionHeader) {
        self.creationDateSort = YES;
    }else {
        self.creationDateSort = NO;
    }
}
- (UIColor *)cameraFocusBoxColor {
    if (!_cameraFocusBoxColor) {
        _cameraFocusBoxColor = [UIColor colorWithRed:0 green:0.47843137254901963 blue:1 alpha:1];
    }
    return _cameraFocusBoxColor;
}
- (void)setVideoAutoPlayType:(HXVideoAutoPlayType)videoAutoPlayType {
    _videoAutoPlayType = videoAutoPlayType;
    [HXPhotoCommon photoCommon].videoAutoPlayType = videoAutoPlayType;
}
- (void)setDownloadNetworkVideo:(BOOL)downloadNetworkVideo {
    _downloadNetworkVideo = downloadNetworkVideo;
    [HXPhotoCommon photoCommon].downloadNetworkVideo = downloadNetworkVideo;
}
- (void)setPhotoStyle:(HXPhotoStyle)photoStyle {
    _photoStyle = photoStyle;
    [HXPhotoCommon photoCommon].photoStyle = photoStyle;
}
- (void)setLanguageType:(HXPhotoLanguageType)languageType {
    if ([HXPhotoCommon photoCommon].languageType != languageType) {
        [HXPhotoCommon photoCommon].cameraRollAlbumModel = nil;
        [HXPhotoCommon photoCommon].languageBundle = nil;
    }
    _languageType = languageType;
    [HXPhotoCommon photoCommon].languageType = languageType;
}
- (void)setClarityScale:(CGFloat)clarityScale {
    if (clarityScale <= 0.f) {
        if ([UIScreen mainScreen].bounds.size.width == 320) {
            _clarityScale = 0.8;
        }else if ([UIScreen mainScreen].bounds.size.width == 375) {
            _clarityScale = 1.4;
        }else {
            _clarityScale = 2.4;
        }
    }else {
        _clarityScale = clarityScale;
    }
}
- (UIColor *)themeColor {
    if (!_themeColor) {
        _themeColor = [UIColor colorWithRed:0 green:0.47843137254901963 blue:1 alpha:1]; 
    }
    return _themeColor;
}
- (NSString *)originalNormalImageName {
    if (!_originalNormalImageName) {
        _originalNormalImageName = @"hx_original_normal";
    }
    return _originalNormalImageName;
}
- (NSString *)originalSelectedImageName {
    if (!_originalSelectedImageName) {
        _originalSelectedImageName = @"hx_original_selected";
    }
    return _originalSelectedImageName;
}
- (void)setVideoMaximumSelectDuration:(NSInteger)videoMaximumSelectDuration {
    if (videoMaximumSelectDuration <= 0) {
        videoMaximumSelectDuration = MAXFLOAT;
    }
    _videoMaximumSelectDuration = videoMaximumSelectDuration;
}
- (void)setVideoMaximumDuration:(NSTimeInterval)videoMaximumDuration {
    if (videoMaximumDuration <= 3) {
        videoMaximumDuration = 4;
    }
    _videoMaximumDuration = videoMaximumDuration;
}
- (CGPoint)movableCropBoxCustomRatio {
//    if (_movableCropBoxCustomRatio.x == 0 || _movableCropBoxCustomRatio.y == 0) {
//        return CGPointMake(1, 1);
//    }
    return _movableCropBoxCustomRatio;
}
- (NSInteger)minVideoClippingTime {
    if (_minVideoClippingTime < 1) {
        _minVideoClippingTime = 1;
    }
    return _minVideoClippingTime;
}
- (NSInteger)maxVideoClippingTime {
    if (!_maxVideoClippingTime) {
        _maxVideoClippingTime = 15;
    }
    return _maxVideoClippingTime;
}
- (UIColor *)authorizationTipColor {
    if (!_authorizationTipColor) {
        _authorizationTipColor = [UIColor blackColor];
    }
    return _authorizationTipColor;
}
- (void)setType:(HXConfigurationType)type {
    _type = type;
    
    self.videoCanEdit = YES;
    self.specialModeNeedHideVideoSelectBtn = YES;
    self.cameraPhotoJumpEdit = YES;
//    self.openCamera = NO;
    self.saveSystemAblum = YES;
    self.albumShowMode = HXPhotoAlbumShowModePopup;
    
    // 颜色设置
    self.statusBarStyle = UIStatusBarStyleLightContent;
    self.themeColor = [UIColor whiteColor];
    self.photoEditConfigur.themeColor = [UIColor hx_colorWithHexStr:@"#07C160"];
    self.navBarBackgroudColor = [UIColor hx_colorWithHexStr:@"#141414"];
    
    // 原图按钮设置
    self.changeOriginalTinColor = NO;
    self.originalNormalImageName = @"hx_original_normal_wx";
    self.originalSelectedImageName = @"hx_original_selected_wx";
    
    self.cameraFocusBoxColor = [UIColor hx_colorWithHexStr:@"#07C160"];
    
    self.authorizationTipColor = [UIColor whiteColor];
    self.navigationTitleSynchColor = YES;
    self.cellSelectedBgColor = [UIColor hx_colorWithHexStr:@"#07C160"];
    self.cellSelectedTitleColor = [UIColor whiteColor];
    self.previewSelectedBtnBgColor = [UIColor hx_colorWithHexStr:@"#07C160"];
    self.selectedTitleColor = [UIColor whiteColor];
    self.bottomDoneBtnBgColor = [UIColor hx_colorWithHexStr:@"#07C160"];
    self.bottomDoneBtnTitleColor = [UIColor whiteColor];
    
    self.bottomViewBgColor = [UIColor hx_colorWithHexStr:@"#141414"];
    
    self.popupTableViewCellBgColor = [UIColor hx_colorWithHexStr:@"#2E2F30"];
    self.popupTableViewCellLineColor = [[UIColor hx_colorWithHexStr:@"#434344"] colorWithAlphaComponent:0.6];
    self.popupTableViewCellSelectColor = [UIColor clearColor];
    self.popupTableViewCellSelectIconColor = [UIColor hx_colorWithHexStr:@"#07C160"];
    self.popupTableViewCellHighlightedColor = [UIColor colorWithRed:0.125 green:0.125 blue:0.125 alpha:1];
    self.popupTableViewBgColor = [UIColor colorWithRed:0.125 green:0.125 blue:0.125 alpha:1];
    self.popupTableViewCellPhotoCountColor = [UIColor whiteColor];
    self.popupTableViewCellAlbumNameColor = [UIColor whiteColor];
    self.popupTableViewHeight = HX_ScreenHeight * 0.65;
    
    self.albumListViewBgColor = [UIColor hx_colorWithHexStr:@"#2E2F30"];
    self.albumListViewCellBgColor = [UIColor hx_colorWithHexStr:@"#2E2F30"];
    self.albumListViewCellSelectBgColor = [UIColor colorWithRed:0.125 green:0.125 blue:0.125 alpha:1];
    self.albumListViewCellLineColor = [[UIColor hx_colorWithHexStr:@"#434344"] colorWithAlphaComponent:0.6];
    self.albumListViewCellTextColor = [UIColor whiteColor];
    
    self.photoListViewBgColor = [UIColor hx_colorWithHexStr:@"#2E2F30"];
    self.photoListBottomPhotoCountTextColor = [UIColor whiteColor];
    self.previewPhotoViewBgColor = [UIColor blackColor];
    
    if (type == HXConfigurationTypeWXChat) {
        self.videoMaximumSelectDuration = 60.f * 5.f;
        self.selectVideoBeyondTheLimitTimeAutoEdit = NO;
        self.photoMaxNum = 0;
        self.videoMaxNum = 0;
        self.maxNum = 9;
        self.selectTogether = YES;
    }else if (type == HXConfigurationTypeWXMoment) {
        self.videoMaximumDuration = 15;
        self.videoMaximumSelectDuration = 15;
        self.selectVideoBeyondTheLimitTimeAutoEdit = YES;
        self.photoMaxNum = 9;
        self.videoMaxNum = 1;
        self.maxNum = 9;
        self.selectTogether = NO;
    }
}
- (HXPhotoEditConfiguration *)photoEditConfigur {
    if (!_photoEditConfigur) {
        _photoEditConfigur = [[HXPhotoEditConfiguration alloc] init];
        _photoEditConfigur.themeColor = self.themeColor;
        _photoEditConfigur.supportRotation = self.supportRotation;
    }
    return _photoEditConfigur;
}
@end
