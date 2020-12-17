//
//  HXAlbumView.swift
//  HXPHPickerExample
//
//  Created by 洪欣 on 2020/11/17.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

protocol HXAlbumViewDelegate: NSObjectProtocol {
    func albumView(_ albumView: HXAlbumView, didSelectRowAt assetCollection: HXPHAssetCollection)
}

class HXAlbumView: UIView, UITableViewDataSource, UITableViewDelegate {
    
    weak var delegate: HXAlbumViewDelegate?
    
    lazy var tableView : UITableView = {
        let tableView = UITableView.init(frame: CGRect.init(), style: .plain)
        if HXPHAssetManager.authorizationStatusIsLimited() {
            tableView.tableHeaderView = promptLb
        }
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = .none
        tableView.register(HXAlbumViewCell.self, forCellReuseIdentifier: "cellId")
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        return tableView
    }()
    lazy var promptLb: UILabel = {
        let promptLb = UILabel.init(frame: CGRect(x: 0, y: 0, width: 0, height: 40))
        promptLb.text = "只能查看允许访问的照片和相关相册".hx_localized
        promptLb.textAlignment = .center
        promptLb.font = UIFont.systemFont(ofSize: 14)
        promptLb.adjustsFontSizeToFitWidth = true
        promptLb.numberOfLines = 0
        return promptLb
    }()
    var config: HXPHAlbumListConfiguration
    var assetCollectionsArray: [HXPHAssetCollection] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var currentSelectedRow: Int = 0
    var currentSelectedAssetCollection: HXPHAssetCollection? {
        didSet {
            if currentSelectedAssetCollection != nil {
                currentSelectedRow = assetCollectionsArray.firstIndex(of: currentSelectedAssetCollection!) ?? 0
            }
        }
    }
    
    init(config: HXPHAlbumListConfiguration) {
        self.config = config
        super.init(frame: CGRect.zero)
        addSubview(tableView)
        configColor()
    }
    func scrollToMiddle() {
        if assetCollectionsArray.isEmpty {
            return
        }
        let indexPath = IndexPath(row: currentSelectedRow, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    }
    func configColor() {
        tableView.backgroundColor = HXPHManager.shared.isDark ? config.backgroundDarkColor : config.backgroundColor
        backgroundColor = HXPHManager.shared.isDark ? config.backgroundDarkColor : config.backgroundColor
        promptLb.textColor = HXPHManager.shared.isDark ? config.limitedStatusPromptDarkColor : config.limitedStatusPromptColor
    }
    func updatePrompt() {
        if HXPHAssetManager.authorizationStatusIsLimited() {
            tableView.tableHeaderView = promptLb
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetCollectionsArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId") as! HXAlbumViewCell
        let assetCollection = assetCollectionsArray[indexPath.row]
        cell.assetCollection = assetCollection
        cell.config = config
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return config.cellHeight
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let assetCollection = assetCollectionsArray[indexPath.row]
        currentSelectedAssetCollection = assetCollection
        delegate?.albumView(self, didSelectRowAt: assetCollection)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let myCell: HXAlbumViewCell = cell as! HXAlbumViewCell
        myCell.cancelRequest()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if HXPHAssetManager.authorizationStatusIsLimited() {
            promptLb.hx_width = hx_width
        }
        tableView.frame = bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
 
class HXAlbumTitleView: UIControl {
    
    var config: HXAlbumTitleViewConfiguration
    
    lazy var contentView: UIView = {
        let contentView = UIView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 30))
        contentView.layer.cornerRadius = 15
        contentView.layer.masksToBounds = true
        contentView.isUserInteractionEnabled = false
        return contentView
    }()
    
    var title: String? {
        didSet {
            if title == nil {
                title = "相册".hx_localized
            }
            titleLb.text = title
            var titleWidth = self.title?.hx_stringWidth(ofFont: self.titleLb.font, maxHeight: self.hx_height) ?? 0
            if titleWidth > hx_width - 40 {
                titleWidth = hx_width - 45
            }
            UIView.animate(withDuration: 0.25) {
                self.titleLb.hx_width = titleWidth
                self.arrowView.hx_x = self.titleLb.frame.maxX + 5
                self.contentView.hx_width = self.arrowView.frame.maxX + 5
                self.contentView.hx_centerX = self.hx_width * 0.5
            }
        }
    }
    
    var titleColor: UIColor? {
        didSet {
            titleLb.textColor = titleColor
        }
    }
    
    private lazy var titleLb: UILabel = {
        let text = "相册".hx_localized
        let font = UIFont.hx_semiboldPingFang(size: 18)
        let titleLb = UILabel.init(frame: CGRect(x: 10, y: 0, width: text.hx_stringWidth(ofFont: font, maxHeight: self.hx_height), height: self.hx_height))
        titleLb.text = text
        titleLb.font = font
        titleLb.textAlignment = .center
        return titleLb
    }()
    
    lazy var arrowView: HXAlbumTitleArrowView = {
        let arrowView = HXAlbumTitleArrowView.init(frame: CGRect(x: titleLb.frame.maxX + 5, y: 0, width: 20, height: 20), config: self.config)
        
        return arrowView
    }()
    
    init(config: HXAlbumTitleViewConfiguration) {
        self.config = config
        super.init(frame: CGRect.zero)
        hx_size = CGSize(width: UIScreen.main.bounds.size.width * 0.5, height: 30)
        contentView.addSubview(titleLb)
        contentView.addSubview(arrowView)
        addSubview(contentView)
        configColor()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLb.hx_height = hx_height
        arrowView.hx_centerY = titleLb.hx_centerY
        contentView.hx_height = hx_height
    }
    
    func configColor() {
        contentView.backgroundColor = HXPHManager.shared.isDark ? config.backgroudDarkColor : config.backgroundColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HXAlbumTitleArrowView: UIView {
    var config: HXAlbumTitleViewConfiguration
    lazy var backgroundLayer: CAShapeLayer = {
        let backgroundLayer = CAShapeLayer.init()
        backgroundLayer.contentsScale = UIScreen.main.scale
        return backgroundLayer
    }()
    lazy var arrowLayer: CAShapeLayer = {
        let arrowLayer = CAShapeLayer.init()
        arrowLayer.contentsScale = UIScreen.main.scale
        return arrowLayer
    }()
    init(frame: CGRect, config: HXAlbumTitleViewConfiguration) {
        self.config = config
        super.init(frame: frame)
        drawContent()
        configColor()
    }
    
    func drawContent() {
        let circlePath = UIBezierPath.init(arcCenter: CGPoint.init(x: hx_width * 0.5, y: hx_height * 0.5), radius: hx_width * 0.5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        backgroundLayer.path = circlePath.cgPath
        layer.addSublayer(backgroundLayer)
        
        let arrowPath = UIBezierPath.init()
        arrowPath.move(to: CGPoint(x: 5, y: 8))
        arrowPath.addLine(to: CGPoint(x: hx_width / 2, y: hx_height - 7))
        arrowPath.addLine(to: CGPoint(x: hx_width - 5, y: 8))
        arrowLayer.path = arrowPath.cgPath
        arrowLayer.lineWidth = 1.5
        arrowLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(arrowLayer)
    }
    
    func configColor() {
        backgroundLayer.fillColor = HXPHManager.shared.isDark ? config.arrowBackgroudDarkColor.cgColor : config.arrowBackgroundColor.cgColor
        arrowLayer.strokeColor = HXPHManager.shared.isDark ? config.arrowDarkColor.cgColor : config.arrowColor.cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
