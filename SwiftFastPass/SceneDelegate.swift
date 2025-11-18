//
//  SceneDelegate.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2025/11/19.
//  Copyright © 2025 huchengzhen. All rights reserved.
//

//
//  SceneDelegate.swift
//  SwiftFastPass
//

import KeePassKit
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // 模糊遮罩（原来在 AppDelegate）
    lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        view.frame = UIScreen.main.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()

    // MARK: - Scene life cycle

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        if setupICloudDocumentsDirectory() {
            // iCloud 可用 → 正常显示 FilesViewController
            let filesViewController = FilesViewController()
            let navigationController = UINavigationController(rootViewController: filesViewController)
            window.rootViewController = navigationController
        } else {
            // iCloud 不可用 → 显示提示界面
            let viewController = UIViewController()
            if #available(iOS 13.0, *) {
                viewController.view.backgroundColor = UIColor.systemBackground
            } else {
                viewController.view.backgroundColor = UIColor.white
            }
            window.rootViewController = viewController

            // 用 alert 提示用户（确保在 root 设置好之后再 present）
            DispatchQueue.main.async {
                let alertController = UIAlertController(
                    title: NSLocalizedString("Please open iCloud in system settings", comment: ""),
                    message: NSLocalizedString("This app does not work without iCloud", comment: ""),
                    preferredStyle: .alert
                )
                viewController.present(alertController, animated: true, completion: nil)
            }
        }

        window.makeKeyAndVisible()
    }

    func sceneWillResignActive(_: UIScene) {
        // App 进入非活跃（来电话、锁屏、退到后台前） → 加上模糊遮罩
        guard let window = window else { return }
        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                window.addSubview(self.blurView)
            },
            completion: nil
        )
    }

    func sceneDidBecomeActive(_: UIScene) {
        // 回到前台、恢复活跃 → 移除模糊
        guard let window = window else { return }
        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                self.blurView.removeFromSuperview()
            },
            completion: nil
        )
    }

    func sceneDidEnterBackground(_: UIScene) {
        // 进入后台时保存数据
        File.save()
    }

    // 如果你想在终止前也保存一次，iOS 13+ 多数场景不会再给你 appWillTerminate
    // 所以把保存放在 sceneDidEnterBackground 即可

    // MARK: - iCloud Documents Directory

    /// 确保 iCloud 容器下的 Documents 目录已创建
    /// - Returns: 创建成功或已存在时返回 true，iCloud 不可用或创建失败时返回 false
    private func setupICloudDocumentsDirectory() -> Bool {
        // 1. 获取 iCloud 容器根目录
        guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            print("iCloud 未启用或不可用")
            return false
        }

        // 2. 拼出 Documents 目录
        let documentsURL = ubiquityURL.appendingPathComponent("Documents", isDirectory: true)

        // 3. 尝试创建目录（如果已存在不会报错）
        do {
            try FileManager.default.createDirectory(
                at: documentsURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            return true
        } catch {
            print("创建 iCloud Documents 目录失败: \(error)")
            return false
        }
    }
}
