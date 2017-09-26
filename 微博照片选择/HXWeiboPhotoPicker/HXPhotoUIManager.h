//
//  HXPhotoUIManager.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/8/9.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HXPhotoUIManager : NSObject

/**  HXPhotoView添加按钮图片  */
@property (copy, nonatomic) NSString *photoViewAddImageName;

/**  网络图片占位图  */
@property (copy, nonatomic) NSString *placeholderImageName;

/*-------------------导航栏相关属性------------------*/

@property (copy, nonatomic) void (^navBar)(UINavigationBar *navBar);

@property (copy, nonatomic) void (^navItem)(UINavigationItem *item); 

@property (copy, nonatomic) void (^navRightBtn)(UIButton *rightBtn);

/**  导航栏背景颜色  */
@property (strong, nonatomic) UIColor *navBackgroundColor;

/**  导航栏背景图片  */
@property (copy, nonatomic) NSString *navBackgroundImageName;

/**  导航栏左边按钮文字颜色  */
@property (strong, nonatomic) UIColor *navLeftBtnTitleColor;

/**  导航栏 标题/相册名 文字颜色  */
@property (strong, nonatomic) UIColor *navTitleColor;

/**  导航栏标题箭头图标  */
@property (copy, nonatomic) NSString *navTitleImageName;

/**  导航栏右边按钮普通状态背景颜色  */
@property (strong, nonatomic) UIColor *navRightBtnNormalBgColor;

/**  导航栏右边按钮普通状态文字颜色  */
@property (strong, nonatomic) UIColor *navRightBtnNormalTitleColor;

/**  导航栏右边按钮禁用状态背景颜色  */
@property (strong, nonatomic) UIColor *navRightBtnDisabledBgColor;

/**  导航栏右边按钮禁用状态文字颜色  */
@property (strong, nonatomic) UIColor *navRightBtnDisabledTitleColor;

/**  导航栏右边按钮禁用状态下的 layer.borderColor 边框线颜色 */
@property (strong, nonatomic) UIColor *navRightBtnBorderColor;

/*-------------------相册列表视图------------------*/
/**  相册列表有选择内容的提醒图标  */
@property (copy, nonatomic) NSString *albumViewSelectImageName;

/**  相册名称文字颜色  */
@property (strong, nonatomic) UIColor *albumNameTitleColor;

/**  照片数量文字颜色  */
@property (strong, nonatomic) UIColor *photosNumberTitleColor;

/**  相册列表视图背景颜色  */
@property (strong, nonatomic) UIColor *albumViewBgColor;

/**  相册列表cell选中颜色  */
@property (strong, nonatomic) UIColor *albumViewCellSelectedColor;

/*-------------------Cell------------------*/
/**  cell iCloud图标  */
@property (copy, nonatomic) NSString *cellICloudIconImageName;

/**  cell相机照片图片  */
@property (copy, nonatomic) NSString *cellCameraPhotoImageName;

/**  cell相机视频图片  */
@property (copy, nonatomic) NSString *cellCameraVideoImageName;

/**  选择按钮普通状态图片  */
@property (copy, nonatomic) NSString *cellSelectBtnNormalImageName;

/**  选择按钮选中状态图片  */
@property (copy, nonatomic) NSString *cellSelectBtnSelectedImageName;

/**  gif标示图标  */
@property (copy, nonatomic) NSString *cellGitIconImageName;


/*-------------------底部预览、原图按钮视图------------------*/
/**  是否开启毛玻璃效果开启了自动屏蔽背景颜色  */
@property (assign, nonatomic) BOOL blurEffect;

/**  隐藏原图按钮  */
@property (assign, nonatomic) BOOL hideOriginalBtn;

/**  底部视图背景颜色  */
@property (strong, nonatomic) UIColor *bottomViewBgColor;

/**  预览按钮普通状态文字颜色  */
@property (strong, nonatomic) UIColor *previewBtnNormalTitleColor;

/**  预览按钮禁用状态文字颜色  */
@property (strong, nonatomic) UIColor *previewBtnDisabledTitleColor;

/**  预览按钮普通状态背景图片  */
@property (copy, nonatomic) NSString *previewBtnNormalBgImageName;

/**  预览按钮禁用状态背景图片  */
@property (copy, nonatomic) NSString *previewBtnDisabledBgImageName;

/**  原图按钮普通状态文字颜色  */
@property (strong, nonatomic) UIColor *originalBtnNormalTitleColor;

/**  原图按钮禁用状态文字颜色  */
@property (strong, nonatomic) UIColor *originalBtnDisabledTitleColor;

/**  原图按钮边框线颜色  */
@property (strong, nonatomic) UIColor *originalBtnBorderColor;

/**  原图按钮背景颜色  */
@property (strong, nonatomic) UIColor *originalBtnBgColor;

/**  原图按钮普通状态图片  */
@property (copy, nonatomic) NSString *originalBtnNormalImageName;

/**  原图按钮选中状态图片  */
@property (copy, nonatomic) NSString *originalBtnSelectedImageName;

/*-------------------半屏相机界面------------------*/
/**  返回按钮X普通状态图片  */
@property (copy, nonatomic) NSString *cameraCloseNormalImageName;

/**  返回按钮X高亮状态图片  */
@property (copy, nonatomic) NSString *cameraCloseHighlightedImageName;

/**  闪光灯自动模式图片  */
@property (copy, nonatomic) NSString *flashAutoImageName;

/**  闪光灯打开模型图片  */
@property (copy, nonatomic) NSString *flashOnImageName;

/**  闪光灯关闭模式图片  */
@property (copy, nonatomic) NSString *flashOffImageName;

/**  反转相机普通状态图片  */
@property (copy, nonatomic) NSString *cameraReverseNormalImageName;

/**  反转相机高亮状态图片  */
@property (copy, nonatomic) NSString *cameraReverseHighlightedImageName;

/**  中心圆点下照片and视频普通状态文字颜色  */
@property (strong, nonatomic) UIColor *cameraPhotoVideoNormalTitleColor;

/**  中心圆点下照片and视频选中状态文字颜色  */
@property (strong, nonatomic) UIColor *cameraPhotoVideoSelectedTitleColor;

/**  拍照按钮普通状态图片  */
@property (copy, nonatomic) NSString *takePicturesBtnNormalImageName;

/**  拍照按钮高亮状态图片  */
@property (copy, nonatomic) NSString *takePicturesBtnHighlightedImageName;

/**  录制按钮普通状态图片  */
@property (copy, nonatomic) NSString *recordedBtnNormalImageName;

/**  录制按钮高亮状态图片  */
@property (copy, nonatomic) NSString *recordedBtnHighlightedImageName;

/**  删除拍摄的照片/视频图片  */
@property (copy, nonatomic) NSString *cameraDeleteBtnImageName;

/**  确定拍摄的照片/视频普通状态图片  */
@property (copy, nonatomic) NSString *cameraNextBtnNormalImageName;

/**  确定拍摄的照片/视频高亮状态图片  */
@property (copy, nonatomic) NSString *cameraNextBtnHighlightedImageName;

/**  中心圆点图片  */
@property (copy, nonatomic) NSString *cameraCenterDotImageName;

/**  相机聚焦图片  */
@property (copy, nonatomic) NSString *cameraFocusImageName;

/**  全屏相机界面下一步按钮文字颜色  */
@property (strong, nonatomic) UIColor *fullScreenCameraNextBtnTitleColor;

/**  全屏相机界面下一步按钮背景颜色  */
@property (strong, nonatomic) UIColor *fullScreenCameraNextBtnBgColor;

@end
