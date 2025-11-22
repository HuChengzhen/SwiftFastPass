import KeePassKit
import UIKit

extension KPKNode {
    func image() -> UIImage {
        // 🟦 特殊：密码条目 & 默认图标 → 用旧蓝钥匙 PNG
        if self is KPKEntry,
           iconId == 0,                      // KeePass 默认 key 图标 id
           (iconColorId == 0 || iconColorId == nil) {
            if let keyImage = UIImage(named: "00_PasswordTemplate") {
                return keyImage
            }
        }

        // 1. 我们自己的 SF Symbols + 颜色
        if Icons.sfSymbolNames.indices.contains(iconId),
           let baseImage = UIImage(systemName: Icons.sfSymbolNames[iconId]) {
            let tintColor = IconColors.resolvedColor(for: iconColorId)
            let colored = baseImage.withTintColor(tintColor, renderingMode: .alwaysOriginal)
            return colored
        }

        // 2. KeePass 自带自定义图标
        if let builtinIcon = icon?.image {
            return builtinIcon
        }

        // 3. 兜底：老系统 / 没有 SF Symbols 时使用旧 PNG 资源
        if OldIcons.iconNames.indices.contains(iconId) {
            return UIImage(named: OldIcons.iconNames[iconId])!.withTintColor(.label)
        } else {
            if self is KPKGroup {
                return UIImage(named: "Directory")!
            } else if self is KPKEntry {
                return UIImage(named: "00_PasswordTemplate")!
            }
        }

        fatalError("No icon image for node")
    }
}

