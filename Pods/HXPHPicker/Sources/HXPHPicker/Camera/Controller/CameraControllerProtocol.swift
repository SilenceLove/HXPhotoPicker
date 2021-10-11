//
//  CameraControllerProtocol.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/31.
//

import Foundation
import CoreLocation

public protocol CameraControllerDelegate: AnyObject {
    
    /// 拍摄完成
    /// - Parameters:
    ///   - cameraController: 对应的 CameraController
    ///   - result: 拍摄结果
    ///   - locatoin: 定位信息
    func cameraController(
        _ cameraController: CameraController,
        didFinishWithResult result: CameraController.Result,
        location: CLLocation?
    )
    
    /// 取消拍摄
    /// - Parameter cameraController: 对应的 CameraController
    func cameraController(didCancel cameraController: CameraController)
}

public extension CameraControllerDelegate {
    
    func cameraController(
        _ cameraController: CameraController,
        didFinishWithResult result: CameraController.Result,
        location: CLLocation?
    ) {
        if !cameraController.autoDismiss {
            cameraController.dismiss(animated: true)
        }
    }
    func cameraController(didCancel cameraController: CameraController) {
        if !cameraController.autoDismiss {
            cameraController.dismiss(animated: true)
        }
    }
}

public protocol CameraViewControllerDelegate: AnyObject {
    
    /// 拍摄完成
    /// - Parameters:
    ///   - cameraViewController: 对应的 CameraViewController
    ///   - result: 拍摄结果
    ///   - locatoin: 定位信息
    func cameraViewController(
        _ cameraViewController: CameraViewController,
        didFinishWithResult result: CameraController.Result,
        location: CLLocation?
    )
    
    /// 取消拍摄
    /// - Parameter cameraViewController: 对应的 CameraViewController
    func cameraViewController(didCancel cameraViewController: CameraViewController)
}

public extension CameraViewControllerDelegate {
    func cameraViewController(
        _ cameraViewController: CameraViewController,
        didFinishWithResult result: CameraController.Result,
        location: CLLocation?
    ) {
        if !cameraViewController.autoDismiss {
            cameraViewController.dismiss(animated: true)
        }
    }
    func cameraViewController(didCancel cameraViewController: CameraViewController) {
        if !cameraViewController.autoDismiss {
            cameraViewController.dismiss(animated: true)
        }
    }
}

protocol CameraResultViewControllerDelegate: AnyObject {
    func cameraResultViewController(didDone cameraResultViewController: CameraResultViewController)
}
