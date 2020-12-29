//
//  HXPhotoConfiguration.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/11/21.
//  Copyright © 2017年 Silence. All rights reserved.
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
    self.videoMaximumSelectDuration = 3 * 60.f;
    self.videoMinimumSelectDuration = 0.f;
    self.videoMaximumDuration = 60.f;
    self.videoMinimumDuration = 3.f;
    if ([UIScreen mainScreen].bounds.size.width != 320 && [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.cameraCellShowPreview = YES;
    }
    self.customAlbumName = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
    self.horizontalRowCount = 6;
    self.supportRotation = YES;
    self.pushTransitionDuration = 0.45f;
    self.popTransitionDuration = 0.35f;
    self.popInteractiveTransitionDuration = 0.35f;
    self.doneBtnShowDetail = YES;
    self.videoCanEdit = YES;
    self.photoCanEdit = YES;
    self.localFileName = @"HXPhotoPickerModelArray";
    self.languageType = HXPhotoLanguageTypeSys;
    self.popupTableViewCellHeight = 65.f;
    if (HX_IS_IPhoneX_All) {
        self.editVideoExportPresetName = AVAssetExportPresetHighestQuality;
        self.popupTableViewHeight = 450;
    }else {
        self.editVideoExportPresetName = AVAssetExportPresetMediumQuality;
        self.popupTableViewHeight = 350;
    }
    self.popupTableViewHorizontalHeight = 250; 
    self.albumShowMode = HXPhotoAlbumShowModeDefault;
    
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
    if (HX_IS_IPhoneX_All) {
        _clarityScale = 1.9;
    }else {
        _clarityScale = 1.5;
    }
    if ([UIScreen mainScreen].bounds.size.width == 320) {
        self.rowCount = 3;
    }else {
        if ([HXPhotoTools isIphone6]) {
            self.rowCount = 3;
        }else {
            self.rowCount = 4;
        }
    }
    self.allowSlidingSelection = YES;
    self.livePhotoAutoPlay = YES;
}
- (void)setLivePhotoAutoPlay:(BOOL)livePhotoAutoPlay {
    _livePhotoAutoPlay = livePhotoAutoPlay;
    [HXPhotoCommon photoCommon].livePhotoAutoPlay = livePhotoAutoPlay;
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
- (void)setCreationDateSort:(BOOL)creationDateSort {
    if ([HXPhotoCommon photoCommon].creationDateSort != creationDateSort) {
        [HXPhotoCommon photoCommon].cameraRollResult = nil;
    }
    _creationDateSort = creationDateSort;
    [HXPhotoCommon photoCommon].creationDateSort = creationDateSort;
}
- (void)setLanguageType:(HXPhotoLanguageType)languageType {
    if ([HXPhotoCommon photoCommon].languageType != languageType) {
        [HXPhotoCommon photoCommon].languageBundle = nil;
    }
    _languageType = languageType;
    [HXPhotoCommon photoCommon].languageType = languageType;
}
- (void)setClarityScale:(CGFloat)clarityScale {
    if (clarityScale <= 0.f) {
        if (HX_IS_IPhoneX_All) {
            _clarityScale = 1.9;
        }else {
            _clarityScale = 1.5;
        }
    }else {
        _clarityScale = clarityScale;
    }
    CGFloat width = ([UIScreen mainScreen].bounds.size.width - 1 * self.rowCount - 1 ) / self.rowCount;
    [HXPhotoCommon photoCommon].requestWidth = width * clarityScale;
}
- (void)setRowCount:(NSUInteger)rowCount {
    _rowCount = rowCount;
    CGFloat width = ([UIScreen mainScreen].bounds.size.width - 1 * rowCount - 1 ) / rowCount;
    [HXPhotoCommon photoCommon].requestWidth = width * self.clarityScale;
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
    if (videoMaximumDuration <= self.videoMinimumDuration) {
        videoMaximumDuration = self.videoMinimumDuration + 1.f;
    }
    _videoMaximumDuration = videoMaximumDuration;
}
- (CGPoint)movableCropBoxCustomRatio {
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
    if (type == HXConfigurationTypeWXChat) {
        [self setWxConfiguration];
        self.videoMaximumSelectDuration = 60.f * 5.f;
        self.selectVideoBeyondTheLimitTimeAutoEdit = NO;
        self.photoMaxNum = 0;
        self.videoMaxNum = 0;
        self.maxNum = 9;
        self.selectTogether = YES;
    }else if (type == HXConfigurationTypeWXMoment) {
        [self setWxConfiguration];
        self.videoMaximumDuration = 15;
        self.videoMaximumSelectDuration = 15;
        self.selectVideoBeyondTheLimitTimeAutoEdit = YES;
        self.photoMaxNum = 9;
        self.videoMaxNum = 1;
        self.maxNum = 9;
        self.selectTogether = NO;
    }
}
- (void)setWxConfiguration {
    self.videoCanEdit = YES;
    self.specialModeNeedHideVideoSelectBtn = YES;
    self.cameraPhotoJumpEdit = YES;
    self.saveSystemAblum = YES;
    self.albumShowMode = HXPhotoAlbumShowModePopup;
    self.photoListCancelLocation = HXPhotoListCancelButtonLocationTypeLeft;
    self.cameraCellShowPreview = NO;
    
    // 原图按钮设置
    self.changeOriginalTinColor = NO;
    self.originalNormalImageName = @"hx_original_normal_wx";
    self.originalSelectedImageName = @"hx_original_selected_wx";

    // 颜色设置
    UIColor *wxColor = [UIColor hx_colorWithHexStr:@"#07C160"];
    self.statusBarStyle = UIStatusBarStyleLightContent;
    self.themeColor = [UIColor whiteColor];
    self.photoEditConfigur.themeColor = wxColor;
    self.previewBottomSelectColor = wxColor;
    self.navBarBackgroudColor = nil;
    self.navBarStyle = UIBarStyleBlack;
    self.navigationTitleArrowColor = [UIColor hx_colorWithHexStr:@"#B2B2B2"];
    self.navigationTitleArrowDarkColor = [UIColor hx_colorWithHexStr:@"#B2B2B2"];
    self.cameraFocusBoxColor = wxColor;
    self.authorizationTipColor = [UIColor whiteColor];
    self.navigationTitleSynchColor = YES;
    self.cellSelectedBgColor = wxColor;
    self.cellSelectedTitleColor = [UIColor whiteColor];
    self.cellDarkSelectBgColor = wxColor;
    self.cellDarkSelectTitleColor = [UIColor whiteColor];
    self.previewSelectedBtnBgColor = wxColor;
    self.selectedTitleColor = [UIColor whiteColor];
    self.previewDarkSelectBgColor = wxColor;
    self.previewDarkSelectTitleColor = [UIColor whiteColor];
    self.bottomDoneBtnBgColor = wxColor;
    self.bottomDoneBtnDarkBgColor = wxColor;
    self.bottomDoneBtnEnabledBgColor = [[UIColor hx_colorWithHexStr:@"#666666"] colorWithAlphaComponent:0.3];
    self.bottomDoneBtnTitleColor = [UIColor whiteColor];
//    self.bottomViewBgColor = [UIColor hx_colorWithHexStr:@"#141414"];
    self.bottomViewBgColor = nil;
    self.bottomViewBarStyle = UIBarStyleBlack;
    
    self.popupTableViewCellBgColor = [UIColor hx_colorWithHexStr:@"#2E2F30"];
    self.popupTableViewCellLineColor = [[UIColor hx_colorWithHexStr:@"#434344"] colorWithAlphaComponent:0.6];
    self.popupTableViewCellSelectColor = [UIColor clearColor];
    self.popupTableViewCellSelectIconColor = wxColor;
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
