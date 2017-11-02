
Pod::Spec.new do |s|

  s.name         = "HXWeiboPhotoPicker"
  s.version      = "2.1.1"
  s.summary      = "仿微博照片/图片选择器 - 支持LivePhoto、GIF图片选择、3DTouch预览、浏览网络图片 功能 - Imitation weibo photo/image picker - support for LivePhoto, GIF image selection, 3DTouch preview, browse the web image function"
  s.homepage     = "https://github.com/LoveZYForever/HXWeiboPhotoPicker"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "LoveZYForever" => "294005139@qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/LoveZYForever/HXWeiboPhotoPicker.git", :tag => "#{s.version}" }
  s.source_files = "微博照片选择/HXWeiboPhotoPicker/*.{h,m}"
  s.resources    = "微博照片选择/HXWeiboPhotoPicker/*.{png,xib,nib,bundle}"
  s.framework    = "UIKit"
  s.requires_arc = true
  s.dependency "SDWebImage", "~> 4.0"

end
