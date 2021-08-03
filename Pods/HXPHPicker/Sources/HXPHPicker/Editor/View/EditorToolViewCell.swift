//
//  EditorToolViewCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

protocol EditorToolViewCellDelegate: AnyObject {
    func toolViewCell(didClick cell: EditorToolViewCell)
}

class EditorToolViewCell: UICollectionViewCell {
    weak var delegate: EditorToolViewCellDelegate?
    lazy var boxView: SelectBoxView = {
        let view = SelectBoxView.init(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        view.isHidden = true
        view.config.style = .tick
        view.config.tickWidth = 1
        view.config.tickColor = .white
        view.config.tickDarkColor = .white
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(didButtonClick), for: .touchUpInside)
        button.tintColor = .white
        return button
    }()
    
    @objc func didButtonClick() {
        delegate?.toolViewCell(didClick: self)
    }
    
    var showBox: Bool = false {
        didSet {
            boxView.isSelected = showBox
            boxView.isHidden = !showBox
        }
    }
    var boxColor: UIColor! {
        didSet {
            boxView.config.selectedBackgroundColor = boxColor
            boxView.config.selectedBackgroudDarkColor = boxColor
        }
    }
    
    var model: EditorToolOptions! {
        didSet {
            let image = UIImage.image(for: model.imageName)?.withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: .normal)
        }
    }
    var selectedColor: UIColor?
    var isSelectedImageView: Bool = false {
        didSet {
            button.tintColor = isSelectedImageView ? selectedColor : .white
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(button)
        contentView.addSubview(boxView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = bounds
        if let image = button.image(for: .normal) {
            boxView.x = width * 0.5 + image.width * 0.5 - boxView.width * 0.5
            boxView.y = height * 0.5 + image.height * 0.5 - boxView.height + 3
        }
    }
}
