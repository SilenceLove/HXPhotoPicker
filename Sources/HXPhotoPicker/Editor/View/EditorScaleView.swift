//
//  EditorScaleView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2022/11/2.
//

import UIKit

class EditorScaleView: UIView {
    
    struct Scale {
        let value: CGFloat
    }
    
    enum State {
        case begin
        case changed
        case end
    }
    
    var state: State = .end
    
    private var shadeView: UIView!
    private var shadeMaskLayer: CAGradientLayer!
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: EditorScaleCollectionView!
    private var centerLineView: UIView!
    private var valueLb: UILabel!
    
    var angleChanged: ((CGFloat, State) -> Void)?
    
    var offsetScale: CGFloat {
        if UIDevice.isPortrait {
            let margin = collectionView.isCenter ? centerOffsetX : collectionView.contentOffset.x
            let offsetX = margin + collectionView.contentInset.left
            let contentWidth = (collectionView.contentSize.width - 1) * 0.5
            let offsetScale = (offsetX / contentWidth) - 1
            return offsetScale
        }
        let margin = collectionView.isCenter ? centerOffsetX : collectionView.contentOffset.y
        let offsetY = margin + collectionView.contentInset.top
        let contentHeight = (collectionView.contentSize.height - 1) * 0.5
        let offsetScale = (offsetY / contentHeight) - 1
        return offsetScale
    }
    
    var centerOffsetX: CGFloat {
        if UIDevice.isPortrait {
            return (collectionView.contentSize.width - 1) * 0.5 - collectionView.contentInset.left
        }
        return (collectionView.contentSize.height - 1) * 0.5 - collectionView.contentInset.top
    }
    
    var count: Int = 47
    
    var centerIndex: Int = 23
    
    var centerCell: EditorScaleViewCell? {
        collectionView.cellForItem(at: .init(item: 0, section: centerIndex)) as? EditorScaleViewCell
    }
    
    var angle: CGFloat {
        min(max(-45, offsetScale * 45), 45)
    }
    
    var scale: Int {
        min(max(-45, Int(round(offsetScale * 45))), 45)
    }
    
    var currentIndex: Int = 0
    
    var themeColor: UIColor = .systemBlue
    
    var padding: CGFloat {
        return 5
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var currentOffsetScale: CGFloat?
    
    var isAngleChange = false
    
    private func initView() {
        valueLb = UILabel()
        valueLb.text = "0"
        valueLb.textColor = .white
        valueLb.font = .systemFont(ofSize: UIDevice.isPad ? 14 : 12)
        addSubview(valueLb)
        
        flowLayout = UICollectionViewFlowLayout()
        collectionView = EditorScaleCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(EditorScaleViewCell.self, forCellWithReuseIdentifier: "EditorScaleViewCellId")
        collectionView.decelerationRate = .fast
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        shadeMaskLayer = CAGradientLayer()
        shadeMaskLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
        shadeMaskLayer.locations = [0.0, 0.05, 0.95, 1.0]
        
        shadeView = UIView()
        shadeView.addSubview(collectionView)
        shadeView.layer.mask = shadeMaskLayer
        addSubview(shadeView)
        
        centerLineView = UIView()
        centerLineView.backgroundColor = .white
        addSubview(centerLineView)
        DispatchQueue.main.async {
            self.currentIndex = self.centerIndex
            self.collectionView.isCenter = true
            if UIDevice.isPortrait {
                self.collectionView.contentOffset.x = self.centerOffsetX
            }else {
                self.collectionView.contentOffset.y = self.centerOffsetX
            }
        }
    }
    
    func reset() {
        currentOffsetScale = nil
        currentIndex = centerIndex
        collectionView.isCenter = true
        if UIDevice.isPortrait {
            collectionView.contentOffset.x = centerOffsetX
        }else {
            collectionView.contentOffset.y = centerOffsetX
        }
        centerCell?.hidePoint()
    }
    
    func updateAngle(_ angle: CGFloat) {
        let offsetScale = angle / 45
        if UIDevice.isPortrait {
            let contentWidth = (collectionView.contentSize.width - 1) * 0.5
            let offsetX = (offsetScale + 1) * contentWidth
            collectionView.contentOffset.x = offsetX - collectionView.contentInset.left
        }else {
            let contentHeight = (collectionView.contentSize.height - 1) * 0.5
            let offsetY = (offsetScale + 1) * contentHeight
            collectionView.contentOffset.y = offsetY - collectionView.contentInset.top
        }
        collectionView.isCenter = angle == 0
        let point = centerLineView.convert(
            .init(x: centerLineView.width * 0.5, y: centerLineView.height * 0.5),
            to: collectionView
        )
        if let indexPath = collectionView.indexPathForItem(at: point) {
            currentIndex = indexPath.section
        }else {
            currentIndex = -1
        }
        valueLb.text = String(scale)
        if UIDevice.isPortrait {
            currentOffsetScale = (
                collectionView.contentInset.left + collectionView.contentOffset.x
            ) / collectionView.contentSize.width
        }else {
            currentOffsetScale = (
                collectionView.contentInset.top + collectionView.contentOffset.y
            ) / collectionView.contentSize.height
        }
    }
    
    func stopScroll() {
        if !isAngleChange {
            return
        }
        let offset = collectionView.contentOffset
        collectionView.setContentOffset(offset, animated: false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.isPortrait {
            shadeMaskLayer.startPoint = CGPoint(x: 0, y: 1)
            shadeMaskLayer.endPoint = CGPoint(x: 1, y: 1)
            
            flowLayout.scrollDirection = .horizontal
            shadeView.frame = .init(x: 0, y: 0, width: width, height: height)
            collectionView.frame = shadeView.bounds
            shadeMaskLayer.frame = CGRect(x: 0, y: 0, width: shadeView.width, height: shadeView.height)
            let margin: CGFloat
            let contentWidth = collectionView.contentSize.width
            if contentWidth > width {
                margin = width * 0.5 - 0.5
            }else {
                margin = (contentWidth * 0.5 + (width - contentWidth) * 0.5) - 0.5
            }
            collectionView.contentInset = .init(top: 5, left: margin, bottom: 0, right: margin)
            
            centerLineView.size = .init(width: 1, height: 25)
            centerLineView.centerX = width * 0.5
            centerLineView.y = 25 - centerLineView.height
            
            valueLb.textAlignment = .center
            valueLb.x = 0
            valueLb.width = width
            valueLb.y = centerLineView.frame.maxY + 2
            valueLb.height = 15
        }else {
            shadeMaskLayer.startPoint = CGPoint(x: 1, y: 0)
            shadeMaskLayer.endPoint = CGPoint(x: 1, y: 1)
            
            flowLayout.scrollDirection = .vertical
            shadeView.frame = .init(x: 0, y: 0, width: width, height: height)
            collectionView.frame = shadeView.bounds
            shadeMaskLayer.frame = CGRect(x: 0, y: 0, width: shadeView.width, height: shadeView.height)
            let margin: CGFloat
            let contentHeight = collectionView.contentSize.height
            if contentHeight > height {
                margin = height * 0.5 - 0.5
            }else {
                margin = (contentHeight * 0.5 + (height - contentHeight) * 0.5) - 0.5
            }
            collectionView.contentInset = .init(top: margin, left: 5, bottom: margin, right: 0)
            centerLineView.size = .init(width: 25, height: 1)
            centerLineView.centerY = height * 0.5
            centerLineView.x = 25 - centerLineView.width
            
            valueLb.textAlignment = .left
            valueLb.y = 0
            valueLb.x = centerLineView.frame.maxX + 2
            valueLb.width = width - valueLb.x
            valueLb.height = height
        }
        DispatchQueue.main.async {
            var contentOffset = self.collectionView.contentOffset
            let contentSize = self.collectionView.contentSize
            let contentInset = self.collectionView.contentInset
            if UIDevice.isPortrait {
                if let currentOffsetScale = self.currentOffsetScale {
                    contentOffset.x = contentSize.width * currentOffsetScale - contentInset.left
                }else {
                    self.collectionView.isCenter = true
                    contentOffset.x = self.centerOffsetX
                }
            }else {
                if let currentOffsetScale = self.currentOffsetScale {
                    contentOffset.y = contentSize.height * currentOffsetScale - contentInset.top
                }else {
                    self.collectionView.isCenter = true
                    contentOffset.y = self.centerOffsetX
                }
            }
            self.collectionView.contentOffset = contentOffset
        }
    }
}

extension EditorScaleView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorScaleViewCellId",
            for: indexPath
        ) as! EditorScaleViewCell
        cell.isShowPoint = indexPath.section == centerIndex
        cell.isOriginal = (indexPath.section == centerIndex ||
                           indexPath.section == 0 ||
                           indexPath.section == count - 1)
        if cell.isOriginal {
            cell.isBold = true
        }else {
            cell.isBold = (indexPath.section + 2) % 5 == 0
        }
        cell.update()
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if UIDevice.isPortrait {
            return .init(width: 1, height: 20)
        }
        return .init(width: 20, height: 1)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        if section == 0 || section == count - 1 {
            return .zero
        }
        if UIDevice.isPortrait {
            return .init(top: 0, left: padding, bottom: 0, right: padding)
        }
        return .init(top: padding, left: 0, bottom: padding, right: 0)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let point = centerLineView.convert(
            .init(x: centerLineView.width * 0.5, y: centerLineView.height * 0.5),
            to: collectionView
        )
        if let indexPath = collectionView.indexPathForItem(at: point) {
            if currentIndex != indexPath.section && isAngleChange {
                let shake = UIImpactFeedbackGenerator(style: .light)
                shake.prepare()
                if #available(iOS 13.0, *) {
                    shake.impactOccurred(intensity: 0.6)
                } else {
                    shake.impactOccurred()
                }
            }
            currentIndex = indexPath.section
        }else {
            currentIndex = -1
        }
        valueLb.text = String(scale)
        if isAngleChange {
            collectionView.isCenter = false
            angleChanged?(angle, state)
            state = .changed
        }else {
            state = .end
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if !isAngleChange {
            isAngleChange = true
            state = .begin
        }
        UIView.animate(withDuration: 0.2) {
            self.centerLineView.backgroundColor = self.themeColor
        }
        centerCell?.showPoint()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollDidStop()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollDidStop()
    }
    
    func scrollDidStop() {
        isAngleChange = false
        state = .end
        if offsetScale >= -0.02 && offsetScale <= 0.02 {
            collectionView.isCenter = true
            if UIDevice.isPortrait {
                collectionView.contentOffset.x = centerOffsetX
            }else {
                collectionView.contentOffset.y = centerOffsetX
            }
        }else {
            collectionView.isCenter = false
        }
        angleChanged?(angle, state)
        UIView.animate(withDuration: 0.25) {
            self.centerLineView.backgroundColor = .white
        }
        if currentIndex == centerIndex {
            centerCell?.hidePoint()
        }
        if UIDevice.isPortrait {
            currentOffsetScale = (
                collectionView.contentInset.left + collectionView.contentOffset.x
            ) / collectionView.contentSize.width
        }else {
            currentOffsetScale = (
                collectionView.contentInset.top + collectionView.contentOffset.y
            ) / collectionView.contentSize.height
        }
    }
}
 
class EditorScaleCollectionView: UICollectionView {
    var isCenter: Bool = true
}

class EditorScaleViewCell: UICollectionViewCell {
    private var lineView: UIView!
    private var pointView: UIView!
    
    var isShowPoint: Bool = false {
        didSet {
            pointView.isHidden = !isShowPoint
        }
    }
    
    var isBold: Bool = false
    var isOriginal: Bool = false
    
    func update() {
        lineView.backgroundColor = isBold ? .white : .white.withAlphaComponent(0.6)
        updateLineView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        initView()
    }
    
    private func initView() {
        pointView = UIView()
        pointView.isHidden = true
        pointView.alpha = 0
        pointView.backgroundColor = .white
        pointView.layer.cornerRadius = 3
        pointView.layer.masksToBounds = true
        contentView.addSubview(pointView)
        
        lineView = UIView()
        lineView.backgroundColor = .white
        contentView.addSubview(lineView)
    }
    
    func showPoint(_ isAnimation: Bool = true) {
        if !isAnimation {
            pointView.alpha = 1
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.pointView.alpha = 1
        }
    }
    
    func hidePoint(_ isAnimation: Bool = true) {
        if !isAnimation {
            pointView.alpha = 0
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.pointView.alpha = 0
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLineView()
    }
    
    private func updateLineView() {
        if UIDevice.isPortrait {
            pointView.y = -5
            pointView.size = .init(width: 6, height: 6)
            pointView.centerX = width * 0.5
            lineView.size = .init(width: 1, height: isOriginal ? 15 : 10)
            lineView.centerX = width * 0.5
            lineView.y = height - lineView.height
        }else {
            pointView.x = -5
            pointView.size = .init(width: 6, height: 6)
            pointView.centerY = height * 0.5
            lineView.size = .init(width: isOriginal ? 15 : 10, height: 1)
            lineView.centerY = height * 0.5
            lineView.x = width - lineView.width
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
