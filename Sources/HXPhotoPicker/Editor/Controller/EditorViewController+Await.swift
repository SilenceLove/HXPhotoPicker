//
//  EditorViewController+Await.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/7/22.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

@available(iOS 13.0.0, *)
public extension EditorViewController {
    
    @MainActor
    static func edit(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditorViewControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) async throws -> EditorAsset {
        let vc = show(asset, config: config, delegate: delegate, fromVC: fromVC)
        return try await vc.edit()
    }
    
    @MainActor
    static func show(
        _ asset: EditorAsset,
        config: EditorConfiguration = .init(),
        delegate: EditorViewControllerDelegate? = nil,
        fromVC: UIViewController? = nil
    ) -> EditorViewController {
        let topVC = fromVC ?? UIViewController.topViewController
        let vc = EditorViewController(asset, config: config, delegate: delegate)
        topVC?.present(vc, animated: true)
        return vc
    }
    
    func edit() async throws -> EditorAsset {
        try await withCheckedThrowingContinuation { continuation in
            var isDimissed: Bool = false
            finishHandler = { result, _ in
                if isDimissed { return }
                isDimissed = true
                continuation.resume(with: .success(result))
            }
            cancelHandler = { _ in
                if isDimissed { return }
                isDimissed = true
                continuation.resume(with: .failure(EditorError.canceled))
            }
        }
    }
    
    enum EditorError: Error, LocalizedError, CustomStringConvertible {
        case canceled
        
        public var errorDescription: String? {
            switch self {
            case .canceled:
                return "canceled：取消编辑"
            }
        }
        
        public var description: String {
            errorDescription ?? "nil"
        }
    }
}
