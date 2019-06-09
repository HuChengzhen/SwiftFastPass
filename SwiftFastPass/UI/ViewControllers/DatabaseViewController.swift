//
//  DatabaseViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/7.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import KeePassKit
import SnapKit

class DatabaseViewController: UIViewController {

    var document: Document!
    var group: KPKGroup!
    
    var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func setupUI() {
        navigationItem.title = group.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped(sender:)))
        
        tableView = UITableView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.estimatedRowHeight = 60
        tableView.register(NodeTableViewCell.self, forCellReuseIdentifier: "NodeTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    @objc func addButtonTapped(sender: Any) {
        let alertController = UIAlertController(title: NSLocalizedString("Please select the content to create", comment: ""), message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        let groupAction = UIAlertAction(title: NSLocalizedString("Add Group", comment: ""), style: .default) { (action) in
            let addGroupViewController = AddGroupViewController()
            addGroupViewController.delegate = self
            self.navigationController?.pushViewController(addGroupViewController, animated: true)
        }
        alertController.addAction(groupAction)
        
        let itemAction = UIAlertAction(title: NSLocalizedString("Add Item", comment: ""), style: .default) { (action) in
            let entryViewController = EntryViewController()
            entryViewController.delegate = self
            self.navigationController?.pushViewController(entryViewController, animated: true)
        }
        alertController.addAction(itemAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

extension DatabaseViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("Group", comment: "")
        case 1:
            return NSLocalizedString("Item", comment: "")
        default:
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return group.groups.count
        case 1:
            return group.entries.count
        default:
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NodeTableViewCell", for: indexPath) as! NodeTableViewCell
        
        switch indexPath.section {
        case 0:
            let group = self.group.groups[indexPath.row]
            cell.iconImageView.image = group.image()
            cell.nameLabel.text = group.title
        case 1:
            let entry = group.entries[indexPath.row]
            cell.iconImageView.image = entry.image()
            cell.nameLabel.text = entry.title
        default:
            fatalError()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let databaseViewController = DatabaseViewController()
            databaseViewController.document = document
            databaseViewController.group = group.groups[indexPath.row]
            navigationController?.pushViewController(databaseViewController, animated: true)
        case 1:
            let entryViewController = EntryViewController()
            entryViewController.entry = group.entries[indexPath.row]
            entryViewController.delegate = self
            navigationController?.pushViewController(entryViewController, animated: true)
        default:
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (action, button, successHandler) in
            let alertController = UIAlertController(title: NSLocalizedString("Do you want to delete this entry?", comment: ""), message: nil, preferredStyle: .actionSheet)
            alertController.popoverPresentationController?.sourceRect = button.bounds
            alertController.popoverPresentationController?.sourceView = button
            let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { (action) in
                switch indexPath.section {
                case 0:
                    self.group.groups[indexPath.row].remove()
                case 1:
                    self.group.entries[indexPath.row].remove()
                default:
                    fatalError()
                }
                self.document.save(to: self.document.fileURL, for: .forOverwriting) { (success) in
                    if success {
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        successHandler(true)
                    }
                }
            }
            alertController.addAction(deleteAction)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                successHandler(false)
            }
            alertController.addAction(cancel)
            
            self.present(alertController, animated: true, completion: nil)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
}

extension DatabaseViewController: EntryViewControllerDelegate {
    func entryViewController(_ controller: EntryViewController, didNewEntry entry: KPKEntry) {
        entry.add(to: self.group)
        document.save(to: document.fileURL, for: .forOverwriting) { (success) in
            if success {
                self.tableView.reloadData()
            } else {
                let alertController = UIAlertController(title: NSLocalizedString("Save Failed", comment: ""), message: nil, preferredStyle: .alert)
                let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
                alertController.addAction(cancel)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func saveDocument() {
        document.save(to: document.fileURL, for: .forOverwriting) { (success) in
            if success {
                self.tableView.reloadData()
            } else {
                let alertController = UIAlertController(title: NSLocalizedString("Save Failed", comment: ""), message: nil, preferredStyle: .alert)
                let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
                alertController.addAction(cancel)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func entryViewController(_ controller: EntryViewController, didEditEntry entry: KPKEntry) {
        saveDocument()
    }
}

extension DatabaseViewController: AddGroupDelegate {
    func addGroup(_ controller: AddGroupViewController, didAddGroup group: KPKGroup) {
        group.add(to: self.group)
        saveDocument()
    }
}
