//
//  BiometricsUtil.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2025/11/19.
//  Copyright © 2025 huchengzhen. All rights reserved.
//

import LocalAuthentication

func biometrics(onSuccess: @escaping () -> Void,
                onFailure: ((Error?) -> Void)? = nil)
{
    let context = LAContext()
    var authError: NSError?

    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                    error: &authError)
    else {
        DispatchQueue.main.async {
            onFailure?(authError)
        }
        return
    }

    let reason = NSLocalizedString("Verify identity to open password database",
                                   comment: "")

    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                           localizedReason: reason)
    { success, error in
        guard error == nil, success else {
            DispatchQueue.main.async {
                onFailure?(error)
            }
            return
        }

        DispatchQueue.main.async {
            onSuccess()
        }
    }
}
