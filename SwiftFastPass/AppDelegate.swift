//
//  AppDelegate.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

//
//  AppDelegate.swift
//  SwiftFastPass
//

import KeePassKit
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // 如果你最低支持 iOS 13+ 或 15+，这里就不需要 window 属性了
    // UIWindow 交给 SceneDelegate 管

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 全局初始化写这里（日志、统计、KeePass 初始化之类的）
        SubscriptionManager.shared.start()
        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(
        _: UIApplication,
        didDiscardSceneSessions _: Set<UISceneSession>
    ) {
        // 可以忽略，除非你要对被丢弃的场景做统计
    }
}
