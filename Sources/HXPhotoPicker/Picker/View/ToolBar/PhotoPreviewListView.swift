//
//  PhotoPreviewListView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/11/23.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

protocol PhotoPreviewListViewDataSource: AnyObject {
    func previewListView(
        _ previewListView: PhotoPreviewListView,
        thumbnailOnPage page: Int
    ) -> PhotoAsset?
    
    func previewListView(
        _ previewListView: PhotoPreviewListView,
        thumbnailWidthToHeightOnPage page: Int
    ) -> CGFloat?
    
    func previewListView(
        _ previewListView: PhotoPreviewListView,
        pageDidChange page: Int,
        reason: PhotoPreviewListView.PageChangeReason
    )
}

class PhotoPreviewListView: UIView {
    
    enum State: Hashable, Sendable {
        case collapsing
        
        /// The collapsed state during scroll.
        /// - Parameters:
        ///   - indexPathForFinalDestinationItem: The index path for where you will eventually arrive after ending dragging.
        case collapsed(indexPathForFinalDestinationItem: IndexPath?)
        
        case expanding
        case expanded
        
        /// The state of interactively transitioning between pages.
        case transitioningInteractively(UICollectionViewTransitionLayout, forwards: Bool)
        
        var indexPathForFinalDestinationItem: IndexPath? {
            guard case .collapsed(let indexPath) = self else { return nil }
            return indexPath
        }
    }
    
    enum Layout {
        /// A normal layout.
        case normal(PhotoPreviewListViewLayout)
        
        /// A layout during interactive paging transition.
        case transition(UICollectionViewTransitionLayout)
    }
    
    weak var dataSource: (any PhotoPreviewListViewDataSource)?
    
    var selectColor: UIColor?
    var selectBgColor: UIColor?
    
    private(set) var state: State = .collapsed(indexPathForFinalDestinationItem: nil)
    
    var indexPathForCurrentCenterItem: IndexPath? {
        collectionView.indexPathForHorizontalCenterItem
    }
    
    private var currentCenterPage: Int? {
        indexPathForCurrentCenterItem?.item
    }
    
    private var lastChangedPage: Int?
    
    // MARK: Publishers
    
    /// What caused the page change.
    enum PageChangeReason: Hashable {
        case configuration
        case tapOnPageThumbnail
        case scrollingBar
        case interactivePaging
    }
    
    // MARK: UI components
    
    private var layout: Layout {
        switch collectionView.collectionViewLayout {
        case let barLayout as PhotoPreviewListViewLayout:
            return .normal(barLayout)
        case let transitionLayout as UICollectionViewTransitionLayout:
            return .transition(transitionLayout)
        default:
            preconditionFailure(
                "Unknown layout: \(collectionView.collectionViewLayout)"
            )
        }
    }
    
    var collectionView: UICollectionView!
    private var numberOfPages: Int = 0
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpViews()
    }
    
    private func setUpViews() {
        let layout = PhotoPreviewListViewLayout(style: .collapsed)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoPreviewListViewCell.self)
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        collectionView.frame = bounds
        adjustContentInset()
    }
    
    private func adjustContentInset() {
        guard bounds.width > 0 else { return }
        let offset = (bounds.width - PhotoPreviewListViewLayout.collapsedItemWidth) / 2
        collectionView.contentInset = .init(
            top: 0,
            left: offset,
            bottom: 0,
            right: offset
        )
        if let lastChangedPage, UIDevice.isPad {
            updateLayout(expandingItemAt: .init(item: lastChangedPage, section: 0), animated: false)
        }
    }
    
    // MARK: - Methods
    
    func configure(numberOfPages: Int, currentPage: Int) {
        self.numberOfPages = numberOfPages
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            DispatchQueue.main.async {
                let indexPath = IndexPath(item: currentPage, section: 0)
                self.expandAndScrollToItem(
                    at: indexPath,
                    causingBy: .configuration,
                    animated: false
                )
            }
        }
    }
    
    func insertData(with indexs: [Int]) {
        var indexPaths: [IndexPath] = []
        for index in indexs {
            indexPaths.append(.init(item: index, section: 0))
        }
        numberOfPages += indexs.count
        collectionView.insertItems(at: indexPaths)
        DispatchQueue.main.async {
            self.correctExpandingItemAspectRatioIfNeeded()
        }

    }
    
    func removeData(with indexs: [Int]) {
        var indexPaths: [IndexPath] = []
        for index in indexs {
            indexPaths.append(.init(item: index, section: 0))
        }
        numberOfPages -= indexs.count
        collectionView.deleteItems(at: indexPaths)
        DispatchQueue.main.async {
            self.correctExpandingItemAspectRatioIfNeeded()
        }

    }
    
    func reloadData(with indexs: [Int]) {
        var indexPaths: [IndexPath] = []
        for index in indexs {
            indexPaths.append(.init(item: index, section: 0))
        }
        collectionView.reloadItems(at: indexPaths)
        
        DispatchQueue.main.async {
            self.correctExpandingItemAspectRatioIfNeeded()
        }
    }
    
    func reloadData() {
        collectionView.reloadData()
        DispatchQueue.main.async {
            self.correctExpandingItemAspectRatioIfNeeded()
        }

    }
    
    func stopScroll(to page: Int, animated: Bool) {
        expandAndScrollToItem(
            at: .init(item: page, section: 0),
            causingBy: .tapOnPageThumbnail,
            animated: animated
        )
        scrollViewDidEndDecelerating(collectionView)
    }
    
    private func pageDidChange(_ page: Int, reason: PageChangeReason) {
        if let lastChangedPage, lastChangedPage == page {
            return
        }
        if lastChangedPage != nil {
            dataSource?.previewListView(self, pageDidChange: page, reason: reason)
        }
        lastChangedPage = page
    }
    
    private func updateLayout(
        expandingItemAt indexPath: IndexPath?,
        expandingThumbnailWidthToHeight: CGFloat? = nil,
        animated: Bool
    ) {
        let style: PhotoPreviewListViewLayout.Style
        if let indexPath {
            style = .expanded(
                indexPath,
                expandingThumbnailWidthToHeight: expandingThumbnailWidthToHeight
            )
        } else {
            style = .collapsed
        }
        let layout = PhotoPreviewListViewLayout(style: style)
        collectionView.setCollectionViewLayout(layout, animated: animated)
        if let indexPath {
            DispatchQueue.main.async {
                let cell = self.collectionView.cellForItem(at: indexPath) as? PhotoPreviewListViewCell
                cell?.reqeustAssetImage(3)
            }
        }
    }
    
    /// Expand an item and scroll there.
    /// - Parameters:
    ///   - indexPath: An index path for the expanding item.
    ///   - reason: What causes the page change. If non-nil, the page change will be notified with it.
    ///   - thumbnailWidthToHeight: An aspect ratio of the expanding thumbnail to calculate the size of expanding item.
    ///   - duration: The total duration of the animation.
    ///   - animated: Whether to animate expanding and scrolling.
    private func expandAndScrollToItem(
        at indexPath: IndexPath,
        causingBy reason: PageChangeReason?,
        thumbnailWidthToHeight: CGFloat? = nil,
        duration: CGFloat = 0.5,
        animated: Bool
    ) {
        state = .expanding
        if let reason {
            pageDidChange(indexPath.item, reason: reason)
        }
        
        func expandAndScroll() {
            updateLayout(
                expandingItemAt: indexPath,
                expandingThumbnailWidthToHeight: thumbnailWidthToHeight,
                animated: false
            )
            // NOTE: Without this, a thumbnail may shift out of the center after scrolling.
            collectionView.scrollToItem(
                at: indexPath,
                at: .centeredHorizontally,
                animated: false
            )
            state = .expanded
            
            if thumbnailWidthToHeight == nil {
                correctExpandingItemAspectRatioIfNeeded()
            }
        }
        if animated {
            UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                expandAndScroll()
            }.startAnimation()
        } else {
            expandAndScroll()
        }
    }
    
    private func correctExpandingItemAspectRatioIfNeeded() {
        guard let indexPathForCurrentCenterItem, let dataSource else { return }
        let page = indexPathForCurrentCenterItem.item
        
        if let thumbnailWidthToHeight = dataSource.previewListView(self, thumbnailWidthToHeightOnPage: page) {
            expandAndScrollToItem(
                at: indexPathForCurrentCenterItem,
                causingBy: nil,
                thumbnailWidthToHeight: thumbnailWidthToHeight,
                animated: false
            )
            return
        }
        
        let photoAsset = dataSource.previewListView(
            self,
            thumbnailOnPage: page
        )
        guard let photoAsset, photoAsset.imageSize.height > 0 else { return }
        expandAndScrollToItem(
            at: indexPathForCurrentCenterItem,
            causingBy: nil,
            thumbnailWidthToHeight: photoAsset.imageSize.width / photoAsset.imageSize.height,
            animated: false
        )
    }
    
    private func expandAndScrollToCenterItem(
        animated: Bool,
        causingBy reason: PageChangeReason
    ) {
        guard let indexPathForCurrentCenterItem else { return }
        expandAndScrollToItem(
            at: indexPathForCurrentCenterItem,
            causingBy: reason,
            animated: animated
        )
    }
    
    private func collapseItem() {
        guard case .normal(let barLayout) = layout,
              barLayout.style.indexPathForExpandingItem != nil else { return }
        state = .collapsing
        UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1) {
            self.updateLayout(expandingItemAt: nil, animated: false)
            self.state = .collapsed(indexPathForFinalDestinationItem: nil)
        }.startAnimation()
    }
}

// MARK: - Interactive paging -

extension PhotoPreviewListView {
    
    func startInteractivePaging(forwards: Bool) {
        guard case .normal(let barLayout) = layout else {
//            assertionFailure()
            return
        }
        
        guard let currentCenterPage else { return }
        let destinationPage = currentCenterPage + (forwards ? 1 : -1)
        guard 0 <= destinationPage,
              destinationPage < collectionView.numberOfItems(inSection: 0) else {
            return
        }
        
        let expandingThumbnailWidthToHeight = dataSource?.previewListView(
            self,
            thumbnailWidthToHeightOnPage: destinationPage
        )
        let style: PhotoPreviewListViewLayout.Style = .expanded(
            IndexPath(item: destinationPage, section: 0),
            expandingThumbnailWidthToHeight: expandingThumbnailWidthToHeight
        )
        let newLayout = PhotoPreviewListViewLayout(style: style)
        
        /*
         * NOTE:
         * Using UICollectionView.startInteractiveTransition(to:completion:),
         * there is a lag from the end of the transition
         * until (completion is called and) the next transition can be started.
         */
        let transitionLayout = UICollectionViewTransitionLayout(
            currentLayout: barLayout,
            nextLayout: newLayout
        )
        collectionView.collectionViewLayout = transitionLayout
        state = .transitioningInteractively(transitionLayout, forwards: forwards)
    }
    
    func updatePagingProgress(_ progress: CGFloat) {
        guard case .transitioningInteractively(let layout, _) = state else {
            return
        }
        layout.transitionProgress = progress
    }
    
    func finishInteractivePaging() {
        guard case .transitioningInteractively(let layout, _) = state else {
            return
        }
        collectionView.collectionViewLayout = layout.nextLayout
        state = .expanded
        
        if let currentCenterPage {
            pageDidChange(currentCenterPage, reason: .interactivePaging)
        }
    }
    
    func cancelInteractivePaging() {
        guard case .transitioningInteractively(let layout, _) = state else {
            return
        }
        collectionView.collectionViewLayout = layout.currentLayout
        state = .expanded
    }
}

extension PhotoPreviewListView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfPages
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PhotoPreviewListViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.tickColor = selectColor
        cell.tickBgColor = selectBgColor
        cell.photoAsset = dataSource?.previewListView(self, thumbnailOnPage: indexPath.item)
        return cell
    }
}

extension PhotoPreviewListView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        if case .normal(let barLayout) = layout,
           barLayout.style.indexPathForExpandingItem != indexPath {
            expandAndScrollToItem(
                at: indexPath,
                causingBy: .tapOnPageThumbnail,
                animated: true
            )
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        collapseItem()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        switch state {
        case .collapsed(let indexPathForFinalDestinationItem):
            guard let indexPathForCurrentCenterItem,
                  scrollView.isDragging else { return }
            pageDidChange(indexPathForCurrentCenterItem.item, reason: .scrollingBar)
            if indexPathForCurrentCenterItem == indexPathForFinalDestinationItem,
               !isEdgeIndexPath(indexPathForCurrentCenterItem) {
                expandAndScrollToCenterItem(animated: true, causingBy: .scrollingBar)
            }
        case .collapsing, .expanding, .expanded, .transitioningInteractively:
            break
        }
    }
    
    private func isEdgeIndexPath(_ indexPath: IndexPath) -> Bool {
        switch indexPath.item {
        case 0, collectionView.numberOfItems(inSection: 0) - 1:
            return true
        default:
            return false
        }
    }
    
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let targetPoint: CGPoint
        if #available(iOS 11.0, *) {
            targetPoint = .init(
                x: targetContentOffset.pointee.x + collectionView.adjustedContentInset.left,
                y: 0
            )
        } else {
            targetPoint = .init(
                x: targetContentOffset.pointee.x + collectionView.contentInset.left,
                y: 0
            )
        }
        let targetIndexPath = collectionView.indexPathForItem(at: targetPoint)
        state = .collapsed(
            indexPathForFinalDestinationItem: targetIndexPath
        )
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        /*
         * When the finger is released with the finger stopped
         * or
         * when the finger is released at the point where it exceeds the limit of left and right edges.
         */
        if !scrollView.isDragging, !decelerate {
            guard let indexPath = indexPathForCurrentCenterItem ?? state.indexPathForFinalDestinationItem else {
                return
            }
            expandAndScrollToItem(
                at: indexPath,
                causingBy: .scrollingBar,
                animated: true
            )
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        switch state {
        case .collapsing, .collapsed:
            expandAndScrollToCenterItem(animated: true, causingBy: .scrollingBar)
        case .expanding, .expanded, .transitioningInteractively:
            break // NOP
        }
    }
}

