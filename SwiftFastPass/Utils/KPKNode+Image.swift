//
//  KPKNode+Image.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import KeePassKit
import UIKit

extension KPKNode {
    func image() -> UIImage {
        if icon?.image != nil {
            return icon!.image!
        } else if Icons.iconNames.indices.contains(iconId) {
            return UIImage(named: Icons.iconNames[iconId])!
        } else {
            if self is KPKGroup {
                return UIImage(named: "Directory")!
            } else if self is KPKEntry {
                return UIImage(named: "00_PasswordTemplate")!
            }
        }
        fatalError()
    }
}
