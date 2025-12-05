//
//  AlbumGlassTitleView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/10/12.
//  Copyright © 2025 Silence. All rights reserved.
//

import UIKit

@available(iOS 26.0, *)
public class AlbumGlassTitleView: UIView, PhotoPickerNavigationTitle {
    let config: PickerConfiguration
    let isSplit: Bool
    
    public var title: String? {
       didSet {
           if let title = title {
               button.setTitle(title, for: .normal)
           }else {
               button.setTitle(.textPhotoList.emptyNavigationTitle.text, for: .normal)
           }
           updateFrame()
       }
    }
    
    public var titleColor: UIColor?
    
    public var isSelected: Bool = false {
        didSet {
            if !isPopupAlbum {
                return
            }
            UIView.animate(withDuration: 0.25) {
                if self.isSelected {
                    self.button.imageView?.transform = .init(rotationAngle: .pi)
                }else {
                    self.button.imageView?.transform = .init(rotationAngle: .pi * 2)
                }
            }
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        contentSize
    }
    
    var button: UIButton!
    
    required public init(config: PickerConfiguration, isSplit: Bool) {
        self.config = config
        self.isSplit = isSplit
        super.init(frame: .zero)
        initViews()
        size = contentSize
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    var isPopupAlbum: Bool { config.albumShowMode.isPop && !isSplit }
    var isPresentAlbum: Bool { config.albumShowMode.isPresent && !isSplit }
    
    var contentSize: CGSize {
        let maxWidth: CGFloat
        #if !targetEnvironment(macCatalyst)
        if UIDevice.isPad {
            maxWidth = 300
        }else {
            maxWidth = 200
        }
        #else
        maxWidth = 300
        #endif
        let text = button.currentTitle ?? ""
        let titleWidth: CGFloat = min(maxWidth, text.width(ofFont: .semiboldPingFang(ofSize: 18), maxHeight: .max))
        if isPopupAlbum {
            return .init(width: titleWidth + 50 , height: 44)
        }else {
            return .init(width: titleWidth + 20, height: 44)
        }
    }
    
    private func initViews() {
        button = UIButton(type: .system)
        var configuration = config.photoList.titleButtonConfig
        configuration?.titleLineBreakMode = .byTruncatingTail
        configuration?.contentInsets = .init(top: 0, leading: 1, bottom: 0, trailing: 1)
        button.configuration = configuration
        if isPopupAlbum {
            button.setImage(.init(systemName: "chevron.down.circle.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        
        addSubview(button)
    }
    
    var selectHandler: ((PhotoAssetCollection) -> Void)?
    var assetCollections: [PhotoAssetCollection] = []
    var actions: [UIAction] = []
    public func makeAlbumData(_ collections: [PhotoAssetCollection], selectHandler: @escaping (PhotoAssetCollection) -> Void) {
        assetCollections = collections
        self.selectHandler = selectHandler
        var actions: [UIAction] = []
        for (index, collection) in collections.enumerated() {
            let albumName = collection.albumName ?? ""
            let id = UIAction.Identifier("album_\(index)")
            let action = UIAction(title: albumName, identifier: id, state: collection.isSelected ? .on: .off, handler: { [weak self] action in
                guard let self else { return }
                if index < self.assetCollections.count {
                    let assetCollection = self.assetCollections[index]
                    self.selectHandler?(assetCollection)
                }
            })
            _ = collection.requestCoverImage() { [weak self] in
                guard let self = self else { return }
                if let info = $2, info.isCancel { return }
                if index < self.actions.count, let image = $0?.scaleToFillSize(size: CGSize(width: 50, height: 50), mode: .center, scale: UIScreen.main.scale) {
                    let action = self.actions[index]
                    action.image = image
                    if let old = self.button.menu {
                        self.button.menu = old.replacingChildren(self.actions)
                    }
                }
            }
            actions.append(action)
        }
        self.actions = actions
        let menu = UIMenu(title: .textManager.picker.albumList.navigationTitle.text,
                          image: nil,
                          identifier: nil,
                          options: [.singleSelection],
                          children: actions)
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
    }
    
    public func addTarget(_ target: Any?, action: Selector) {
        if isPresentAlbum {
            button.addTarget(target, action: action, for: .touchUpInside)
        }
    }
    
    public func updateFrame() {
        size = contentSize
        invalidateIntrinsicContentSize()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = bounds
    }

    required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
    }
}
