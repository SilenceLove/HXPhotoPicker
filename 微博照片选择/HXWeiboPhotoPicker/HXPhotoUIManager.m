//
//  HXPhotoUIManager.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/8/9.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoUIManager.h"

@implementation HXPhotoUIManager
- (NSString *)photoViewAddImageName {
    if (!_photoViewAddImageName) {
        _photoViewAddImageName = @"compose_pic_add@2x.png";
    }
    return _photoViewAddImageName;
}
- (NSString *)placeholderImageName {
    if (!_placeholderImageName) {
        _placeholderImageName = @"qz_photolist_picture_fail@2x.png";
    }
    return _placeholderImageName;
}
- (UIColor *)navLeftBtnTitleColor {
    if (!_navLeftBtnTitleColor) {
        _navLeftBtnTitleColor = [UIColor blackColor];
    }
    return _navLeftBtnTitleColor;
}
- (UIColor *)navTitleColor {
    if (!_navTitleColor) {
        _navTitleColor = [UIColor blackColor];
    }
    return _navTitleColor;
}
- (NSString *)navTitleImageName {
    if (!_navTitleImageName) {
        _navTitleImageName = @"headlines_icon_arrow@2x.png";
    }
    return _navTitleImageName;
}
- (UIColor *)navRightBtnNormalBgColor {
    if (!_navRightBtnNormalBgColor) {
        _navRightBtnNormalBgColor = [UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1];
    }
    return _navRightBtnNormalBgColor;
}
- (UIColor *)navRightBtnDisabledBgColor {
    if (!_navRightBtnDisabledBgColor) {
        _navRightBtnDisabledBgColor = [UIColor whiteColor];
    }
    return _navRightBtnDisabledBgColor;
}
- (UIColor *)navRightBtnBorderColor {
    if (!_navRightBtnBorderColor) {
        _navRightBtnBorderColor = [UIColor lightGrayColor];
    }
    return _navRightBtnBorderColor;
}
- (UIColor *)navRightBtnNormalTitleColor {
    if (!_navRightBtnNormalTitleColor) {
        _navRightBtnNormalTitleColor = [UIColor whiteColor];
    }
    return _navRightBtnNormalTitleColor;
}
- (UIColor *)navRightBtnDisabledTitleColor {
    if (!_navRightBtnDisabledTitleColor) {
        _navRightBtnDisabledTitleColor = [UIColor lightGrayColor];
    }
    return _navRightBtnDisabledTitleColor;
}
- (UIColor *)bottomViewBgColor {
    if (!_bottomViewBgColor) {
        _bottomViewBgColor = [UIColor whiteColor];
    }
    return _bottomViewBgColor;
}
- (UIColor *)previewBtnNormalTitleColor {
    if (!_previewBtnNormalTitleColor) {
        _previewBtnNormalTitleColor = [UIColor blackColor];
    }
    return _previewBtnNormalTitleColor;
}
- (UIColor *)previewBtnDisabledTitleColor {
    if (!_previewBtnDisabledTitleColor) {
        _previewBtnDisabledTitleColor = [UIColor lightGrayColor];
    }
    return _previewBtnDisabledTitleColor;
}
- (NSString *)previewBtnNormalBgImageName {
    if (!_previewBtnNormalBgImageName) {
        _previewBtnNormalBgImageName = @"compose_photo_preview_seleted@2x.png";
    }
    return _previewBtnNormalBgImageName;
}
- (NSString *)previewBtnDisabledBgImageName {
    if (!_previewBtnDisabledBgImageName) {
        _previewBtnDisabledBgImageName = @"compose_photo_preview_disable@2x.png";
    }
    return _previewBtnDisabledBgImageName;
}
- (UIColor *)originalBtnBgColor {
    if (!_originalBtnBgColor) {
        _originalBtnBgColor = [UIColor whiteColor];
    }
    return _originalBtnBgColor;
}
- (UIColor *)originalBtnNormalTitleColor {
    if (!_originalBtnNormalTitleColor) {
        _originalBtnNormalTitleColor = [UIColor blackColor];
    }
    return _originalBtnNormalTitleColor;
}
- (UIColor *)originalBtnDisabledTitleColor {
    if (!_originalBtnDisabledTitleColor) {
        _originalBtnDisabledTitleColor = [UIColor lightGrayColor];
    }
    return _originalBtnDisabledTitleColor;
}
- (UIColor *)originalBtnBorderColor {
    if (!_originalBtnBorderColor) {
        _originalBtnBorderColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:0.7];
    }
    return _originalBtnBorderColor;
}
- (NSString *)originalBtnNormalImageName {
    if (!_originalBtnNormalImageName) {
        _originalBtnNormalImageName = @"椭圆-1@2x.png";
    }
    return _originalBtnNormalImageName;
}
- (NSString *)originalBtnSelectedImageName {
    if (!_originalBtnSelectedImageName) {
        _originalBtnSelectedImageName = @"椭圆-1-拷贝@2x.png";
    }
    return _originalBtnSelectedImageName;
}
- (UIColor *)albumViewBgColor {
    if (!_albumViewBgColor) {
        _albumViewBgColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1];
    }
    return _albumViewBgColor;
}
- (NSString *)albumViewSelectImageName {
    if (!_albumViewSelectImageName) {
        _albumViewSelectImageName = @"compose_photo_filter_checkbox_checked@2x.png";
    }
    return _albumViewSelectImageName;
}
- (UIColor *)albumNameTitleColor {
    if (!_albumNameTitleColor) {
        _albumNameTitleColor = [UIColor blackColor];
    }
    return _albumNameTitleColor;
}
- (UIColor *)photosNumberTitleColor {
    if (!_photosNumberTitleColor) {
        _photosNumberTitleColor = [UIColor darkGrayColor];
    }
    return _photosNumberTitleColor;
}
- (NSString *)cellCameraPhotoImageName {
    if (!_cellCameraPhotoImageName) {
        _cellCameraPhotoImageName = @"compose_photo_photograph@2x.png";
    }
    return _cellCameraPhotoImageName;
}
- (NSString *)cellCameraVideoImageName {
    if (!_cellCameraVideoImageName) {
        _cellCameraVideoImageName = @"compose_photo_video@2x.png";
    }
    return _cellCameraVideoImageName;
}
- (NSString *)cellGitIconImageName {
    if (!_cellGitIconImageName) {
        _cellGitIconImageName = @"timeline_image_gif@2x.png";
    }
    return _cellGitIconImageName;
}
- (NSString *)cellSelectBtnNormalImageName {
    if (!_cellSelectBtnNormalImageName) {
        _cellSelectBtnNormalImageName = @"compose_guide_check_box_default@2x.png";
    }
    return _cellSelectBtnNormalImageName;
}
- (NSString *)cellSelectBtnSelectedImageName {
    if (!_cellSelectBtnSelectedImageName) {
        _cellSelectBtnSelectedImageName = @"compose_guide_check_box_right@2x.png";
    }
    return _cellSelectBtnSelectedImageName;
}
- (NSString *)cameraCloseNormalImageName {
    if (!_cameraCloseNormalImageName) {
        _cameraCloseNormalImageName = @"camera_close@2x.png";
    }
    return _cameraCloseNormalImageName;
}
- (NSString *)cameraCloseHighlightedImageName {
    if (!_cameraCloseHighlightedImageName) {
        _cameraCloseHighlightedImageName = @"camera_close_highlighted@2x.png";
    }
    return _cameraCloseHighlightedImageName;
}
- (NSString *)cameraReverseNormalImageName {
    if (!_cameraReverseNormalImageName) {
        _cameraReverseNormalImageName = @"camera_overturn@2x.png";
    }
    return _cameraReverseNormalImageName;
}
- (NSString *)cameraReverseHighlightedImageName {
    if (!_cameraReverseHighlightedImageName) {
        _cameraReverseHighlightedImageName = @"camera_overturn_highlighted@2x.png";
    }
    return _cameraReverseHighlightedImageName;
}
- (NSString *)flashAutoImageName {
    if (!_flashAutoImageName) {
        _flashAutoImageName = @"camera_flashlight_auto_disable@2x.png";
    }
    return _flashAutoImageName;
}
- (NSString *)flashOnImageName {
    if (!_flashOnImageName) {
        _flashOnImageName = @"camera_flashlight_open_disable@2x.png";
    }
    return _flashOnImageName;
}
- (NSString *)flashOffImageName {
    if (!_flashOffImageName) {
        _flashOffImageName = @"camera_flashlight_disable@2x.png";
    }
    return _flashOffImageName;
}
- (NSString *)takePicturesBtnNormalImageName {
    if (!_takePicturesBtnNormalImageName) {
        _takePicturesBtnNormalImageName = @"camera_camera_background@2x.png";
    }
    return _takePicturesBtnNormalImageName;
}
- (NSString *)takePicturesBtnHighlightedImageName {
    if (!_takePicturesBtnHighlightedImageName) {
        _takePicturesBtnHighlightedImageName = @"camera_camera_background_highlighted@2x.png";
    }
    return _takePicturesBtnHighlightedImageName;
}
- (NSString *)recordedBtnNormalImageName {
    if (!_recordedBtnNormalImageName) {
        _recordedBtnNormalImageName = @"camera_video_background@2x.png";
    }
    return _recordedBtnNormalImageName;
}
- (NSString *)recordedBtnHighlightedImageName {
    if (!_recordedBtnHighlightedImageName) {
        _recordedBtnHighlightedImageName = @"camera_video_background_highlighted@2x.png";
    }
    return _recordedBtnHighlightedImageName;
}
- (NSString *)cameraDeleteBtnImageName {
    if (!_cameraDeleteBtnImageName) {
        _cameraDeleteBtnImageName = @"video_delete_dustbin@2x.png";
    }
    return _cameraDeleteBtnImageName;
}
- (NSString *)cameraNextBtnNormalImageName {
    if (!_cameraNextBtnNormalImageName) {
        _cameraNextBtnNormalImageName = @"video_next_button@2x.png";
    }
    return _cameraNextBtnNormalImageName;
}
- (NSString *)cameraNextBtnHighlightedImageName {
    if (!_cameraNextBtnHighlightedImageName) {
        _cameraNextBtnHighlightedImageName = @"video_next_button_highlighted@2x.png";
    }
    return _cameraNextBtnHighlightedImageName;
}
- (NSString *)cameraCenterDotImageName {
    if (!_cameraCenterDotImageName) {
        _cameraCenterDotImageName = @"camera_drop_highlighted@2x.png";
    }
    return _cameraCenterDotImageName;
}
- (NSString *)cameraFocusImageName {
    if (!_cameraFocusImageName) {
        _cameraFocusImageName = @"camera_ Focusing@2x.png";
    }
    return _cameraFocusImageName;
}
- (UIColor *)fullScreenCameraNextBtnTitleColor {
    if (!_fullScreenCameraNextBtnTitleColor) {
        _fullScreenCameraNextBtnTitleColor = [UIColor whiteColor];
    }
    return _fullScreenCameraNextBtnTitleColor;
}
- (UIColor *)fullScreenCameraNextBtnBgColor {
    if (!_fullScreenCameraNextBtnBgColor) {
        _fullScreenCameraNextBtnBgColor = [UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1];
    }
    return _fullScreenCameraNextBtnBgColor;
}
- (UIColor *)cameraPhotoVideoNormalTitleColor {
    if (!_cameraPhotoVideoNormalTitleColor) {
        _cameraPhotoVideoNormalTitleColor = [UIColor lightGrayColor];
    }
    return _cameraPhotoVideoNormalTitleColor;
}
- (UIColor *)cameraPhotoVideoSelectedTitleColor {
    if (!_cameraPhotoVideoSelectedTitleColor) {
        _cameraPhotoVideoSelectedTitleColor = [UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1];
    }
    return _cameraPhotoVideoSelectedTitleColor;
}
@end
