
Pod::Spec.new do |s|

  s.name         = "HXPhotoPicker_YY"
  s.version      = "2.4.2"
  s.summary      = "照片/视频选择器 - 支持LivePhoto、GIF图片选择、自定义裁剪照片、3DTouch预览、浏览网络图片/网络视频 功能 - Imitation weibo photo/image picker - support for LivePhoto, GIF image selection, 3DTouch preview, browse the web image function"
  s.homepage     = "https://github.com/SilenceLove/HXPhotoPicker"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "SilenceLove" => "294005139@qq.com" }

  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/SilenceLove/HXPhotoPicker.git", :tag => "#{s.version}" }
  s.source_files = "照片选择器/HXPhotoPicker/**/*.{h,m}"
  s.resources    = "照片选择器/HXPhotoPicker/Resource/*.{png,xib,nib,bundle}"

  s.framework    = 'UIKit','Photos','PhotosUI'
  s.requires_arc = true

  s.dependency "YYWebImage"

end
