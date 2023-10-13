//
//  PhotoPreviewViewControllerProtocol.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/10/23.
//

import UIKit

protocol PhotoPreviewViewControllerDelegate: AnyObject {
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didOriginalButton isOriginal: Bool
    )
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didSelectBox photoAsset: PhotoAsset,
        isSelected: Bool,
        updateCell: Bool
    )
    #if HXPICKER_ENABLE_EDITOR
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        shouldEditPhotoAsset photoAsset: PhotoAsset,
        editorConfig: EditorConfiguration
    ) -> EditorConfiguration?
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        shouldEditVideoAsset videoAsset: PhotoAsset,
        editorConfig: EditorConfiguration
    ) -> EditorConfiguration?
    #endif
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        editAssetFinished photoAsset: PhotoAsset
    )
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        networkImagedownloadSuccess photoAsset: PhotoAsset
    )
    func previewViewController(
        didFinishButton previewController: PhotoPreviewViewController,
        photoAssets: [PhotoAsset]
    )
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        requestSucceed photoAsset: PhotoAsset
    )
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        requestFailed photoAsset: PhotoAsset
    )
    func previewViewController(
        movePhotoAsset previewController: PhotoPreviewViewController
    )
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        moveItem fromIndex: Int,
        toIndex: Int
    )
}
extension PhotoPreviewViewControllerDelegate {
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didOriginalButton isOriginal: Bool
    ) { }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didSelectBox photoAsset: PhotoAsset,
        isSelected: Bool,
        updateCell: Bool
    ) { }
    #if HXPICKER_ENABLE_EDITOR
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        shouldEditPhotoAsset photoAsset: PhotoAsset,
        editorConfig: EditorConfiguration
    ) -> EditorConfiguration? { editorConfig }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        shouldEditVideoAsset videoAsset: PhotoAsset,
        editorConfig: EditorConfiguration
    ) -> EditorConfiguration? { editorConfig }
    #endif
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        editAssetFinished photoAsset: PhotoAsset
    ) { }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        networkImagedownloadSuccess photoAsset: PhotoAsset
    ) { }
    func previewViewController(
        didFinishButton previewController: PhotoPreviewViewController,
        photoAssets: [PhotoAsset]
    ) { }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        requestSucceed photoAsset: PhotoAsset
    ) { }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        requestFailed photoAsset: PhotoAsset
    ) { }
    func previewViewController(
        movePhotoAsset previewController: PhotoPreviewViewController
    ) { }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        moveItem fromIndex: Int,
        toIndex: Int
    ) { }
}
