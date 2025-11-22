//
//  DatabaseViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/7.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import KeePassKit
import SnapKit
import UIKit

class DatabaseViewController: UIViewController {
    var document: Document!
    var group: KPKGroup!

    private var tableView: UITableView!

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

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = group.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped(sender:))
        )

        // 统一用 insetGrouped 风格，和系统“设置”/你订阅页列表一致
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 64, bottom: 0, right: 16)
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = 56
        tableView.tableFooterView = UIView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.register(NodeTableViewCell.self, forCellReuseIdentifier: "NodeTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self

        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleTableLongPress(_:))
        )
        tableView.addGestureRecognizer(longPressGesture)
    }

    // MARK: - Actions

    @objc private func handleTableLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let location = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location),
              indexPath.section == 0,
              let cell = tableView.cellForRow(at: indexPath)
        else {
            return
        }

        let selectedGroup = group.groups[indexPath.row]
        let alertController = UIAlertController(
            title: selectedGroup.title,
            message: nil,
            preferredStyle: .actionSheet
        )
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }
        let editAction = UIAlertAction(
            title: NSLocalizedString("Edit Group", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.presentGroupEditor(for: selectedGroup)
        }
        alertController.addAction(editAction)
        let cancel = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel,
            handler: nil
        )
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }

    private func presentGroupEditor(for group: KPKGroup) {
        let viewController = AddGroupViewController()
        viewController.delegate = self
        viewController.configure(with: group)
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc func addButtonTapped(sender _: Any) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Please select the content to create", comment: ""),
            message: nil,
            preferredStyle: .actionSheet
        )
        alertController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem

        let groupAction = UIAlertAction(
            title: NSLocalizedString("Add Group", comment: ""),
            style: .default
        ) { _ in
            let addGroupViewController = AddGroupViewController()
            addGroupViewController.delegate = self
            self.navigationController?.pushViewController(addGroupViewController, animated: true)
        }
        alertController.addAction(groupAction)

        let itemAction = UIAlertAction(
            title: NSLocalizedString("Add Item", comment: ""),
            style: .default
        ) { _ in
            let entryViewController = EntryViewController()
            entryViewController.attach(delegate: self)
            self.navigationController?.pushViewController(entryViewController, animated: true)
        }
        alertController.addAction(itemAction)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel,
            handler: nil
        )
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension DatabaseViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return NSLocalizedString("Group", comment: "")
        case 1: return NSLocalizedString("Item", comment: "")
        default: fatalError()
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return group.groups.count
        case 1: return group.entries.count
        default: fatalError()
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NodeTableViewCell",
            for: indexPath
        ) as! NodeTableViewCell

        let node: KPKNode
        switch indexPath.section {
        case 0:
            node = group.groups[indexPath.row]
        case 1:
            node = group.entries[indexPath.row]
        default:
            fatalError()
        }

        cell.configure(with: node)
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let databaseViewController = DatabaseViewController()
            databaseViewController.document = document
            databaseViewController.group = group.groups[indexPath.row]
            navigationController?.pushViewController(databaseViewController, animated: true)
        case 1:
            let entryViewController = EntryViewController()
            entryViewController.configure(with: group.entries[indexPath.row])
            entryViewController.attach(delegate: self)
            navigationController?.pushViewController(entryViewController, animated: true)
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration?
    {
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: NSLocalizedString("Delete", comment: "")
        ) { _, button, successHandler in
            let alertController = UIAlertController(
                title: NSLocalizedString("Do you want to delete this entry?", comment: ""),
                message: nil,
                preferredStyle: .actionSheet
            )
            alertController.popoverPresentationController?.sourceRect = button.bounds
            alertController.popoverPresentationController?.sourceView = button

            let deleteAction = UIAlertAction(
                title: NSLocalizedString("Delete", comment: ""),
                style: .destructive
            ) { _ in
                var autoFillUUIDs: [String] = []
                switch indexPath.section {
                case 0:
                    let targetGroup = self.group.groups[indexPath.row]
                    autoFillUUIDs = self.entryUUIDs(in: targetGroup)
                    targetGroup.remove()
                case 1:
                    let entry = self.group.entries[indexPath.row]
                    autoFillUUIDs = [entry.uuid.uuidString]
                    entry.remove()
                default:
                    fatalError()
                }
                self.document.save(to: self.document.fileURL, for: .forOverwriting) { success in
                    if success {
                        autoFillUUIDs.forEach {
                            AutoFillCredentialStore.shared.removeCredential(withUUID: $0)
                        }
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        successHandler(true)
                    }
                }
            }
            alertController.addAction(deleteAction)

            let cancel = UIAlertAction(
                title: "Cancel",
                style: .cancel
            ) { _ in
                successHandler(false)
            }
            alertController.addAction(cancel)

            self.present(alertController, animated: true, completion: nil)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Entry / Group Delegates

extension DatabaseViewController: EntryViewControllerDelegate {
    func entryViewController(_: EntryViewController, didNewEntry entry: KPKEntry) {
        entry.add(to: group)
        saveDocument {
            AutoFillCredentialStore.shared.upsertEntryIfPossible(entry)
        }
    }

    func entryViewController(_: EntryViewController, didEditEntry entry: KPKEntry) {
        saveDocument {
            AutoFillCredentialStore.shared.upsertEntryIfPossible(entry)
        }
    }

    fileprivate func saveDocument(onSuccess: (() -> Void)? = nil) {
        document.save(to: document.fileURL, for: .forOverwriting) { success in
            DispatchQueue.main.async {
                if success {
                    self.tableView.reloadData()
                    onSuccess?()
                } else {
                    let alertController = UIAlertController(
                        title: NSLocalizedString("Save Failed", comment: ""),
                        message: nil,
                        preferredStyle: .alert
                    )
                    let cancel = UIAlertAction(
                        title: NSLocalizedString("Cancel", comment: ""),
                        style: .cancel,
                        handler: nil
                    )
                    alertController.addAction(cancel)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }

    private func entryUUIDs(in group: KPKGroup) -> [String] {
        var identifiers = group.entries.map { $0.uuid.uuidString }
        for child in group.groups {
            identifiers.append(contentsOf: entryUUIDs(in: child))
        }
        return identifiers
    }
}

extension DatabaseViewController: AddGroupDelegate {
    func addGroup(_: AddGroupViewController, didAddGroup group: KPKGroup) {
        group.add(to: self.group)
        saveDocument()
    }

    func addGroup(_: AddGroupViewController, didEditGroup _: KPKGroup) {
        saveDocument()
    }
}
