//
//  UITextField+PasswordAutofill.swift
//  SwiftFastPass
//  Created by 胡诚真 on 2024/5/20.
//  Copyright © 2024 huchengzhen. All rights reserved.

import UIKit

extension UITextField {
    /// Force the system to treat this text field as non-password to avoid autofill/save prompts.
    func disablePasswordAutoFill() {
        guard #available(iOS 10.0, *) else { return }
        if #available(iOS 12.0, *) {
            textContentType = .oneTimeCode
        } else {
            textContentType = UITextContentType(rawValue: "")
        }
    }
}
