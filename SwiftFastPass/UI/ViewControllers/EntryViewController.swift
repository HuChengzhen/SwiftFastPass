//
//  EntryViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import Eureka
import KeePassKit
import UIKit
import UniformTypeIdentifiers

protocol EntryViewControllerDelegate: AnyObject {
    func entryViewController(_ controller: EntryViewController, didNewEntry entry: KPKEntry)
    func entryViewController(_ controller: EntryViewController, didEditEntry entry: KPKEntry)
}

final class EntryViewController: FormViewController {
    enum RowTag: String {
        case icon
        case title
        case username
        case password
        case generatePassword
        case url
        case notes
    }

    private var entry: KPKEntry?
    private weak var delegate: EntryViewControllerDelegate?
    private var iconId: Int?
    private var isPasswordVisible = false

    private var sensitiveFieldMenuHandlers: [RowTag: SensitiveFieldMenuHandler] = [:]

    func configure(with entry: KPKEntry) {
        self.entry = entry
    }

    func attach(delegate: EntryViewControllerDelegate) {
        self.delegate = delegate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureForm()
        if entry != nil {
            disableFormEditing()
        }
    }

    private func configureNavigationBar() {
        if let entry = entry {
            navigationItem.title = entry.title
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
        } else {
            navigationItem.title = NSLocalizedString("New Item", comment: "")
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        }
    }

    private func configureForm() {
        // 通常习惯先重置一下 form（可选）
//        form = Form()

        // MARK: - Section 1: 图标 & 标题
        form
            +++ Section()
            <<< ImageRow(RowTag.icon.rawValue) { row in
                row.title = NSLocalizedString("Icon", comment: "")
                row.sourceTypes = []
                row.value = entry?.image() ?? UIImage(named: "00_PasswordTemplate")
            }
            .cellSetup { [weak self] cell, _ in
                self?.configureIconCell(cell)
            }
            .onCellSelection { [weak self] _, row in
                self?.imageRowSelected(row: row)
            }
            <<< TextRow(RowTag.title.rawValue) { row in
                row.title = NSLocalizedString("Title", comment: "")
                row.value = entry?.title
            }

            // MARK: - Section 2: 账号、URL、密码相关
            +++ Section()
            <<< TextRow(RowTag.username.rawValue) { row in
                row.title = NSLocalizedString("User Name", comment: "")
                row.value = entry?.username
            }
            .cellSetup { [weak self] cell, _ in
                self?.registerSensitiveFieldInteractions(for: cell, tag: .username)
            }
            <<< URLRow(RowTag.url.rawValue) { row in
                row.title = NSLocalizedString("URL", comment: "")

                // ⚠ 如果 entry?.url 是 String，这里要转成 URL
                if let urlString = entry?.url {
                    row.value = URL(string: urlString)
                } else {
                    row.value = nil
                }
            }
            <<< PasswordRow(RowTag.password.rawValue) { row in
                row.title = NSLocalizedString("Password", comment: "")
                row.value = entry?.password
            }
            .cellSetup { [weak self] cell, _ in
                self?.registerSensitiveFieldInteractions(for: cell, tag: .password)
                self?.configurePasswordCell(cell)
            }
            .cellUpdate { [weak self] cell, _ in
                self?.configurePasswordCell(cell)
            }
            <<< ButtonRow(RowTag.generatePassword.rawValue) { row in
                row.title = NSLocalizedString("Generate Password", comment: "")
                row.hidden = Condition(booleanLiteral: entry != nil)
            }
            .onCellSelection { [weak self] _, _ in
                self?.generatePasswordButtonTapped()
            }

            // MARK: - Section 3: 备注
            +++ Section(NSLocalizedString("Notes", comment: ""))
            <<< TextAreaRow(RowTag.notes.rawValue) { row in
                row.placeholder = NSLocalizedString("Notes", comment: "")
                row.value = entry?.notes
                row.textAreaHeight = .dynamic(initialTextViewHeight: 80)
            }
    }



    private func configureIconCell(_ cell: ImageCell) {
        cell.accessoryView?.tintColor = UIColor.label
    }

    private func configurePasswordCell(_ cell: PasswordCell) {
        cell.textField.isSecureTextEntry = !isPasswordVisible
        guard let row = cell.row as? PasswordRow else {
            cell.textField.rightView = nil
            cell.textField.rightViewMode = .never
            return
        }

        if row.isDisabled {
            cell.textField.rightView = nil
            cell.textField.rightViewMode = .never
            return
        }

        cell.textField.rightViewMode = .always

        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: isPasswordVisible ? "eye.slash" : "eye"), for: .normal)
        button.tintColor = .secondaryLabel
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        button.addTarget(self, action: #selector(passwordVisibilityButtonTapped), for: .touchUpInside)
        button.accessibilityLabel = isPasswordVisible ? NSLocalizedString("Hide Password", comment: "") : NSLocalizedString("Show Password", comment: "")
        cell.textField.rightView = button
    }

    @objc
    private func editButtonTapped() {
        enableFormEditing()
    }

    @objc
    private func doneButtonTapped() {
        let title = NSLocalizedString("Are you sure you want to modify the database?", comment: "")
        let message = NSLocalizedString("This modification cannot be restored", comment: "")
        let confirmTitle = NSLocalizedString("Confirm", comment: "")
        let cancelTitle = NSLocalizedString("Cancel", comment: "")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: confirmTitle, style: .destructive) { [weak self] _ in
            self?.persistChanges()
        })
        alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))
        present(alertController, animated: true)
    }

    @objc
    private func passwordVisibilityButtonTapped() {
        isPasswordVisible.toggle()
        refreshPasswordVisibility()
    }

    private func refreshPasswordVisibility() {
        guard let row = form.rowBy(tag: RowTag.password.rawValue) as? PasswordRow else {
            return
        }
        row.updateCell()
    }

    private func hidePasswordIfNeeded() {
        guard isPasswordVisible else {
            return
        }
        isPasswordVisible = false
        refreshPasswordVisibility()
    }

    private func persistChanges() {
        let titleRow = form.rowBy(tag: RowTag.title.rawValue) as? TextRow
        let usernameRow = form.rowBy(tag: RowTag.username.rawValue) as? TextRow
        let passwordRow = form.rowBy(tag: RowTag.password.rawValue) as? PasswordRow
        let urlRow = form.rowBy(tag: RowTag.url.rawValue) as? URLRow
        let notesRow = form.rowBy(tag: RowTag.notes.rawValue) as? TextAreaRow

        let title = titleRow?.value
        let username = usernameRow?.value
        let password = passwordRow?.value
        let url = urlRow?.value
        let notes = notesRow?.value

        if let entry = entry {
            entry.title = title
            entry.username = username
            entry.password = password
            entry.url = url?.absoluteString
            entry.notes = notes
            if let iconId = iconId {
                entry.iconId = iconId
            }
            delegate?.entryViewController(self, didEditEntry: entry)
            disableFormEditing()
        } else {
            let newEntry = KPKEntry()
            newEntry.title = title
            newEntry.username = username
            newEntry.password = password
            newEntry.url = url?.absoluteString
            newEntry.notes = notes
            if let iconId = iconId {
                newEntry.iconId = iconId
            }
            delegate?.entryViewController(self, didNewEntry: newEntry)
            navigationController?.popViewController(animated: true)
        }
    }

    private func enableFormEditing() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        for row in form.allRows {
            row.disabled = Condition(booleanLiteral: false)
            row.evaluateDisabled()
        }
        updateGeneratePasswordVisibility(isHidden: false)
    }

    private func disableFormEditing() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
        for row in form.allRows {
            row.disabled = Condition(booleanLiteral: true)
            row.evaluateDisabled()
        }
        updateGeneratePasswordVisibility(isHidden: true)
        hidePasswordIfNeeded()
    }

    private func updateGeneratePasswordVisibility(isHidden: Bool) {
        guard let row = form.rowBy(tag: RowTag.generatePassword.rawValue) as? ButtonRow else {
            return
        }
        row.hidden = Condition(booleanLiteral: isHidden)
        row.evaluateHidden()
    }

    private func imageRowSelected(row: ImageRow) {
        guard !row.isDisabled else { return }
        let selectIconViewController = SelectIconViewController()
        selectIconViewController.didSelectAction = { [weak self, weak row] _, iconId in
            self?.iconId = iconId
            row?.value = UIImage(named: Icons.iconNames[iconId])
            row?.updateCell()
        }
        navigationController?.pushViewController(selectIconViewController, animated: true)
    }

    private func generatePasswordButtonTapped() {
        let viewController = PasswordGenerateViewController()
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func registerSensitiveFieldInteractions(for cell: UITableViewCell, tag: RowTag) {
        removeSensitiveInteractions(from: cell)
        let handler = SensitiveFieldMenuHandler(controller: self, rowTag: tag)
        sensitiveFieldMenuHandlers[tag] = handler
        let contextMenuInteraction = UIContextMenuInteraction(delegate: handler)
        cell.addInteraction(contextMenuInteraction)
        if #available(iOS 16.0, *) {
            let editMenuInteraction = UIEditMenuInteraction(delegate: handler)
            cell.addInteraction(editMenuInteraction)
        }
    }

    private func removeSensitiveInteractions(from view: UIView) {
        for interaction in view.interactions where interaction is UIContextMenuInteraction {
            view.removeInteraction(interaction)
        }
        if #available(iOS 16.0, *) {
            for interaction in view.interactions where interaction is UIEditMenuInteraction {
                view.removeInteraction(interaction)
            }
        }
    }

    private func shouldAllowSensitiveMenu(for tag: RowTag) -> Bool {
        switch tag {
        case .username:
            guard let row = form.rowBy(tag: RowTag.username.rawValue) as? TextRow else { return false }
            return row.isDisabled && !(row.value?.isEmpty ?? true)
        case .password:
            guard let row = form.rowBy(tag: RowTag.password.rawValue) as? PasswordRow else { return false }
            return row.isDisabled && !(row.value?.isEmpty ?? true)
        default:
            return false
        }
    }

    private func sensitiveValue(for tag: RowTag) -> String? {
        switch tag {
        case .username:
            return (form.rowBy(tag: RowTag.username.rawValue) as? TextRow)?.value
        case .password:
            return (form.rowBy(tag: RowTag.password.rawValue) as? PasswordRow)?.value
        default:
            return nil
        }
    }

    private func copyToPasteboard(_ text: String) {
        let pasteboard = UIPasteboard.general
        pasteboard.setItems([[UTType.plainText.identifier: text]], options: [.expirationDate: Date().addingTimeInterval(30)])
    }

    private func presentPasswordDetail(with value: String) {
        let viewController = ShowPasswordViewController()
        viewController.password = value
        present(viewController, animated: true)
    }

    private func menuElements(for tag: RowTag) -> [UIMenuElement]? {
        guard shouldAllowSensitiveMenu(for: tag), let value = sensitiveValue(for: tag) else { return nil }
        let copyTitle = NSLocalizedString("Copy", comment: "")
        let displayTitle = NSLocalizedString("Display", comment: "")

        let copyAction = UIAction(title: copyTitle, image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
            self?.copyToPasteboard(value)
        }
        let displayAction = UIAction(title: displayTitle, image: UIImage(systemName: "eye")) { [weak self] _ in
            self?.presentPasswordDetail(with: value)
        }
        return [copyAction, displayAction]
    }
}

extension EntryViewController: PasswordGenerateDelegat {
    func passwordGenerate(_: PasswordGenerateViewController, didGenerate password: String) {
        guard let row = form.rowBy(tag: RowTag.password.rawValue) as? PasswordRow else {
            return
        }
        row.value = password
        row.updateCell()
    }
}

extension EntryViewController {
     final class SensitiveFieldMenuHandler: NSObject {
        weak var controller: EntryViewController?
         let rowTag: RowTag

         init(controller: EntryViewController, rowTag: RowTag) {
            self.controller = controller
            self.rowTag = rowTag
        }

        private func makeMenu() -> UIMenu? {
            guard let elements = controller?.menuElements(for: rowTag), !elements.isEmpty else {
                return nil
            }
            return UIMenu(title: "", children: elements)
        }
    }
}

extension EntryViewController.SensitiveFieldMenuHandler: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        guard controller?.menuElements(for: rowTag) != nil else {
            return nil
        }
        let identifier = rowTag.rawValue as NSString
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { [weak self] _ in
            self?.makeMenu()
        }
    }
}

@available(iOS 16.0, *)
extension EntryViewController.SensitiveFieldMenuHandler: UIEditMenuInteractionDelegate {
    func editMenuInteraction(_: UIEditMenuInteraction, menuFor _: UIEditMenuConfiguration, suggestedActions _: [UIMenuElement]) -> UIMenu? {
        makeMenu()
    }

    func editMenuInteraction(_ interaction: UIEditMenuInteraction, targetRectFor _: UIEditMenuConfiguration) -> CGRect {
        interaction.view?.bounds ?? .zero
    }
}
