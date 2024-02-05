//
//  PhotoAlbumViewController.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/19.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit
import Photos

public class PhotoAlbumViewController: UIViewController, PhotoAlbumController {
    
    public weak var delegate: PhotoAlbumControllerDelegate?
    public var assetCollections: [PhotoAssetCollection] = []
    public var selectedAssetCollection: PhotoAssetCollection?
    
    let config: PickerConfiguration
    public required init(config: PickerConfiguration) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    var tableView: UITableView!
    var datas: [AlbumData] = []
    var rowCount: CGFloat {
        (UIDevice.isPad || !UIDevice.isPortrait) ? 4 : 2
    }
    
    public override func viewDidLoad() {
        if config.albumShowMode.isPop {
            title = .textManager.picker.albumList.selectNavigationTitle.text
        }else {
            title = .textManager.picker.albumList.navigationTitle.text
        }
        navigationController?.navigationBar.isTranslucent = config.navigationBarIsTranslucent
//        if #available(iOS 11.0, *) {
//            navigationItem.backButtonTitle = ""
//        }else {
//            navigationItem.backBarButtonItem = .init(title: "", style: .plain, target: self, action: #selector(didBackClick))
//        }
        initItems()
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        tableView.register(PhotoAlbumCollectionCell.self)
        tableView.register(PhotoAlbumViewCell.self)
        tableView.register(PhotoAlbumHeaderView.self, forHeaderFooterViewReuseIdentifier: PhotoAlbumHeaderView.className)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        view.addSubview(tableView)
        reloadData()
        updateColors()
    }
    
    func initItems() {
        let items = config.albumController.leftNavigationItems + config.albumController.rightNavigationItems
        var leftItems: [UIBarButtonItem] = []
        var rightItems: [UIBarButtonItem] = []
        for (index, item) in items.enumerated() {
            let view = item.init(config: config)
            view.itemDelegate = self
            if index < config.albumController.leftNavigationItems.count {
                leftItems.append(.init(customView: view))
            }else {
                rightItems.append(.init(customView: view))
            }
        }
        navigationItem.leftBarButtonItems = leftItems
        navigationItem.rightBarButtonItems = rightItems
    }
    
//    @objc
//    func didBackClick() {
//        navigationController?.popViewController(animated: true)
//    }
    
    public func reloadData() {
        datas = []
        var userAlbums: [PhotoAssetCollection] = []
        var systemAlbums: [PhotoAssetCollection] = []
        for assetCollection in assetCollections {
            if let collection = assetCollection.collection {
                if collection.assetCollectionType == .album ||
                    collection.assetCollectionSubtype == .smartAlbumUserLibrary ||
                    collection.assetCollectionSubtype == .albumRegular {
                    userAlbums.append(assetCollection)
                    continue
                }
            }
            systemAlbums.append(assetCollection)
        }
        if !userAlbums.isEmpty {
            datas.append(.init(title: .textManager.picker.albumList.myAlbumSectionTitle.text, assetCollections: userAlbums))
        }
        if !systemAlbums.isEmpty {
            datas.append(.init(title: .textManager.picker.albumList.mediaSectionTitle.text, assetCollections: systemAlbums))
        }
        tableView.reloadData()
    }
    
    func updateColors() {
        if config.appearanceStyle == .normal {
            if #available(iOS 13.0, *) {
                overrideUserInterfaceStyle = .light
            }
        }
        let isDark = PhotoManager.isDark
        let titleTextAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor:
                isDark ? config.navigationTitleDarkColor : config.navigationTitleColor,
            .font: UIFont.semiboldPingFang(ofSize: 18)
        ]
        view.backgroundColor = isDark ? config.albumController.backgroundDarkColor : config.albumController.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        navigationController?.navigationBar.tintColor = isDark ? config.navigationDarkTintColor: config.navigationTintColor
        navigationController?.navigationBar.titleTextAttributes = titleTextAttributes
        let barStyle = isDark ? config.navigationBarDarkStyle : config.navigationBarStyle
        navigationController?.navigationBar.barStyle = barStyle
        
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.titleTextAttributes = titleTextAttributes
            switch barStyle {
            case .`default`:
                appearance.backgroundEffect = UIBlurEffect(style: .extraLight)
            default:
                appearance.backgroundEffect = UIBlurEffect(style: .dark)
            }
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.albumController(willAppear: self)
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.albumController(didAppear: self)
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.albumController(willDisappear: self)
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.albumController(didDisappear: self)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateColors()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        HXLog("PhotoAlbumViewController deinited 👍")
    }
    
    struct AlbumData {
        let title: String
        let assetCollections: [PhotoAssetCollection]
    }
}

extension PhotoAlbumViewController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        datas.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return datas[section].assetCollections.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell: PhotoAlbumCollectionCell = tableView.dequeueReusableCell()
            cell.delegate = self
            cell.config = config.albumController
            cell.assetCollections = datas[indexPath.section].assetCollections
            return cell
        }
        let cell: PhotoAlbumViewCell = tableView.dequeueReusableCell()
        cell.config = config.albumController
        cell.assetCollection = datas[indexPath.section].assetCollections[indexPath.row]
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            let data = datas[indexPath.section]
            let count = data.assetCollections.count
            let marginCount = rowCount - 1
            let margin: CGFloat = assetCollections.count > Int(rowCount) * 2 ? 5 : 0
            let itemWidth = (view.width - (30 + 12 * marginCount) - UIDevice.leftMargin - UIDevice.rightMargin) / rowCount - margin
            let fontHeight = config.albumController.albumNameFont.lineHeight + config.albumController.photoCountFont.lineHeight + 8
            let itemHeight = itemWidth + fontHeight + 20
            if count <= Int(rowCount) {
                return itemHeight
            }
            return itemHeight * 2
        }
        return 50
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotoAlbumHeaderView.className) as! PhotoAlbumHeaderView
        view.delegate = self
        view.config = config.albumController
        let data = datas[section]
        view.titleLb.text = data.title
        view.allBtn.isHidden = section != 0 || data.assetCollections.count <= Int(rowCount) * 2
        return view
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        50
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        .init()
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0.01
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            return
        }
        let assetCollection = datas[indexPath.section].assetCollections[indexPath.row]
        collectionCell(didSelected: assetCollection)
    }
}

extension PhotoAlbumViewController:
    PhotoAlbumCollectionCellDelegate,
    PhotoMyAlbumViewControllerDelegate,
    PhotoAlbumHeaderViewDelegate,
    PhotoNavigationItemDelegate
{
    
    public func collectionCell(didSelected assetCollection: PhotoAssetCollection) {
        delegate?.albumController(self, didSelectedWith: assetCollection)
    }
    
    public func myAlbumViewController(_ myAlbumViewController: PhotoMyAlbumViewController, didSelectedWith assetCollection: PhotoAssetCollection) {
        collectionCell(didSelected: assetCollection)
    }
    
    public func myAlbumViewController(willAppear myAlbumViewController: PhotoMyAlbumViewController) {
        delegate?.albumController(willAppear: self)
    }
    
    public func myAlbumViewController(didAppear myAlbumViewController: PhotoMyAlbumViewController) {
        delegate?.albumController(didAppear: self)
    }
    
    public func myAlbumViewController(willDisappear myAlbumViewController: PhotoMyAlbumViewController) {
        delegate?.albumController(willDisappear: self)
    }
    
    public func myAlbumViewController(didDisappear myAlbumViewController: PhotoMyAlbumViewController) {
        delegate?.albumController(didDisappear: self)
    }
    
    public func albumHeaderView(didAllClick albumHeaderView: PhotoAlbumHeaderView) {
        let vc = PhotoMyAlbumViewController()
        vc.delegate = self
        vc.config = config.albumController
        vc.assetCollections = datas[0].assetCollections
        navigationController?.pushViewController(vc, animated: true)
    }
    
    public func photoControllerDidCancel() {
        dismiss(animated: true)
    }
}
