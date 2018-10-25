//
//  HXPhotoConfiguration.h
//  照片选择器
//
//  Created by 洪欣 on 2017/11/21.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, HXPhotoConfigurationCameraType) {
    HXPhotoConfigurationCameraTypePhoto = 0,        //!< 拍照
    HXPhotoConfigurationCameraTypeVideo = 1,        //!< 录制
    HXPhotoConfigurationCameraTypeTypePhotoAndVideo //!< 拍照和录制一起
}; 

typedef NS_ENUM(NSUInteger, HXPhotoAlbumShowMode) {
    HXPhotoAlbumShowModeDefault,    //!< 默认的
    HXPhotoAlbumShowModePopup       //!< 弹窗
};

@class HXDatePhotoBottomView;
@class HXDatePhotoPreviewBottomView;
@class HXPhotoManager;
@class HXPhotoModel;

@interface HXPhotoConfiguration : NSObject

/**
 照片列表是否按照片日期排序  默认YES
 */
@property (assign, nonatomic) BOOL creationDateSort;

/**
 相册列表展示方式
 */
@property (assign, nonatomic) HXPhotoAlbumShowMode albumShowMode;

/**
 模型数组保存草稿时存在本地的文件名称 default HXPhotoPickerModelArray
 如果有多个地方保存了草稿请设置不同的fileName
 */
@property (copy, nonatomic) NSString *localFileName;

/**
 只针对 照片、视频不能同时选并且视频只能选择1个的时候隐藏掉视频cell右上角的选择按钮
 */
@property (assign, nonatomic) BOOL specialModeNeedHideVideoSelectBtn;

/**
 在照片列表选择照片完后点击完成时是否请求图片
 选中了原图则是原图，没选中则是高清图
 并赋值给model的 thumbPhoto 和 previewPhoto 属性
 */
@property (assign, nonatomic) BOOL requestImageAfterFinishingSelection;

/**
 视频是否可以编辑   default NO
 
 */
@property (assign, nonatomic) BOOL videoCanEdit;

/**
 是否替换照片编辑界面   default NO
 
 */
@property (assign, nonatomic) BOOL replacePhotoEditViewController;

/**
 图片编辑完成调用这个block 传入模型
 beforeModel 编辑之前的模型
 afterModel  编辑之后的模型
 */
@property (copy, nonatomic) void (^usePhotoEditComplete)(HXPhotoModel *beforeModel,  HXPhotoModel *afterModel);

/**
 是否替换视频编辑界面   default NO
 
 */
@property (assign, nonatomic) BOOL replaceVideoEditViewController;

/**
 将要跳转编辑界面 在block内实现跳转
 isOutside 是否是HXPhotoView预览时的编辑
 beforeModel 编辑之前的模型
 */
@property (copy, nonatomic) void (^shouldUseEditAsset)(UIViewController *viewController, BOOL isOutside, HXPhotoManager *manager, HXPhotoModel *beforeModel);

/**
 视频编辑完成调用这个block 传入模型
 beforeModel 编辑之前的模型
 afterModel  编辑之后的模型
 */
@property (copy, nonatomic) void (^useVideoEditComplete)(HXPhotoModel *beforeModel,  HXPhotoModel *afterModel);

/**
 照片是否可以编辑   default YES
 */
@property (assign, nonatomic) BOOL photoCanEdit;

/**
 过渡动画枚举
 时间函数曲线相关
 UIViewAnimationOptionCurveEaseInOut
 UIViewAnimationOptionCurveEaseIn
 UIViewAnimationOptionCurveEaseOut   -->    default
 UIViewAnimationOptionCurveLinear
 */
@property (assign, nonatomic) UIViewAnimationOptions transitionAnimationOption;

/**
 push动画时长 default 0.45f
 */
@property (assign, nonatomic) NSTimeInterval pushTransitionDuration;

/**
 po动画时长 default 0.35f
 */
@property (assign, nonatomic) NSTimeInterval popTransitionDuration;

/**
 手势松开时返回的动画时长 default 0.35f
 */
@property (assign, nonatomic) NSTimeInterval popInteractiveTransitionDuration;

/**
 是否可移动的裁剪框
 */
@property (assign, nonatomic) BOOL movableCropBox;

/**
 可移动的裁剪框是否可以编辑大小
 */
@property (assign, nonatomic) BOOL movableCropBoxEditSize;

/**
 可移动裁剪框的比例 (w,h)
 一定要是宽比高哦!!!
 当 movableCropBox = YES && movableCropBoxEditSize = YES
 如果不设置比例即可自由编辑大小
 */
@property (assign, nonatomic) CGPoint movableCropBoxCustomRatio;

/**
 是否替换相机控制器
 使用自己的相机时需要调用下面两个block
 */
@property (assign, nonatomic) BOOL replaceCameraViewController;

/**
 将要跳转相机界面 在block内实现跳转
 demo1 里有示例（使用的是系统相机）
 */
@property (copy, nonatomic) void (^shouldUseCamera)(UIViewController *viewController, HXPhotoConfigurationCameraType cameraType, HXPhotoManager *manager);

/**
 相机拍照完成调用这个block 传入模型
 */
@property (copy, nonatomic) void (^useCameraComplete)(HXPhotoModel *model);

#pragma mark - < UI相关 >
/**
 弹窗方式的相册列表竖屏时的高度
 */
@property (assign, nonatomic) CGFloat popupTableViewHeight;

/**
 弹窗方式的相册列表横屏时的高度
 */
@property (assign, nonatomic) CGFloat popupTableViewHorizontalHeight;

/**
 弹窗方式的相册列表Cell选中的颜色
 */
@property (strong, nonatomic) UIColor *popupTableViewCellSelectColor;

/**
 弹窗方式的相册列表Cell底部线的颜色
 */
@property (strong, nonatomic) UIColor *popupTableViewCellLineColor;

/**
 弹窗方式的相册列表Cell的背景颜色
 */
@property (strong, nonatomic) UIColor *popupTableViewCellBgColor;

/**
 弹窗方式的相册列表Cell上相册名称的颜色
 */
@property (strong, nonatomic) UIColor *popupTableViewCellAlbumNameColor;

/**
 弹窗方式的相册列表Cell上相册名称的字体
 */
@property (strong, nonatomic) UIFont *popupTableViewCellAlbumNameFont;

/**
 弹窗方式的相册列表Cell上照片数量的颜色
 */
@property (strong, nonatomic) UIColor *popupTableViewCellPhotoCountColor;

/**
 弹窗方式的相册列表Cell上照片数量的字体
 */
@property (strong, nonatomic) UIFont *popupTableViewCellPhotoCountFont;

/**
 弹窗方式的相册列表Cell的高度
 */
@property (assign, nonatomic) CGFloat popupTableViewCellHeight;

/**
 显示底部照片详细信息 default YES
 */
@property (assign, nonatomic) BOOL showBottomPhotoDetail;

/**
 完成按钮是否显示详情 default YES
 */
@property (assign, nonatomic) BOOL doneBtnShowDetail;

/**
 是否支持旋转  默认YES
 - 如果不需要建议设置成NO
 */
@property (assign, nonatomic) BOOL supportRotation;

/**
 状态栏样式 默认 UIStatusBarStyleDefault
 */
@property (assign, nonatomic) UIStatusBarStyle statusBarStyle;

/**
 cell选中时的背景颜色
 */
@property (strong, nonatomic) UIColor *cellSelectedBgColor;

/**
 cell选中时的文字颜色
 */
@property (strong, nonatomic) UIColor *cellSelectedTitleColor;

/**
 选中时数字的颜色
 */
@property (strong, nonatomic) UIColor *selectedTitleColor;

/**
 sectionHeader悬浮时的标题颜色 ios9以上才有效果
 */
@property (strong, nonatomic) UIColor *sectionHeaderSuspensionTitleColor;

/**
 sectionHeader悬浮时的背景色 ios9以上才有效果
 */
@property (strong, nonatomic) UIColor *sectionHeaderSuspensionBgColor;

/**
 导航栏标题颜色
 */
@property (strong, nonatomic) UIColor *navigationTitleColor;

/**
 导航栏背景颜色
 */
@property (strong, nonatomic) UIColor *navBarBackgroudColor;

/**
 headerSection 半透明毛玻璃效果  默认YES  ios9以上才有效果
 */
@property (assign, nonatomic) BOOL sectionHeaderTranslucent;

/**
 导航栏标题颜色是否与主题色同步  默认NO;
 - 同步会过滤掉手动设置的导航栏标题颜色
 */
@property (assign, nonatomic) BOOL navigationTitleSynchColor;

/**
 主题颜色  默认 tintColor
 - 改变主题颜色后建议也改下原图按钮的图标
 */
@property (strong, nonatomic) UIColor *themeColor;

/**
 原图按钮普通状态下的按钮图标名
 - 改变主题颜色后建议也改下原图按钮的图标
 */
@property (copy, nonatomic) NSString *originalNormalImageName;

/**
 原图按钮选中状态下的按钮图标名
 - 改变主题颜色后建议也改下原图按钮的图标
 */
@property (copy, nonatomic) NSString *originalSelectedImageName;

/**
 是否隐藏原图按钮  默认 NO
 */
@property (assign, nonatomic) BOOL hideOriginalBtn;

/**
 sectionHeader 是否显示照片的位置信息 默认 5、6不显示，其余的显示
 */
@property (assign, nonatomic) BOOL sectionHeaderShowPhotoLocation;

/**
 相机cell是否显示预览
 屏幕宽  320  ->  NO
 other  ->  YES
 */
@property (assign, nonatomic) BOOL cameraCellShowPreview;

/**
 横屏时是否隐藏状态栏 默认显示  暂不支持修改
 */
//@property (assign, nonatomic) BOOL horizontalHideStatusBar;

/**
 横屏时相册每行个数  默认6个
 */
@property (assign, nonatomic) NSInteger horizontalRowCount;

/**
 是否需要显示日期section  默认YES
 */
@property (assign, nonatomic) BOOL showDateSectionHeader;

/**
 照片列表按日期倒序 默认 NO
 */
@property (assign, nonatomic) BOOL reverseDate;

#pragma mark - < 基本配置 >
/**
 相册列表每行多少个照片 默认4个 iphone 4s / 5  默认3个
 */
@property (assign, nonatomic) NSInteger rowCount;

/**
 最大选择数 等于 图片最大数 + 视频最大数 默认10 - 必填
 */
@property (assign, nonatomic) NSInteger maxNum;

/**
 图片最大选择数 默认9 - 必填
 */
@property (assign, nonatomic) NSInteger photoMaxNum;

/**
 视频最大选择数 // 默认1 - 必填
 */
@property (assign, nonatomic) NSInteger videoMaxNum;

/**
 是否打开相机功能
 */
@property (assign, nonatomic) BOOL openCamera;

/**
 是否开启查看GIF图片功能 - 默认开启
 */
@property (assign, nonatomic) BOOL lookGifPhoto;

/**
 是否开启查看LivePhoto功能呢 - 默认 NO
 */
@property (assign, nonatomic) BOOL lookLivePhoto;

/**
 图片和视频是否能够同时选择 默认支持
 */
@property (assign, nonatomic) BOOL selectTogether;

/**
 相机视频录制最大秒数  -  默认60s
 */
@property (assign, nonatomic) NSTimeInterval videoMaximumDuration;

/**
 *  删除临时的照片/视频 -
 注:相机拍摄的照片并没有保存到系统相册 或 是本地图片
 如果当这样的照片都没有被选中时会清空这些照片 有一张选中了就不会删..
 - 默认 NO
 */
@property (assign, nonatomic) BOOL deleteTemporaryPhoto;

/**
 *  拍摄的 照片/视频 是否保存到系统相册  默认NO
 *  支持添加到自定义相册 - (需9.0以上)
 */
@property (assign, nonatomic) BOOL saveSystemAblum;

/**
 拍摄的照片/视频保存到指定相册的名称  默认 BundleName
 (需9.0以上系统才可以保存到自定义相册 , 以下的系统只保存到相机胶卷...)
 */
@property (copy, nonatomic) NSString *customAlbumName;

/**
 *  视频能选择的最大秒数  -  默认 3分钟/180秒
 */
@property (assign, nonatomic) NSTimeInterval videoMaxDuration;

/**
 是否为单选模式 默认 NO
 会自动过滤掉gif、livephoto
 */
@property (assign, nonatomic) BOOL singleSelected;

/**
 单选模式下选择图片时是否直接跳转到编辑界面  - 默认 YES
 */
@property (assign, nonatomic) BOOL singleJumpEdit;

/**
 是否开启3DTouch预览功能 默认 YES
 */
@property (assign, nonatomic) BOOL open3DTouchPreview;

/**
 下载iCloud上的资源  默认YES
 */
@property (assign, nonatomic) BOOL downloadICloudAsset;

/**
 是否过滤iCloud上的资源 默认NO
 */
@property (assign, nonatomic) BOOL filtrationICloudAsset;

/**
 小图照片清晰度 越大越清晰、越消耗性能
 设置太大的话获取图片资源时耗时长且内存消耗大可能会引起界面卡顿
 default：[UIScreen mainScreen].bounds.size.width
 320    ->  0.8
 375    ->  1.4
 other  ->  1.7
 */
@property (assign, nonatomic) CGFloat clarityScale;

#pragma mark - < block返回的视图 >
/**
 设置导航栏
 */
@property (copy, nonatomic) void (^navigationBar)(UINavigationBar *navigationBar, UIViewController *viewController);

/**
 照片列表底部View
 */
@property (copy, nonatomic) void (^photoListBottomView)(HXDatePhotoBottomView *bottomView);

/**
 预览界面底部View
 */
@property (copy, nonatomic) void (^previewBottomView)(HXDatePhotoPreviewBottomView *bottomView);

/**
 相册列表的collectionView
 - 旋转屏幕时也会调用
 */
@property (copy, nonatomic) void (^albumListCollectionView)(UICollectionView *collectionView);

/**
 相册列表的tableView
 - 旋转屏幕时也会调用
 */
@property (copy, nonatomic) void (^albumListTableView)(UITableView *tableView);

/**
 弹窗样式的相册列表
 - 旋转屏幕时也会调用
 */
@property (copy, nonatomic) void (^popupAlbumTableView)(UITableView *tableView);

/**
 相片列表的collectionView
 - 旋转屏幕时也会调用
 */
@property (copy, nonatomic) void (^photoListCollectionView)(UICollectionView *collectionView);

/**
 预览界面的collectionView
 - 旋转屏幕时也会调用
 */
@property (copy, nonatomic) void (^previewCollectionView)(UICollectionView *collectionView);

@end
