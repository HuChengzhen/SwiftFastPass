//
//  LockViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/7.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import Eureka
import KeePassKit
import LocalAuthentication
import UIKit

class LockViewController: FormViewController {
    var file: File!

    var keyFileContent: Data?
    private let premiumAccess = PremiumAccessController.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        openDatabaseIfHasPassword()
    }

    private func openDatabaseIfHasPassword() {
        guard premiumAccess.isPremiumUnlocked, file.securityLevel.usesBiometrics else {
            return
        }

        var hasCredentials = file.password != nil || file.keyFileContent != nil
        var loadedFromKeychain = false
        if !hasCredentials {
            loadedFromKeychain = file.loadCachedCredentials()
            hasCredentials = loadedFromKeychain
        }

        guard hasCredentials else {
            return
        }

        let openBlock = {
            self.openDatabase(password: self.file.password,
                              keyFileContent: self.file.keyFileContent,
                              updateFile: false)
        }

        if loadedFromKeychain, file.securityLevel.keychainRequiresUserPresence {
            openBlock()
        } else {
            biometrics(onSuccess: openBlock)
        }
    }

    // MARK: - Public

    func openDatabase(password: String?, keyFileContent: Data?, updateFile: Bool) {
        guard let url = resolveBookmarkURL() else {
            return
        }

        let document = Document(fileURL: url)
        document.key = buildCompositeKey(password: password, keyFileContent: keyFileContent)

        document.open { [weak self] success in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if success {
                    if updateFile {
                        self.file.attach(password: password, keyFileContent: keyFileContent)
                        self.file.image = document.tree?.root?.image()
                    }

                    let databaseViewController = DatabaseViewController()
                    databaseViewController.document = document
                    databaseViewController.group = document.tree?.root

                    if let navigationController = self.navigationController {
                        navigationController.pushViewController(databaseViewController, animated: true)
                        if let index = navigationController.viewControllers.firstIndex(of: self) {
                            navigationController.viewControllers.remove(at: index)
                        }
                    }
                } else {
                    self.presentInvalidKeyAlert()
                }
            }
        }
    }

    // MARK: - Private helpers

    private func resolveBookmarkURL() -> URL? {
        var isStale = false

        do {
            let url = try URL(resolvingBookmarkData: file.bookmark,
                              bookmarkDataIsStale: &isStale)

            if isStale {
                do {
                    let newBookmark = try url.bookmarkData(options: .suitableForBookmarkFile)
                    file.updateBookmark(newBookmark)
                } catch {
                    print("LockViewController.openDatabase bookmark update error: \(error)")
                    // 这里选择继续使用旧 url，视需求可以 return nil
                }
            }

            return url
        } catch {
            print("LockViewController.openDatabase bookmark resolve error: \(error)")
            return nil
        }
    }

    private func buildCompositeKey(password: String?, keyFileContent: Data?) -> KPKCompositeKey {
        let compositeKey = KPKCompositeKey()

        if let password = password,
           !password.isEmpty,
           let passwordKey = KPKPasswordKey(password: password)
        {
            compositeKey.add(passwordKey)
        }

        if let keyFileContent = keyFileContent,
           let fileKey = try? KPKFileKey(keyFileData: keyFileContent)
        {
            compositeKey.add(fileKey)
        }

        return compositeKey
    }

    private func presentInvalidKeyAlert() {
        let title = NSLocalizedString("Password or key file is not correct", comment: "")
        let message = NSLocalizedString("Please check password and key file", comment: "")

        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)

        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                   style: .cancel,
                                   handler: nil)
        alertController.addAction(cancel)

        present(alertController, animated: true, completion: nil)
    }

    private func setupUI() {
        navigationItem.title = file.name
        let editItem = UIBarButtonItem(title: NSLocalizedString("Edit", comment: ""), style: .plain, target: self, action: #selector(editButtonTapped))
        let openItem = UIBarButtonItem(title: NSLocalizedString("Open", comment: ""), style: .done, target: self, action: #selector(openButtonTapped(sender:)))
        navigationItem.rightBarButtonItems = [editItem, openItem]
        form +++ Section()
            <<< TextRow("password") { row in
                row.title = NSLocalizedString("Password", comment: "")
                row.placeholder = NSLocalizedString("Enter password here", comment: "")
            }.cellSetup { cell, _ in
                cell.textField.isSecureTextEntry = true
                if #available(iOS 12.0, *) {
                    cell.textField.textContentType = .oneTimeCode
                } else {
                    cell.textField.textContentType = nil
                }
            }
            +++ Section()
            <<< ButtonRow("keyFile") { row in
                row.title = NSLocalizedString("Select Key File", comment: "")
            }.onCellSelection(keyFileButtonTapped)
    }

    @objc func openButtonTapped(sender _: Any) {
        let password = (form.rowBy(tag: "password") as! TextRow).value
        openDatabase(password: password, keyFileContent: keyFileContent, updateFile: true)
    }

    @objc private func editButtonTapped() {
        let settings = DatabaseSettingsViewController(file: file)
        navigationController?.pushViewController(settings, animated: true)
    }

    func keyFileButtonTapped(cell: ButtonCellOf<String>, row _: ButtonRow) {
        guard premiumAccess.enforce(feature: .keyFile, presenter: self) else { return }
        if keyFileContent == nil {
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
            documentPicker.delegate = self
            present(documentPicker, animated: true, completion: nil)
        } else {
            keyFileContent = nil
            let buttonRow = form.rowBy(tag: "keyFile") as! ButtonRow
            buttonRow.title = NSLocalizedString("Select Key File", comment: "")
            cell.tintColor = UIColor.systemBlue
            buttonRow.updateCell()
        }
    }
}

extension LockViewController: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                print(error)
                return
            }
            keyFileContent = data
            let buttonRow = form.rowBy(tag: "keyFile") as! ButtonRow
            buttonRow.title = NSLocalizedString("File: ", comment: "") + url.lastPathComponent
            buttonRow.cell.tintColor = UIColor.systemRed
            buttonRow.updateCell()
        }
    }
}
