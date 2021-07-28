#
# Be sure to run `pod lib lint YJMediaBrowser.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YJMediaBrowser'
  s.version          = '0.1.0'
  s.summary          = '仿微信图片、视频浏览器'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: 仿微信图片、视频浏览器。包括滑动查看、放大、缩小、拖拽、保存到相册、识别图中二维码等功能。
                       DESC

  s.homepage         = 'https://github.com/xyz5102/YJMediaBrowser'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xyz5102' => '627454910@qq.com' }
  s.source           = { :git => 'https://github.com/xyz5102/YJMediaBrowser.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'YJMediaBrowser/Classes/**/*'
  
  # s.resource_bundles = {
  #   'YJMediaBrowser' => ['YJMediaBrowser/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  s.dependency 'Masonry', '~> 1.1.0'
  s.dependency 'SDWebImage', '~> 5.10.4'
  s.dependency 'SDWebImageFLPlugin', '~> 0.5.0'
  s.dependency 'AliPlayerSDK_iOS', '~> 5.3.2'
end
