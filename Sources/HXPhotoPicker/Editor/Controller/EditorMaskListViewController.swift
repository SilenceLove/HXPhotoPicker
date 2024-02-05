//
//  EditorMaskListViewController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/6/11.
//

import UIKit
import CoreGraphics
import CoreText

protocol EditorMaskListViewControllerDelegate: AnyObject {
    func editorMaskListViewController(
        _ editorMaskListViewController: EditorMaskListViewController,
        didSelected image: UIImage
    )
}

class EditorMaskListViewController: BaseViewController {
    
    weak var delegate: EditorMaskListViewControllerDelegate?
    
    private var bgView: UIVisualEffectView!
    private var finishButton: UIButton!
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    
    let config: EditorConfiguration.CropSize
    init(config: EditorConfiguration.CropSize) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
        view.backgroundColor = .clear
        title = .textManager.editor.crop.maskListTitle.text
        let finishButtonWidth = finishButton.currentTitle?.width(
            ofFont: finishButton.titleLabel!.font,
            maxHeight: 50
        ) ?? 0
        finishButton.width = finishButtonWidth
        finishButton.height = 30
        navigationItem.rightBarButtonItem = .init(customView: finishButton)
        view.addSubview(bgView)
        view.addSubview(collectionView)
    }
    
    private func initViews() {
        let visualEffect = UIBlurEffect.init(style: .dark)
        bgView = UIVisualEffectView.init(effect: visualEffect)
        
        finishButton = UIButton(type: .system)
        finishButton.setTitle(.textManager.editor.crop.maskListFinishTitle.text, for: .normal)
        finishButton.setTitleColor(config.angleScaleColor, for: .normal)
        finishButton.titleLabel?.font = .textManager.editor.crop.maskListFinishTitleFont
        finishButton.isEnabled = false
        finishButton.addTarget(self, action: #selector(didFinishButtonClick), for: .touchUpInside)
        
        flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.minimumLineSpacing = 10
        flowLayout.minimumInteritemSpacing = 10
        
        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: flowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(EditorMaskListViewCell.self, forCellWithReuseIdentifier: "EditorMaskListViewCellID")
    }
    
    @objc
    private func didFinishButtonClick() {
        dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(.image(for: .clear, havingSize: .zero), for: .default)
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgView.frame = view.bounds
        
        let spacing = flowLayout.minimumInteritemSpacing
        let rowCount = UIDevice.isPortrait ? config.maskRowCount: config.maskLandscapeRowNumber
        let itemWidth = (
            view.width - UIDevice.leftMargin - UIDevice.rightMargin - 24 - spacing * (rowCount - 1)
        ) / rowCount
        flowLayout.itemSize = .init(width: itemWidth, height: itemWidth)
        
        collectionView.contentInset = .init(
            top: 12,
            left: 12 + UIDevice.leftMargin,
            bottom: 12 + UIDevice.bottomMargin,
            right: 12 + UIDevice.rightMargin
        )
        
        let navHeight = navigationController?.navigationBar.frame.maxY ?? UIDevice.navigationBarHeight
        collectionView.frame = .init(x: 0, y: navHeight, width: view.width, height: view.height - navHeight)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorMaskListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        config.maskList.count
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorMaskListViewCellID",
            for: indexPath
        ) as! EditorMaskListViewCell
        cell.config = config.maskList[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let maskType = config.maskList[indexPath.item]
        switch maskType {
        case .image(let image):
            dismiss(animated: true)
            delegate?.editorMaskListViewController(self, didSelected: image)
        case .imageName(let imageName):
            if let image = imageName.image {
                dismiss(animated: true)
                delegate?.editorMaskListViewController(self, didSelected: image)
            }else {
                ProgressHUD.showWarning(addedTo: view, text: .textManager.editor.processingFailedHUDTitle.text, animated: true, delayHide: 1.5)
            }
        case .text(let text, let font):
            ProgressHUD.showLoading(addedTo: self.view)
            let viewSize = view.size
            DispatchQueue.global(qos: .userInitiated).async {
                let newFont = UIFont(name: font.fontName, size: min(viewSize.width, viewSize.height)) ?? font
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let attDic: [NSAttributedString.Key: Any] = [
                    .font: newFont,
                    .paragraphStyle: paragraphStyle
                ]
                let rect = text.boundingRect(ofAttributes: attDic, size: .init(width: 9999, height: 9999))
                let format = UIGraphicsImageRendererFormat()
                format.opaque = false
                format.scale = UIScreen._scale
                let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
                let image = renderer.image { context in
                    let string = text as NSString
                    string.draw(in: rect, withAttributes: attDic)
                }
                DispatchQueue.main.async {
                    ProgressHUD.hide(forView: self.view)
                    self.dismiss(animated: true)
                    self.delegate?.editorMaskListViewController(self, didSelected: image)
                }
            }
        }
    }
}
