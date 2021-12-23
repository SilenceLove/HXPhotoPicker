//
//  SystemCameraViewController.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

class SystemCameraViewController: UIImagePickerController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didTakePictures),
            name: NSNotification.Name(rawValue: "_UIImagePickerControllerUserDidCaptureItem"),
            object: nil
        )
    }
    @objc func didTakePictures() {
        if let viewController = topViewController {
            layoutEditView(view: viewController.view)
        }
    }
    private func layoutEditView(view: UIView) {
        var imageScrollView: UIScrollView?
        getSubviewsOfView(v: view).forEach { (subView) in
            if NSStringFromClass(subView.classForCoder) == "PLCropOverlayCropView" {
                subView.frame = subView.superview?.bounds ?? subView.frame
            }else if subView is UIScrollView && NSStringFromClass(subView.classForCoder) == "PLImageScrollView" {
                let isNewImageScrollView = imageScrollView == nil
                imageScrollView = subView as? UIScrollView
                if let scrollView = imageScrollView {
                    let size = scrollView.size
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
    private func getSubviewsOfView(v: UIView) -> [UIView] {
        var allView: [UIView] = [v]
        v.subviews.forEach {
            allView.append(contentsOf: getSubviewsOfView(v: $0))
        }
        return allView
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
