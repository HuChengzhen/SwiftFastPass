# SwiftFastPass

SwiftFastPass 是一个面向 iOS 的本地密码管理器。应用使用 KeePassKit 读写 `.kdbx` 数据库，支持密码库加密、密钥文件与生物识别授权，并通过 SnapKit、MenuItemKit、Eureka 等依赖构建出全功能的编辑/浏览体验。仓库包含完整的应用源码、测试以及必要的第三方依赖配置（CocoaPods/Carthage）。

## 功能亮点
- **多重加密**：支持主密码与密钥文件的组合，并依据安全等级在钥匙串缓存派生凭证。
- **生物识别**：可选 Face ID / Touch ID 解锁，新增数据库时也可以开启或关闭生物识别。
- **密码生成 & 预览**：内置密码生成器、密码放大显示视图，以及复制保护逻辑（自动清理剪贴板）。
- **本地化**：已提供英文与简体中文（zh-Hans）界面与文案，UI/Localizable 在 `Base.lproj`、`en.lproj`、`zh-Hans.lproj`。

## 目录结构
```
SwiftFastPass/            # App 源码（UI、Models、Utils、PasswordCreator 等）
SwiftFastPassTests/       # 单元测试
SwiftFastPassUITests/     # UI 自动化
Pods/, Carthage/          # 引入的第三方库
Assets.xcassets, fonts/   # 资源与字体
Base.lproj/, *.lproj/     # 本地化 storyboards 与 strings
```

## 依赖与工具
- Xcode 15 / Swift 5
- CocoaPods（SnapKit、MenuItemKit、Eureka 等）
- Carthage（桥接头所需的第三方框架）

## 环境准备
1. 安装 CocoaPods 依赖
   ```bash
   pod install
   ```
2. 安装 Carthage 依赖
   ```bash
   carthage bootstrap --platform iOS --use-xcframeworks
   ```

## 构建与运行
首选通过 `SwiftFastPass.xcworkspace` 打开工程，选中 `SwiftFastPass` scheme，然后选择 iOS 15+ 模拟器（例如 iPhone 15）运行。如果希望在命令行构建：
```bash
xcodebuild -workspace SwiftFastPass.xcworkspace \
           -scheme SwiftFastPass \
           -destination "platform=iOS Simulator,name=iPhone 15"
```

## 测试
仓库内提供单元测试与 UI 测试：
```bash
xcodebuild test -workspace SwiftFastPass.xcworkspace \
                -scheme SwiftFastPass \
                -destination "platform=iOS Simulator,name=iPhone 15"
```
新增功能时请至少补充一条单元测试；若变更影响 UI（例如新增密码列表交互），应编写或更新 UITest 进行回归。

## 开发指引
- 遵循 Swift 5 代码风格（四空格缩进、同行大括号，`final class` 优先）。
- 模块组织：`UI/` 存放控制器与视图、`Models/` 管理 KeePass 实体、`PasswordCreator/` 负责生成逻辑、`Utils/` 放置工具扩展。
- 所有本地化文本必须同步更新 `en.lproj` 与 `zh-Hans.lproj`。
- Storyboard ID 与控制器名一致（例如 `PasswordListViewController`）。
- 不要提交真实的签名证书，所需的 entitlements 已包含在仓库。

## 安全提示
- 密钥与敏感常量请通过 Build Settings/环境变量注入，不要写入 `Info.plist`。
- 若修改 `SwiftFastPass-Bridging-Header.h`，仅暴露必要的 Objective-C 符号。
- 钥匙串访问策略位于 `FileSecretStore`，根据 `File.SecurityLevel` 自动附加 `SecAccessControl`，确保凭证只在解锁设备且满足生物识别要求时使用。

## 贡献
欢迎通过 Issues / Pull Requests 反馈和提交改动。PR 请包含：
1. 简短说明与关联 issue。
2. UI 改动时的模拟器截图。
3. `xcodebuild test` 通过说明。
