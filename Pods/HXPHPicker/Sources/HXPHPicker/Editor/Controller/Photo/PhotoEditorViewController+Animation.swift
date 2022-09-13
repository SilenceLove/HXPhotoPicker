//
//  PhotoEditorViewController+Animation.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/14.
//

import UIKit

extension PhotoEditorViewController {
    func showChartletView() {
        UIView.animate(withDuration: 0.25) {
            self.setChartletViewFrame()
        }
    }
    func hiddenChartletView() {
        UIView.animate(withDuration: 0.25) {
            self.setChartletViewFrame()
        }
    }
    
    func showFilterView() {
        UIView.animate(withDuration: 0.25) {
            self.setFilterViewFrame()
        }
    }
    func hiddenFilterView() {
        UIView.animate(withDuration: 0.25) {
            self.setFilterViewFrame()
        }
    }
    
    func showBrushColorView() {
        brushColorView.isHidden = false
        brushBlockView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.brushColorView.alpha = 1
            self.brushBlockView.alpha = 1
        }
    }
    
    func hiddenBrushColorView() {
        if brushColorView.isHidden {
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.brushColorView.alpha = 0
            self.brushBlockView.alpha = 0
        } completion: { (_) in
            guard let option = self.currentToolOption,
                  option.type == .graffiti else {
                return
            }
            self.brushColorView.isHidden = true
            self.brushBlockView.isHidden = true
        }
    }
    
    func showMosaicToolView() {
        mosaicToolView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.mosaicToolView.alpha = 1
        }
    }
    func hiddenMosaicToolView() {
        if mosaicToolView.isHidden {
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.mosaicToolView.alpha = 0
        } completion: { (_) in
            guard let option = self.currentToolOption,
                  option.type == .mosaic else {
                return
            }
            self.mosaicToolView.isHidden = true
        }
    }
    func croppingAction() {
        if state == .cropping {
            cropConfirmView.isHidden = false
            cropToolView.isHidden = false
            hidenTopView()
        }else {
            if let option = currentToolOption {
                if option.type == .graffiti {
                    imageView.drawEnabled = true
                }else if option.type == .mosaic {
                    imageView.mosaicEnabled = true
                }
            }
            showTopView()
        }
        UIView.animate(withDuration: 0.25) {
            self.cropConfirmView.alpha = self.state == .cropping ? 1 : 0
            self.cropToolView.alpha = self.state == .cropping ? 1 : 0
        } completion: { (isFinished) in
            if self.state != .cropping {
                self.cropConfirmView.isHidden = true
                self.cropToolView.isHidden = true
            }
        }

    }
    func showTopView() {
        topViewIsHidden = false
        toolView.isHidden = false
        topView.isHidden = false
        if let option = currentToolOption {
            if option.type == .graffiti {
                brushColorView.isHidden = false
                brushBlockView.isHidden = false
            }else if option.type == .mosaic {
                mosaicToolView.isHidden = false
            }
        }else {
            imageView.stickerEnabled = true
        }
        UIView.animate(withDuration: 0.25) {
            self.toolView.alpha = 1
            self.topView.alpha = 1
            self.topMaskLayer.isHidden = false
            if let option = self.currentToolOption {
                if option.type == .graffiti {
                    self.brushColorView.alpha = 1
                    self.brushBlockView.alpha = 1
                }else if option.type == .mosaic {
                    self.mosaicToolView.alpha = 1
                }
            }
        }
    }
    func hidenTopView() {
        topViewIsHidden = true
        UIView.animate(withDuration: 0.25) {
            self.toolView.alpha = 0
            self.topView.alpha = 0
            self.topMaskLayer.isHidden = true
            if let option = self.currentToolOption {
                if option.type == .graffiti {
                    self.brushColorView.alpha = 0
                    self.brushBlockView.alpha = 0
                }else if option.type == .mosaic {
                    self.mosaicToolView.alpha = 0
                }
            }
        } completion: { (isFinished) in
            if self.topViewIsHidden {
                self.toolView.isHidden = true
                self.topView.isHidden = true
                self.brushColorView.isHidden = true
                self.brushBlockView.isHidden = true
                self.mosaicToolView.isHidden = true
            }
        }
    }
}
