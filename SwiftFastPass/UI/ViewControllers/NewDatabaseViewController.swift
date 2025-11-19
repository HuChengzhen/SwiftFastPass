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
    private enum FormTag {
        static let securityLevel = "security_level_row"
        static let securityDescription = "security_level_detail_row"
    }
    private var selectedSecurityLevel: File.SecurityLevel = .balanced

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
            }.cellSetup { cell, _ in
                cell.textField.disablePasswordAutoFill()
            }.cellUpdate { cell, _ in
                cell.textField.disablePasswordAutoFill()
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
                        return ValidationError(msg: NSLocalizedString("Passwords are different.", comment: ""))
                    }
                    return nil
                }))
                row.validationOptions = .validatesOnChange
            }.cellSetup { cell, _ in
                cell.textField.disablePasswordAutoFill()
            }.cellUpdate { cell, _ in
                cell.textField.disablePasswordAutoFill()
            }.onChange { _ in
                self.validateInputUpdateAddButtonState()
            }
            +++ Section()
            <<< ButtonRow("keyFile") { row in
                row.title = NSLocalizedString("New Key File", comment: "")

            }.onCellSelection(keyFileButtonTapped)
            +++ Section(NSLocalizedString("Security Level", comment: ""))
            <<< SegmentedRow<File.SecurityLevel>(FormTag.securityLevel) { [weak self] row in
                row.title = NSLocalizedString("Protection", comment: "")
                row.options = File.SecurityLevel.allCases
                row.value = self?.selectedSecurityLevel ?? .balanced
                row.displayValueFor = { $0?.localizedTitle }
            }.onChange { [weak self] row in
                guard let level = row.value else { return }
                self?.handleSecurityLevelSelection(level)
            }
            <<< TextAreaRow(FormTag.securityDescription) { [weak self] row in
                row.disabled = true
                row.textAreaHeight = .fixed(cellHeight: 120)
                row.value = self?.selectedSecurityLevel.localizedDescription
            }.cellUpdate { cell, _ in
                cell.textView.backgroundColor = .clear
                if #available(iOS 13.0, *) {
                    cell.textView.textColor = .secondaryLabel
                } else {
                    cell.textView.textColor = .darkGray
                }
            }
        updateSecurityDetailRow(for: selectedSecurityLevel)
    }

    private func handleSecurityLevelSelection(_ level: File.SecurityLevel) {
        guard level != selectedSecurityLevel else {
            return
        }
        if level.usesBiometrics {
            requestBiometricAuthorization(for: level)
        } else {
            applySecurityLevel(level)
        }
    }

    private func applySecurityLevel(_ level: File.SecurityLevel) {
        selectedSecurityLevel = level
        updateSecurityDetailRow(for: level)
    }

    private func revertSecurityLevelSelection() {
        if let row: SegmentedRow<File.SecurityLevel> = form.rowBy(tag: FormTag.securityLevel) {
            row.value = selectedSecurityLevel
            row.updateCell()
        }
        updateSecurityDetailRow(for: selectedSecurityLevel)
    }

    private func updateSecurityDetailRow(for level: File.SecurityLevel) {
        if let row: TextAreaRow = form.rowBy(tag: FormTag.securityDescription) {
            row.value = level.localizedDescription
            row.updateCell()
        }
    }

    private func requestBiometricAuthorization(for level: File.SecurityLevel) {
        biometrics(onSuccess: { [weak self] in
            self?.applySecurityLevel(level)
        }, onFailure: { [weak self] error in
            self?.presentBiometricFailureAlert(error: error)
            self?.revertSecurityLevelSelection()
        })
    }

    private func presentBiometricFailureAlert(error: Error?) {
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
        present(alert, animated: true, completion: nil)
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
                    let securityRow: SegmentedRow<File.SecurityLevel>? = self.form.rowBy(tag: FormTag.securityLevel)
                    let securityLevel = securityRow?.value ?? self.selectedSecurityLevel
                    let file = File(name: fileName,
                                    bookmark: bookmark,
                                    requiresKeyFileContent: self.keyFileContent != nil,
                                    securityLevel: securityLevel)
                    let shouldCacheCredentials = securityLevel.cachesCredentials
                    let storedPassword = shouldCacheCredentials ? password : nil
                    let storedKeyFileContent = shouldCacheCredentials ? self.keyFileContent : nil
                    file.attach(password: storedPassword,
                                keyFileContent: storedKeyFileContent,
                                requiresKeyFileContent: self.keyFileContent != nil,
                                securityLevel: securityLevel)
                    file.image = document.tree?.root?.image()

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

private extension File.SecurityLevel {
    var localizedTitle: String {
        switch self {
        case .paranoid:
            return NSLocalizedString("Lockdown", comment: "Security level option")
        case .balanced:
            return NSLocalizedString("Balanced", comment: "Security level option")
        case .convenience:
            return NSLocalizedString("Quick Unlock", comment: "Security level option")
        }
    }

    var localizedDescription: String {
        switch self {
        case .paranoid:
            return NSLocalizedString("Every unlock requires the master password plus the key file. Nothing is cached and biometrics stay off.", comment: "Security level description")
        case .balanced:
            return NSLocalizedString("Enter the master password after a reboot or long break, but Face ID / Touch ID can reopen the vault for a short period. The key file selection is stored only on this device and is not uploaded or synced.", comment: "Security level description")
        case .convenience:
            return NSLocalizedString("Store a derived master key inside iOS Keychain so biometrics always unlock this database. If someone can unlock your device, they can open the vault too.", comment: "Security level description")
        }
    }
}
