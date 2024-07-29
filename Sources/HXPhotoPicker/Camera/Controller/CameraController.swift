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
        let cameraVC = config.cameraViewController.init(config: config, type: type)
        cameraVC.delegate = self
        viewControllers = [cameraVC]
    }
    
    public typealias CaptureCompletion = (Result, PHAsset?, CLLocation?) -> Void
    
    public var completion: CaptureCompletion?
    
    public var cancelHandler: ((CameraController) -> Void)?
    
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
    public func cameraViewController(_ cameraViewController: any CameraViewControllerProtocol, didFinishWithResult result: Result, phAsset: PHAsset?, location: CLLocation?) {
        isDismissed = true
        completion?(result, phAsset, location)
        cameraDelegate?.cameraController(
            self,
            didFinishWithResult: result,
            phAsset: phAsset,
            location: location
        )
    }
    
    public func cameraViewController(didCancel cameraViewController: any CameraViewControllerProtocol) {
        isDismissed = true
        cancelHandler?(self)
        cameraDelegate?.cameraController(didCancel: self)
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
