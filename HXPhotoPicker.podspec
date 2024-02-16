Pod::Spec.new do |spec|
    spec.name               = "HXPhotoPicker"
    spec.version            = "4.1.6"
    spec.summary            = "照片/视频选择器 - 支持LivePhoto、GIF图片选择、自定义编辑照片/视频、3DTouch预览、浏览网络图片/网络视频 功能 - Imitation weibo photo/image picker - support for LivePhoto, GIF image selection, 3DTouch preview, browse the web image function"
    spec.homepage           = "https://github.com/SilenceLove/HXPhotoPicker"
    spec.license            = { :type => "MIT", :file => "LICENSE" }
    spec.author             = { "SilenceLove" => "294005139@qq.com" }
    
    spec.swift_versions     = ['5.0']
    spec.platform           = :ios, "12.0"
    spec.ios.deployment_target = "12.0"
    spec.source             = { :git => "https://github.com/SilenceLove/HXPhotoPicker.git", :tag => "#{spec.version}" }

    spec.framework          = 'UIKit','Photos','PhotosUI'
    spec.requires_arc       = true
    spec.default_subspec    = 'Full'
    
    spec.subspec 'Core' do |core|
        core.source_files   = "Sources/HXPhotoPicker/Core/**/*.{swift}"
        core.resources      = "Sources/HXPhotoPicker/Resources/*.{bundle}"
    end
    
    spec.subspec 'Picker' do |picker|
        picker.subspec 'Lite' do |lite|
            lite.source_files   = "Sources/HXPhotoPicker/Picker/**/*.{swift}"
            lite.dependency 'HXPhotoPicker/Core'
            lite.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_PICKER' }
        end
        picker.subspec 'KF' do |kf|
            kf.dependency 'HXPhotoPicker/Picker/Lite'
            kf.dependency 'Kingfisher', '~> 7.0'
        end
    end
  
    spec.subspec 'Editor' do |editor|
        editor.subspec 'Lite' do |lite|
            lite.source_files   = "Sources/HXPhotoPicker/Editor/**/*.{swift}"
            lite.dependency 'HXPhotoPicker/EditorView/Lite'
            lite.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_EDITOR' }
        end
        editor.subspec 'KF' do |kf|
            kf.dependency 'HXPhotoPicker/EditorView/KF'
            kf.dependency 'HXPhotoPicker/Editor/Lite'
            kf.dependency 'Kingfisher', '~> 7.0'
        end
    end
    
    spec.subspec 'EditorView' do |editor_view|
        editor_view.subspec 'Lite' do |lite|
            lite.source_files   = "Sources/HXPhotoPicker/Editor+View/**/*.{swift}"
            lite.dependency 'HXPhotoPicker/Core'
            lite.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_EDITOR_VIEW' }
        end
        editor_view.subspec 'KF' do |kf|
            kf.dependency 'HXPhotoPicker/EditorView/Lite'
            kf.dependency 'Kingfisher', '~> 7.0'
        end
    end
    
    spec.subspec 'Camera' do |camera|
        camera.subspec 'Lite' do |lite|
            lite.source_files   = "Sources/HXPhotoPicker/Camera/**/*.{swift,metal}"
            lite.dependency 'HXPhotoPicker/Core'
            lite.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_CAMERA' }
        end
        camera.subspec 'Location' do |loca|
            loca.source_files   = "Sources/HXPhotoPicker/Camera+Location/**/*.{swift}"
            loca.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_CAMERA_LOCATION' }
            loca.dependency 'HXPhotoPicker/Camera/Lite'
        end
    end
    
    spec.subspec 'Lite' do |lite|
        lite.dependency 'HXPhotoPicker/Picker/Lite'
        lite.dependency 'HXPhotoPicker/Editor/Lite'
        lite.dependency 'HXPhotoPicker/Camera/Lite'
    end
    
    spec.subspec 'NoLocation' do |noLocation|
        noLocation.dependency 'HXPhotoPicker/Picker'
        noLocation.dependency 'HXPhotoPicker/Editor'
        noLocation.dependency 'HXPhotoPicker/Camera/Lite'
    end
    
    
    spec.subspec 'Full' do |full|
        full.dependency 'HXPhotoPicker/Picker'
        full.dependency 'HXPhotoPicker/Editor'
        full.dependency 'HXPhotoPicker/Camera'
    end
end
