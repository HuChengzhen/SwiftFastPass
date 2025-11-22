import KeePassKit
import UIKit

extension KPKNode {
    func image() -> UIImage {
        // 1. KeePass 自带的自定义图标（数据库里内嵌的）
        if let builtinIcon = icon?.image {
            return builtinIcon
        }

        // 2. 使用我们自己的 SF Symbols + 颜色

            if Icons.sfSymbolNames.indices.contains(iconId),
               let baseImage = UIImage(systemName: Icons.sfSymbolNames[iconId]), iconColorId != 0 {
                // iconColorId 越界时给个安全默认值
                let idx: Int
                if (1 ..< IconColors.palette.count).contains(iconColorId) {
                    idx = iconColorId
                } else {
                    idx = 1   // 0 可以定义为跟随 label 的颜色
                }

                let tintColor = IconColors.palette[idx]

                // 关键：在“带颜色的图像”上设置 renderingMode
                let colored = baseImage.withTintColor(tintColor, renderingMode: .alwaysOriginal)
                return colored
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
