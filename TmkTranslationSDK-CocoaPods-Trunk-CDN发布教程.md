# 发布和更新第三方库到 CocoaPods 公共 Trunk/CDN 教程

> 适用场景：将 iOS SDK 或二进制 framework 发布到 CocoaPods 公共 Trunk/CDN，使第三方项目无需添加私有 Specs 源，只通过 `pod 'PodName', '<version>'` 完成接入。

## 1. 目标效果

发布完成后，接入方的 `Podfile` 可以保持简单：

```ruby
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'TmkTranslationSDK', '1.2.0-dev1'
end
```

通常不需要添加私有 Specs 源：

```ruby
source 'https://github.com/timekettle/TmkTranslationSDK-iOS.git'
```

如果本地 CocoaPods 环境不稳定，可以临时显式声明公共 CDN：

```ruby
source 'https://cdn.cocoapods.org/'
```

这是 CocoaPods 公共 CDN，不是私有源。

## 2. 核心概念

### 2.1 GitHub Specs 仓库不等于公共 CocoaPods

把 podspec 推送到自己的 Specs 仓库，只能让添加了该源的项目解析到：

```ruby
source 'https://github.com/your-org/YourSpecsRepo.git'
```

如果希望用户不加私有 source，只写：

```ruby
pod 'TmkTranslationSDK', '1.2.0-dev1'
```

就必须发布到 CocoaPods Trunk：

```bash
pod trunk push Specs/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec --allow-warnings
```

### 2.2 Trunk 同版本不能覆盖

同一个 pod 的同一个版本只能发布一次。已经发布过的版本不能通过再次 `pod trunk push` 覆盖。

如果错误版本已经发布，通常应发布新版本，例如：

```text
1.1.3
1.2.0-dev1
1.2.0
```

不要依赖删除后重发。同版本删除后通常也不能再次发布。

### 2.3 podspec 里的资源必须公网可访问

公共 Trunk/CDN 面向所有 CocoaPods 用户，所以 `s.source` 应使用公网可访问地址。

推荐：

```ruby
s.source = {
  :git => 'https://github.com/timekettle/TmkTranslationSDK-xcframework.git',
  :tag => "v#{s.version}"
}
```

避免：

```ruby
s.source = {
  :git => 'git@github.com:timekettle/TmkTranslationSDK-xcframework.git',
  :tag => "v#{s.version}"
}
```

SSH 地址会依赖用户本机权限，不适合作为公共 CocoaPods 发布源。

## 3. 发布前准备

### 3.1 确认 CocoaPods Trunk 账号

查看当前机器是否已登录：

```bash
pod trunk me
```

如果没有登录，注册：

```bash
pod trunk register mobile_dev@timekettle.co 'Timekettle' --description='release machine'
```

然后打开邮件里的确认链接。

### 3.2 确认二进制仓库 tag

如果 podspec 使用：

```ruby
:tag => "v#{s.version}"
```

那么：

```ruby
s.version = '1.2.0-dev1'
```

必须对应二进制仓库里的 tag：

```text
v1.2.0-dev1
```

检查命令：

```bash
git ls-remote --tags https://github.com/timekettle/TmkTranslationSDK-xcframework.git refs/tags/v1.2.0-dev1
```

有输出表示 tag 存在。

### 3.3 确认依赖也可公开解析

podspec 中的依赖也必须能从公共 CocoaPods 源解析，例如：

```ruby
s.dependency 'AgoraAudio_Special_iOS', '~> 4.5.2.4'
s.dependency 'AgoraRtm/RtmKit', '2.2.6'
```

如果某个依赖只存在于私有 Specs 源，接入方仍然必须添加私有 source，无法达到“只写 pod”的目标。

## 4. 新增或更新 podspec

### 4.1 目录命名

Specs 目录使用不带 `v` 的版本号：

```text
Specs/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec
```

不要写成：

```text
Specs/TmkTranslationSDK/v1.2.0-dev1/
```

### 4.2 示例 podspec

```ruby
Pod::Spec.new do |s|
  s.name             = 'TmkTranslationSDK'
  s.version          = '1.2.0-dev1'
  s.summary          = 'Timekettle Translation SDK for iOS.'
  s.description      = 'Private binary distribution spec for TmkTranslationSDK.'
  s.homepage         = 'https://github.com/timekettle/TmkTranslationSDK-xcframework'
  s.license          = { :type => 'Proprietary', :text => 'Copyright (c) Timekettle. All rights reserved.' }
  s.author           = { 'Timekettle' => 'ios@timekettle.co' }
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.0'

  s.source = {
    :git => 'https://github.com/timekettle/TmkTranslationSDK-xcframework.git',
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
```

### 4.3 关键字段检查

| 字段 | 要求 |
| --- | --- |
| `s.name` | 与 CocoaPods 上的 pod 名一致 |
| `s.version` | 与 Specs 版本目录一致 |
| `s.homepage` | 公网可访问 |
| `s.source` | 公网可访问，推荐 HTTPS |
| `s.platform` | 与 SDK 最低支持系统一致 |
| `s.vendored_frameworks` | 指向实际产物路径 |
| `s.dependency` | 依赖必须可解析 |

## 5. 本地校验

### 5.1 Ruby 语法检查

```bash
ruby -c Specs/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec
```

期望输出：

```text
Syntax OK
```

### 5.2 podspec lint

```bash
pod spec lint Specs/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec --allow-warnings
```

期望输出：

```text
TmkTranslationSDK.podspec passed validation.
```

常见 warning 示例：

```text
The iOS Simulator deployment target ... is set to 8.0/11.0
```

如果来自三方依赖且 lint 通过，通常不阻塞发布。

常见错误：

```text
Operation not permitted @ rb_sysopen - ~/Library/Caches/CocoaPods/Pods/VERSION
```

这是本机 CocoaPods 缓存目录写权限问题。处理方式：

```bash
rm -rf ~/Library/Caches/CocoaPods
pod spec lint Specs/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec --allow-warnings
```

## 6. 提交 Specs 仓库

将新增或修改的 podspec 提交到自己的 Specs 仓库：

```bash
git status --short --branch
git add Specs/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec
git diff --cached --stat
git commit -m "chore: 新增1.2.0-dev1规格"
git push origin main
```

注意：这一步只是更新自己的 GitHub Specs 仓库，还没有发布到 CocoaPods 公共 Trunk/CDN。

## 7. 发布到 CocoaPods Trunk

### 7.1 发布命令

必须指定 podspec 路径：

```bash
pod trunk push Specs/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec --allow-warnings
```

不要只执行：

```bash
pod trunk push
```

如果当前目录没有 `.podspec`，会报：

```text
No podspec found in directory `.`
Please specify the path to the podspec file.
```

### 7.2 确认 Trunk 已登记

```bash
pod trunk info TmkTranslationSDK
```

期望看到：

```text
Versions:
  - 1.2.0-dev1
```

## 8. 等待并验证 CDN 同步

Trunk 发布成功不等于所有 CDN 索引立即可用。CocoaPods 解析依赖时会依赖 CDN 的 podspec JSON 和版本索引。

### 8.1 检查单个 podspec JSON

```bash
curl -IL https://cdn.cocoapods.org/Specs/d/f/6/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec.json
```

最终状态为 `HTTP/2 200` 表示单个 JSON 已同步。

### 8.2 检查版本索引

```bash
curl -L https://cdn.cocoapods.org/all_pods_versions_d_f_6.txt | grep TmkTranslationSDK
```

期望包含：

```text
1.2.0-dev1
```

如果单个 JSON 是 `200`，但版本索引仍没有新版本，`pod install` 仍可能找不到该版本。继续等待 CDN 索引同步即可。

### 8.3 检查本机 CocoaPods 是否能读取

```bash
pod spec cat TmkTranslationSDK --version=1.2.0-dev1
```

如果能输出 podspec，说明本机 CocoaPods 已能解析该版本。

## 9. 查看当前支持的所有历史版本

### 9.1 查看 Trunk 当前登记版本

```bash
pod trunk info TmkTranslationSDK
```

该命令会列出 CocoaPods Trunk 当前登记的版本，例如：

```text
Versions:
  - 1.2.0-dev1
```

### 9.2 查看 CDN 版本索引

```bash
curl -L https://cdn.cocoapods.org/all_pods_versions_d_f_6.txt | grep TmkTranslationSDK
```

该命令更接近 `pod install` 解析依赖时使用的版本索引。输出示例：

```text
TmkTranslationSDK/1.2.0-dev1
```

如果历史版本共存，索引中应能看到多个版本信息。

### 9.3 确认指定版本是否可解析

```bash
pod spec cat TmkTranslationSDK --version=1.2.0-dev1
```

能输出 podspec 表示本机 CocoaPods 当前可以解析该版本。

也可以检查单个 CDN JSON：

```bash
curl -IL https://cdn.cocoapods.org/Specs/d/f/6/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec.json
```

判断优先级建议：

1. `pod trunk info TmkTranslationSDK`：看 Trunk 当前登记版本。
2. `all_pods_versions_d_f_6.txt`：看 CDN 当前参与解析的版本索引。
3. `pod spec cat --version=...`：看本机 CocoaPods 能否实际读到。
4. 单个 JSON `curl -IL`：辅助判断 CDN 文件是否残留或已同步。

## 10. 第三方 Demo 验证

### 10.1 Podfile

```ruby
platform :ios, '15.0'

target 'SDKPodDemo' do
  use_frameworks!
  pod 'TmkTranslationSDK', '1.2.0-dev1'
end
```

如需显式公共 CDN：

```ruby
source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'SDKPodDemo' do
  use_frameworks!
  pod 'TmkTranslationSDK', '1.2.0-dev1'
end
```

### 10.2 安装

新版本刚发布后，建议首次使用：

```bash
pod install --repo-update
```

成功示例：

```text
Analyzing dependencies
Downloading dependencies
Installing AgoraAudio_Special_iOS
Installing AgoraRtm
Installing TmkTranslationSDK (1.2.0-dev1)
Generating Pods project
Integrating client project
Pod installation complete!
```

### 10.3 为什么 `pod install --repo-update` 成功，而 `pod install` 失败

`pod install` 更偏向使用本地已有 specs 索引。

`pod install --repo-update` 会先刷新 specs repo，再解析依赖。

新版本刚发布后，本地索引可能还不知道新版本，所以普通 `pod install` 可能报：

```text
None of your spec sources contain a spec satisfying the dependency
```

刷新过一次后，后续普通 `pod install` 通常也会成功。

## 11. 常见问题

### 11.1 `Unable to accept duplicate entry`

错误：

```text
Unable to accept duplicate entry for: TmkTranslationSDK (1.1.2)
```

原因：该版本已经发布到 Trunk，不能覆盖。

处理：发布新版本。

### 11.2 `Unable to find a specification`

错误：

```text
Unable to find a specification for `TmkTranslationSDK (= 1.2.0-dev1)`
```

排查：

```bash
pod trunk info TmkTranslationSDK
pod spec cat TmkTranslationSDK --version=1.2.0-dev1
curl -IL https://cdn.cocoapods.org/Specs/d/f/6/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec.json
curl -L https://cdn.cocoapods.org/all_pods_versions_d_f_6.txt | grep TmkTranslationSDK
pod install --repo-update
```

常见原因：

- 版本未发布到 Trunk。
- Trunk 已登记，但 CDN 版本索引未同步。
- 本地 CocoaPods specs 缓存未刷新。
- Podfile 版本写错。
- Podfile 的 `source` 限制了搜索范围。

### 11.3 `No podspec exists at path ~/.cocoapods/repos/trunk/...`

原因：本地 trunk 缓存损坏或文件缺失。

处理：

```bash
rm -rf ~/.cocoapods/repos/trunk
pod setup
pod install --repo-update
```

如果 `pod repo update trunk` 报：

```text
Unable to find the `trunk` repo.
```

说明本地 trunk repo 不存在，先执行：

```bash
pod setup
```

必要时显式加回 CDN：

```bash
pod repo add-cdn trunk https://cdn.cocoapods.org/
```

### 11.4 `s.homepage` URL 不可达

lint 可能提示：

```text
url: The URL (...) is not reachable.
```

处理：将 `s.homepage` 改为公网可访问地址。

### 11.5 SSH source 导致公共安装失败

如果 podspec 中存在：

```ruby
:git => 'git@github.com:your-org/your-repo.git'
```

公共用户可能无法拉取。

应改为：

```ruby
:git => 'https://github.com/your-org/your-repo.git'
```

### 11.6 删除已发布的测试版或开发版

如果某个版本只是临时测试版，不应继续对外可安装，可以从 Trunk 删除：

```bash
pod trunk delete TmkTranslationSDK 1.2.0-dev1
```

删除前先确认当前账号有 owner 权限：

```bash
pod trunk me
pod trunk info TmkTranslationSDK
```

删除后验证：

```bash
pod trunk info TmkTranslationSDK
pod spec cat TmkTranslationSDK --version=1.2.0-dev1
curl -L https://cdn.cocoapods.org/all_pods_versions_d_f_6.txt | grep TmkTranslationSDK
curl -IL https://cdn.cocoapods.org/Specs/d/f/6/TmkTranslationSDK/1.2.0-dev1/TmkTranslationSDK.podspec.json
```

注意：

- 删除后该版本不应再作为公共可安装版本使用。
- 同一个版本删除后通常不能再次发布，不要把 delete 当成“覆盖重发”的手段。
- CDN 单个 podspec JSON 可能短时间仍返回 `200`，以 `pod trunk info` 和 `all_pods_versions...` 版本索引是否还列出该版本作为主要判断。
- 后续如需继续测试，应发布新版本号，例如 `1.2.0-dev2`，不要复用已删除版本号。

## 12. 发布检查清单

- [ ] Specs 目录存在：`Specs/TmkTranslationSDK/<version>/TmkTranslationSDK.podspec`
- [ ] `s.version` 与目录名一致
- [ ] 如果版本是 `dev`、`beta`、`rc` 等预发布版本，已确认允许对外临时发布
- [ ] 二进制仓库存在 `v<version>` tag
- [ ] `s.source` 使用公网 HTTPS 地址
- [ ] `s.homepage` 可公网访问
- [ ] 所有 `s.dependency` 都能从公共源解析
- [ ] `ruby -c` 通过
- [ ] `pod spec lint --allow-warnings` 通过
- [ ] GitHub Specs 仓库已提交并推送
- [ ] `pod trunk me` 有有效 session
- [ ] `pod trunk push` 发布成功
- [ ] `pod trunk info` 能看到新版本
- [ ] CDN podspec JSON 返回 `200`
- [ ] CDN 版本索引包含新版本
- [ ] 如需确认历史版本共存，`pod trunk info` 和 CDN 版本索引均能看到目标历史版本
- [ ] `pod spec cat` 能输出新版本
- [ ] Demo `pod install --repo-update` 安装成功
- [ ] 如果删除测试版，已确认 `pod trunk info` 和 CDN 版本索引不再列出该版本

## 13. 命令模板

将 `VERSION` 替换为实际版本：

```bash
VERSION=1.2.0-dev1

git ls-remote --tags https://github.com/timekettle/TmkTranslationSDK-xcframework.git refs/tags/v${VERSION}

ruby -c Specs/TmkTranslationSDK/${VERSION}/TmkTranslationSDK.podspec

pod spec lint Specs/TmkTranslationSDK/${VERSION}/TmkTranslationSDK.podspec --allow-warnings

git status --short --branch
git add Specs/TmkTranslationSDK/${VERSION}/TmkTranslationSDK.podspec
git diff --cached --stat
git commit -m "chore: 新增${VERSION}规格"
git push origin main

pod trunk me
pod trunk push Specs/TmkTranslationSDK/${VERSION}/TmkTranslationSDK.podspec --allow-warnings
pod trunk info TmkTranslationSDK

pod spec cat TmkTranslationSDK --version=${VERSION}
curl -IL https://cdn.cocoapods.org/Specs/d/f/6/TmkTranslationSDK/${VERSION}/TmkTranslationSDK.podspec.json
curl -L https://cdn.cocoapods.org/all_pods_versions_d_f_6.txt | grep TmkTranslationSDK
```

Demo 验证：

```bash
pod install --repo-update
```

## 14. 官方参考

- CocoaPods Trunk 发布说明：https://guides.cocoapods.org/making/getting-setup-with-trunk.html
- CocoaPods Podfile 语法：https://guides.cocoapods.org/syntax/podfile.html
- CocoaPods `pod install` 与 `pod update` 区别：https://guides.cocoapods.org/using/pod-install-vs-update.html
- CocoaPods 命令行参考：https://guides.cocoapods.org/terminal/commands.html
