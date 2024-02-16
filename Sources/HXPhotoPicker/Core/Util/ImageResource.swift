//
//  ImageResource.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/1/30.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

public extension HX {
    
    static var imageResource: ImageResource { .shared }
    
    class ImageResource {
        public static let shared = ImageResource()
        
        #if HXPICKER_ENABLE_PICKER
        /// 选择器
        public var picker: Picker = .init()
        #endif
        
        #if HXPICKER_ENABLE_EDITOR || HXPICKER_ENABLE_EDITOR_VIEW
        /// 编辑器
        public var editor: Editor = .init()
        #endif
        
        #if HXPICKER_ENABLE_CAMERA
        /// 相机
        public var camera: Camera = .init()
        #endif
    }
}

public extension HX.ImageResource {
    
    #if HXPICKER_ENABLE_PICKER
    struct Picker {
        /// 相册列表
        public var albumList: AlbumList = .init()
        /// 照片列表
        public var photoList: PhotoList = .init()
        /// 预览界面
        public var preview: Preview = .init()
        /// 未授权界面
        public var notAuthorized: NotAuthorized = .init()
        
        public struct NotAuthorized {
            /// 未授权界面的关闭按钮
            public var close: String = "hx_picker_notAuthorized_close"
            /// 未授权界面暗黑模式下的关闭按钮
            public var closeDark: String = "hx_picker_notAuthorized_close_dark"
        }
        
        public struct AlbumList {
            /// 相册为空时的封面图片
            var emptyCover: String = "hx_picker_album_empty"
            
            var cell: Cell = .init()
            
            struct Cell {
                /// cell箭头
                var arrow: String = "hx_picker_photolist_bottom_prompt_arrow"
            }
        }
        
        public struct PhotoList {
            /// 取消按钮
            public var cancel: String = "hx_picker_photolist_cancel"
            /// 暗黑模式下的取消按钮
            public var cancelDark: String = "hx_picker_photolist_cancel"
            
            /// 筛选按钮正常状态
            public var filterNormal: String = "hx_picker_photolist_nav_filter_normal"
            /// 筛选按钮选中状态
            public var filterSelected: String = "hx_picker_photolist_nav_filter_selected"
            /// 筛选界面
            public var filter: Filter = .init()
            
            public var cell: Cell = .init()
            
            public var bottomView: BottomView = .init()
            
            public struct Cell {
                /// 视频图标
                public var video: String = "hx_picker_cell_video_icon"
                /// 已编辑照片图标
                public var photoEdited: String = "hx_picker_cell_photo_edit_icon"
                /// 已编辑视频图标
                public var videoEdited: String = "hx_picker_cell_video_edit_icon"
                /// iCloud图标
                public var iCloud: String = "hx_picker_photo_icloud_mark"
                
                /// 相机图标
                public var camera: String = "hx_picker_photoList_photograph"
                /// 暗黑模式下的相机图标
                public var cameraDark: String = "hx_picker_photoList_photograph_white"
            }
            
            public struct Filter {
                /// 所有项目图标
                public var any: String = "hx_photo_list_filter_any"
                /// 已编辑图标
                public var edited: String = "hx_photo_list_filter_edited"
                /// 照片图标
                public var photo: String = "hx_photo_list_filter_photo"
                /// 动图图标
                public var gif: String = "hx_photo_list_filter_gif"
                /// 实况图标
                public var livePhoto: String = "hx_photo_list_filter_livePhoto"
                /// 视频图标
                public var video: String = "hx_photo_list_filter_video"
            }
            
            public struct BottomView {
                /// 相册权限提示图标
                public var permissionsPrompt: String = "hx_picker_photolist_bottom_prompt"
                /// 相册权限跳转箭头图标
                public var permissionsArrow: String = "hx_picker_photolist_bottom_prompt_arrow"
                
                /// 已选列表删除图标
                public var delete: String = "hx_picker_toolbar_select_cell_delete"
            }
        }
        
        public struct Preview {
            /// 返回图标
            public var back: String = "hx_picker_photolist_back"
            /// 取消图标
            public var cancel: String = "hx_picker_photolist_cancel"
            /// 暗黑模式下的取消按钮
            public var cancelDark: String = "hx_picker_photolist_cancel"
            /// 播放视频图标
            public var videoPlay: String = "hx_picker_cell_video_play"
            /// 实况图片标签图标
            public var livePhoto: String = "hx_picker_livePhoto"
        }
    }
    #endif

    #if HXPICKER_ENABLE_EDITOR || HXPICKER_ENABLE_EDITOR_VIEW
    struct Editor {
        /// 工具栏
        public var tools: Tools = .init()
        /// 视频裁剪
        public var video: Video = .init()
        /// 画笔
        public var brush: Brush = .init()
        /// 尺寸裁剪
        public var crop: Crop = .init()
        /// 文本
        public var text: Text = .init()
        /// 贴纸
        public var sticker: Sticker = .init()
        /// 配乐
        public var music: Music = .init()
        /// 马赛克/涂抹
        public var mosaic: Mosaic = .init()
        /// 画面调整
        public var adjustment: Adjustment = .init()
        /// 滤镜
        public var filter: Filter = .init()
        
        public struct Tools {
            /// 视频
            public var video: String = "hx_editor_tools_play"
            /// 画笔绘制
            public var graffiti: String = "hx_editor_tools_graffiti"
            /// 旋转、裁剪
            public var cropSize: String = "hx_editor_photo_crop"
            /// 文本
            public var text: String = "hx_editor_photo_tools_text"
            /// 贴图
            public var chartlet: String = "hx_editor_photo_tools_emoji"
            /// 马赛克-涂抹
            public var mosaic: String = "hx_editor_tools_mosaic"
            /// 画面调整
            public var adjustment: String = "hx_editor_tools_filter_change"
            /// 滤镜
            public var filter: String = "hx_editor_tools_filter"
            /// 配乐
            public var music: String = "hx_editor_tools_music"
        }
        
        public struct Brush {
            /// 画笔自定义颜色
            public var customColor: String = "hx_editor_brush_color_custom"
            /// 撤销
            public var undo: String = "hx_editor_brush_repeal"
            /// 画布-撤销
            public var canvasUndo: String = "hx_editor_canvas_draw_undo"
            /// 画布-反撤销
            public var canvasRedo: String = "hx_editor_canvas_draw_redo"
            /// 画布-清空
            public var canvasUndoAll: String = "hx_editor_canvas_draw_undo_all"
        }
        
        public struct Crop {
            /// 选中原始比例时， 垂直比例-正常状态
            public var ratioVerticalNormal: String = "hx_editor_crop_scale_switch_left"
            /// 选中原始比例时， 垂直比例-选中状态
            public var ratioVerticalSelected: String = "hx_editor_crop_scale_switch_left_selected"
            /// 选中原始比例时， 横向比例-正常状态
            public var ratioHorizontalNormal: String = "hx_editor_crop_scale_switch_right"
            /// 选中原始比例时， 横向比例-选中状态
            public var ratioHorizontalSelected: String = "hx_editor_crop_scale_switch_right_selected"
            /// 水平镜像
            public var mirrorHorizontally: String = "hx_editor_photo_mirror_horizontally"
            /// 垂直镜像
            public var mirrorVertically: String = "hx_editor_photo_mirror_vertically"
            /// 向左旋转
            public var rotateLeft: String = "hx_editor_photo_rotate_left"
            /// 向右旋转
            public var rotateRight: String = "hx_editor_photo_rotate_right"
            
            /// 自定义蒙版
            public var maskList: String = "hx_editor_crop_mask_list"
        }
        
        public struct Text {
            /// 文字背景-正常状态
            public var backgroundNormal: String = "hx_editor_photo_text_normal"
            /// 文字背景-选中状态
            public var backgroundSelected: String = "hx_editor_photo_text_selected"
            /// 文本自定义颜色
            public var customColor: String = "hx_editor_brush_color_custom"
        }
        
        public struct Sticker {
            /// 返回按钮
            public var back: String = "hx_photo_edit_pull_down"
            /// 跳转相册按钮
            public var album: String = "hx_editor_tools_chartle_album"
            /// 相册为空时的封面图片
            public var albumEmptyCover: String = "hx_picker_album_empty"
            /// 贴纸删除按钮
            public var delete: String = "hx_editor_view_sticker_item_delete"
            /// 贴纸旋转按钮
            public var rotate: String = "hx_editor_view_sticker_item_rotate"
            /// 贴纸缩放按钮
            public var scale: String = "hx_editor_view_sticker_item_scale"
            /// 拖拽底部删除垃圾桶打开状态
            public var trashOpen: String = "hx_editor_photo_trash_open"
            /// 拖拽底部删除垃圾桶关闭状态
            public var trashClose: String = "hx_editor_photo_trash_close"
        }
        
        public struct Adjustment {
            /// 亮度
            public var brightness: String = "hx_editor_filter_edit_brightness"
            /// 对比度
            public var contrast: String = "hx_editor_filter_edit_contrast"
            /// 曝光度
            public var exposure: String = "hx_editor_filter_edit_exposure"
            /// 高光
            public var highlights: String = "hx_editor_filter_edit_highlights"
            /// 饱和度
            public var saturation: String = "hx_editor_filter_edit_saturation"
            /// 阴影
            public var shadows: String = "hx_editor_filter_edit_shadows"
            /// 锐化
            public var sharpen: String = "hx_editor_filter_edit_sharpen"
            /// 暗角
            public var vignette: String = "hx_editor_filter_edit_vignette"
            /// 色温
            public var warmth: String = "hx_editor_filter_edit_warmth"
        }
        
        public struct Filter {
            /// 编辑
            public var edit: String = "hx_editor_tools_filter_edit"
        }
        
        public struct Mosaic {
            /// 撤销
            public var undo: String = "hx_editor_brush_repeal"
            /// 马赛克
            public var mosaic: String = "hx_editor_tool_mosaic_normal"
            /// 涂抹
            public var smear: String = "hx_editor_tool_mosaic_color"
            /// 每次涂抹的图片
            public var smearMask: String = "hx_editor_mosaic_brush_image"
        }
        
        public struct Music {
            /// 搜索图标
            public var search: String = "hx_editor_video_music_search"
            /// 音量图标
            public var volum: String = "hx_editor_video_music_volume"
            /// 选择框-未选中
            public var selectionBoxNormal: String = "hx_editor_box_normal"
            /// 选择框-选中
            public var selectionBoxSelected: String = "hx_editor_box_selected"
        }
        
        public struct Video {
            /// 播放
            public var play: String = "hx_editor_video_control_play"
            /// 暂停
            public var pause: String = "hx_editor_video_control_pause"
            /// 左边箭头
            public var leftArrow: String = "hx_editor_video_control_arrow_left"
            /// 右边箭头
            public var rightArrow: String = "hx_editor_video_control_arrow_right"
        }
    }
    #endif

    #if HXPICKER_ENABLE_CAMERA
    struct Camera {
        /// 底部返回
        public var back: String = "hx_camera_down_back"
        
        /// 相机切换
        public var switchCamera: String = "hx_camera_overturn"
    }
    #endif
}
