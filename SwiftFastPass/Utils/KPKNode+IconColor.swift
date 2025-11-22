//
//  KPKNode+IconColor.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2025/11/22
//

import Foundation
import KeePassKit

private let iconColorIdCustomDataKey = "FastPass.IconColorId"

extension KPKNode {

    /// 使用 KPKNode 自带的 customData 持久化 iconColorId
    var iconColorId: Int {
        get {
            // 从 customData 中读出字符串再转 Int
            if let value = customData[iconColorIdCustomDataKey],
               let intValue = Int(value) {
                return intValue
            }
            return 0
        }
        set {
            // 0 视为“使用默认颜色”，可以选择不写入，直接删 key
            if newValue == 0 {
                removeCustomData(forKey: iconColorIdCustomDataKey)
            } else {
                setCustomData(String(newValue), forKey: iconColorIdCustomDataKey)
            }
        }
    }
}
