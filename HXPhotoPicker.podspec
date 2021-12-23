
Pod::Spec.new do |s|

  s.name         = "HXPhotoPicker"
  s.version      = "3.3.1"
  s.summary      = "照片/视频选择器 - 支持LivePhoto、GIF图片选择、自定义编辑照片/视频、3DTouch预览、浏览网络图片/网络视频 功能 - Imitation weibo photo/image picker - support for LivePhoto, GIF image selection, 3DTouch preview, browse the web image function"
  s.homepage     = "https://github.com/SilenceLove/HXPhotoPicker"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "SilenceLove" => "294005139@qq.com" }

  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/SilenceLove/HXPhotoPicker.git", :tag => "#{s.version}" }

  s.framework    = 'UIKit','Photos','PhotosUI'
  s.requires_arc = true
  s.default_subspec = 'Default'
  
  s.subspec 'Default' do |de|
    de.source_files = "HXPhotoPicker/**/*.{h,m}"
    de.resources = "HXPhotoPicker/Resources/*.{bundle}"
  end
  
  s.subspec 'SDWebImage' do |sd|
    sd.source_files = "HXPhotoPicker/**/*.{h,m}"
    sd.dependency 'SDWebImage', '~> 5.0'
    sd.resources = "HXPhotoPicker/Resources/*.{bundle}"
  end
  
  s.subspec 'SDWebImage_AF' do |sd_af|
    sd_af.source_files = "HXPhotoPicker/**/*.{h,m}"
    sd_af.dependency 'SDWebImage', '~> 5.0'
    sd_af.dependency 'AFNetworking'
    sd_af.resources = "HXPhotoPicker/Resources/*.{bundle}"
  end
  
  s.subspec 'YYWebImage' do |yy|
    yy.source_files = "HXPhotoPicker/**/*.{h,m}"
    yy.dependency 'YYWebImage', '~> 1.0.5'
    yy.resources = "HXPhotoPicker/Resources/*.{bundle}"
  end
  
  s.subspec 'YYWebImage_AF' do |yy_af|
    yy_af.source_files = "HXPhotoPicker/**/*.{h,m}"
    yy_af.dependency 'YYWebImage', '~> 1.0.5'
    yy_af.dependency 'AFNetworking'
    yy_af.resources = "HXPhotoPicker/Resources/*.{bundle}"
  end
  
  s.subspec 'CustomItem' do |customItem|
    customItem.source_files = "HXPhotoPicker/**/*.{h,m}"
    customItem.dependency 'SDWebImage', '~> 5.0'
    customItem.dependency 'AFNetworking'
    customItem.resources = "HXPhotoPicker/Resources/*.{bundle}"
    customItem.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'HXPhotoViewCustomItemSizeEnable=1'}
  end
end
