//
//  EditorChartletViewListCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

protocol EditorChartletViewListCellDelegate: AnyObject {
    func listCell(_ cell: EditorChartletViewListCell, didSelectImage image: UIImage, imageData: Data?)
}

class EditorChartletViewListCell: UICollectionViewCell,
                                  UICollectionViewDataSource,
                                  UICollectionViewDelegate,
                                  UICollectionViewDelegateFlowLayout {
    weak var delegate: EditorChartletViewListCellDelegate?
    private var loadingView: UIActivityIndicatorView!
    private var flowLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    
    var rowCount: Int = 4
    var chartletList: [EditorChartlet] = [] {
        didSet {
            collectionView.reloadData()
            resetOffset()
        }
    }
    var editorType: EditorContentViewType = .image
    
    func resetOffset() {
        collectionView.contentOffset = CGPoint(
            x: -collectionView.contentInset.left,
            y: -collectionView.contentInset.top
        )
    }
    
    func startLoading() {
        loadingView.startAnimating()
    }
    func stopLoad() {
        loadingView.stopAnimating()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 5
        flowLayout.minimumInteritemSpacing = 5
        collectionView = HXCollectionView.init(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(EditorChartletViewCell.self, forCellWithReuseIdentifier: "EditorChartletViewListCellID")
        contentView.addSubview(collectionView)
        loadingView = UIActivityIndicatorView(style: .white)
        loadingView.hidesWhenStopped = true
        contentView.addSubview(loadingView)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        chartletList.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorChartletViewListCellID",
            for: indexPath
        ) as! EditorChartletViewCell
        cell.editorType = editorType
        cell.chartlet = chartletList[indexPath.item]
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let rowCount = !UIDevice.isPortrait && !UIDevice.isPad ? 7 : CGFloat(self.rowCount)
        let margin = collectionView.contentInset.left + collectionView.contentInset.right
        let spacing = flowLayout.minimumLineSpacing * (rowCount - 1)
        let itemWidth = (width - margin - spacing) / rowCount
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let cell = collectionView.cellForItem(at: indexPath) as! EditorChartletViewCell
        if var image = cell.chartlet.image {
            let imageData: Data?
            if editorType == .image {
                if let count = image.images?.count,
                   let img = image.images?.first,
                   count > 0 {
                    image = img
                }
                imageData = nil
            }else {
                imageData = cell.chartlet.imageData
            }
            delegate?.listCell(
                self,
                didSelectImage: image,
                imageData: imageData
            )
        }else {
            if let url = cell.chartlet.url, cell.downloadCompletion {
                PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: superview)
                PhotoManager.ImageView.download(with: .init(downloadURL: url), options: nil, progressHandler: nil) { [weak self]  in
                    guard let self = self else { return }
                    PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.superview)
                    switch $0 {
                    case .success(let result):
                        if let image = result.image {
                            if self.editorType == .image {
                                self.delegate?.listCell(self, didSelectImage: image, imageData: nil)
                                return
                            }
                            self.delegate?.listCell(self, didSelectImage: image, imageData: result.imageData)
                        }else if let imageData = result.imageData, let image = UIImage(data: imageData) {
                            if self.editorType == .image {
                                self.delegate?.listCell(self, didSelectImage: image, imageData: nil)
                                return
                            }
                            self.delegate?.listCell(self, didSelectImage: image, imageData: imageData)
                        }
                    case .failure:
                        return
                    }
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
        loadingView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        collectionView.contentInset = UIEdgeInsets(
            top: 60,
            left: 15 + UIDevice.leftMargin,
            bottom: 15 + UIDevice.bottomMargin,
            right: 15 + UIDevice.rightMargin
        )
        collectionView.scrollIndicatorInsets = UIEdgeInsets(
            top: 60,
            left: UIDevice.leftMargin,
            bottom: 15 + UIDevice.bottomMargin,
            right: UIDevice.rightMargin
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
