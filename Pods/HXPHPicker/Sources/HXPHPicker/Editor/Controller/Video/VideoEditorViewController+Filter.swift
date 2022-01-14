//
//  VideoEditorViewController+Filter.swift
//  HXPHPicker
//
//  Created by Slience on 2022/1/12.
//

import UIKit

extension VideoEditorViewController: PhotoEditorFilterViewDelegate {
    
    func filterView(shouldSelectFilter filterView: PhotoEditorFilterView) -> Bool {
        true
    }
    
    func filterView(
        _ filterView: PhotoEditorFilterView,
        didSelected filter: PhotoEditorFilter,
        atItem: Int
    ) {
//        videoView.playerView.pause()
        if filter.isOriginal {
            videoView.imageResizerView.videoFilter = nil
            videoView.playerView.setFilter(nil, value: 0)
//            videoView.playerView.play()
            return
        }
        let value = filterView.sliderView.value
        let filterInfo = self.config.filter.infos[atItem]
        videoView.playerView.setFilter(filterInfo, value: value)
        videoView.imageResizerView.videoFilter = .init(index: atItem, value: value)
//        videoView.playerView.play()
    }
    func filterView(_ filterView: PhotoEditorFilterView,
                    didChanged value: Float) {
//        let filterInfo = config.filter.infos[filterView.currentSelectedIndex - 1]
//        videoView.playerView.setFilter(filterInfo, value: value)
//        videoView.imageResizerView.filterValue = value
    }
    func filterView(_ filterView: PhotoEditorFilterView, touchUpInside value: Float) {
//        videoView.playerView.pause()
        let index = filterView.currentSelectedIndex - 1
        let filterInfo = config.filter.infos[index]
        videoView.playerView.setFilter(filterInfo, value: value)
        videoView.imageResizerView.videoFilter = .init(index: index, value: value)
//        videoView.playerView.play()
    }
    
    func showFilterView() {
        isFilter = true
        UIView.animate(withDuration: 0.25) {
            self.setFilterViewFrame()
        }
    }
    func hiddenFilterView() {
        isFilter = false
        UIView.animate(withDuration: 0.25) {
            self.setFilterViewFrame()
        }
    }
}
