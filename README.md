# TmkTranslationSDK-iOS

Private CocoaPods Specs repository for TmkTranslationSDK iOS releases.

## Repository Role

This repository is a private CocoaPods Specs repository, not the SDK source repository.

It is intended to let third-party iOS apps integrate the binary SDK with:

```ruby
pod 'TmkTranslationSDK', '1.1.2'
```

after they add this private Specs source to their `Podfile`.

## Third-Party Integration

Add both the public CocoaPods CDN and this private Specs repository to the top of the consumer app's `Podfile`:

```ruby
source 'https://cdn.cocoapods.org/'
source 'https://github.com/timekettle/TmkTranslationSDK-iOS.git'

platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!

  pod 'TmkTranslationSDK', '1.1.2'
end
```

Then run:

```bash
pod install --repo-update
```

`TmkTranslationSDK` and its Agora dependencies are delivered as dynamic frameworks. CocoaPods embeds these frameworks into the app bundle through the `[CP] Embed Pods Frameworks` build phase. Xcode's `User Script Sandboxing` must be set to `No` for the app target, otherwise the embed script can fail with `Operation not permitted` when it copies frameworks. The `post_install` hook above applies this setting automatically after `pod install`; if the setting is managed manually in Xcode, set `Build Settings > User Script Sandboxing` to `No`.

## Version Selection Examples

Use the latest version published in this Specs repository:

```ruby
pod 'TmkTranslationSDK'
```

Note: with the currently retained versions, CocoaPods will resolve the latest version to `1.1.2`.

Pin to an exact version:

```ruby
pod 'TmkTranslationSDK', '1.1.2'
```

Allow a minimum version:

```ruby
pod 'TmkTranslationSDK', '>= 1.1.2'
```

Allow a version range:

```ruby
pod 'TmkTranslationSDK', '>= 1.1.2', '< 2.0.0'
```

Currently retained historical versions in this repository:

- `1.1.2`
- `1.1.1`
- `1.1.0`
- `1.0.0`
- `0.1.0`

## Requirements

- iOS 15.0+
- Swift 5
- Access to this private repository
- Access to the binary release artifact referenced by the podspec

## Maintainer Checklist

For each new SDK release:

1. Publish the binary artifact to the SDK release repository.
2. Create a spec at `Specs/TmkTranslationSDK/<version>/TmkTranslationSDK.podspec`.
3. Set `s.version = '<version>'`.
4. Ensure `s.source` points to the correct binary source and uses the same version in both the tag and referenced artifact.
5. Run `pod spec lint Specs/TmkTranslationSDK/<version>/TmkTranslationSDK.podspec --allow-warnings`.
6. Add the new version directory without removing historical versions.
7. Commit and push this Specs repository.

## Notes

- The version directory must be a semantic version such as `1.1.2`, `1.0.0`, or `0.1.0`, not `v1.1.2`, `v1.0.0`, or `v0.1.0`.
- Consumers must update this Specs repo before installation, for example with `pod install --repo-update`.
- From the next release onward, keep previously published version directories so consumers can continue pinning older SDK releases.
