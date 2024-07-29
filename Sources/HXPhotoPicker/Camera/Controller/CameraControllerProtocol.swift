//
//  CameraControllerProtocol.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/31.
//

import UIKit
import CoreLocation
import AVFoundation
import Photos

#if !targetEnvironment(macCatalyst)

public protocol CameraViewControllerProtocol: UIViewController {
    var delegate: CameraViewControllerDelegate? { get set }
    init(config: CameraConfiguration, type: CameraController.CaptureType)
}

public protocol CameraControllerDelegate: AnyObject {
    
    /// 拍摄完成
    /// - Parameters:
    ///   - cameraController: 对应的 CameraController
    ///   - result: 拍摄结果
    ///   - phAsset: 保存到相册的 PHAsset 对象
    ///   - locatoin: 定位信息
    func cameraController(
        _ cameraController: CameraController,
        didFinishWithResult result: CameraController.Result,
        phAsset: PHAsset?,
        location: CLLocation?
    )
    
    /// 取消拍摄
    /// - Parameter cameraController: 对应的 CameraController
    func cameraController(didCancel cameraController: CameraController)
}

public extension CameraControllerDelegate {
    
    func cameraController(didCancel cameraController: CameraController) {
        if !cameraController.config.isAutoBack {
            cameraController.dismiss(animated: true)
        }
    }
}

public protocol CameraViewControllerDelegate: AnyObject {
    
    /// 拍摄完成
    /// - Parameters:
    ///   - cameraViewController: 对应的 CameraViewController
    ///   - result: 拍摄结果
    ///   - phAsset: 保存到相册的 PHAsset 对象
    ///   - locatoin: 定位信息
    func cameraViewController(
        _ cameraViewController: CameraViewControllerProtocol,
        didFinishWithResult result: CameraController.Result,
        phAsset: PHAsset?,
        location: CLLocation?
    )
    
    /// 取消拍摄
    /// - Parameter cameraViewController: 对应的 CameraViewController
    func cameraViewController(didCancel cameraViewController: CameraViewControllerProtocol)
}

protocol CameraResultViewControllerDelegate: AnyObject {
    func cameraResultViewController(didDone cameraResultViewController: CameraResultViewController)
}

#endif
