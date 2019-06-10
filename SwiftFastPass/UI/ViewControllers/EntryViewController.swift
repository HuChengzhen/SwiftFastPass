//
//  EntryViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import Eureka
import KeePassKit
import MobileCoreServices
import MenuItemKit

enum EntryViewControllerMode {
    case new
    case display
}

protocol EntryViewControllerDelegate: class {
    func entryViewController(_ controller: EntryViewController, didNewEntry entry: KPKEntry)
    
    func entryViewController(_ controller: EntryViewController, didEditEntry entry: KPKEntry)
}

class EntryViewController: FormViewController {
    
    var entry: KPKEntry?
    var isDisabled = true
    weak var delegate: EntryViewControllerDelegate?
    var iconId: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        if entry != nil {
            navigationItem.title = entry!.title
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped(sender:)))
        } else {
            navigationItem.title = NSLocalizedString("New Item", comment: "")
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(sender:)))
        }
        
        form +++ Section()
            <<< ImageRow("icon") { row in
                row.title = NSLocalizedString("Icon", comment: "")
                row.sourceTypes = []
                row.value = entry?.image() ?? UIImage(named: "00_PasswordTemplate")
                
                }
                .cellSetup({ (cell, row) in
                    if #available(iOS 13.0, *) {
//                        cell.accessoryView?.tintColor = UIColor.label
                    } else {
                        cell.accessoryView?.tintColor = UIColor.black
                    }
                })
                .onCellSelection(self.imageRowSelected)
            
            <<< TextRow("title") { row in
                row.title = NSLocalizedString("Title", comment: "")
                row.value = entry?.title
            }
            
            +++ Section()
            <<< TextRow("userName") { row in
                row.title = NSLocalizedString("User Name", comment: "")
                row.value = entry?.username
            }.onCellSelection(self.userNameRowSelected(cell:row:))
            
            +++ Section()
            <<< PasswordRow("password") { row in
                row.title = NSLocalizedString("Password", comment: "")
                row.value = entry?.password
                }.onCellSelection(self.passwordRowSelected(cell:row:))
            
            <<< ButtonRow("generatePassword") { row in
                row.title = NSLocalizedString("Generate Password", comment: "")
                if entry != nil {
                    row.hidden = Condition(booleanLiteral: true)
                }
        }.onCellSelection(self.generatePasswordButtonTapped(cell:row:))
        
        if entry != nil {
            form.allRows.forEach { (row) in
                row.disabled = Condition(booleanLiteral: true)
                row.evaluateDisabled()
            }
        }
    }
    
    @objc func editButtonTapped(sender: Any) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(sender:)))
        form.allRows.forEach { (row) in
            row.disabled = Condition(booleanLiteral: false)
            row.evaluateDisabled()
        }
        let generatePasswordRow = form.rowBy(tag: "generatePassword") as! ButtonRow
        generatePasswordRow.hidden = Condition(booleanLiteral: false)
        generatePasswordRow.evaluateHidden()
    }
    
    @objc func doneButtonTapped(sender: Any) {
        let alertController = UIAlertController(title: NSLocalizedString("Are you sure you want to modify the database?", comment: ""), message: NSLocalizedString("This modification cannot be restored", comment: ""), preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: NSLocalizedString("Confirm", comment: ""), style: .destructive) { (action) in
            let title = (self.form.rowBy(tag: "title") as! TextRow).value
            let userName = (self.form.rowBy(tag: "userName") as! TextRow).value
            let password = (self.form.rowBy(tag: "password") as! PasswordRow).value
            
            if let entry = self.entry {
                entry.title = title
                entry.username = userName
                entry.password = password
                if let iconId = self.iconId {
                    entry.iconId = iconId
                }
                self.delegate?.entryViewController(self, didEditEntry: entry)
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.editButtonTapped(sender:)))
                self.form.allRows.forEach { (row) in
                    row.disabled = Condition(booleanLiteral: true)
                    row.evaluateDisabled()
                }
                let generatePasswordRow = self.form.rowBy(tag: "generatePassword") as! ButtonRow
                generatePasswordRow.hidden = Condition(booleanLiteral: true)
                generatePasswordRow.evaluateHidden()
            } else {
                let entry = KPKEntry()
                entry.title = title
                entry.username = userName
                entry.password = password
                if let iconId = self.iconId {
                    entry.iconId = iconId
                }
                self.delegate?.entryViewController(self, didNewEntry: entry)
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(confirmAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func imageRowSelected(cell: ImageCell, row: ImageRow) {
        if !row.isDisabled {
            let selectIconViewController =  SelectIconViewController()
            selectIconViewController.didSelectAction = { (viewController, iconId) in
                self.iconId = iconId
                row.value = UIImage(named: Icons.iconNames[iconId])
                row.updateCell()
            }
            
            self.navigationController?.pushViewController(selectIconViewController, animated: true)
        }
    }
    
    func passwordRowSelected(cell: PasswordCell, row: PasswordRow) {
        if row.isDisabled, row.value != nil, !row.value!.isEmpty{
            let copy = UIMenuItem(title: NSLocalizedString("Copy", comment: "")) { (item) in
                UIPasteboard.general.setItems([[kUTTypeUTF8PlainText as String: row.value!]], options: [.expirationDate: Date(timeInterval: 30, since: Date())])
            }
            let showLarge = UIMenuItem(title: NSLocalizedString("Display", comment: "")) { (item) in
                let showPasswordViewController = ShowPasswordViewController()
                showPasswordViewController.password = row.value!
                self.present(showPasswordViewController, animated: true, completion: nil)
            }
            UIMenuController.shared.menuItems = [copy, showLarge]
            UIMenuController.shared.setTargetRect(cell.bounds, in: cell)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }
    
    func userNameRowSelected(cell: TextCell, row: TextRow) {
        if row.isDisabled, row.value != nil, !row.value!.isEmpty{
            let copy = UIMenuItem(title: NSLocalizedString("Copy", comment: "")) { (item) in
                UIPasteboard.general.setItems([[kUTTypeUTF8PlainText as String: row.value!]], options: [.expirationDate: Date(timeInterval: 30, since: Date())])
            }
            let showLarge = UIMenuItem(title: NSLocalizedString("Display", comment: "")) { (item) in
                let showPasswordViewController = ShowPasswordViewController()
                showPasswordViewController.password = row.value!
                self.present(showPasswordViewController, animated: true, completion: nil)
            }
            UIMenuController.shared.menuItems = [copy, showLarge]
            UIMenuController.shared.setTargetRect(cell.bounds, in: cell)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }
    
    func generatePasswordButtonTapped(cell: ButtonCell, row: ButtonRow) {
        let viewController = PasswordGenerateViewController()
        viewController.delegate = self
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension EntryViewController: PasswordGenerateDelegat {
    func passwordGenerate(_ viewController: PasswordGenerateViewController, didGenerate password: String) {
        let row = form.rowBy(tag: "password") as! PasswordRow
        row.value = password
        row.updateCell()
    }
}
