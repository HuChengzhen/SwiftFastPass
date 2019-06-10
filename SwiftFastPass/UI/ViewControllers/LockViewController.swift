//
//  LockViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/7.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import Eureka
import LocalAuthentication
import KeePassKit

class LockViewController: FormViewController {

    var file: File!
    
    var keyFileContent: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        openDatabaseIfHasPassword()
    }
    
    private func openDatabaseIfHasPassword() {
        if file.password != nil || file.keyFileContent != nil {
            let context = LAContext()
            var error: NSError? = nil
            let success = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            guard error == nil else {
                print("LockViewController.openDatabaseIfHasPassword error: \(error!)")
                return
            }
            
            if success {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("Verify identity to open password database", comment: "")) { (success, error) in
                    if error != nil {
                        print("LockViewController.openDatabaseIfHasPassword error: \(error!)")
                        return
                    }
                    if success {
                        self.openDatabase(password: self.file.password, keyFileContent: self.file.keyFileContent, updateFile: false)
                    }
                }
            }
        }
    }
    
    func openDatabase(password: String?, keyFileContent: Data?, updateFile: Bool) {
        var isStale: Bool = false
        let url: URL
        do {
            url = try URL(resolvingBookmarkData: self.file.bookmark, bookmarkDataIsStale: &isStale)
        } catch {
            print("LockViewController.openDatabaseIfHasPassword error: \(error)")
            return
        }
        if isStale {
            do {
                self.file.updateBookmark(try url.bookmarkData(options: .suitableForBookmarkFile))
            } catch {
                print("LockViewController.openDatabaseIfHasPassword error: \(error)")
            }
        }
        
        let document = Document(fileURL: url)
        document.key = KPKCompositeKey(password: password, keyFileData: keyFileContent)
        document.open { (success) in
            if success {
                if updateFile {
                    self.file.attach(password: password, keyFileContent: keyFileContent)
                    self.file.image = document.tree?.root?.image()
                }
                DispatchQueue.main.async {
                    let databaseViewController = DatabaseViewController()
                    databaseViewController.document = document
                    databaseViewController.group = document.tree?.root
                    self.navigationController?.pushViewController(databaseViewController, animated: true)
                    let index = self.navigationController!.viewControllers.firstIndex(of: self)!
                    self.navigationController?.viewControllers.remove(at: index)
                }
            } else {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: NSLocalizedString("Password or key file is not correct", comment: ""), message: NSLocalizedString("Please check password and key file", comment: ""), preferredStyle: .alert)
                    let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
                    alertController.addAction(cancel)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
        
    private func setupUI() {
        navigationItem.title = file.name
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Open", comment: ""), style: .done, target: self, action: #selector(openButtonTapped(sender:)))
        form +++ Section()
            <<< PasswordRow("password") { row in
                row.title = NSLocalizedString("Password", comment: "")
                row.placeholder = NSLocalizedString("Enter password here", comment: "")
            }
            +++ Section()
            <<< ButtonRow("keyFile") { row in
                row.title = NSLocalizedString("Select Key File", comment: "")
                }.onCellSelection(self.keyFileButtonTapped)
    }
    
    @objc func openButtonTapped(sender: Any) {
        let password = (form.rowBy(tag: "password") as! PasswordRow).value
        openDatabase(password: password, keyFileContent: keyFileContent, updateFile: true)
    }
    
    func keyFileButtonTapped(cell: ButtonCellOf<String>, row: ButtonRow) {
        if keyFileContent == nil {
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
            documentPicker.delegate = self
            self.present(documentPicker, animated: true, completion: nil)
        } else {
            keyFileContent = nil
            let buttonRow = form.rowBy(tag: "keyFile") as! ButtonRow
            buttonRow.title = NSLocalizedString("Select Key File", comment: "")
//            cell.tintColor = UIColor.systemBlue
            cell.tintColor = UIColor.blue
            buttonRow.updateCell()
        }
    }
}

extension LockViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                print(error)
                return
            }
            self.keyFileContent = data
            let buttonRow = form.rowBy(tag: "keyFile") as! ButtonRow
            buttonRow.title = NSLocalizedString("File: ", comment: "") + url.lastPathComponent
//            buttonRow.cell.tintColor = UIColor.systemRed
            buttonRow.cell.tintColor = UIColor.red
            buttonRow.updateCell()
        }
    }
}
