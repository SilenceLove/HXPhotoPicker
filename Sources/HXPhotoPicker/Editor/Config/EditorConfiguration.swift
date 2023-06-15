//
//  EditorConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

public struct EditorConfiguration: IndicatorTypeConfig {
    
    public var modalPresentationStyle: UIModalPresentationStyle
    
    /// If the built-in language is not enough, you can add a custom language text
    /// PhotoManager.shared.customLanguages - custom language array
    /// PhotoManager.shared.fixedCustomLanguage - If there are multiple custom languages, one can be fixed to display
    /// 如果自带的语言不够，可以添加自定义的语言文字
    /// PhotoManager.shared.customLanguages - 自定义语言数组
    /// PhotoManager.shared.fixedCustomLanguage - 如果有多种自定义语言，可以固定显示某一种
    public var languageType: LanguageType = .system
    
    /// hide status bar
    /// 隐藏状态栏
    public var prefersStatusBarHidden: Bool = true
    
    /// Rotation is allowed, and rotation can only be disabled in full screen
    /// 允许旋转，全屏情况下才可以禁止旋转
    public var shouldAutorotate: Bool = true
    
    /// 是否自动返回
    public var isAutoBack: Bool = true
    
    /// supported directions
    /// 支持的方向
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask = .all
    
    /// 取消按钮的文字颜色
    public var cancelButtonTitleColor: UIColor = .white
    
    /// 完成按钮普通状态下的文字颜色
    public var finishButtonTitleNormalColor: UIColor = "#FDCC00".hx.color
    
    /// 完成按钮禁用状态下的文字颜色
    public var finishButtonTitleDisableColor: UIColor = "#FDCC00".hx.color.withAlphaComponent(0.6)
    
    /// 是否在未编辑状态下禁用完成按钮
    public var isWhetherFinishButtonDisabledInUneditedState: Bool = false
    
    /// 编辑之后的地址配置，默认在tmp下
    /// 每次编辑时请设置不同地址，防止之前存在的数据被覆盖
    /// 如果编辑的是GIF，请设置gif后缀的地址
    public var urlConfig: EditorURLConfig?
    
    /// 图片配置
    public lazy var photo: Photo = .init()
    
    /// 视频配置
    public lazy var video: Video = .init()
    
    /// 画笔
    public lazy var brush: Brush = .init()
    
    /// 贴图配置
    public lazy var chartlet: Chartlet = .init()
    
    /// 文本
    public lazy var text: Text = .init()
    
    /// 裁剪画面配置
    public lazy var cropSize: CropSize = .init()
    
    /// 马赛克配置
    public lazy var mosaic: Mosaic = .init()
    
    /// 固定裁剪状态
    public var isFixedCropSizeState: Bool = false
    
    /// 固定裁剪大小状态时忽略视频裁剪时间
    public var isIgnoreCropTimeWhenFixedCropSizeState: Bool = true
    
    /// 工具视图配置
    public lazy var toolsView: ToolsView = .default
    
    public init() {
        if #available(iOS 13.0, *) {
            modalPresentationStyle = .automatic
        } else {
            modalPresentationStyle = .fullScreen
        }
    }
}

public extension EditorConfiguration {
    
    struct Photo {
        
        /// 控制画笔、贴图...导出之后清晰程度
        public var scale: CGFloat = UIScreen.main.scale
        
        /// 默认选中指定工具
        public var defaultSelectedToolOption: ToolsView.Options.`Type`?
        
        /// 滤镜图片压缩比例
        public var filterScale: CGFloat = 0.5
        
        /// 滤镜配置
        public lazy var filter: Filter = .photoDefault
        
        public init() { }
    }
    
    struct Video {
        /// 视频导出的分辨率
        public var preset: ExportPreset = .ratio_960x540
        
        /// 视频导出的质量[0-10]
        public var quality: Int = 6
        
        /// 加载完成后自动播放
        public var isAutoPlay: Bool = true
        
        /// 默认选中指定工具
        public var defaultSelectedToolOption: ToolsView.Options.`Type`? = .time
        
        /// 音乐配置
        public var music: Music = .init()
        
        /// 裁剪时长配置
        public var cropTime: CropTime = .init()
        
        /// 滤镜配置
        public lazy var filter: Filter = .videoDefault
        
        public init() { }
        
        public struct CropTime {
            
            /// 视频最大裁剪时长
            /// > 0 视频时长超过时必须裁剪
            /// = 0 可不裁剪
            public var maximumTime: TimeInterval = 0
            
            /// 视频最小裁剪时长，最小1
            public var minimumTime: TimeInterval = 1
            
            /// 左右箭头正常状态下的颜色
            public var arrowNormalColor: UIColor = .white
            
            /// 左右箭头高亮状态下的颜色
            public var arrowHighlightedColor: UIColor = .black
            
            /// 边框高亮状态下的颜色
            public var frameHighlightedColor: UIColor = "#FDCC00".hx.color
            
            public init() { }
        }
    }
    
    struct Brush {
        /// 画笔颜色数组
        public var colors: [String] = PhotoTools.defaultColors()
        
        /// 默认画笔颜色索引
        public var defaultColorIndex: Int = 2
        
        /// 初始画笔宽度
        public var lineWidth: CGFloat = 5
        
        /// 画笔最大宽度
        public var maximumLinewidth: CGFloat = 20
        
        /// 画笔最小宽度
        public var minimumLinewidth: CGFloat = 2
        
        /// 显示画笔尺寸大小滑动条
        public var showSlider: Bool = true
        
        /// 添加自定义颜色 - iOS 14+
        public var addCustomColor: Bool = true
        
        /// 自定义默认颜色 - iOS 14+
        public var customDefaultColor: UIColor = "#9EB6DC".hx.color
        
        /// 绘制时隐藏贴图视图
        public var isHideStickersDuringDrawing: Bool = true
        
        public init() { }
    }
    
    struct CropSize {
        
        /// 角度刻度滑动时的线条颜色
        public var angleScaleColor: UIColor = "#FDCC00".hx.color
        
        /// 圆形裁剪框
        /// isResetToOriginal = true，可以避免重置时恢复原始宽高
        public var isRoundCrop: Bool = false
        
        /// 默认固定比例
        /// ```
        /// /// 如果不想要底部其他的比例请将`aspectRatios`置空
        /// aspectRatios = []
        /// ```
        public var isFixedRatio: Bool = false
        
        /// 默认宽高比
        public var aspectRatio: CGSize = .zero
        
        /// 裁剪时遮罩类型
        public var maskType: EditorView.MaskType = .blurEffect(style: .dark)
        
        /// 显示比例大小
        public var isShowScaleSize: Bool = true
        
        /// 宽高比数组默认选择的下标
        /// 选中不代表默认就是对应的宽高比
        /// ```
        /// // 如果想要默认对应的宽高比也要设置 `aspectRatio`
        /// var cropSize = CropSize()
        /// // 默认选中 2
        /// cropSize.defaultSeletedIndex = 2
        /// // 默认的宽高比也要设置与之对应的比例，这样进入裁剪的时候默认就是设置的样式
        /// cropSize.aspectRatio = .init(width: 1, height: 1)
        /// // 固定宽高比
        /// cropSize.isFixedRatio = true
        /// // 点击还原重置到原始宽高比
        /// cropSize.isResetToOriginal = true
        /// ```
        public var defaultSeletedIndex: Int = 1
        
        /// 宽高比配置
        public var aspectRatios: [EditorRatioToolConfig] = [
            .init(title: "原始比例".localized, ratio: .init(width: -1, height: -1)),
            .init(title: "自由格式".localized, ratio: .zero),
            .init(title: "正方形".localized, ratio: .init(width: 1, height: 1)),
            .init(title: "16:9", ratio: .init(width: 16, height: 9)),
            .init(title: "5:4", ratio: .init(width: 5, height: 4)),
            .init(title: "7:5", ratio: .init(width: 7, height: 5)),
            .init(title: "4:3", ratio: .init(width: 4, height: 3)),
            .init(title: "5:3", ratio: .init(width: 5, height: 3)),
            .init(title: "3:2", ratio: .init(width: 3, height: 2))
        ]
        
        /// 当默认固定比例时，点击还原是否重置到原始宽高比
        /// true：重置到原始宽高比
        /// false：重置到设置的默认宽高比`aspectRatio`，居中显示
        public var isResetToOriginal: Bool = false
        
        /// 蒙版素材列表
        public var maskList: [MaskType] = []
        
        /// 蒙版素材每行显示数量
        public var maskRowCount: CGFloat = 4
        
        /// 蒙版素材横屏时每行显示数量
        public var maskLandscapeRowNumber: CGFloat = 8
        
        public enum MaskType {
            case text(String, UIFont)
            case image(UIImage)
            case imageName(String)
        }
        
        public init() { } 
    }
    
    struct Text {
        /// 文本颜色数组
        public var colors: [String] = PhotoTools.defaultColors()
        /// 文本光标颜色
        public var tintColor: UIColor = "#FDCC00".hx.color
        /// 确定按钮文字颜色
        public var doneTitleColor: UIColor = "#FDCC00".hx.color
        /// 确定按钮背景颜色
        public var doneBackgroundColor: UIColor = .clear
        /// 文本字体
        public var font: UIFont = .boldSystemFont(ofSize: 25)
        /// 最大字数限制，0为不限制
        public var maximumLimitTextLength: Int = 0
        /// 文本视图推出样式
        public var modalPresentationStyle: UIModalPresentationStyle
        
        public init() {
            if #available(iOS 13.0, *) {
                self.modalPresentationStyle = .automatic
            }else {
                self.modalPresentationStyle = .fullScreen
            }
        }
    }
    
    struct Mosaic {
        /// 生成马赛克的大小
        public var mosaicWidth: CGFloat = 20
        /// 涂鸦时马赛克的线宽
        public var mosaiclineWidth: CGFloat = 25
        /// 涂抹的宽度
        public var smearWidth: CGFloat = 30
        
        /// 绘制时隐藏贴图视图
        public var isHideStickersDuringDrawing: Bool = true
        
        public init() { }
    }
    
    struct Filter {
        /// 滤镜信息
        public var infos: [PhotoEditorFilterInfo]
        
        /// 滤镜选中颜色
        public var selectedColor: UIColor
        
        /// 标识符，再次编辑时用于展示上次滤镜效果
        public var identifier: String
        
        public init(
            infos: [PhotoEditorFilterInfo] = [],
            selectedColor: UIColor = "#FDCC00".hx.color,
            identifier: String = ""
        ) {
            self.infos = infos
            self.selectedColor = selectedColor
            self.identifier = identifier
        }
        
        public static var videoDefault: Filter {
            .init(infos: PhotoTools.defaultVideoFilters(), identifier: "hx_editor_default")
        }
        
        public static var photoDefault: Filter {
            .init(infos: PhotoTools.defaultFilters(), identifier: "hx_editor_default")
        }
    }
    
    struct Music {
        /// 显示搜索
        public var showSearch: Bool = true
        /// 搜索框光标颜色
        public var tintColor: UIColor = "#FDCC00".hx.color
        /// 完成按钮文字颜色
        public var finishButtonTitleColor: UIColor = "#FDCC00".hx.color
        /// 完成按钮背景颜色
        public var finishButtonBackgroundColor: UIColor = .clear
        /// 搜索框的 placeholder
        public var placeholder: String = ""
        /// 滚动停止时自动播放音乐
        public var autoPlayWhenScrollingStops: Bool = false
        /// 配乐信息 / 搜索列表默认的第一页
        /// 也可通过代理回调设置
        /// func videoEditorViewController(
        /// _ videoEditorViewController: VideoEditorViewController,
        ///  loadMusic completionHandler: @escaping ([VideoEditorMusicInfo]) -> Void) -> Bool
        public var infos: [VideoEditorMusicInfo] = []
        
        /// 获取音乐列表, infos 为空时才会触发
        /// handler = { response -> Bool in
        ///     // 传入音乐数据
        ///     response(self.getMusics())
        ///     // 是否显示loading
        ///     return false
        /// }
        public var handler: ((@escaping ([VideoEditorMusicInfo]) -> Void) -> Bool)?
        
        public init() { }
    }
    
    struct Chartlet {
        public enum LoadScene {
            /// cell显示时
            case cellDisplay
            /// 滚动停止时
            case scrollStop
        }
        /// 每行显示个数
        public var rowCount: Int = UIDevice.isPad ? 6 : 5
        /// 贴图加载时机
        public var loadScene: LoadScene = .cellDisplay
        /// 贴图标题
        public var titles: [EditorChartlet] = []
        
        #if HXPICKER_ENABLE_PICKER
        /// 是否允许添加 从相册选取
        public var allowAddAlbum: Bool = true
        /// 相册图标
        public var albumImageName: String = "hx_editor_tools_chartle_album"
        /// 相册配置
        public var albumPickerConfigHandler: (() -> PickerConfiguration)?
        #endif
        
        /// 加载标题, titles 为空时才会触发
        /// titleHandler = { response in
        ///     // 传入标题数据
        ///     response(self.getChartletTitles())
        /// }
        public var titleHandler: ((@escaping EditorTitleChartletResponse) -> Void)?
        
        /// 加载贴图列表
        /// listHandler = { titleIndex, response in
        ///     // 传入标题下标，对应标题下的贴纸数据
        ///     response(titleIndex, self.getChartlets())
        /// }
        public var listHandler: ((Int, @escaping EditorChartletListResponse) -> Void)?
        
        public init() { }
    }

    
    struct ToolsView {
        /// 工具栏item选项
        public var toolOptions: [Options]
        
        /// 工具栏选项选中颜色
        public var toolSelectedColor: UIColor = "#FDCC00".hx.color
        
        /// 配乐选中之后勾 颜色
        public var musicTickColor: UIColor = "#222222".hx.color
        /// 配乐选中时框框背景颜色
        public var musicTickBackgroundColor: UIColor = "#FDCC00".hx.color
        
        public init(toolOptions: [Options] = []) {
            self.toolOptions = toolOptions
        }
        
        public struct Options {
            
            /// icon图标
            public let imageName: String
            
            /// 类型
            public let type: `Type`
            
            public init(imageName: String,
                        type: `Type`) {
                self.imageName = imageName
                self.type = type
            }
            
            /// 编辑工具
            public enum `Type` {
                
                /// video - 播放、时长裁剪
                case time
                
                /// 涂鸦
                case graffiti
                
                /// 贴图
                case chartlet
                
                /// 文本
                case text
                
                /// photo - 马赛克
                case mosaic
                
                /// 画面调整
                case filterEdit
                
                /// 滤镜
                case filter
                
                /// video - 配乐
                case music
                
                /// 尺寸裁剪
                case cropSize
            }
        }
        
        
        public static var `default`: ToolsView {
            let time = Options(
                imageName: "hx_editor_tools_play",
                type: .time
            )
            let graffiti = Options(
                imageName: "hx_editor_tools_graffiti",
                type: .graffiti
            )
            let chartlet = Options(
                imageName: "hx_editor_photo_tools_emoji",
                type: .chartlet
            )
            let text = Options(
                imageName: "hx_editor_photo_tools_text",
                type: .text
            )
            let cropSize = Options(
                imageName: "hx_editor_photo_crop",
                type: .cropSize
            )
            let music = Options(
                imageName: "hx_editor_tools_music",
                type: .music
            )
            let mosaic = Options(
                imageName: "hx_editor_tools_mosaic",
                type: .mosaic
            )
            let filterEdit = Options(
                imageName: "hx_editor_tools_filter_change",
                type: .filterEdit
            )
            let filter = Options(
                imageName: "hx_editor_tools_filter",
                type: .filter
            )
            return .init(toolOptions: [time, graffiti, chartlet, text, music, cropSize, mosaic, filterEdit, filter])
        }
    }
} 
