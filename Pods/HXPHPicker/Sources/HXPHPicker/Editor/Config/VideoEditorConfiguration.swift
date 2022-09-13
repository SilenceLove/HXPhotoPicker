//
//  VideoEditorConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//
import UIKit
import AVFoundation

open class VideoEditorConfiguration: EditorConfiguration {
    
    /// 视频导出的分辨率
    public var exportPreset: ExportPreset = .ratio_960x540
    
    /// 视频导出的质量[0-10]
    public var videoQuality: Int = 6
    
    /// 返回按钮图标
    public var backButtonImageName: String = "hx_editor_back"
    
    /// 视频导出的地址配置，默认在tmp下
    /// 每次编辑时请设置不同地址，防止之前存在的数据被覆盖
    public var videoURLConfig: EditorURLConfig?
    
    /// 编辑控制器的默认状态
    public var defaultState: VideoEditorViewController.State = .normal
    
    /// 当编辑控制器默认状态是裁剪状态时是否必须裁剪视频
    public var mustBeTailored: Bool = true
    
    /// 画笔
    public lazy var brush: EditorBrushConfiguration = .init()
    
    /// 贴图配置
    public lazy var chartlet: EditorChartletConfiguration = .init()
    
    /// 文本
    public lazy var text: EditorTextConfiguration = .init()
    
    /// 音乐配置
    public lazy var music: Music = .init()
    
    /// 滤镜配置
    public lazy var filter: Filter = .init(infos: PhotoTools.defaultVideoFilters())
    
    /// 裁剪时长配置
    public lazy var cropTime: VideoCropTimeConfiguration = .init()
    
    /// 裁剪画面配置
    public lazy var cropSize: EditorCropSizeConfiguration = .init() 
    
    /// 裁剪确认视图配置
    public lazy var cropConfirmView: CropConfirmViewConfiguration = .init()
    
    /// 工具视图配置
    public lazy var toolView: EditorToolViewConfiguration = {
        let graffiti = EditorToolOptions(
            imageName: "hx_editor_tools_graffiti",
            type: .graffiti
        )
        let chartlet = EditorToolOptions(
            imageName: "hx_editor_photo_tools_emoji",
            type: .chartlet
        )
        let text = EditorToolOptions(
            imageName: "hx_editor_photo_tools_text",
            type: .text
        )
        let cropSize = EditorToolOptions(
            imageName: "hx_editor_photo_crop",
            type: .cropSize
        )
        let music = EditorToolOptions.init(
            imageName: "hx_editor_tools_music",
            type: .music
        )
        let cropTime = EditorToolOptions.init(
            imageName: "hx_editor_video_crop",
            type: .cropTime
        )
        let filter = EditorToolOptions(
            imageName: "hx_editor_tools_filter",
            type: .filter
        )
        return .init(toolOptions: [graffiti, chartlet, text, music, cropSize, cropTime, filter])
    }()
}

extension VideoEditorConfiguration {
    
    public struct Music {
        /// 显示搜索
        public var showSearch: Bool = true
        /// 完成按钮背景颜色、搜索框光标颜色
        public var tintColor: UIColor = .systemTintColor
        /// 搜索框的 placeholder
        public var placeholder: String = ""
        /// 滚动停止时自动播放音乐
        public var autoPlayWhenScrollingStops: Bool = true
        /// 配乐信息
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
}
