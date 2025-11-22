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
    private var iconColorId: Int?
    private var isPasswordVisible = false

    private var sensitiveFieldMenuHandlers: [RowTag: SensitiveFieldMenuHandler] = [:]

    // MARK: - Public API

    func configure(with entry: KPKEntry) {
        self.entry = entry
        // 把已有图标信息同步到本地状态，方便初始化 UI
        self.iconId = entry.iconId
        self.iconColorId = entry.iconColorId
    }

    func attach(delegate: EntryViewControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .clear

        configureNavigationBar()
        configureForm()
        if entry != nil {
            disableFormEditing()
        }
    }

    // MARK: - Navigation Bar

    private func configureNavigationBar() {
        if let entry = entry {
            navigationItem.title = entry.title
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .edit,
                target: self,
                action: #selector(editButtonTapped)
            )
        } else {
            navigationItem.title = NSLocalizedString("New Item", comment: "")
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(doneButtonTapped)
            )
        }
    }

    // MARK: - Form

    private func configureForm() {

        // MARK: Section 1: 图标 & 标题

        form
            +++ Section()
            <<< ImageRow(RowTag.icon.rawValue) { [weak self] row in
                guard let self = self else { return }
                row.title = NSLocalizedString("Icon", comment: "")
                row.sourceTypes = []

                // 有老数据但没有颜色时，继续用原来的 PNG 图标
                if let entry = self.entry, entry.iconColorId == 0 {
                    row.value = entry.image()
                } else if self.entry == nil {
                    // 新建条目默认图标
                    row.value = UIImage(named: "00_PasswordTemplate")
                } else {
                    // 其余情况（有颜色的 SF 图标）只用 accessoryView 来显示
                    row.value = nil
                }
            }
            .cellSetup { [weak self] cell, _ in
                guard let self = self else { return }
                cell.height = { 56 }

                // 使用统一风格的圆角彩色图标
                if #available(iOS 13.0, *) {
                    if let iconId = self.iconId,
                       let colorId = self.iconColorId,
                       colorId != 0,
                       Icons.sfSymbolNames.indices.contains(iconId),
                       IconColors.palette.indices.contains(colorId) {

                        let symbolName = Icons.sfSymbolNames[iconId]
                        let tint = IconColors.palette[colorId]
                        cell.accessoryView = self.makeIconAccessoryView(
                            symbolName: symbolName,
                            color: tint
                        )
                    }
                }
            }
            .onCellSelection { [weak self] cell, row in
                self?.imageRowSelected(cell: cell, row: row)
            }
            <<< TextRow(RowTag.title.rawValue) { row in
                row.title = NSLocalizedString("Title", comment: "")
                row.value = entry?.title
            }

            // MARK: Section 2: 用户名、URL、密码

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
                if let urlString = entry?.url {
                    row.value = URL(string: urlString)
                }
            }
            .cellSetup { [weak self] cell, _ in
                self?.registerSensitiveFieldInteractions(for: cell, tag: .url)
            }

            <<< TextRow(RowTag.password.rawValue) { row in
                row.title = NSLocalizedString("Password", comment: "")
                row.value = entry?.password
            }
            .cellSetup { [weak self] cell, _ in
                self?.registerSensitiveFieldInteractions(for: cell, tag: .password)
                if #available(iOS 12.0, *) {
                    cell.textField.textContentType = .oneTimeCode
                } else {
                    cell.textField.textContentType = nil
                }
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

            // MARK: Section 3: 备注

            +++ Section(NSLocalizedString("Notes", comment: ""))
            <<< TextAreaRow(RowTag.notes.rawValue) { row in
                row.placeholder = NSLocalizedString("Notes", comment: "")
                row.value = entry?.notes
                row.textAreaHeight = .dynamic(initialTextViewHeight: 80)
            }
    }

    // MARK: - Icon Row Helpers

    /// 统一的右侧圆角彩色图标视图
    private func makeIconAccessoryView(symbolName: String, color: UIColor) -> UIView {
        let size: CGFloat = 32
        let container = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))

        let bgView = UIView()
        bgView.translatesAutoresizingMaskIntoConstraints = false
        bgView.backgroundColor = color.withAlphaComponent(0.12)
        bgView.layer.cornerRadius = size / 2
        bgView.layer.masksToBounds = true

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = color

        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            imageView.image = UIImage(systemName: symbolName, withConfiguration: config)
        } else {
            imageView.image = UIImage(named: "00_PasswordTemplate")
        }

        container.addSubview(bgView)
        bgView.addSubview(imageView)

        NSLayoutConstraint.activate([
            bgView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bgView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            bgView.widthAnchor.constraint(equalToConstant: size),
            bgView.heightAnchor.constraint(equalToConstant: size),

            imageView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        return container
    }

    private func configurePasswordCell(_ cell: TextCell) {
        if #available(iOS 12.0, *) {
            cell.textField.textContentType = .oneTimeCode
        } else {
            cell.textField.textContentType = nil
        }
        cell.textField.isSecureTextEntry = !isPasswordVisible
        guard let row = cell.row as? TextRow else {
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
        button.accessibilityLabel = isPasswordVisible
            ? NSLocalizedString("Hide Password", comment: "")
            : NSLocalizedString("Show Password", comment: "")
        cell.textField.rightView = button
    }

    // MARK: - Actions

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
        guard let row = form.rowBy(tag: RowTag.password.rawValue) as? TextRow else {
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

    // MARK: - Save

    private func persistChanges() {
        let titleRow = form.rowBy(tag: RowTag.title.rawValue) as? TextRow
        let usernameRow = form.rowBy(tag: RowTag.username.rawValue) as? TextRow
        let passwordRow = form.rowBy(tag: RowTag.password.rawValue) as? TextRow
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
            if let iconId = iconId, let iconColorId = iconColorId {
                entry.iconId = iconId
                entry.iconColorId = iconColorId
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
            if let iconColorId = iconColorId {
                newEntry.iconColorId = iconColorId
            }
            delegate?.entryViewController(self, didNewEntry: newEntry)
            navigationController?.popViewController(animated: true)
        }
    }

    private func enableFormEditing() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        for row in form.allRows {
            row.disabled = Condition(booleanLiteral: false)
            row.evaluateDisabled()
        }
        updateGeneratePasswordVisibility(isHidden: false)
    }

    private func disableFormEditing() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(editButtonTapped)
        )
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

    // MARK: - Icon row tap

    private func imageRowSelected(cell: ImageCell, row: ImageRow) {
        guard !row.isDisabled else { return }

        let selectIconViewController = SelectIconViewController()
        selectIconViewController.initialIconIndex = iconId ?? 0
        selectIconViewController.initialColorIndex = iconColorId ?? 0

        selectIconViewController.didSelectAction = { [weak self, weak cell] _, iconIndex, colorIndex in
            guard let self = self, let cell = cell else { return }

            self.iconId = iconIndex
            self.iconColorId = colorIndex

            if #available(iOS 13.0, *) {
                let symbolName = Icons.sfSymbolNames[iconIndex]
                let tint = IconColors.palette[colorIndex]
                cell.accessoryView = self.makeIconAccessoryView(
                    symbolName: symbolName,
                    color: tint
                )
            }

            // 不再需要旧的 image 缩略图
            row.value = nil
            row.updateCell()
        }

        navigationController?.pushViewController(selectIconViewController, animated: true)
    }

    private func generatePasswordButtonTapped() {
        let viewController = PasswordGenerateViewController()
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: - Sensitive fields (复制 / 展示菜单)

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
            guard let row = form.rowBy(tag: RowTag.password.rawValue) as? TextRow else { return false }
            return row.isDisabled && !(row.value?.isEmpty ?? true)
        case .url:
            guard let row = form.rowBy(tag: RowTag.url.rawValue) as? URLRow else { return false }
            return row.isDisabled && row.value != nil
        default:
            return false
        }
    }

    private func sensitiveValue(for tag: RowTag) -> String? {
        switch tag {
        case .username:
            return (form.rowBy(tag: RowTag.username.rawValue) as? TextRow)?.value
        case .password:
            return (form.rowBy(tag: RowTag.password.rawValue) as? TextRow)?.value
        case .url:
            return (form.rowBy(tag: RowTag.url.rawValue) as? URLRow)?.value?.absoluteString
        default:
            return nil
        }
    }

    private func copyToPasteboard(_ text: String) {
        let pasteboard = UIPasteboard.general
        pasteboard.setItems(
            [[UTType.plainText.identifier: text]],
            options: [.expirationDate: Date().addingTimeInterval(30)]
        )
    }

    private func presentSensitiveDetail(with value: String) {
        let viewController = ShowPasswordViewController()
        viewController.password = value
        present(viewController, animated: true)
    }

    fileprivate func menuElements(for tag: RowTag) -> [UIMenuElement]? {
        guard shouldAllowSensitiveMenu(for: tag),
              let value = sensitiveValue(for: tag) else { return nil }
        let copyTitle = NSLocalizedString("Copy", comment: "")
        let displayTitle = NSLocalizedString("Display", comment: "")

        let copyAction = UIAction(title: copyTitle, image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
            self?.copyToPasteboard(value)
        }
        let displayAction = UIAction(title: displayTitle, image: UIImage(systemName: "eye")) { [weak self] _ in
            self?.presentSensitiveDetail(with: value)
        }
        return [copyAction, displayAction]
    }
}

// MARK: - Password Generator

extension EntryViewController: PasswordGenerateDelegat {
    func passwordGenerate(_: PasswordGenerateViewController, didGenerate password: String) {
        guard let row = form.rowBy(tag: RowTag.password.rawValue) as? TextRow else {
            return
        }
        row.value = password
        row.updateCell()
    }
}

// MARK: - SensitiveFieldMenuHandler

extension EntryViewController {
    final class SensitiveFieldMenuHandler: NSObject {
        weak var controller: EntryViewController?
        let rowTag: RowTag

        init(controller: EntryViewController, rowTag: RowTag) {
            self.controller = controller
            self.rowTag = rowTag
        }

        private func makeMenu() -> UIMenu? {
            guard let controller = controller,
                  let elements = controller.menuElements(for: rowTag),
                  !elements.isEmpty else {
                return nil
            }
            return UIMenu(title: "", children: elements)
        }
    }
}

extension EntryViewController.SensitiveFieldMenuHandler: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _: UIContextMenuInteraction,
        configurationForMenuAtLocation _: CGPoint
    ) -> UIContextMenuConfiguration? {
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
    func editMenuInteraction(
        _: UIEditMenuInteraction,
        menuFor _: UIEditMenuConfiguration,
        suggestedActions _: [UIMenuElement]
    ) -> UIMenu? {
        makeMenu()
    }

    func editMenuInteraction(
        _ interaction: UIEditMenuInteraction,
        targetRectFor _: UIEditMenuConfiguration
    ) -> CGRect {
        interaction.view?.bounds ?? .zero
    }
}

// MARK: - 小工具：安全下标

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
