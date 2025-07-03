Pod::Spec.new do |spec|
    spec.name               = "HXPhotoPicker"
    spec.version            = "5.0.3"
    spec.summary            = "照片/视频选择器 - 支持LivePhoto、GIF图片选择、自定义编辑照片/视频、3DTouch预览、浏览网络图片/网络视频 功能 - Imitation weibo photo/image picker - support for LivePhoto, GIF image selection, 3DTouch preview, browse the web image function"
    spec.homepage           = "https://github.com/SilenceLove/HXPhotoPicker"
    spec.license            = { :type => "MIT", :file => "LICENSE" }
    spec.author             = { "SilenceLove" => "294005139@qq.com" }
    
    spec.swift_versions     = ['5.0']
    spec.platform           = :ios, "10.0"
    spec.ios.deployment_target = "10.0"
    spec.source             = { :git => "https://github.com/SilenceLove/HXPhotoPicker.git", :tag => "#{spec.version}" }

    spec.framework          = 'UIKit','Photos','PhotosUI'
    spec.requires_arc       = true
    spec.default_subspec    = 'Default'
    
    spec.subspec 'Core' do |core|
        core.source_files   = "Sources/HXPhotoPicker/Core/**/*.{swift}"
        core.dependency 'HXPhotoPicker/Resources'
        core.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_CORE' }
    end
    
    spec.subspec 'Resources' do |resources|
        resources.resources          = "Sources/HXPhotoPicker/Resources/*.{bundle}"
        resources.resource_bundle    = { 'HXPhotoPicker_Privacy' => ['Sources/HXPhotoPicker/Resources/PrivacyInfo.xcprivacy']}
    end
    
    spec.subspec 'Picker' do |picker|
        picker.source_files   = "Sources/HXPhotoPicker/Picker/**/*.{swift}"
        picker.dependency 'HXPhotoPicker/Core'
        picker.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_PICKER' }
    end
  
    spec.subspec 'Editor' do |editor|
        editor.source_files   = "Sources/HXPhotoPicker/Editor/**/*.{swift}"
        editor.dependency 'HXPhotoPicker/EditorView'
        editor.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_EDITOR' }
    end
    
    spec.subspec 'EditorView' do |editor_view|
        editor_view.source_files   = "Sources/HXPhotoPicker/Editor+View/**/*.{swift}"
        editor_view.dependency 'HXPhotoPicker/Core'
        editor_view.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_EDITOR_VIEW' }
    end
    
    spec.subspec 'Camera' do |camera|
        camera.subspec 'Lite' do |lite|
            lite.source_files   = "Sources/HXPhotoPicker/Camera/**/*.{swift,metal}"
            lite.dependency 'HXPhotoPicker/Core'
            lite.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_CAMERA' }
        end
        camera.subspec 'Location' do |loca|
            loca.dependency 'HXPhotoPicker/Camera/Lite'
            loca.source_files   = "Sources/HXPhotoPicker/Camera+Location/**/*.{swift}"
            loca.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_CAMERA_LOCATION' }
        end
    end
    
    spec.subspec 'NoLocation' do |noLocation|
        noLocation.dependency 'HXPhotoPicker/Picker'
        noLocation.dependency 'HXPhotoPicker/Editor'
        noLocation.dependency 'HXPhotoPicker/Camera/Lite'
    end
    
    spec.subspec 'GIFImageView' do |gif|
        gif.source_files   = "Sources/ImageView/GIFImageView.swift"
        gif.dependency 'SwiftyGif'
        gif.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_CORE_IMAGEVIEW_GIF' }
    end
    
    spec.subspec 'KFImageView' do |kf|
        kf.source_files   = "Sources/ImageView/KFImageView.swift"
        kf.dependency 'Kingfisher'
        kf.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_CORE_IMAGEVIEW_KF' }
    end
    
    spec.subspec 'SDImageView' do |sd|
        sd.source_files   = "Sources/ImageView/SDImageView.swift"
        sd.dependency 'SDWebImage'
        sd.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_CORE_IMAGEVIEW_SD' }
    end
    
    spec.subspec 'SwiftyGif' do |sd|
        sd.dependency 'HXPhotoPicker/Default'
        sd.dependency 'HXPhotoPicker/GIFImageView'
    end
    
    spec.subspec 'Kingfisher' do |kf|
        kf.dependency 'HXPhotoPicker/Default'
        kf.dependency 'HXPhotoPicker/KFImageView'
    end
    
    spec.subspec 'SDWebImage' do |sd|
        sd.dependency 'HXPhotoPicker/Default'
        sd.dependency 'HXPhotoPicker/SDImageView'
    end
    
    spec.subspec 'Default' do |default|
        default.dependency 'HXPhotoPicker/Picker'
        default.dependency 'HXPhotoPicker/Editor'
        default.dependency 'HXPhotoPicker/Camera'
    end
end
