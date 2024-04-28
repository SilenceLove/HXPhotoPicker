//
//  EditorConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

public struct EditorConfiguration: IndicatorTypeConfig, PhotoHUDConfig {
    
    /// 图片资源
    public var imageResource: HX.ImageResource { HX.ImageResource.shared }
    
    /// 文本管理
    public var textManager: HX.TextManager { HX.TextManager.shared }
    
    public var modalPresentationStyle: UIModalPresentationStyle
    
    /// If the built-in language is not enough, you can add a custom language text
    /// customLanguages - custom language array
    /// 如果自带的语言不够，可以添加自定义的语言文字
    /// customLanguages - 自定义语言数组
    public var languageType: LanguageType = .system
    
    /// 自定义语言
    public var customLanguages: [CustomLanguage] {
        get { PhotoManager.shared.customLanguages }
        set { PhotoManager.shared.customLanguages = newValue }
    }
    
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
    
    /// Text color of cancel button
    /// 取消按钮的文字颜色
    public var cancelButtonTitleColor: UIColor = .white
    
    /// The text color of the Done button in its normal state
    /// 完成按钮普通状态下的文字颜色
    public var finishButtonTitleNormalColor: UIColor = "#FDCC00".hx.color
    
    /// Done button text color in disabled state
    /// 完成按钮禁用状态下的文字颜色
    public var finishButtonTitleDisableColor: UIColor = "#FDCC00".hx.color.withAlphaComponent(0.6)
    
    /// Whether to disable the done button in the unedited state
    /// 是否在未编辑状态下禁用完成按钮
    public var isWhetherFinishButtonDisabledInUneditedState: Bool = false
    
    /// The position of the Cancel/Done button when the screen is vertical
    /// iPad：.top
    /// 竖屏时，取消/完成按钮的位置
    public var buttonType: ButtonType
    
    /// The URL configuration after editing, the default is under tmp
    /// Please set a different URL each time you edit to prevent the existing data from being overwritten
    /// If editing a GIF, please set the URL of the gif suffix
    /// 编辑之后的URL配置，默认在tmp下
    /// 每次编辑时请设置不同URL，防止之前存在的数据被覆盖
    /// 如果编辑的是GIF，请设置gif后缀的URL
    public var urlConfig: EditorURLConfig?
    
    /// picture configuration
    /// 图片配置
    public var photo: Photo = .init()
    
    /// video configuration
    /// 视频配置
    public var video: Video = .init()
     
    /// brush configuration
    /// 画笔
    /// iOS 13.0 以上此属性无效，绘制功能更换为 PKCanvasView
    public var brush: Brush = .init()
    
    /// chartlet configuration
    /// 贴图配置
    public var chartlet: Chartlet = .init()
    
    /// text configuration
    /// 文本
    public var text: Text = .init()
    
    /// Crop Screen Configuration
    /// 裁剪画面配置
    public var cropSize: CropSize = .init()
    
    /// Mosaic configuration
    /// 马赛克配置
    public var mosaic: Mosaic = .init()
    
    /// Fixed cropping state
    /// 固定裁剪状态
    public var isFixedCropSizeState: Bool = false
    
    /// Ignore video cropping duration when fixed crop size state
    /// 固定裁剪大小状态时忽略视频裁剪时长
    public var isIgnoreCropTimeWhenFixedCropSizeState: Bool = true
    
    /// Tool View Configuration
    /// 工具视图配置
    public var toolsView: ToolsView = .default
    
    public init() {
        if #available(iOS 13.0, *) {
            modalPresentationStyle = .automatic
        } else {
            modalPresentationStyle = .fullScreen
        }
        if UIDevice.isPad {
            buttonType = .top
        }else {
            buttonType = .bottom
        }
    }
}

public extension EditorConfiguration {
    
    struct Photo {
        
        /// Control brushes, textures... clarity after export
        /// 控制画笔、贴图...导出之后清晰程度
        public var scale: CGFloat = UIScreen._scale
        
        /// The specified tool is selected by default
        /// 默认选中指定工具
        public var defaultSelectedToolOption: ToolsView.Options.`Type`?
        
        /// Filter image compression ratio
        /// 滤镜图片压缩比例
        public var filterScale: CGFloat = 0.5
        
        /// filter configuration
        /// 滤镜配置
        public var filter: Filter = .photoDefault
        
        public init() { }
    }
    
    struct Video {
        
        /// Video export resolution
        /// 视频导出的分辨率
        public var preset: ExportPreset = .ratio_960x540
        
        /// Quality of video export [0-10]
        /// 视频导出的质量[0-10]
        public var quality: Int = 6
        
        /// Autoplay after loading is complete
        /// 加载完成后自动播放
        public var isAutoPlay: Bool = true
        
        /// The specified tool is selected by default
        /// 默认选中指定工具
        public var defaultSelectedToolOption: ToolsView.Options.`Type`? = .time
        
        /// music configuration
        /// 音乐配置
        public var music: Music = .init()
        
        /// Clipping duration configuration
        /// 裁剪时长配置
        public var cropTime: CropTime = .init()
        
        /// filter configuration
        /// 滤镜配置
        public var filter: Filter = .videoDefault
        
        public init() { }
        
        public struct CropTime {
            
            /// Video maximum cropping duration
            /// > 0 The video must be cropped when it is longer than
            /// = 0 for no clipping
            /// 视频最大裁剪时长
            /// > 0 视频时长超过时必须裁剪
            /// = 0 可不裁剪
            public var maximumTime: TimeInterval = 0
            
            /// Video minimum cropping duration, minimum 1
            /// 视频最小裁剪时长，最小1
            public var minimumTime: TimeInterval = 1
            
            /// The color of the left and right arrows in normal state
            /// 左右箭头正常状态下的颜色
            public var arrowNormalColor: UIColor = .white
            
            /// The color of the left and right arrows when they are highlighted
            /// 左右箭头高亮状态下的颜色
            public var arrowHighlightedColor: UIColor = .black
            
            /// The color of the highlighted border
            /// 边框高亮状态下的颜色
            public var frameHighlightedColor: UIColor = "#FDCC00".hx.color
            
            public init() { }
        }
    }
    
    struct Brush {
        
        /// array of brush colors
        /// 画笔颜色数组
        public var colors: [String] = PhotoTools.defaultColors()
        
        /// default brush color index
        /// 默认画笔颜色索引
        public var defaultColorIndex: Int = 2
        
        /// initial brush width
        /// 初始画笔宽度
        public var lineWidth: CGFloat = 5
        
        /// Maximum brush width
        /// 画笔最大宽度
        public var maximumLinewidth: CGFloat = 20
        
        /// Brush Min Width
        /// 画笔最小宽度
        public var minimumLinewidth: CGFloat = 2
        
        /// Show brush size slider
        /// 显示画笔尺寸大小滑动条
        public var showSlider: Bool = true
        
        /// Add custom colors - iOS 14+
        /// 添加自定义颜色 - iOS 14+
        public var addCustomColor: Bool = true
        
        /// Customize Default Colors - iOS 14+
        /// 自定义默认颜色 - iOS 14+
        public var customDefaultColor: UIColor = "#9EB6DC".hx.color
        
        /// Hide texture view while drawing
        /// 绘制时隐藏贴图视图
        public var isHideStickersDuringDrawing: Bool = true
        
        public init() { }
    }
    
    struct CropSize {
        
        /// The line color when the angular scale is swiped
        /// 角度刻度滑动时的线条颜色
        public var angleScaleColor: UIColor = "#FDCC00".hx.color
        
        /// round crop box
        /// isResetToOriginal = false, which can avoid restoring the original width and height when resetting
        /// 圆形裁剪框
        /// isResetToOriginal = false，可以避免重置时恢复原始宽高
        public var isRoundCrop: Bool = false
        
        /// default fixed ratio
        /// 默认固定比例
        /// ```swift
        /// /// Leave `aspectRatios` empty if you don't want other ratios at the bottom
        /// /// 如果不想要底部其他的比例请将`aspectRatios`置空
        /// aspectRatios = []
        /// ```
        public var isFixedRatio: Bool = false
        
        /// default aspect ratio
        /// 默认宽高比
        public var aspectRatio: CGSize = .zero
        
        /// Mask type when clipping
        /// 裁剪时遮罩类型
        public var maskType: EditorView.MaskType = .blurEffect(style: .dark)
        
        /// Show proportional size
        /// 显示比例大小
        public var isShowScaleSize: Bool = true
        
        /// The subscript for the default selection of the aspect ratio array
        /// Selecting does not mean that the default is the corresponding aspect ratio
        /// 宽高比数组默认选择的下标
        /// 选中不代表默认就是对应的宽高比
        /// isRoundCrop = true 时无效
        /// ```swift
        /// // If you want the default corresponding aspect ratio also set `aspectRatio`
        /// // 如果想要默认对应的宽高比也要设置 `aspectRatio`
        /// var cropSize = CropSize()
        /// // 2 is selected by default
        /// // 默认选中 2
        /// cropSize.defaultSeletedIndex = 2
        /// // The default aspect ratio should also be set to the corresponding ratio, so that when entering the cropping, the default is the set style
        /// // 默认的宽高比也要设置与之对应的比例，这样进入裁剪的时候默认就是设置的样式
        /// cropSize.aspectRatio = .init(width: 1, height: 1)
        /// // fixed aspect ratio
        /// // 固定宽高比
        /// cropSize.isFixedRatio = true
        /// // Click Restore to reset to the original aspect ratio
        /// // 点击还原重置到原始宽高比
        /// cropSize.isResetToOriginal = true
        /// ```
        public var defaultSeletedIndex: Int = 1
        
        /// aspect ratio configuration
        /// 宽高比配置
        public var aspectRatios: [EditorRatioToolConfig] = [
            .init(title: .localized("原始比例"), ratio: .init(width: -1, height: -1)),
            .init(title: .localized("自由格式"), ratio: .zero),
            .init(title: .localized("正方形"), ratio: .init(width: 1, height: 1)),
            .init(title: .custom("16:9"), ratio: .init(width: 16, height: 9)),
            .init(title: .custom("5:4"), ratio: .init(width: 5, height: 4)),
            .init(title: .custom("7:5"), ratio: .init(width: 7, height: 5)),
            .init(title: .custom("4:3"), ratio: .init(width: 4, height: 3)),
            .init(title: .custom("5:3"), ratio: .init(width: 5, height: 3)),
            .init(title: .custom("3:2"), ratio: .init(width: 3, height: 2))
        ]
        
        /// When the default fixed ratio, click restore to reset to the original aspect ratio
        /// true: reset to original aspect ratio
        /// false: Reset to the default aspect ratio `aspectRatio` set, centered
        /// 当默认固定比例时，点击还原是否重置到原始宽高比
        /// true：重置到原始宽高比
        /// false：重置到设置的默认宽高比`aspectRatio`，居中显示
        public var isResetToOriginal: Bool = false
        
        public var maskListProtcol: EditorMaskListProtocol.Type = EditorMaskListViewController.self
        
        /// Mask material list
        /// 蒙版素材列表
        public var maskList: [MaskType] = []
        
        /// Display quantity of mask material per line
        /// 蒙版素材每行显示数量
        public var maskRowCount: CGFloat = 4
        
        /// Display quantity per line when the mask material is horizontal
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

        /// array of text colors
        /// 文本颜色数组
        public var colors: [String] = PhotoTools.defaultColors()
        
        /// text cursor color
        /// 文本光标颜色
        public var tintColor: UIColor = "#FDCC00".hx.color
        
        /// OK button text color
        /// 确定按钮文字颜色
        public var doneTitleColor: UIColor = "#FDCC00".hx.color
        
        /// OK button background color
        /// 确定按钮背景颜色
        public var doneBackgroundColor: UIColor = .clear
        
        /// text font
        /// 文本字体
        public var font: UIFont = .boldSystemFont(ofSize: 25)
        
        /// Maximum character limit, 0 means no limit
        /// 最大字数限制，0为不限制
        public var maximumLimitTextLength: Int = 0
        
        /// text view launch style
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
        
        /// The size of the generated mosaic
        /// 生成马赛克的大小
        public var mosaicWidth: CGFloat = 20
        
        /// The line width of the mosaic when graffiti
        /// 涂鸦时马赛克的线宽
        public var mosaiclineWidth: CGFloat = 25
        
        /// width of smear
        /// 涂抹的宽度
        public var smearWidth: CGFloat = 30
        
        /// 当滤镜发生改变时更改马赛克背景
        public var isFilterApply: Bool = true
        
        /// Hide texture view while drawing
        /// 绘制时隐藏贴图视图
        public var isHideStickersDuringDrawing: Bool = true
        
        public init() { }
    }
    
    struct Filter {
        
        /// filter information
        /// 滤镜信息
        public var infos: [PhotoEditorFilterInfo]
        
        /// filter selected color
        /// 滤镜选中颜色
        public var selectedColor: UIColor
        
        /// Identifier, used to display the last filter effect when editing again
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
        public var placeholder: String {
            get { .textManager.editor.music.searchPlaceholder.text }
            set { HX.TextManager.shared.editor.music.searchPlaceholder = .custom(newValue) }
        }
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
        
        public var listProtcol: EditorChartletListProtocol.Type = EditorChartletViewController.self
        
        public var modalPresentationStyle: UIModalPresentationStyle
        
        /// 每行显示个数
        public var rowCount: Int = UIDevice.isPad ? 6 : 5
        /// 贴图加载时机
        public var loadScene: LoadScene = .cellDisplay
        /// 贴图标题
        public var titles: [EditorChartlet] = []
        
        #if HXPICKER_ENABLE_PICKER
        /// 是否允许添加 从相册选取
        public var allowAddAlbum: Bool = false
        /// 相册图标
        public var albumImageName: String {
            get { .imageResource.editor.sticker.album.name }
            set { HX.imageResource.editor.sticker.album = .local(newValue) }
        }
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
        
        public init() {
            if #available(iOS 13.0, *) {
                modalPresentationStyle = .automatic
            } else {
                modalPresentationStyle = .fullScreen
            }
        }
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
            public let imageType: HX.ImageResource.ImageType
            
            /// 类型
            public let type: `Type`
            
            public init(imageType: HX.ImageResource.ImageType,
                        type: `Type`) {
                self.imageType = imageType
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
                imageType: .imageResource.editor.tools.video,
                type: .time
            )
            let graffiti = Options(
                imageType: .imageResource.editor.tools.graffiti,
                type: .graffiti
            )
            let chartlet = Options(
                imageType: .imageResource.editor.tools.chartlet,
                type: .chartlet
            )
            let text = Options(
                imageType: .imageResource.editor.tools.text,
                type: .text
            )
            let cropSize = Options(
                imageType: .imageResource.editor.tools.cropSize,
                type: .cropSize
            )
            let music = Options(
                imageType:.imageResource.editor.tools.music,
                type: .music
            )
            let mosaic = Options(
                imageType: .imageResource.editor.tools.mosaic,
                type: .mosaic
            )
            let filterEdit = Options(
                imageType: .imageResource.editor.tools.adjustment,
                type: .filterEdit
            )
            let filter = Options(
                imageType: .imageResource.editor.tools.filter,
                type: .filter
            )
            return .init(toolOptions: [time, graffiti, chartlet, text, music, cropSize, mosaic, filterEdit, filter])
        }
    }
    
    enum ButtonType {
        case top
        case bottom
    }
    
} 
