//
//  HXPhotoConfiguration.m
//  照片选择器
//
//  Created by 洪欣 on 2017/11/21.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoConfiguration.h"
#import "HXPhotoTools.h"

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
    self.selectTogether = YES;
    self.maxNum = 10;
    self.photoMaxNum = 9;
    self.videoMaxNum = 1;
    self.showBottomPhotoDetail = YES;
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
    self.showDeleteNetworkPhotoAlert = NO;
    self.downloadICloudAsset = YES;
    self.videoMaxDuration = 3 * 60.f;
    self.videoMaximumDuration = 60.f;
    //    self.saveSystemAblum = NO;
    self.deleteTemporaryPhoto = YES;
    self.showDateSectionHeader = YES;
    //    self.reverseDate = NO;
    if ([UIScreen mainScreen].bounds.size.width != 320) {
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
    self.transitionAnimationOption = UIViewAnimationOptionCurveEaseOut;
    if (kDevice_Is_iPhoneX) {
        self.clarityScale = 2.0f;
    }else if ([UIScreen mainScreen].bounds.size.width == 320) {
        self.clarityScale = 0.8;
    }else if ([UIScreen mainScreen].bounds.size.width == 375) {
        self.clarityScale = 1.4;
    }else {
        self.clarityScale = 1.7;
    }
    
    self.doneBtnShowDetail = YES;
//    self.videoCanEdit = YES;
    self.singleJumpEdit = YES;
    self.photoCanEdit = YES;
    
//    [self preloadImage];
}

//- (void)preloadImage {
//    [HXPhotoTools hx_imageNamed:@"icon_yunxiazai@2x.png"];
//    [HXPhotoTools hx_imageNamed:@"compose_guide_check_box_default@2x.png"];
//    [HXPhotoTools hx_imageNamed:@"compose_photo_video@2x.png"];
//    [HXPhotoTools hx_imageNamed:@"compose_photo_photograph@2x.png"];
//    [HXPhotoTools hx_imageNamed:@"takePhoto@2x.png"];
//    [HXPhotoTools hx_imageNamed:@"qz_photolist_picture_fail@2x.png"];
//    [HXPhotoTools hx_imageNamed:@"compose_guide_check_box_default@2x.png"];
//    [HXPhotoTools hx_imageNamed:@"compose_guide_check_box_default111@2x.png"];
//}

- (void)setClarityScale:(CGFloat)clarityScale {
    if (clarityScale <= 0.f) {
        if ([UIScreen mainScreen].bounds.size.width == 320) {
            _clarityScale = 0.8;
        }else if ([UIScreen mainScreen].bounds.size.width == 375) {
            _clarityScale = 1.4;
        }else {
            _clarityScale = 1.7;
        }
    }else {
        _clarityScale = clarityScale;
    }
}
- (UIColor *)themeColor {
    if (!_themeColor) {
        _themeColor = [UIColor colorWithRed:0 green:0.478431 blue:1 alpha:1]; 
    }
    return _themeColor;
}
- (NSString *)originalNormalImageName {
    if (!_originalNormalImageName) {
        _originalNormalImageName = @"hx_original_normal@2x.png";
        [HXPhotoTools hx_imageNamed:_originalNormalImageName];
    }
    return _originalNormalImageName;
}
- (NSString *)originalSelectedImageName {
    if (!_originalSelectedImageName) {
        _originalSelectedImageName = @"hx_original_selected@2x.png";
        [HXPhotoTools hx_imageNamed:_originalSelectedImageName];
    }
    return _originalSelectedImageName;
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
@end
