//
//  KPKNode+Image.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import KeePassKit

extension KPKNode {
    func image() -> UIImage {
        if self.icon?.image != nil {
            return self.icon!.image!
        } else if Icons.iconNames.indices.contains(self.iconId) {
            return UIImage(named: Icons.iconNames[self.iconId])!
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
