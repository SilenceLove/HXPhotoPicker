//
//  ImageResource.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/1/30.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit

public enum HX {
    public struct ImageResource {
        public static let shared = ImageResource()
        
        #if HXPICKER_ENABLE_PICKER
        public var picker: Picker = .init()
        #endif
        
        #if HXPICKER_ENABLE_EDITOR
        public var editor: Editor = .init()
        #endif
        
        #if HXPICKER_ENABLE_CAMERA
        public var camera: Camera = .init()
        #endif
    }
}

extension HX.ImageResource {
    #if HXPICKER_ENABLE_PICKER
    public struct Picker {
        
    }
    #endif

    #if HXPICKER_ENABLE_EDITOR
    public struct Editor {
        
    }
    #endif

    #if HXPICKER_ENABLE_CAMERA
    public struct Camera {
        
    }
    #endif
}
