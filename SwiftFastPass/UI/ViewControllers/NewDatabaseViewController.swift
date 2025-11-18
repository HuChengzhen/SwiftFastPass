//
//  NewDatabaseViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import Eureka
import KeePassKit
import UIKit

protocol NewDatabaseDelegate: AnyObject {
    func newDatabase(viewController: NewDatabaseViewController, didNewDatabase file: File)
}

class NewDatabaseViewController: FormViewController {
    var keyFileContent: Data?
    weak var delegate: NewDatabaseDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("New Database", comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(sender:)))
        navigationItem.rightBarButtonItem?.isEnabled = false

        form +++ Section()
            <<< TextRow("name") { row in
                row.title = NSLocalizedString("Name", comment: "")
                row.placeholder = NSLocalizedString("Enter name here", comment: "")
                row.add(rule: RuleRequired())
                row.validationOptions = .validatesOnChange
            }.onChange { _ in
                self.validateInputUpdateAddButtonState()
            }
            +++ Section()
            <<< PasswordRow("password") { row in
                row.title = NSLocalizedString("Password", comment: "")
                row.placeholder = NSLocalizedString("Enter password here", comment: "")
                row.add(rule: RuleRequired())
                row.validationOptions = .validatesOnChange
            }.onChange { _ in
                self.validateInputUpdateAddButtonState()
            }
            <<< PasswordRow("confirmPassword") { row in
                row.title = NSLocalizedString("Confirm password", comment: "")
                row.placeholder = NSLocalizedString("Confirm password here", comment: "")
                row.add(rule: RuleRequired())
                row.add(rule: RuleClosure(closure: { value -> ValidationError? in
                    let passwordRow: PasswordRow? = self.form.rowBy(tag: "password")
                    if passwordRow?.value != value {
                        return ValidationError(msg: "Passwords are diffrent.")
                    }
                    return nil
                }))
                row.validationOptions = .validatesOnChange
            }.onChange { _ in
                self.validateInputUpdateAddButtonState()
            }
            +++ Section()
            <<< ButtonRow("keyFile") { row in
                row.title = NSLocalizedString("New Key File", comment: "")

            }.onCellSelection(keyFileButtonTapped)
            <<< SwitchRow("rememberCredentials_switch") { row in
                row.title = NSLocalizedString("Remember password & key file", comment: "")
                row.value = true
                row.cellStyle = .subtitle
            }.cellUpdate { cell, _ in
                cell.detailTextLabel?.text = NSLocalizedString("Disable to enter them manually every time.", comment: "")
            }.onChange { [weak self] row in
                let remember = row.value ?? true
                self?.updateBiometricAvailability(rememberCredentials: remember)
            }
            <<< LabelRow("useBiometrics_title") { row in
                row.title = "使用生物识别自动解锁"
                row.cell.imageView?.image = UIImage(systemName: "faceid")
            }
            <<< SwitchRow("useBiometrics_switch") { row in
                row.value = false
                row.cellStyle = .subtitle
            }.cellUpdate { [weak self] cell, _ in
                let rememberRow: SwitchRow? = self?.form.rowBy(tag: "rememberCredentials_switch")
                let rememberCredentials = rememberRow?.value ?? true
                if rememberCredentials {
                    cell.detailTextLabel?.text = "使用 Face ID / Touch ID 快速解锁密码库"
                } else {
                    cell.detailTextLabel?.text = NSLocalizedString("Biometrics require saved credentials.", comment: "")
                }
                cell.isUserInteractionEnabled = rememberCredentials
                cell.textLabel?.isEnabled = rememberCredentials
                cell.detailTextLabel?.isEnabled = rememberCredentials
            }.onChange { [weak self] row in
                if row.value == true {
                    self?.requestBiometricAuthorization()
                } else {
                    self?.disableBiometricUnlock()
                }
            }
        updateBiometricAvailability(rememberCredentials: true)
    }

    func requestBiometricAuthorization() {
        biometrics(onSuccess: { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // 确保开关是打开状态
                if let row: SwitchRow = self.form.rowBy(tag: "useBiometrics_switch") {
                    row.value = true
                    row.updateCell()
                }
            }
        }, onFailure: { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // 认证失败或取消 → 关掉开关
                if let row: SwitchRow = self.form.rowBy(tag: "useBiometrics_switch") {
                    row.value = false
                    row.updateCell()
                }

                // 可选：给个提示
                let title = NSLocalizedString("Unable to enable biometric unlock", comment: "")
                let message: String
                if let error = error {
                    message = error.localizedDescription
                } else {
                    message = NSLocalizedString("Biometric authentication failed. You can enable it later in database settings.", comment: "")
                }

                let alert = UIAlertController(title: title,
                                              message: message,
                                              preferredStyle: .alert)
                let ok = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
        })
    }

    func disableBiometricUnlock() {
        if let row: SwitchRow = form.rowBy(tag: "useBiometrics_switch") {
            row.value = false
            row.updateCell()
        }
        // 如果将来你有全局设置或临时状态，也可以在这里顺便清理
    }

    private func updateBiometricAvailability(rememberCredentials: Bool) {
        if !rememberCredentials {
            disableBiometricUnlock()
        }
        if let biometricsRow: SwitchRow = form.rowBy(tag: "useBiometrics_switch") {
            biometricsRow.updateCell()
        }
    }

    func keyFileButtonTapped(cell: ButtonCellOf<String>, row: ButtonRow) {
        if keyFileContent != nil {
            keyFileContent = nil
            row.title = NSLocalizedString("New Key File", comment: "")
            row.updateCell()
            cell.tintColor = UIColor.systemBlue
        } else {
            keyFileContent = NSData.kpk_generateKeyfileData(of: .xmlVersion2)
            row.title = NSLocalizedString("Remove Key File", comment: "")
            row.updateCell()
            cell.tintColor = UIColor.systemRed
        }
    }

    func validateInputUpdateAddButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = form.validate().isEmpty
    }

    @objc func cancelButtonTapped(sender _: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc func doneButtonTapped(sender: UIButton) {
        sender.isEnabled = false
        view.endEditing(true)

        let tree = KPKTree(templateContents: ())
        let targetDirURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)!.appendingPathComponent("Documents")
        let name = (form.rowBy(tag: "name") as! TextRow).value!
        let fileName = name + ".kdbx"
        let fileURL = targetDirURL.appendingPathComponent(fileName)
        let password = (form.rowBy(tag: "password") as! PasswordRow).value!

        guard !FileManager.default.fileExists(atPath: fileURL.path) else {
            let alertController = UIAlertController(title: NSLocalizedString("The file with the same name already exists in the folder", comment: ""), message: NSLocalizedString("Please use a different file name", comment: ""), preferredStyle: .alert)
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            alertController.addAction(cancel)
            present(alertController, animated: true, completion: nil)
            sender.isEnabled = true
            return
        }

        if keyFileContent != nil {
            let keyFileName = name + ".key"
            let keyFileURL = targetDirURL.appendingPathComponent(keyFileName)
            do {
                try keyFileContent!.write(to: keyFileURL, options: .atomic)
            } catch {
                print("NewDatabaseViewController.addButtonTapped error: \(error)")
                sender.isEnabled = true
                return
            }
        }

        let document = Document(fileURL: fileURL)
        document.tree = tree
        let key = KPKCompositeKey()

        // 添加密码（如果有）
        if let passwordKey = KPKPasswordKey(password: password) {
            key.add(passwordKey)
        }

        // 添加 keyfile（如果有）
        if let keyFileContent = keyFileContent, let fileKey = try? KPKFileKey(keyFileData: keyFileContent) {
            key.add(fileKey)
        }
        document.key = key
        document.save(to: document.fileURL, for: .forCreating) { success in
            if success {
                do {
                    let bookmark = try document.fileURL.bookmarkData(options: .suitableForBookmarkFile)
                    let rememberCredentialsRow: SwitchRow? = self.form.rowBy(tag: "rememberCredentials_switch")
                    let rememberCredentials = rememberCredentialsRow?.value ?? true

                    let file = File(name: fileName, bookmark: bookmark, requiresKeyFileContent: self.keyFileContent != nil)
                    let storedPassword = rememberCredentials ? password : nil
                    let storedKeyFileContent = rememberCredentials ? self.keyFileContent : nil
                    file.attach(password: storedPassword,
                                keyFileContent: storedKeyFileContent,
                                requiresKeyFileContent: self.keyFileContent != nil)
                    file.image = document.tree?.root?.image()

                    let useBiometricsRow: SwitchRow? = self.form.rowBy(tag: "useBiometrics_switch")
                    if rememberCredentials {
                        file.allowBiometricUnlock = useBiometricsRow?.value ?? false
                    } else {
                        file.allowBiometricUnlock = false
                    }

                    self.delegate?.newDatabase(viewController: self, didNewDatabase: file)
                    return
                } catch {
                    print("NewDatabaseViewController.addButtonTapped error: \(error)")
                }
            }
            sender.isEnabled = true
        }
    }
}
