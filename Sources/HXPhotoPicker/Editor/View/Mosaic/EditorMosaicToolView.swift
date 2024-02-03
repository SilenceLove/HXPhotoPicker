//
//  EditorMosaicToolView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/20.
//

import UIKit

protocol EditorMosaicToolViewDelegate: AnyObject {
    func mosaicToolView(
        _ mosaicToolView: EditorMosaicToolView,
        didChangedMosaicType type: EditorMosaicType
    )
    func mosaicToolView(
        didUndoClick mosaicToolView: EditorMosaicToolView
    )
}

class EditorMosaicToolView: UIView {
    weak var delegate: EditorMosaicToolViewDelegate?
    private var mosaicButton: UIButton!
    private var smearButton: UIButton!
    private var undoButton: UIButton!
    
    var canUndo: Bool = false {
        didSet {
            undoButton.isEnabled = canUndo
        }
    }
    var mosaicType: EditorMosaicType = .mosaic {
        didSet {
            if mosaicType == .mosaic {
                mosaicButton.isSelected = true
                mosaicButton.imageView?.tintColor = selectedColor
                smearButton.isSelected = false
                smearButton.imageView?.tintColor = nil
            }else {
                mosaicButton.isSelected = false
                mosaicButton.imageView?.tintColor = nil
                smearButton.isSelected = true
                smearButton.imageView?.tintColor = selectedColor
            }
        }
    }
    let selectedColor: UIColor
    init(selectedColor: UIColor) {
        self.selectedColor = selectedColor
        super.init(frame: .zero)
        initViews()
    }
    
    private func initViews() {
        mosaicButton = UIButton(type: .custom)
        let mosaicImage: UIImage? = .imageResource.editor.mosaic.mosaic.image?.withRenderingMode(.alwaysTemplate)
        mosaicButton.setImage(mosaicImage, for: .normal)
        mosaicButton.setImage(mosaicImage, for: .selected)
        mosaicButton.addTarget(self, action: #selector(didMosaicClick(button:)), for: .touchUpInside)
        mosaicButton.tintColor = .white
        mosaicButton.isSelected = true
        mosaicButton.imageView?.tintColor = selectedColor
        addSubview(mosaicButton)
        
        smearButton = UIButton(type: .custom)
        let smearImage: UIImage? = .imageResource.editor.mosaic.smear.image?.withRenderingMode(.alwaysTemplate)
        smearButton.setImage(smearImage, for: .normal)
        smearButton.setImage(smearImage, for: .selected)
        smearButton.addTarget(self, action: #selector(didSmearClick(button:)), for: .touchUpInside)
        smearButton.tintColor = .white
        addSubview(smearButton)
        
        undoButton = UIButton(type: .custom)
        undoButton.setImage(.imageResource.editor.mosaic.undo.image, for: .normal)
        undoButton.addTarget(self, action: #selector(didUndoClick(button:)), for: .touchUpInside)
        undoButton.tintColor = .white
        undoButton.isEnabled = false
        addSubview(undoButton)
    }
    
    @objc
    private func didMosaicClick(button: UIButton) {
        button.isSelected = true
        button.imageView?.tintColor = selectedColor
        smearButton.isSelected = false
        smearButton.imageView?.tintColor = nil
        delegate?.mosaicToolView(self, didChangedMosaicType: .mosaic)
    }
    
    @objc
    private func didSmearClick(button: UIButton) {
        button.isSelected = true
        button.imageView?.tintColor = selectedColor
        mosaicButton.isSelected = false
        mosaicButton.imageView?.tintColor = nil
        delegate?.mosaicToolView(self, didChangedMosaicType: .smear)
    }
    
    @objc
    private func didUndoClick(button: UIButton) {
        delegate?.mosaicToolView(didUndoClick: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            if UIDevice.isPad {
                let buttonWidth = (width - height) * 0.5
                mosaicButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: height)
                smearButton.frame = CGRect(x: mosaicButton.frame.maxX, y: 0, width: buttonWidth, height: height)
                undoButton.frame = CGRect(x: width - height, y: 0, width: height, height: height)
            }else {
                let buttonWidth = (width - UIDevice.leftMargin - UIDevice.rightMargin - height) * 0.5
                mosaicButton.frame = CGRect(x: UIDevice.leftMargin, y: 0, width: buttonWidth, height: height)
                smearButton.frame = CGRect(x: mosaicButton.frame.maxX, y: 0, width: buttonWidth, height: height)
                undoButton.frame = CGRect(x: width - UIDevice.rightMargin - height, y: 0, width: height, height: height)
            }
            let buttonWidth = (width - UIDevice.leftMargin - UIDevice.rightMargin - height) * 0.5
            mosaicButton.frame = CGRect(x: UIDevice.leftMargin, y: 0, width: buttonWidth, height: height)
            smearButton.frame = CGRect(x: mosaicButton.frame.maxX, y: 0, width: buttonWidth, height: height)
            undoButton.frame = CGRect(x: width - UIDevice.rightMargin - height, y: 0, width: height, height: height)
        }else {
            undoButton.frame = CGRect(x: 0, y: UIDevice.topMargin, width: width, height: 44)
            mosaicButton.frame = .init(
                x: 0,
                y: undoButton.frame.maxY,
                width: width,
                height: (height - undoButton.height) / 2
            )
            smearButton.frame = .init(
                x: 0,
                y: mosaicButton.frame.maxY,
                width: width,
                height: (height - undoButton.height) / 2
            )
        }
    }
}
