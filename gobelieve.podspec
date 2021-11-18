#
# Be sure to run `pod lib lint imkit.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = "gobelieve"
  s.version          = "0.1.1"
  s.summary          = "imkit."
  s.description      = "imkit of gobelieve"
  s.homepage         = "http://developer.gobelieve.io"
  s.license          = 'MIT'
  s.author           = { "houxh" => "houxuehua49@gmail.com" }
  s.source           = { :git => 'git@github.com:GoBelieveIO/im_ios.git' }
  s.platform         = :ios, '8.0'
  s.requires_arc     = true

  s.subspec 'imsdk' do |sp|
    sp.public_header_files = 'imsdk/*.h'
    sp.source_files        = 'imsdk/*.{h,m,c}'
  end

  s.subspec 'imlib' do |sp|
     sp.source_files     = 'imlib/**/*.{h,m,c}'
     sp.dependency 'gobelieve/imsdk'
     sp.dependency 'SDWebImage', '~> 5.1.0'
     sp.dependency 'FMDB', '~> 2.7.0'
     sp.dependency 'Masonry', '~>1.1.0'
     sp.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'YES' }    
  end

  s.subspec 'imkit' do |sp|
    sp.preserve_paths   = 'imkit/amr/libopencore-amrnb.a'
    sp.library          = 'opencore-amrnb'
    sp.xcconfig         = { 'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/gobelieve/imkit/amr"' }
    sp.source_files     = 'imkit/**/*.{h,m,c}'
    sp.resource         = ['imkit/imKitRes/sounds/*.aiff', 'imkit/imKitRes/gobelieve.xcassets', 'imkit/imKitRes/Emoji.xcassets']
    sp.dependency 'gobelieve/imsdk'
    sp.dependency 'gobelieve/imlib'
    sp.dependency 'SDWebImage', '~> 5.1.0'
    sp.dependency 'Toast', '~> 4.0.0'
    sp.dependency 'MBProgressHUD', '~> 1.2.0'
    sp.dependency 'FMDB', '~> 2.7.0'
    sp.dependency 'Masonry', '~>1.1.0'
    sp.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'YES' }    
  end

end
