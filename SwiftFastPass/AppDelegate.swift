//
//  AppDelegate.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import KeePassKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        view.frame = UIScreen.main.bounds
        return view
    }()

    private func setupWindow() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let filesViewController = FilesViewController()
        let navigationViewController = UINavigationController(rootViewController: filesViewController)
        window.rootViewController = navigationViewController
        self.window = window
        self.window?.makeKeyAndVisible()
    }
    
    private func setupICloudDocumentsDirectory() {
        let documentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)!.appendingPathComponent("Documents")
//        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("setupICloudDocumentsDirectory error: \(error)")
            }
//        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupICloudDocumentsDirectory()
        setupWindow()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        UIView.transition(with: self.window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.window?.addSubview(self.blurView)
        }, completion: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIView.transition(with: self.window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.blurView.removeFromSuperview()
        }, completion: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        File.save()
    }


}

