Pod::Spec.new do |spec|
    spec.name                   = "HXPhotoPicker-Lite"
    spec.version                = "4.2.1"
    spec.summary                = "Photo selector - Support LivePhoto, GIF selection"
    spec.homepage               = "https://github.com/SilenceLove/HXPhotoPicker"
    spec.license                = { :type => "MIT", :file => "LICENSE" }
    spec.author                 = { "SilenceLove" => "294005139@qq.com" }
    spec.swift_versions         = ['5.0']
    spec.ios.deployment_target  = "10.0"
    spec.source                 = { :git => "https://github.com/SilenceLove/HXPhotoPicker.git", :tag => "#{spec.version}" }
    spec.framework              = 'UIKit','Photos','PhotosUI'
    spec.requires_arc           = true
    spec.default_subspec        = 'Full'
  
    spec.subspec 'Core' do |core|
        core.source_files   = "Sources/HXPhotoPicker/Core/**/*.{swift}"
        core.dependency 'HXPhotoPicker-Lite/Resources'
    end
    
    spec.subspec 'Resources' do |resources|
        resources.resources          = "Sources/HXPhotoPicker/Resources/*.{bundle}"
        resources.resource_bundle    = { 'HXPhotoPicker_Privacy' => ['Sources/HXPhotoPicker/Resources/PrivacyInfo.xcprivacy']}
    end
  
    spec.subspec 'Picker' do |picker|
        picker.subspec 'Lite' do |lite|
            lite.source_files   = "Sources/HXPhotoPicker/Picker/**/*.{swift}"
            lite.dependency 'HXPhotoPicker-Lite/Core'
            lite.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_PICKER' }
        end
        picker.subspec 'KF' do |kf|
            kf.dependency 'HXPhotoPicker-Lite/Picker/Lite'
            kf.dependency 'Kingfisher'
            kf.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_PICKER_LITE' }
        end
    end
  
    spec.subspec 'Editor' do |editor|
        editor.subspec 'Lite' do |lite|
            lite.source_files   = "Sources/HXPhotoPicker/Editor/**/*.{swift}"
            lite.dependency 'HXPhotoPicker-Lite/EditorView/Lite'
            lite.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_EDITOR' }
        end
        editor.subspec 'KF' do |kf|
            kf.dependency 'HXPhotoPicker-Lite/EditorView/KF'
            kf.dependency 'HXPhotoPicker-Lite/Editor/Lite'
            kf.dependency 'Kingfisher'
        end
    end
    
    spec.subspec 'EditorView' do |editor_view|
        editor_view.subspec 'Lite' do |lite|
            lite.source_files   = "Sources/HXPhotoPicker/Editor+View/**/*.{swift}"
            lite.dependency 'HXPhotoPicker-Lite/Core'
            lite.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_EDITOR_VIEW' }
        end
        editor_view.subspec 'KF' do |kf|
            kf.dependency 'HXPhotoPicker-Lite/EditorView/Lite'
            kf.dependency 'Kingfisher'
        end
    end
    
    spec.subspec 'Camera' do |camera|
        camera.subspec 'Lite' do |lite|
            lite.source_files   = "Sources/HXPhotoPicker/Camera/**/*.{swift,metal}"
            lite.dependency 'HXPhotoPicker-Lite/Core'
            lite.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_CAMERA' }
        end
        camera.subspec 'Location' do |loca|
            loca.source_files   = "Sources/HXPhotoPicker/Camera+Location/**/*.{swift}"
            loca.dependency 'HXPhotoPicker-Lite/Camera/Lite'
            loca.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HXPICKER_ENABLE_CAMERA_LOCATION' }
        end
    end
    
    spec.subspec 'Lite' do |lite|
        lite.dependency 'HXPhotoPicker-Lite/Picker/Lite'
        lite.dependency 'HXPhotoPicker-Lite/Editor/Lite'
        lite.dependency 'HXPhotoPicker-Lite/Camera/Lite'
    end
    
    spec.subspec 'Full' do |full|
        full.dependency 'HXPhotoPicker-Lite/Picker'
        full.dependency 'HXPhotoPicker-Lite/Editor'
        full.dependency 'HXPhotoPicker-Lite/Camera'
    end
    
    spec.subspec 'NoLocation' do |noLocation|
        noLocation.dependency 'HXPhotoPicker-Lite/Picker'
        noLocation.dependency 'HXPhotoPicker-Lite/Editor'
        noLocation.dependency 'HXPhotoPicker-Lite/Camera/Lite'
    end
end
