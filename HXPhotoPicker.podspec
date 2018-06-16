
Pod::Spec.new do |s|

  s.name         = "HXPhotoPicker"
  s.version      = "2.1.6"
  s.summary      = "照片/视频选择器 - 支持LivePhoto、GIF图片选择、自定义裁剪照片、3DTouch预览、浏览网络图片 功能 - Imitation weibo photo/image picker - support for LivePhoto, GIF image selection, 3DTouch preview, browse the web image function"
  s.homepage     = "https://github.com/LoveZYForever/HXPhotoPicker"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "LoveZYForever" => "294005139@qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/LoveZYForever/HXPhotoPicker.git", :tag => "#{s.version}" }
  s.source_files = "微博照片选择/HXPhotoPicker/*.{h,m}"
  s.resources    = "微博照片选择/HXPhotoPicker/*.{png,xib,nib,bundle}"
  s.framework    = "UIKit"
  s.requires_arc = true
  s.dependency "SDWebImage", "~> 4.0"

end
