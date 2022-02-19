source 'https://github.com/CocoaPods/Specs.git'

def commonPods
  platform:ios,'12.0'
  use_frameworks!
  pod 'HXPHPicker'
  pod 'GDPerformanceView-Swift'
  pod 'GPUImage'
end

target "HXPhotoPickerExample" do
  commonPods
    #ios14下出现显示空白需要将SDWebImage升级到最新版，YYWebImage由于没人维护所以需要替换成SDWebImage
#    pod 'SDWebImage'
#    pod 'AFNetworking'
#    pod 'Masonry'
     # SD或YY任选其一...
#    pod 'YYWebImage'
end

target "HXPHPickerExample" do
  commonPods
end
