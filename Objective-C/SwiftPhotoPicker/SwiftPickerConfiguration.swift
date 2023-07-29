//
//  SwiftPickerConfiguration.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2023/6/14.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit
import HXPhotoPicker

/// 根据需求自己添加要修改的属性
class SwiftPickerConfiguration: NSObject {
   
   @objc
   var isAutoBack: Bool = true
   
   @objc
   var selectOptions: SelectOptions = .any
   
   @objc
   var selectMode: SelectMode = .multiple
   
   @objc
   var allowSelectedTogether: Bool = true
   
   @objc
   var allowSyncICloudWhenSelectPhoto: Bool = true
   
   @objc
   var albumShowMode: SwiftAlbumShowMode = .normal
   
   @objc
   enum SelectOptions: Int {
       case photo
       case photo_gif
       case photo_livePhoto
       case gif_livePhoto
       case video
       case any
       
       var toSwift: PickerAssetOptions {
           switch self {
           case .photo:
               return .photo
           case .photo_gif:
               return .gifPhoto
           case .photo_livePhoto:
               return .livePhoto
           case .gif_livePhoto:
               return [.livePhoto, .gifPhoto, .photo]
           case .video:
               return [.video]
           case .any:
               return [.photo, .gifPhoto, .livePhoto, .video]
           }
       }
   }
   
   @objc
   enum SelectMode: Int {
       case single
       case multiple
       
       var toSwift: PickerSelectMode {
           switch self {
           case .single:
               return .single
           case .multiple:
               return .multiple
           }
       }
   }
   
   @objc
   enum SwiftAlbumShowMode: Int {
       case normal
       case popup
       
       var toSwift: AlbumShowMode {
           switch self {
           case .normal:
               return .normal
           case .popup:
               return .popup
           }
       }
   }
    
    var toHX: PickerConfiguration {
        var config = PickerConfiguration()
        config.isAutoBack = isAutoBack
        config.selectOptions = selectOptions.toSwift
        config.selectMode = selectMode.toSwift
        config.allowSelectedTogether = allowSelectedTogether
        config.allowSyncICloudWhenSelectPhoto = allowSyncICloudWhenSelectPhoto
        config.albumShowMode = albumShowMode.toSwift
        return config
    }
}
