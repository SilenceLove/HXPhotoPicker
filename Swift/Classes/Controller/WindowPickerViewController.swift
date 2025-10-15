//
//  WindowPickerViewController.swift
//  Example
//
//  Created by Slience on 2021/9/17.
//

import UIKit
import HXPhotoPicker

class WindowPickerViewController: UIViewController {
    
    lazy var manager: PickerManager = {
        let manager = PickerManager()
        manager.config = PhotoTools.getWXPickerConfig()
        manager.config.photoList.cameraCell.cameraImageName = "hx_picker_photoList_photograph"
        manager.config.photoList.sort = .desc
        manager.config.photoList.backgroundColor = .white
        manager.config.photoList.cell.backgroundColor = .white
        manager.config.photoList.cell.targetWidth = 300
        manager.config.photoList.cameraCell.allowPreview = false
        manager.config.photoList.cameraCell.backgroundColor = UIColor(hexString: "#f1f1f1")
        manager.config.photoList.emptyView.titleColor = UIColor(hexString: "#666666")
        manager.config.photoList.emptyView.subTitleColor = UIColor(hexString: "#666666")
        manager.config.photoList.limitCell.lineColor = UIColor(hexString: "#999999")
        manager.config.photoList.limitCell.titleColor = UIColor(hexString: "#999999")
        manager.config.photoList.limitCell.backgroundColor = UIColor(hexString: "#f1f1f1")
        manager.config.notAuthorized.backgroundColor = .white
        manager.config.notAuthorized.titleColor = UIColor(hexString: "#666666")
        manager.config.notAuthorized.subTitleColor = UIColor(hexString: "#666666")
//        manager.fetchLimit = 200
        return manager
    }()
    lazy var pickerView: HXPhotoPicker.PhotoPickerView = {
        let view = HXPhotoPicker.PhotoPickerView(
            manager: manager,
            scrollDirection: .horizontal,
            delegate: self
        )
//        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UIDevice.bottomMargin, right: 0)
        return view
    }()
    var showPicker = true
    lazy var toolbar: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 50))
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "select_photo"), for: .normal)
        button.addTarget(self, action: #selector(didSelectPhotoClick), for: .touchUpInside)
        button.size = CGSize(width: 40, height: 40)
        button.centerY = 25
        button.x = 12
        view.backgroundColor = UIColor(hexString: "#eeeeee")
        view.addSubview(button)
        return view
    }()
    
    lazy var bottomView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 50 + UIDevice.bottomMargin))
        view.addSubview(originalBtn)
        view.addSubview(finishButton)
        view.backgroundColor = UIColor(hexString: "#eeeeee")
        return view
    }()
    lazy var finishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("完成", for: .normal)
        button.titleLabel?.font = UIFont.mediumPingFang(ofSize: 16)
        button.setTitleColor(
            UIColor(hexString: "#ffffff"),
            for: .normal
        )
        button.setTitleColor(
            UIColor(hexString: "#ffffff").withAlphaComponent(0.5),
            for: .disabled
        )
        button.setBackgroundImage(
            UIImage.image(
                for: UIColor(hexString: "#07C160"),
                havingSize: CGSize.zero
            ),
            for: .normal
        )
        button.setBackgroundImage(
            UIImage.image(
                for: UIColor(hexString: "#07C160").withAlphaComponent(0.5),
                havingSize: CGSize.zero
            ),
            for: .disabled
        )
        button.layer.cornerRadius = 3
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(didFinishButtonClick(button:)), for: .touchUpInside)
        button.frame = CGRect(x: view.width - 12 - 60, y: 0, width: 60, height: 33)
        button.centerY = 25
        return button
    }()
    @objc func didFinishButtonClick(button: UIButton) {
        let pickerResultVC = PickerResultViewController()
        pickerResultVC.config = PhotoTools.getWXPickerConfig()
        pickerResultVC.selectedAssets = pickerView.selectedAssets
        navigationController?.pushViewController(pickerResultVC, animated: true)
        if showPicker {
            didSelectPhotoClick()
        }else {
            pickerView.clear()
        }
        resetOriginal()
        finishButton.isEnabled = false
    }
    lazy var originalBtn: UIView = {
        let originalBtn = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 50)))
        originalBtn.addSubview(originalTitleLb)
        originalBtn.addSubview(boxControl)
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(didOriginalButtonClick))
        originalBtn.addGestureRecognizer(tap)
        originalBtn.center = CGPoint(x: view.width * 0.5, y: 25)
        
        boxControl.centerY = 25
        originalTitleLb.centerY = 25
        return originalBtn
    }()
    lazy var originalTitleLb: UILabel = {
        let originalTitleLb = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 80, height: 30)))
        originalTitleLb.text = "原图"
        originalTitleLb.textColor = UIColor(hexString: "#07C160")
        originalTitleLb.font = UIFont.systemFont(ofSize: 16)
        return originalTitleLb
    }()
    lazy var boxControl: SelectBoxView = {
        var config = SelectBoxConfiguration()
        config.size = .init(width: 17, height: 17)
        config.style = .tick
        config.backgroundColor = .clear
        config.borderColor = UIColor(hexString: "#07C160")
        config.tickColor = .white
        config.selectedBackgroundColor = UIColor(hexString: "#07C160")
        let boxControl = SelectBoxView(
            config,
            frame: CGRect(x: 0, y: 0, width: 17, height: 17)
        )
        boxControl.isSelected = false
        boxControl.backgroundColor = UIColor.clear
        return boxControl
    }()
    @objc func didOriginalButtonClick() {
        boxControl.isSelected = !boxControl.isSelected
        if !boxControl.isSelected {
            // 取消
            resetOriginal()
            manager.cancelRequestAssetFileSize()
        }else {
            // 选中
            requestFileSize()
        }
        pickerView.isOriginal = boxControl.isSelected
        boxControl.layer.removeAnimation(forKey: "SelectControlAnimation")
        let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
        keyAnimation.duration = 0.3
        keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
        boxControl.layer.add(keyAnimation, forKey: "SelectControlAnimation")
    }
    func resetOriginal() {
        boxControl.isSelected = false
        pickerView.isOriginal = false
        originalTitleLb.text = "原图"
        updateOriginal()
    }
    func requestFileSize() {
        if !boxControl.isSelected {
            return
        }
        manager.requestSelectedAssetFileSize { [weak self] bytes, bytesString in
            if bytes > 0 {
                self?.originalTitleLb.text = "原图" + " (" + bytesString + ")"
            }else {
                self?.originalTitleLb.text = "原图"
            }
            self?.updateOriginal()
        }
    }
    func updateOriginal() {
        let titleWidth = originalTitleLb.text!.width(ofFont: originalTitleLb.font, maxHeight: 30)
        boxControl.x = (originalBtn.width - (boxControl.width + 4 + titleWidth)) * 0.5
        originalTitleLb.x = boxControl.frame.maxX + 4
        originalTitleLb.width = titleWidth
    }
    
    lazy var sendBgView: UIView = {
        let view = UIView()
        view.addSubview(sendBlurView)
        view.addSubview(sendTitleLb)
        return view
    }()
    
    lazy var sendBlurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: effect)
        view.viewWithTag(1)?.alpha = 1
        return view
    }()
    
    lazy var sendTitleLb: UILabel = {
        let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 20)))
        label.text = "拖到此区域发送"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    var beginDragPoint: CGPoint = .zero
    
    @objc
    func didSelectPhotoClick() {
        let toolbarY = view.height - toolbar.height - UIDevice.bottomMargin
        let pickerViewY = view.height - pickerView.height - bottomView.height
        showPicker = toolbar.y == toolbarY
        if showPicker {
            // 每次显示都重新加载所有照片
            pickerView.fetchAsset()
        }
        resetOriginal()
        UIView.animate(withDuration: 0.25) {
            if self.showPicker {
                self.pickerView.y = pickerViewY
                self.toolbar.y = self.pickerView.y - 50
            }else {
                self.toolbar.y = toolbarY
                self.pickerView.y = self.view.height
            }
            self.bottomView.y = self.pickerView.frame.maxY
        } completion: { _ in
            if !self.showPicker {
                self.pickerView.clear()
            }
        }
    }
    
    var pickerViewHeight: CGFloat {
        if scrollDirection == .horizontal {
            return 200
        }else {
            return 350
        }
    }
    var scrollDirection: UICollectionView.ScrollDirection = .horizontal
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Picker View"
        view.backgroundColor = .white
        view.addSubview(pickerView)
        view.addSubview(toolbar)
        view.addSubview(bottomView)
        updateOriginal()
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "打开选择器",
            style: .plain,
            target: self,
            action: #selector(openPickerController)
        )
        let changeButton = UIButton(type: .system)
        changeButton.setTitle("改变布局", for: .normal)
        changeButton.addTarget(self, action: #selector(didChangePickerView), for: .touchUpInside)
        changeButton.frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 30))
        changeButton.y = 120
        changeButton.centerX = view.width * 0.5
        view.addSubview(changeButton)
        pickerView.fetchAsset()
        
        /// 获取相册列表
//        print(manager.fetchAssetCollections(for: .init()))
    }
    
    @objc
    func didChangePickerView() {
        if !showPicker {
            return
        }
        if scrollDirection == .horizontal {
            scrollDirection = .vertical
            pickerView.manager.config.photoList.cell.targetWidth = 250
        }else {
            scrollDirection = .horizontal
            pickerView.manager.config.photoList.cell.targetWidth = 300
        }
        UIView.animate(withDuration: 0.25) {
            self.pickerView.height = self.pickerViewHeight
            self.pickerView.y = self.view.height - self.pickerViewHeight - self.bottomView.height
            self.toolbar.y = self.pickerView.y - 50
            self.bottomView.y = self.pickerView.frame.maxY
        } completion: { _ in
            if self.scrollDirection == .horizontal {
                self.pickerView.scrollDirection = self.scrollDirection
            }
        }
        if scrollDirection == .vertical {
            pickerView.scrollDirection = scrollDirection
        }
    }
    
    @objc
    func openPickerController() {
        // 基本配置是一样的，可以直接用
        let wxConfig = PhotoTools.getWXPickerConfig()
        let vc = hx.present(
            picker: wxConfig,
            selectedAssets: pickerView.selectedAssets
        ) { [weak self] result, pickerController in
            pickerController.dismiss(true) {
                let pickerResultVC = PickerResultViewController()
                pickerResultVC.config = PhotoTools.getWXPickerConfig()
                pickerResultVC.selectedAssets = result.photoAssets
                self?.navigationController?.pushViewController(pickerResultVC, animated: true)
            }
        }
        vc.autoDismiss = false
        if showPicker {
            didSelectPhotoClick()
        }else {
            pickerView.clear()
        }
        resetOriginal()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if showPicker {
            pickerView.frame = CGRect(
                x: 0,
                y: view.height - pickerViewHeight - bottomView.height,
                width: view.width,
                height: pickerViewHeight
            )
            toolbar.frame = CGRect(x: 0, y: pickerView.y - 50, width: view.width, height: 50)
        }else {
            pickerView.frame = CGRect(x: 0, y: view.height, width: view.width, height: pickerViewHeight)
            toolbar.frame = CGRect(
                x: 0,
                y: view.height - 50 - UIDevice.bottomMargin,
                width: view.width,
                height: 50
            )
        }
        bottomView.y = pickerView.frame.maxY
    }
    deinit {
        print("deinit\(self)")
    }
}

extension WindowPickerViewController: PhotoPickerViewDelegate {
    
    func photoPickerView(
        _ photoPickerView: HXPhotoPicker.PhotoPickerView,
        didFinishSelection result: PickerResult
    ) {
        if showPicker {
            didSelectPhotoClick()
        }else {
            pickerView.clear()
        }
        resetOriginal()
    }
    
    /// 在dismiss完成之后再跳转界面
    func photoPickerView(
        _ photoPickerView: HXPhotoPicker.PhotoPickerView,
        dismissCompletion result: PickerResult
    ) {
        let pickerResultVC = PickerResultViewController()
        pickerResultVC.config = PhotoTools.getWXPickerConfig()
        pickerResultVC.selectedAssets = result.photoAssets
        navigationController?.pushViewController(pickerResultVC, animated: true)
    }
    
    func photoPickerView(_ photoPickerView: HXPhotoPicker.PhotoPickerView, didSelectAsset photoAsset: PhotoAsset, at index: Int) {
        requestFileSize()
        finishButton.isEnabled = !pickerView.selectedAssets.isEmpty
    }
    
    func photoPickerView(_ photoPickerView: HXPhotoPicker.PhotoPickerView, didDeselectAsset photoAsset: PhotoAsset, at index: Int) {
        requestFileSize()
        finishButton.isEnabled = !pickerView.selectedAssets.isEmpty
    }
    
    func photoPickerView(_ photoPickerView: HXPhotoPicker.PhotoPickerView, previewDidOriginalButton isSelected: Bool) {
        if isSelected != boxControl.isSelected {
            didOriginalButtonClick()
        }
    }
    
    func photoPickerView(
        _ photoPickerView: HXPhotoPicker.PhotoPickerView,
        gestureRecognizer: UIPanGestureRecognizer,
        beginDrag photoAsset: PhotoAsset,
        dragView: UIView
    ) {
        let keyWindow = UIApplication.shared.keyWindow
        beginDragPoint = gestureRecognizer.location(in: keyWindow)
        sendBgView.frame = CGRect(x: 0, y: 0, width: view.width, height: pickerView.y - 50)
        sendBlurView.frame = sendBgView.bounds
        UIView.animate(withDuration: 0.25) {
            self.sendBlurView.effect = UIBlurEffect(style: .light)
            self.sendBlurView.viewWithTag(1)?.alpha = 1
        }
        sendTitleLb.center = CGPoint(x: sendBgView.width * 0.5, y: sendBgView.height * 0.5)
        keyWindow?.insertSubview(sendBgView, belowSubview: dragView)
        sendBgView.backgroundColor = UIColor(hexString: "#87CEFA").withAlphaComponent(0)
        sendTitleLb.alpha = 0
    }
    
    func photoPickerView(
        _ photoPickerView: HXPhotoPicker.PhotoPickerView,
        gestureRecognizer: UIPanGestureRecognizer,
        changeDrag photoAsset: PhotoAsset
    ) {
        let point = gestureRecognizer.location(in: UIApplication.shared.keyWindow)
        if point.y < sendBgView.frame.maxY {
            sendTitleLb.text = "松手发送"
        }else {
            sendTitleLb.text = "拖到此区域发送"
        }
        
        var scale = 1 - (point.y - sendBgView.frame.maxY) / (beginDragPoint.y - sendBgView.frame.maxY)
        if scale < 0 {
            scale = 0
        }
        if scale > 1 {
            scale = 1
        }
        sendBgView.backgroundColor = UIColor(hexString: "#87CEFA").withAlphaComponent(scale)
        sendTitleLb.alpha = scale * 5
    }
    
    func photoPickerView(
        _ photoPickerView: HXPhotoPicker.PhotoPickerView,
        gestureRecognizer: UIPanGestureRecognizer,
        endDrag photoAsset: PhotoAsset
    ) -> Bool {
        UIView.animate(withDuration: 0.25) {
            self.sendBgView.backgroundColor = UIColor(hexString: "#87CEFA").withAlphaComponent(0)
            self.sendTitleLb.alpha = 0
            self.sendBlurView.effect = nil
            self.sendBlurView.viewWithTag(1)?.alpha = 0
        } completion: { _ in
            self.sendBgView.removeFromSuperview()
        }
        let point = gestureRecognizer.location(in: UIApplication.shared.keyWindow)
        if point.y < sendBgView.frame.maxY {
            view.hx.showSuccess(text: "发送成功", delayHide: 1.5, animated: true)
            /*
             获取Asset的URL
             photoAsset.getAssetURL { result in
                 switch result {
                 case .success(let result):
                     print(result.url)
                 case .failure(let error):
                     print(error)
                 }
             }
             */
            if photoAsset.isSelected {
                pickerView.deselect(at: photoAsset)
            }
            return false
        }
        return true
    }
}
