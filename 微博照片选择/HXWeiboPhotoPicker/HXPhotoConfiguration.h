//
//  HXPhotoConfiguration.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/11/21.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    HXPhotoConfigurationCameraTypePhoto = 0,        // 拍照
    HXPhotoConfigurationCameraTypeVideo = 1,        // 录制
    HXPhotoConfigurationCameraTypeTypePhotoAndVideo     // 拍照和录制一起
} HXPhotoConfigurationCameraType;

@class HXDatePhotoBottomView;
@class HXDatePhotoPreviewBottomView;
@class HXPhotoManager;
@class HXPhotoModel;

@interface HXPhotoConfiguration : NSObject

/**
 视频是否可以编辑   default YES
 计划中...
 */
@property (assign, nonatomic) BOOL videoCanEdit;

/**
 是否替换照片编辑界面   default NO
 计划中...
 */
@property (assign, nonatomic) BOOL replacePhotoEditViewController;

/**
 是否替换视频编辑界面   default NO
 计划中...
 */
@property (assign, nonatomic) BOOL replaceVideoEditViewController;

/**
 完成按钮是否显示详情   default YES
 */
@property (assign, nonatomic) BOOL doneBtnShowDetail;

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
 小图照片清晰度 越大越清晰、越消耗性能
 设置太大的话获取图片资源时耗时长且内存消耗大可能会引起界面卡顿
 default：[UIScreen mainScreen].bounds.size.width
         320    ->  0.8
         375    ->  1.4
         other  ->  1.7
 */
@property (assign, nonatomic) CGFloat clarityScale;

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
 设置导航栏
 */
@property (copy, nonatomic) void (^navigationBar)(UINavigationBar *navigationBar);

/**
 headerSection 半透明毛玻璃效果  默认YES  ios9以上才有效果
 */
@property (assign, nonatomic) BOOL sectionHeaderTranslucent;

/**
 照片列表底部View
 */
@property (copy, nonatomic) void (^photoListBottomView)(HXDatePhotoBottomView *bottomView);

/**
 预览界面底部View
 */
@property (copy, nonatomic) void (^previewBottomView)(HXDatePhotoPreviewBottomView *bottomView);

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
 下载iCloud上的资源  默认YES
 */
@property (assign, nonatomic) BOOL downloadICloudAsset;

/**
 是否过滤iCloud上的资源 默认NO
 */
@property (assign, nonatomic) BOOL filtrationICloudAsset;

/**
 sectionHeader 是否显示照片的位置信息 默认 5、6不显示，其余的显示
 */
@property (assign, nonatomic) BOOL sectionHeaderShowPhotoLocation;

/**
 拍摄的照片/视频保存到指定相册的名称  默认 BundleName
 (需9.0以上系统才可以保存到自定义相册 , 以下的系统只保存到相机胶卷...)
 */
@property (copy, nonatomic) NSString *customAlbumName;

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

/**
 相机视频录制最大秒数  -  默认60s
 */
@property (assign, nonatomic) NSTimeInterval videoMaximumDuration;

/**
 *  删除临时的照片/视频 -
    注:相机拍摄的照片并没有保存到系统相册 或 是本地图片
    如果当这样的照片都没有被选中时会清空这些照片 有一张选中了就不会删..
    - 默认 YES
 */
@property (assign, nonatomic) BOOL deleteTemporaryPhoto;

/**
 *  拍摄的 照片/视频 是否保存到系统相册  默认NO
 *  支持添加到自定义相册 - (需9.0以上)
 */
@property (assign, nonatomic) BOOL saveSystemAblum;

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
 是否开启3DTouch预览功能 默认 YES
 */
@property (assign, nonatomic) BOOL open3DTouchPreview;

/**
 删除网络图片时是否显示Alert // 默认不显示
 */
@property (assign, nonatomic) BOOL showDeleteNetworkPhotoAlert;

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
 当选择类型为 HXPhotoManagerSelectedTypePhotoAndVideo 时 此属性为YES时 选择的视频会跟图片分开排  反之  视频和图片混合在一起排
 */
@property (assign, nonatomic) BOOL separate; // ---- 预留 

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
 图片和视频是否能够同时选择 默认支持
 */
@property (assign, nonatomic) BOOL selectTogether;

/**
 相册列表每行多少个照片 默认4个 iphone 4s / 5  默认3个
 */
@property (assign, nonatomic) NSInteger rowCount;

/**
 相册列表的collectionView
 - 旋转屏幕时也会调用
 */
@property (copy, nonatomic) void(^albumListCollectionView)(UICollectionView *collectionView);

/**
 相册列表的tableView
 - 旋转屏幕时也会调用
 */
@property (copy, nonatomic) void(^albumListTableView)(UITableView *tableView);

/**
 相片列表的collectionView
 - 旋转屏幕时也会调用
 */
@property (copy, nonatomic) void(^photoListCollectionView)(UICollectionView *collectionView);

/**
 预览界面的collectionView
 - 旋转屏幕时也会调用
 */
@property (copy, nonatomic) void(^previewCollectionView)(UICollectionView *collectionView);

@end
