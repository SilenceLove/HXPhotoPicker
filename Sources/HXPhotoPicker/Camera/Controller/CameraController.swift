//
//  CameraController.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit
import CoreLocation
import AVFoundation
import Photos

#if !targetEnvironment(macCatalyst)
open class CameraController: UINavigationController {
    
    public enum CameraType {
        case normal
        case metal
    }
    
    /// 相机拍摄类型
    public enum CaptureType {
        // 拍照
        case photo
        // 录制
        case video
        // 拍照和录制
        case all
    }
    
    /// 拍摄结果
    public enum Result {
        /// 图片
        case image(UIImage)
        /// 视频地址
        case video(URL)
    }
    
    public weak var cameraDelegate: CameraControllerDelegate?
    
    /// 自动dismiss
    public var autoDismiss: Bool = true {
        didSet {
            let vc = viewControllers.first as? CameraViewController
            vc?.autoDismiss = autoDismiss
        }
    }
    
    /// 相机配置
    public let config: CameraConfiguration
    
    /// 相机初始化
    /// - Parameters:
    ///   - config: 相机配置
    ///   - type: 相机类型
    ///   - delegate: 相机代理
    public init(
        config: CameraConfiguration,
        type: CaptureType,
        delegate: CameraControllerDelegate? = nil
    ) {
        self.config = config
        cameraDelegate = delegate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = config.modalPresentationStyle
        let cameraVC = CameraViewController(
            config: config,
            type: type,
            delegate: self
        )
        viewControllers = [cameraVC]
    }
    
    public typealias CaptureCompletion = (Result, CLLocation?) -> Void
    public typealias CapturePHAssetCompletion = (Result, PHAsset, CLLocation?) -> Void
    
    /// 跳转相机
    /// - Parameters:
    ///   - config: 相机配置
    ///   - type: 相机类型
    ///   - completion: 拍摄完成
    /// - Returns: 相机对应的 CameraController
    @discardableResult
    public static func capture(
        config: CameraConfiguration,
        type: CaptureType = .all,
        fromVC: UIViewController? = nil,
        completion: @escaping CaptureCompletion
    ) -> CameraController {
        let controller = CameraController(
            config: config,
            type: type
        )
        controller.completion = completion
        (fromVC ?? UIViewController.topViewController)?.present(controller, animated: true)
        return controller
    }
    
    public var completion: CaptureCompletion?
    
    public var phAssetcompletion: CapturePHAssetCompletion?
    
    public var cancelHandler: ((CameraController) -> Void)?
    
    /// 跳转相机 config.isSaveSystemAlbum = true 时才会触发闭包
    /// - Parameters:
    ///   - config: 相机配置
    ///   - type: 相机类型
    ///   - completion: 拍摄完成
    /// - Returns: 相机对应的 CameraController
    @discardableResult
    public static func captureAsset(
        config: CameraConfiguration,
        type: CaptureType = .all,
        fromVC: UIViewController? = nil,
        completion: @escaping CapturePHAssetCompletion
    ) -> CameraController {
        let controller = CameraController(
            config: config,
            type: type
        )
        controller.phAssetcompletion = completion
        (fromVC ?? UIViewController.topViewController)?.present(controller, animated: true)
        return controller
    }
    
    open override var prefersStatusBarHidden: Bool {
        config.prefersStatusBarHidden
    }
    open override var shouldAutorotate: Bool {
        config.shouldAutorotate
    }
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        config.supportedInterfaceOrientations
    }
    
    var isDismissed: Bool = false
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let vcs = navigationController?.viewControllers {
            if !vcs.contains(self) {
                if !isDismissed {
                    cancelHandler?(self)
                }
            }
        }else if presentingViewController == nil {
            if !isDismissed {
                cancelHandler?(self)
            }
        }
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CameraController: CameraViewControllerDelegate {
    public func cameraViewController(
        _ cameraViewController: CameraViewController,
        didFinishWithResult result: CameraController.Result,
        location: CLLocation?
    ) {
        isDismissed = true
        completion?(result, location)
        cameraDelegate?.cameraController(
            self,
            didFinishWithResult: result,
            location: location
        )
    }
    public func cameraViewController(
        _ cameraViewController: CameraViewController,
        didFinishWithResult result: Result,
        phAsset: PHAsset,
        location: CLLocation?
    ) {
        isDismissed = true
        phAssetcompletion?(result, phAsset, location)
        cameraDelegate?.cameraController(
            self,
            didFinishWithResult: result,
            phAsset: phAsset,
            location: location
        )
    }
    public func cameraViewController(didCancel cameraViewController: CameraViewController) {
        isDismissed = true
        cancelHandler?(self)
        cameraDelegate?.cameraController(didCancel: self)
    }
    public func cameraViewController(
        _ cameraViewController: CameraViewController,
        flashModeDidChanged flashMode: AVCaptureDevice.FlashMode
    ) {
        cameraDelegate?.cameraController(self, flashModeDidChanged: flashMode)
    }
    public func cameraViewController(
        _ cameraViewController: CameraViewController,
        didSwitchCameraCompletion position: AVCaptureDevice.Position
    ) {
        cameraDelegate?.cameraController(self, didSwitchCameraCompletion: position)
    }
    public func cameraViewController(
        _ cameraViewController: CameraViewController,
        didChangeTakeType takeType: CameraBottomViewTakeType
    ) {
        cameraDelegate?.cameraController(self, didChangeTakeType: takeType)
    }
}

@available(iOS 13.0.0, *)
public extension CameraController {
    
    struct CaptureResult {
        
        public let result: Result
        
        /// config.isSaveSystemAlbum = true 才有值
        public let phAsset: PHAsset?
        
        public let localtion: CLLocation?
    }
    
    @MainActor
    static func capture(
        _ config: CameraConfiguration = .init(),
        type: CameraController.CaptureType = .all,
        delegate: CameraControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> CaptureResult {
        let vc = show(config, type: type, delegate: delegate, fromVC: fromVC)
        return try await vc.takePhotograph()
    }
    
    @MainActor
    static func show(
        _ config: CameraConfiguration = .init(),
        type: CameraController.CaptureType = .all,
        delegate: CameraControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) -> CameraController {
        let topVC = fromVC ?? UIViewController.topViewController
        let vc = CameraController(config: config, type: type, delegate: delegate)
        topVC?.present(vc, animated: true)
        return vc
    }
    
    func takePhotograph() async throws -> CaptureResult {
        try await withCheckedThrowingContinuation { continuation in
            var isDimissed: Bool = false
            completion = {
                if isDimissed { return }
                isDimissed = true
                continuation.resume(with: .success(CaptureResult(result: $0, phAsset: nil, localtion: $1)))
            }
            phAssetcompletion = {
                if isDimissed { return }
                isDimissed = true
                continuation.resume(with: .success(CaptureResult(result: $0, phAsset: $1, localtion: $2)))
            }
            cancelHandler = { _ in
                if isDimissed { return }
                isDimissed = true
                continuation.resume(with: .failure(CaptureError.canceled))
            }
        }
    }
    
    enum CaptureError: Error, LocalizedError, CustomStringConvertible {
        case canceled
        
        public var errorDescription: String? {
            switch self {
            case .canceled:
                return "canceled：取消拍照"
            }
        }
        
        public var description: String {
            errorDescription ?? "nil"
        }
    }
}
#endif
