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
    
    /// 视频导出的地址，默认在tmp下
    public var videoExportURL: URL?
    
    /// 编辑控制器的默认状态
    public var defaultState: VideoEditorViewController.State = .normal
    
    /// 当编辑控制器默认状态是裁剪状态时是否必须裁剪视频
    public var mustBeTailored: Bool = true
    
    /// 贴图配置
    public lazy var chartlet: EditorChartletConfig = .init()
    
    /// 文本
    public lazy var text: EditorTextConfig = .init()
    
    /// 音乐配置
    public lazy var music: MusicConfig = .init()
    
    public struct MusicConfig {
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
        
        public init() { }
    }
    
    /// 裁剪配置
    public lazy var cropping: VideoCroppingConfiguration = .init()
    
    /// 裁剪视图配置
    public lazy var cropView: CropConfirmViewConfiguration = .init()
    
    /// 工具视图配置
    public lazy var toolView: EditorToolViewConfiguration = {
        let chartlet = EditorToolOptions(
            imageName: "hx_editor_photo_tools_emoji",
            type: .chartlet
        )
        let text = EditorToolOptions(
            imageName: "hx_editor_photo_tools_text",
            type: .text
        )
        let music = EditorToolOptions.init(
            imageName: "hx_editor_tools_music",
            type: .music
        )
        let crop = EditorToolOptions.init(
            imageName: "hx_editor_video_crop",
            type: .cropping
        )
        return .init(toolOptions: [chartlet, text, music, crop])
    }()
}
