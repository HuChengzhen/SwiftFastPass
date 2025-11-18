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

protocol NewDatabaseDelegate: class {
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
                    let file = File(name: fileName, bookmark: bookmark)
                    file.attach(password: password, keyFileContent: self.keyFileContent)
                    file.image = document.tree?.root?.image()
                    self.delegate?.newDatabase(viewController: self, didNewDatabase: file)
                    self.dismiss(animated: true, completion: nil)
                    return
                } catch {
                    print("NewDatabaseViewController.addButtonTapped error: \(error)")
                }
            }
            sender.isEnabled = true
        }
    }
}
