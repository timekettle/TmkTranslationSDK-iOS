Pod::Spec.new do |s|
  s.name             = 'TmkTranslationSDK'
  s.version          = '1.1.2'
  s.summary          = 'Timekettle Translation SDK for iOS.'
  s.description      = 'Private binary distribution spec for TmkTranslationSDK.'
  s.homepage         = 'https://github.com/timekettle/tmk-translation-sdk'
  s.license          = { :type => 'Proprietary', :text => 'Copyright (c) Timekettle. All rights reserved.' }
  s.author           = { 'Timekettle' => 'ios@timekettle.co' }
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.0'

  s.source = {
    :git => 'git@github.com:timekettle/TmkTranslationSDK-xcframework.git',
    :tag => "v#{s.version}"
  }

  s.vendored_frameworks = 'TmkTranslationSDK.xcframework'
  s.frameworks       = 'AVFoundation', 'AudioToolbox', 'Foundation', 'UIKit'

  s.dependency 'AgoraAudio_Special_iOS', '~> 4.5.2.4'
  s.dependency 'AgoraRtm/RtmKit', '2.2.6'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
  s.user_target_xcconfig = {
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks'
  }
end
