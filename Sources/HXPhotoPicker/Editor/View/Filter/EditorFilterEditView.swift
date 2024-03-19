//
//  EditorFilterEditView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/18.
//

import UIKit

class EditorFilterEditModel: Equatable {
    
    enum `Type` {
        case brightness
        case contrast
        case exposure
        case saturation
        case warmth
        case vignette
        case sharpen
        case highlights
        case shadows
        
        var title: String {
            switch self {
            case .brightness:
                return .textManager.editor.adjustment.brightnessTitle.text
            case .contrast:
                return .textManager.editor.adjustment.contrastTitle.text
            case .exposure:
                return .textManager.editor.adjustment.exposureTitle.text
            case .saturation:
                return .textManager.editor.adjustment.saturationTitle.text
            case .warmth:
                return .textManager.editor.adjustment.warmthTitle.text
            case .vignette:
                return .textManager.editor.adjustment.vignetteTitle.text
            case .sharpen:
                return .textManager.editor.adjustment.sharpenTitle.text
            case .highlights:
                return .textManager.editor.adjustment.highlightsTitle.text
            case .shadows:
                return .textManager.editor.adjustment.shadowsTitle.text
            }
        }
        
        var image: UIImage? {
            switch self {
            case .brightness:
                return .imageResource.editor.adjustment.brightness.image
            case .contrast:
                return .imageResource.editor.adjustment.contrast.image
            case .exposure:
                return .imageResource.editor.adjustment.exposure.image
            case .saturation:
                return .imageResource.editor.adjustment.saturation.image
            case .warmth:
                return .imageResource.editor.adjustment.warmth.image
            case .vignette:
                return .imageResource.editor.adjustment.vignette.image
            case .sharpen:
                return .imageResource.editor.adjustment.sharpen.image
            case .highlights:
                return .imageResource.editor.adjustment.highlights.image
            case .shadows:
                return .imageResource.editor.adjustment.shadows.image
            }
        }
    }
    
    let type: `Type`
    
    let parameters: [PhotoEditorFilterParameterInfo]
    
    init(
        type: `Type`,
        parameters: [PhotoEditorFilterParameterInfo]
    ) {
        self.type = type
        self.parameters = parameters
    }
    
    static func == (lhs: EditorFilterEditModel, rhs: EditorFilterEditModel) -> Bool {
        lhs === rhs
    }
}

protocol EditorFilterEditViewDelegate: AnyObject {
    func filterEditView(_ filterEditView: EditorFilterEditView, didSelected editModel: EditorFilterEditModel)
}

class EditorFilterEditView: UIView {
    
    weak var delegate: EditorFilterEditViewDelegate?
    
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    
    let models: [EditorFilterEditModel]
    
    init() {
        models = [
            .init(
                type: .brightness,
                parameters: [.init(parameter: .init(defaultValue: 0), sliderType: .center)]
            ),
            .init(
                type: .contrast,
                parameters: [.init(parameter: .init(defaultValue: 0), sliderType: .normal)]
            ),
            .init(
                type: .saturation,
                parameters: [.init(parameter: .init(defaultValue: 0), sliderType: .center)]
            ),
            .init(
                type: .exposure,
                parameters: [.init(parameter: .init(defaultValue: 0), sliderType: .center)]
            ),
            .init(
                type: .highlights,
                parameters: [.init(parameter: .init(defaultValue: 0), sliderType: .normal)]
            ),
            .init(
                type: .shadows,
                parameters: [.init(parameter: .init(defaultValue: 0), sliderType: .center)]
            ),
            .init(
                type: .warmth,
                parameters: [.init(parameter: .init(defaultValue: 0), sliderType: .center)]
            ),
            .init(
                type: .vignette,
                parameters: [.init(parameter: .init(defaultValue: 0), sliderType: .normal)]
            ),
            .init(
                type: .sharpen,
                parameters: [.init(parameter: .init(defaultValue: 0), sliderType: .center)]
            )
        ]
        super.init(frame: .zero)
        flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 10
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.itemSize = CGSize(width: 60, height: 90)
        collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 50),
            collectionViewLayout: flowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(
            EditorFilterEditViewCell.self,
            forCellWithReuseIdentifier: "EditorFilterEditViewCellID"
        )
        addSubview(collectionView)
    }
    
    func scrollToValue() {
        var item: Int?
        for (index, model) in models.enumerated() {
            guard let value = model.parameters.first?.value else {
                continue
            }
            if value != 0 {
                item = index
                break
            }
        }
        guard let item else { return }
        collectionView.scrollToItem(at: .init(item: item, section: 0), at: UIDevice.isPortrait ? .centeredHorizontally : .centeredVertically, animated: false)
    }
    
    func reloadData() {
        collectionView.reloadData()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            let count = CGFloat(models.count)
            let contentWidth = 60 * count + 10 * (count - 1) + UIDevice.rightMargin + 30
            let maxWidth = width
            if contentWidth < maxWidth {
                let collectionX = (maxWidth - contentWidth) * 0.5
                collectionView.frame = .init(x: collectionX, y: 0, width: min(maxWidth, contentWidth), height: height)
            }else {
                collectionView.frame = bounds
            }
            flowLayout.scrollDirection = .horizontal
            flowLayout.sectionInset = UIEdgeInsets(
                top: 10,
                left: 15 + UIDevice.leftMargin,
                bottom: 0,
                right: 15 + UIDevice.rightMargin
            )
        }else {
            collectionView.frame = bounds
            flowLayout.scrollDirection = .vertical
            flowLayout.sectionInset = UIEdgeInsets(
                top: 15,
                left: 10,
                bottom: 15 + UIDevice.bottomMargin,
                right: 0
            )
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension EditorFilterEditView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        models.count
    }
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorFilterEditViewCellID",
            for: indexPath
        ) as! EditorFilterEditViewCell
        cell.model = models[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        delegate?.filterEditView(self, didSelected: models[indexPath.item])
    }
}

class EditorFilterEditViewCell: UICollectionViewCell {
    
    private var bgView: UIVisualEffectView!
    private var imageView: UIImageView!
    private var titleLb: UILabel!
    private var parameterLb: UILabel!
    
    var model: EditorFilterEditModel? {
        didSet {
            guard let model = model else {
                return
            }
            titleLb.text = model.type.title
            imageView.image = model.type.image
            if let para = model.parameters.first, !para.isNormal {
                parameterLb.isHidden = false
                parameterLb.text = String(Int(para.value * 100))
            }else {
                parameterLb.isHidden = true
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView()
        let visualEffect = UIBlurEffect.init(style: .dark)
        bgView = UIVisualEffectView.init(effect: visualEffect)
        bgView.contentView.addSubview(imageView)
        bgView.layer.masksToBounds = true
        contentView.addSubview(bgView)
        titleLb = UILabel()
        titleLb.textColor = .white
        titleLb.font = .regularPingFang(ofSize: 13)
        titleLb.textAlignment = .center
        titleLb.adjustsFontSizeToFitWidth = true
        contentView.addSubview(titleLb)
        parameterLb = UILabel()
        parameterLb.text = "0"
        parameterLb.textColor = .white
        parameterLb.font = .regularPingFang(ofSize: 11)
        parameterLb.textAlignment = .center
        parameterLb.isHidden = true
        contentView.addSubview(parameterLb)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgView.frame = .init(x: 4, y: 4, width: width - 8, height: width - 8)
        bgView.layer.cornerRadius = bgView.width * 0.5
        imageView.size = .init(width: 20, height: 20)
        imageView.centerX = bgView.width * 0.5
        imageView.centerY = bgView.height * 0.5
        titleLb.y = bgView.frame.maxY + 12
        titleLb.width = 0
        titleLb.height = titleLb.textHeight
        titleLb.width = width
        
        parameterLb.y = titleLb.frame.maxY + 2
        parameterLb.width = width
        parameterLb.height = 12
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
