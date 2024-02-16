//
//  TextManager.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/2/4.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

public extension HX {
    
    static var textManager: TextManager { .shared }
    
    class TextManager {
        public static let shared = TextManager()
        
        #if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_CAMERA
        /// 选择器
        public var picker: Picker = .init()
        /// 相机
        public var camera: Camera = .init()
        public var cameraNotAuthorized: CameraNotAuthorized = .init()
        #endif
        
        #if HXPICKER_ENABLE_EDITOR || HXPICKER_ENABLE_EDITOR_VIEW
        /// 编辑器
        public var editor: Editor = .init()
        #endif
    }
}

public extension HX.TextManager {
    
    enum TextType {
        /// 内部本地化
        case localized(String)
        /// 直接显示，不本地化
        case custom(String)
        
        var text: String {
            switch self {
            case .localized(let text):
                return text.localized
            case .custom(let text):
                return text
            }
        }
    }
    
    #if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_CAMERA
    struct Picker {
        /// 相册未授权
        public var notAuthorized: NotAuthorized = .init()
        
        /// 相册列表、照片列表界面导航栏的取消按钮
        public var navigationCancelTitle: TextType = .localized("取消")
        public var navigationCancelTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 17)
        
        public var photoTogetherSelectHudTitle: TextType = .localized("照片和视频不能同时选择")
        public var videoTogetherSelectHudTitle: TextType = .localized("视频和照片不能同时选择")
        public var maximumSelectedPhotoHudTitle: TextType = .localized("最多只能选择%d张照片")
        public var maximumSelectedVideoHudTitle: TextType = .localized("最多只能选择%d个视频")
        public var maximumSelectedHudTitle: TextType = .localized("已达到最大选择数")
        public var maximumSelectedVideoDurationHudTitle: TextType = .localized("视频最大时长为%d秒，无法选择")
        public var minimumSelectedVideoDurationHudTitle: TextType = .localized("视频最小时长为%d秒，无法选择")
        public var maximumVideoEditDurationHudTitle: TextType = .localized("视频可编辑最大时长为%d秒，无法编辑")
        public var maximumSelectedPhotoFileSizeHudTitle: TextType = .localized("照片大小超过最大限制")
        public var maximumSelectedVideoFileSizeHudTitle: TextType = .localized("视频大小超过最大限制")
        
        public var albumList: AlbumList = .init()
        public var photoList: PhotoList = .init()
        public var preview: Preview = .init()
        
        public var browserDeleteTitle: TextType = .localized("删除")
        
        public struct NotAuthorized {
            public var title: TextType = .localized("无法访问相册中照片")
            public var titleFont: UIFont = HXPickerWrapper<UIFont>.semiboldPingFang(ofSize: 20)
            public var subTitle: TextType = .localized("当前无照片访问权限，建议前往系统设置，\n允许访问「照片」中的「所有照片」。")
            public var subTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
            public var buttonTitle: TextType = .localized("前往系统设置")
            public var buttonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 16)
            
            /// 相册未授权时Alert弹出的内容
            public var alertTitle: TextType = .localized("无法访问相册中照片")
            public var alertMessage: TextType = .localized("当前无照片访问权限，建议前往系统设置，\n允许访问「照片」中的「所有照片」。")
            public var alertLeftTitle: TextType = .localized("取消")
            public var alertRightTitle: TextType = .localized("前往系统设置")
        }
        
        public struct AlbumList {
            public var backTitle: TextType = .localized("返回")
            public var navigationTitle: TextType = .localized("相册")
            public var selectNavigationTitle: TextType = .localized("选择相册")
            public var permissionsTitle: TextType = .localized("只能查看允许访问的照片和相关相册")
            public var permissionsTitleFont: UIFont = .systemFont(ofSize: 14)
            public var myAlbumSectionTitle: TextType = .localized("我的相册")
            public var mediaSectionTitle: TextType = .localized("媒体类型")
            public var lookAllSectionTitle: TextType = .localized("查看全部")
            public var emptyAlbumName: TextType = .localized("所有照片")
            
            public var myAlbumNavigationTitle: TextType = .localized("我的相册")
        }
        
        public struct PhotoList {
            
            public var emptyNavigationTitle: TextType = .localized("照片")
            
            public var cell: Cell = .init()
            public var filter: Filter = .init()
            public var bottomView: BottomView = .init()
            
            public var filterBottomTitle: TextType = .localized("筛选条件")
            public var filterBottomEmptyItemTitle: TextType = .localized("没有项目")
            
            public var hapticTouchSelectedTitle: TextType = .localized("选择")
            public var hapticTouchDeselectedTitle: TextType = .localized("取消选择")
            public var hapticTouchEditTitle: TextType = .localized("编辑")
            public var hapticTouchRemoveEditTitle: TextType = .localized("清空已编辑的内容")
            
            public var emptyTitle: TextType = .localized("没有照片")
            public var emptyTitleFont: UIFont = HXPickerWrapper<UIFont>.semiboldPingFang(ofSize: 20)
            public var emptySubTitle: TextType = .localized("你可以使用相机拍些照片")
            public var emptySubTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 16)
            
            public var videoExportFailedHudTitle: TextType = .localized("视频导出失败")
            public var saveSystemAlbumFailedHudTitle: TextType = .localized("保存失败")
            public var cameraUnavailableHudTitle: TextType = .localized("相机不可用!")
            
            public var iCloudSyncHudTitle: TextType = .localized("正在同步iCloud")
            public var iCloudSyncFailedHudTitle: TextType = .localized("iCloud同步失败")
            
            public var pageAllTitle: TextType = .localized("全部")
            public var pagePhotoTitle: TextType = .localized("照片")
            public var pageVideoTitle: TextType = .localized("视频")
            public var pageGifTitle: TextType = .custom("GIF")
            public var pageLivePhotoTitle: TextType = .custom("LivePhoto")
            
            public struct Filter {
                public var title: TextType = .localized("筛选")
                public var finishTitle: TextType = .localized("完成")
                
                public var sectionTitle: TextType = .localized("仅显示")
                public var anyTitle: TextType = .localized("所有项目")
                public var editedTitle: TextType = .localized("已编辑")
                public var photoTitle: TextType = .localized("筛选照片")
                public var gifTitle: TextType = .custom("GIF")
                public var livePhotoTitle: TextType = .custom("LivePhoto")
                public var videoTitle: TextType = .localized("筛选视频")
                
                public var bottomTitle: TextType = .localized("筛选结果")
                public var bottomEmptyTitle: TextType = .localized("无筛选条件")
                public var bottomTitleFont: UIFont = .systemFont(ofSize: 12)
            }
            
            public struct Cell {
                public var gifTitle: TextType = .custom("GIF")
                public var LivePhotoTitle: TextType = .custom("Live")
            }
        }
        
        public struct Preview {
            public var cancelTitle: TextType = .localized("取消")
            public var emptyAssetHudTitle: TextType = .localized("没有可选资源")
            public var downloadFailedHudTitle: TextType = .localized("下载失败")
            public var iCloudSyncHudTitle: TextType = .localized("正在同步iCloud")
            public var iCloudSyncFailedHudTitle: TextType = .localized("iCloud同步失败")
            public var videoLoadFailedHudTitle: TextType = .localized("视频加载失败!")
            public var bottomView: BottomView = .init()
        }
        
        public struct BottomView {
            public var permissionsTitle: TextType = .localized("无法访问相册中所有照片，\n请允许访问「照片」中的「所有照片」")
            public var permissionsTitleFont: UIFont = .systemFont(ofSize: 15)
            public var finishTitle: TextType = .localized("完成")
            public var finishTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 16)
            public var previewTitle: TextType = .localized("预览")
            public var previewTitleFont: UIFont = .systemFont(ofSize: 17)
            public var editTitle: TextType = .localized("编辑")
            public var editTitleFont: UIFont = .systemFont(ofSize: 17)
            public var originalTitle: TextType = .localized("原图")
            public var originalTitleFont: UIFont = .systemFont(ofSize: 17)
        }
    }
    #endif
    
    #if HXPICKER_ENABLE_EDITOR || HXPICKER_ENABLE_EDITOR_VIEW
    struct Editor {
        public var tools: Tools = .init()
        public var brush: Tools = .init()
        public var text: Text = .init()
        public var sticker: Sticker = .init()
        public var crop: Crop = .init()
        public var music: Music = .init()
        public var adjustment: Adjustment = .init()
        public var filter: Filter = .init()
        
        public var iCloudSyncHudTitle: TextType = .localized("正在同步iCloud")
        public var loadFailedAlertTitle: TextType = .localized("提示")
        public var photoLoadFailedAlertMessage: TextType = .localized("图片获取失败!")
        public var videoLoadFailedAlertMessage: TextType = .localized("视频获取失败!")
        public var iCloudSyncFailedAlertMessage: TextType = .localized("iCloud同步失败")
        public var loadFailedAlertDoneTitle: TextType = .localized("确定")
        public var processingHUDTitle: TextType = .localized("正在处理...")
        public var processingFailedHUDTitle: TextType = .localized("处理失败")
        
        public struct Tools {
            public var cancelTitle: TextType = .localized("取消")
            public var cancelTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
            public var finishTitle: TextType = .localized("完成")
            public var finishTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
            public var resetTitle: TextType = .localized("还原")
            public var resetTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
        }
        
        public struct Brush {
            public var cancelTitle: TextType = .localized("取消")
            public var cancelTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
            public var finishTitle: TextType = .localized("完成")
            public var finishTitleFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 17)
        }
        
        public struct Text {
            public var cancelTitle: TextType = .localized("取消")
            public var cancelTitleFont: UIFont = .systemFont(ofSize: 17)
            public var finishTitle: TextType = .localized("完成")
            public var finishTitleFont: UIFont = .systemFont(ofSize: 17)
        }
        
        public struct Sticker {
            public var trashCloseTitle: TextType = .localized("拖动到此处删除")
            public var trashOpenTitle: TextType = .localized("松手即可删除")
        }
        
        public struct Crop {
            public var maskListTitle: TextType = .localized("蒙版素材")
            public var maskListFinishTitle: TextType = .localized("完成")
            public var maskListFinishTitleFont: UIFont = .systemFont(ofSize: 17)
            
        }
        
        public struct Music {
            public var emptyHudTitle: TextType = .localized("暂无配乐")
            public var lyricEmptyTitle: TextType = .localized("此歌曲暂无歌词，请您欣赏")
            
            public var searchButtonTitle: TextType = .localized("搜索")
            public var searchButtonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 14) 
            public var volumeButtonTitle: TextType = .localized("音量")
            public var volumeButtonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 14)
            public var volumeMusicButtonTitle: TextType = .localized("配乐")
            public var volumeMusicButtonTitleFont: UIFont = .systemFont(ofSize: 15)
            public var volumeOriginalButtonTitle: TextType = .localized("视频原声")
            public var volumeOriginalButtonTitleFont: UIFont = .systemFont(ofSize: 15)
            
            public var musicButtonTitle: TextType = .localized("配乐")
            public var musicButtonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 16)
            public var originalButtonTitle: TextType = .localized("视频原声")
            public var originalButtonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 16)
            public var lyricButtonTitle: TextType = .localized("歌词")
            public var lyricButtonTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 16)
            
            public var listTitle: TextType = .localized("背景音乐")
            public var finishTitle: TextType = .localized("完成")
            public var finishTitleFont: UIFont = .systemFont(ofSize: 17)
            public var searchPlaceholder: TextType = .localized("搜索歌名")
            public var searchPlaceholderFont: UIFont = .systemFont(ofSize: 17)
        }
        
        public struct Adjustment {
            public var brightnessTitle: TextType = .localized("亮度")
            public var contrastTitle: TextType = .localized("对比度")
            public var exposureTitle: TextType = .localized("曝光度")
            public var saturationTitle: TextType = .localized("饱和度")
            public var warmthTitle: TextType = .localized("色温")
            public var vignetteTitle: TextType = .localized("暗角")
            public var sharpenTitle: TextType = .localized("锐化")
            public var highlightsTitle: TextType = .localized("高光")
            public var shadowsTitle: TextType = .localized("阴影")
        }
        
        public struct Filter {
            public var originalPhotoTitle: TextType = .localized("原图")
            public var originalVideoTitle: TextType = .localized("原片")
            
            public var nameFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 13)
            public var parameterFont: UIFont = HXPickerWrapper<UIFont>.regularPingFang(ofSize: 11)
        }
    }
    #endif
    
    #if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_CAMERA
    struct Camera {
        
        public var unavailableTitle: TextType = .localized("相机不可用!")
        public var unavailableDoneTitle: TextType = .localized("确定")
        
        public var failedTitle: TextType = .localized("相机初始化失败!")
        public var failedDoneTitle: TextType = .localized("确定")
        
        public var switchCameraFailedTitle: TextType = .localized("摄像头切换失败!")
        public var audioInputFailedTitle: TextType = .localized("麦克风添加失败，录制视频会没有声音哦!")
        public var saveSystemAlbumFailedHudTitle: TextType = .localized("保存失败")
        
        public var capturePhotoTitle: TextType = .localized("照片")
        public var captureVideoTitle: TextType = .localized("视频")
        public var captureFailedHudTitle: TextType = .localized("拍摄失败!")
        public var capturePhotoTipTitle: TextType = .localized("轻触拍照")
        public var captureVideoTipTitle: TextType = .localized("按住摄像")
        public var captureVideoClickTipTitle: TextType = .localized("点击摄像")
        public var captureTipTitle: TextType = .localized("轻触拍照，按住摄像")
        
        public var resultFinishTitle: TextType = .localized("完成")
        public var resultFinishTitleFont: UIFont = HXPickerWrapper<UIFont>.mediumPingFang(ofSize: 16)
        
        public var notAuthorized: NotAuthorized = .init()
        
        public struct NotAuthorized {
            /// 麦克风未授权时Alert弹出的内容
            public var audioTitle: TextType = .localized("无法使用麦克风")
            public var audioMessage: TextType = .localized("请在设置-隐私-相机中允许访问麦克风")
            public var audioLeftTitle: TextType = .localized("取消")
            public var audioRightTitle: TextType = .localized("前往系统设置")
        }
    }
    #endif
    
    #if HXPICKER_ENABLE_PICKER || HXPICKER_ENABLE_CAMERA
    struct CameraNotAuthorized {
        /// 相机未授权时Alert弹出的内容
        public var title: TextType = .localized("无法使用相机功能")
        public var message: TextType = .localized("请前往系统设置中，允许访问「相机」。")
        public var leftTitle: TextType = .localized("取消")
        public var rightTitle: TextType = .localized("前往系统设置")
    }
    #endif
}

