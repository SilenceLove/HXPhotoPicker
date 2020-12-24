//
//  HXPHPicker.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

class HXPHPicker: NSObject {
    
    enum SelectType: Int {
        case photo = 0      //!< 只显示图片
        case video = 1      //!< 只显示视频
        case any = 2        //!< 任何类型
    }

    enum SelectMode: Int {
        case single = 0         //!< 单选模式
        case multiple = 1       //!< 多选模式
    }
    
    enum AppearanceStyle: Int {
        case varied = 0     //!< 跟随系统变化
        case normal = 1     //!< 正常风格，不会跟随系统变化
        case dark = 2       //!< 暗黑风格
    }
    
    enum LanguageType: Int {
        case system = 0             //!< 跟随系统语言
        case simplifiedChinese = 1  //!< 中文简体
        case traditionalChinese = 2 //!< 中文繁体
        case japanese = 3           //!< 日文
        case korean = 4             //!< 韩文
        case english = 5            //!< 英文
        case thai = 6               //!< 泰语
        case indonesia = 7          //!< 印尼语
    }
    enum Asset {
        enum MediaType: Int {
            case photo = 0      //!< 照片
            case video = 1      //!< 视频
        }

        enum MediaSubType: Int {
            case image = 0          //!< 手机相册里的图片
            case imageAnimated = 1  //!< 手机相册里的动图
            case livePhoto = 2      //!< 手机相册里的LivePhoto
            case localImage = 3     //!< 本地图片
            case video = 4          //!< 手机相册里的视频
            case localVideo = 5     //!< 本地视频
        }
    }
    enum Album {
        enum ShowMode: Int {
            case normal = 0         //!< 正常展示
            case popup = 1          //!< 弹出展示
        }
    }
    enum PhotoList {
        enum CancelType {
            case text
            case image
        }
        enum CancelPosition {
            case left
            case right
        }
        enum Cell {
            enum SelectBoxType: Int {
                case number //!< 数字
                case tick   //!< √
            }
        }
    }
    enum CameraAlbumLocal: String {
        case identifier = "HXCameraAlbumLocalIdentifier"
        case identifierType = "HXCameraAlbumLocalIdentifierType"
        case language = "HXCameraAlbumLocalLanguage"
    }
    enum LivePhotoError {
        case imageError(Error?)
        case videoError(Error?)
        case allError(Error?, Error?)
    }
}

enum HXPickerError: LocalizedError {
    case error(message: String)
}
extension HXPickerError {
    public var errorDescription: String? {
        switch self {
            case let .error(message):
                return message
        }
    }
}


class HXPHImagePickerController: UIImagePickerController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(didTakePictures), name: NSNotification.Name(rawValue: "_UIImagePickerControllerUserDidCaptureItem"), object: nil)
    }
    @objc func didTakePictures() {
        if let viewController = topViewController  {
            layoutEditView(view: viewController.view)
        }
    }
    func layoutEditView(view: UIView) {
        var imageScrollView: UIScrollView?
        getSubviewsOfView(v: view).forEach { (subView) in
            if NSStringFromClass(subView.classForCoder) == "PLCropOverlayCropView"  {
                subView.frame = subView.superview?.bounds ?? subView.frame
            }else if subView is UIScrollView && NSStringFromClass(subView.classForCoder) == "PLImageScrollView" {
                let isNewImageScrollView = imageScrollView == nil
                imageScrollView = subView as? UIScrollView
                if let scrollView = imageScrollView {
                    let size = scrollView.hx_size
                    let inset = abs(size.width - size.height) * 0.5
                    scrollView.contentInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
                    if isNewImageScrollView {
                        let contentSize = scrollView.contentSize
                        if contentSize.height > contentSize.width {
                            let offset = round((contentSize.height - contentSize.width) * 0.5 - inset)
                            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: offset)
                        }
                    }
                }
            }
        }
    }
    func getSubviewsOfView(v:UIView) -> [UIView] {
        if v.subviews.isEmpty {
            return [v]
        }
        var allView: [UIView] = [v]
        v.subviews.forEach { (subView) in
            allView.append(contentsOf: getSubviewsOfView(v: subView))
        }
        return allView
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
