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

    // MARK: Row Tag

    enum RowTag: String {
        case icon
        case title
        case username
        case password
        case generatePassword
        case url
        case notes
    }

    // MARK: Properties
    private let accentColor = UIColor(red: 0.25, green: 0.49, blue: 1.0, alpha: 1.0)
    
    
    private var entry: KPKEntry?
    private weak var delegate: EntryViewControllerDelegate?

    /// 选中的图标 & 颜色
    private var iconId: Int? = DefaultIcon.id
    private var iconColorId: Int? = DefaultIcon.colorId

    private var isPasswordVisible = false
    private var sensitiveFieldMenuHandlers: [RowTag: SensitiveFieldMenuHandler] = [:]

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Public API

    func configure(with entry: KPKEntry) {
        self.entry = entry
        self.iconId = entry.iconId
        self.iconColorId = entry.iconColorId
    }

    func attach(delegate: EntryViewControllerDelegate) {
        self.delegate = delegate
    }

    private enum DefaultIcon {
        static let sfSymbolName = "key.fill"

        /// 默认图标在 Icons.sfSymbolNames 里的下标
        static let id: Int = {
            Icons.sfSymbolNames.firstIndex(of: sfSymbolName) ?? 0
        }()

        /// 默认颜色，用你现在的调色板逻辑（一般就是蓝色）
        static let colorId: Int = IconColors.normalizedIndex(nil)
    }


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        configureNavigationBar()
        configureForm()
        setupHeaderBanner()

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

    // MARK: - Form 构建

    private func configureForm() {

        // ========== Section 1: 基本信息（图标 + 标题） ==========
        form +++ Section()
            <<< IconRow(RowTag.icon.rawValue) { [weak self] row in
                row.value = self?.currentIconPreviewImage()
            }
            .onCellSelection { [weak self] cell, row in
                self?.iconRowTapped(row: row)
            }







            <<< TextRow(RowTag.title.rawValue) { row in
                row.title = NSLocalizedString("Title", comment: "")
                row.value = entry?.title
                row.placeholder = NSLocalizedString("Title", comment: "")
            }

        // ========== Section 2: 账号 / URL / 密码 ==========

        // 用户名
        // 用户名
        let primarySection = Section()
        form +++ primarySection
            <<< TextRow(RowTag.username.rawValue) { row in
                row.title = NSLocalizedString("User Name", comment: "")
                row.value = entry?.username
                row.placeholder = NSLocalizedString("User Name", comment: "")
            }
            .cellSetup { [weak self] cell, _ in
                self?.registerSensitiveFieldInteractions(for: cell, tag: .username)
                self?.applyFieldVisualStyle(.username, to: cell)
            }
            .cellUpdate { [weak self] cell, _ in
                self?.applyFieldVisualStyle(.username, to: cell)
            }

            // URL
            <<< URLRow(RowTag.url.rawValue) { row in
                row.title = NSLocalizedString("URL", comment: "")
                if let urlString = entry?.url {
                    row.value = URL(string: urlString)
                }
                row.placeholder = NSLocalizedString("https://example.com", comment: "URL placeholder")
            }
            .cellSetup { [weak self] cell, _ in
                self?.registerSensitiveFieldInteractions(for: cell, tag: .url)
                if let textCell = cell as? TextCell {
                    self?.applyFieldVisualStyle(.url, to: textCell)
                }
            }
            .cellUpdate { [weak self] cell, _ in
                if let textCell = cell as? TextCell {
                    self?.applyFieldVisualStyle(.url, to: textCell)
                }
            }




            <<< TextRow(RowTag.password.rawValue) { row in
                row.title = NSLocalizedString("Password", comment: "")
                row.value = entry?.password
                row.placeholder = NSLocalizedString("Password", comment: "")
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
            .cellSetup { cell, _ in
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = .systemBlue
            }
            .onCellSelection { [weak self] _, _ in
                self?.generatePasswordButtonTapped()
            }

        // ========== Section 3: 备注 ==========

        form +++ Section(NSLocalizedString("Notes", comment: ""))
            <<< TextAreaRow(RowTag.notes.rawValue) { row in
                row.placeholder = NSLocalizedString("Notes", comment: "")
                row.value = entry?.notes
                row.textAreaHeight = .dynamic(initialTextViewHeight: 80)
            }
    }
    private func configureIconRow(row: LabelRow, cell: LabelCell) {
        // 关键：把左边默认的 imageView 清掉
        cell.imageView?.image = nil

        cell.accessoryType = .none
        cell.accessoryView = nil

        // 当前要显示的 icon / color
        let iconIndex = iconId ?? 0
        let colorIndex = IconColors.normalizedIndex(iconColorId)

        var image: UIImage?

        if #available(iOS 13.0, *),
           Icons.sfSymbolNames.indices.contains(iconIndex),
           IconColors.palette.indices.contains(colorIndex) {

            let symbolName = Icons.sfSymbolNames[iconIndex]
            let tint = IconColors.resolvedColor(for: colorIndex)
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)

            image = UIImage(systemName: symbolName, withConfiguration: config)?
                .withTintColor(tint, renderingMode: .alwaysOriginal)
        } else if let entry = entry {
            // 旧条目兼容：用原来的 image()
            image = entry.image()
        } else {
            image = UIImage(named: "00_PasswordTemplate")
        }

        guard let iconImage = image else { return }

        let iconView = UIImageView(image: iconImage)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit

        cell.accessoryView = iconView

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    
    // MARK: - 关键信息行统一样式

    private enum FieldVisualStyle {
        case username
        case url
        case password
    }

    private func applyFieldVisualStyle(_ style: FieldVisualStyle, to cell: TextCell) {
        guard let row = cell.row as? TextRow else { return }

        let hasValue = !(row.value?.isEmpty ?? true)
        let isReadOnly = row.isDisabled

        // 行本身背景：轻量的卡片感，比周围稍亮一点
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.contentView.backgroundColor = cell.backgroundColor
        cell.selectionStyle = .none

        // 所有字段统一：标题偏小、偏弱，内容更突出
        cell.textLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        cell.textField.borderStyle = .none

        // 根据不同字段，定义图标 / 颜色 / 字体
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)

            switch style {
            case .username:
                let color = accentColor
                cell.imageView?.image = UIImage(systemName: "person.fill", withConfiguration: config)
                cell.imageView?.tintColor = color

                cell.textLabel?.textColor = color.withAlphaComponent(0.9)

                cell.textField.font = .systemFont(ofSize: 17, weight: hasValue ? .semibold : .regular)
                if isReadOnly && hasValue {
                    cell.textField.textColor = color
                } else {
                    cell.textField.textColor = .label
                }

            case .url:
                let color = UIColor.systemTeal
                cell.imageView?.image = UIImage(systemName: "link", withConfiguration: config)
                cell.imageView?.tintColor = color

                cell.textLabel?.textColor = color.withAlphaComponent(0.9)

                cell.textField.font = .systemFont(ofSize: 16, weight: .regular)
                if isReadOnly && hasValue {
                    cell.textField.textColor = color
                } else {
                    cell.textField.textColor = .label
                }

            case .password:
                let color = UIColor.systemOrange
                cell.imageView?.image = UIImage(systemName: "key.fill", withConfiguration: config)
                cell.imageView?.tintColor = color

                cell.textLabel?.textColor = color.withAlphaComponent(0.9)

                // 密码用等宽字体，更有“密码感”
                cell.textField.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .medium)
                if isReadOnly && hasValue {
                    cell.textField.textColor = color
                } else {
                    cell.textField.textColor = .label
                }
            }
        } else {
            // iOS 13 以下没有 SF Symbols，就简单一点
            cell.imageView?.image = nil
            cell.textLabel?.textColor = .secondaryLabel
            cell.textField.font = .systemFont(ofSize: 17)
            cell.textField.textColor = .label
        }
    }


    private func iconRowTapped(row: IconRow) {
        guard !row.isDisabled else { return }

        let vc = SelectIconViewController()
        vc.initialIconIndex = iconId ?? 0
        vc.initialColorIndex = iconColorId ?? 0

        vc.didSelectAction = { [weak self] _, iconIndex, colorIndex in
            guard let self = self else { return }

            self.iconId = iconIndex
            self.iconColorId = IconColors.normalizedIndex(colorIndex)

            row.value = self.currentIconPreviewImage()
            row.updateCell()
        }

        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 图标预览

    private func currentIconPreviewImage() -> UIImage? {
        if let entry = entry,
           !EntryViewController.hasIconOverride(entry: entry,
                                                selectedIconId: iconId,
                                                selectedColorId: iconColorId) {
            let image = entry.image()
            return entry.usesSFSymbolIcon() ? image : image.withRenderingMode(.alwaysOriginal)
        }

        // 用当前选择的 SF Symbols 图标（默认就是蓝色 key.fill）
        let resolvedIconId = iconId ?? DefaultIcon.id
        let resolvedColorId = iconColorId ?? DefaultIcon.colorId

        return makeSymbolImage(iconIndex: resolvedIconId, colorIndex: resolvedColorId)
    }



    private func makeSymbolImage(iconIndex: Int, colorIndex: Int?) -> UIImage? {
        guard #available(iOS 13.0, *),
              Icons.sfSymbolNames.indices.contains(iconIndex)
        else { return UIImage(named: "00_PasswordTemplate") }

        let symbolName = Icons.sfSymbolNames[iconIndex]
        let tint = IconColors.resolvedColor(for: colorIndex)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        return UIImage(systemName: symbolName, withConfiguration: config)?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
    }

    /// 判断当前是否有“待保存”的图标/颜色选择，用于预览时决定是否沿用旧图标。
    static func hasIconOverride(entry: KPKEntry?,
                                selectedIconId: Int?,
                                selectedColorId: Int?) -> Bool {
        guard let entry = entry else { return true }

        let resolvedIconId = selectedIconId ?? entry.iconId
        let resolvedColorId = IconColors.normalizedIndex(selectedColorId ?? entry.iconColorId)
        let entryColorId = IconColors.normalizedIndex(entry.iconColorId)

        return resolvedIconId != entry.iconId || resolvedColorId != entryColorId
    }


    
    private func setupHeaderBanner() {
        guard tableView.tableHeaderView == nil else { return }

        let header = UIView()
        header.backgroundColor = .clear

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = accentColor.withAlphaComponent(0.10)
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = true

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit        // ✅ 防止变形

        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
            iconView.image = UIImage(systemName: "key.fill", withConfiguration: config)
        }
        iconView.tintColor = accentColor

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = accentColor
        titleLabel.text = NSLocalizedString("Create a secure item", comment: "")

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = NSLocalizedString("Save your username & password here, and FastPass can fill it for you next time.", comment: "")

        header.addSubview(card)
        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)

        let inset: CGFloat = 20

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: inset),
            card.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -inset),
            card.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8),

            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 24),   // ✅ 固定宽高
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            subtitleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        let width = view.bounds.width
        header.frame = CGRect(x: 0, y: 0, width: width, height: 1)
        header.layoutIfNeeded()
        let targetSize = header.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        )
        header.frame.size.height = targetSize.height

        tableView.tableHeaderView = header
    }


    // MARK: - 统一的图标视图（右侧圆角彩色）

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

    // MARK: - 密码 cell

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

        // ⭐️ 这里加高亮 & 等宽字体
        // ⭐️ 统一用视觉样式
        applyFieldVisualStyle(.password, to: cell)

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
        let title = NSLocalizedString("Save Changes?", comment: "")
        let message = NSLocalizedString("update_item_warning_message", comment: "")
        let confirmTitle = NSLocalizedString("Save", comment: "")
        let cancelTitle = NSLocalizedString("Cancel", comment: "")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: confirmTitle, style: .destructive) { [weak self] _ in
                self?.persistChanges()
            }
        )
        alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))
        present(alertController, animated: true)
    }

    @objc
    private func passwordVisibilityButtonTapped() {
        isPasswordVisible.toggle()
        refreshPasswordVisibility()
    }

    private func refreshPasswordVisibility() {
        (form.rowBy(tag: RowTag.password.rawValue) as? TextRow)?.updateCell()
    }

    private func hidePasswordIfNeeded() {
        guard isPasswordVisible else { return }
        isPasswordVisible = false
        refreshPasswordVisibility()
    }

    // MARK: - 保存逻辑

    private func persistChanges() {
        let titleRow = form.rowBy(tag: RowTag.title.rawValue) as? TextRow
        let usernameRow = form.rowBy(tag: RowTag.username.rawValue) as? TextRow
        let passwordRow = form.rowBy(tag: RowTag.password.rawValue) as? TextRow
        let urlRow = form.rowBy(tag: RowTag.url.rawValue) as? URLRow
        let notesRow = form.rowBy(tag: RowTag.notes.rawValue) as? TextAreaRow

        let resolvedIconId = iconId ?? DefaultIcon.id
        // 老条目保持 0 以继续使用 KeePass 图标；新条目默认配色
        let resolvedIconColorId: Int
        if entry != nil, (iconColorId == nil || iconColorId == 0) {
            resolvedIconColorId = 0
        } else {
            resolvedIconColorId = IconColors.normalizedIndex(iconColorId)
        }

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
            entry.iconId = resolvedIconId
            entry.iconColorId = resolvedIconColorId
            delegate?.entryViewController(self, didEditEntry: entry)
            disableFormEditing()
        } else {
            let newEntry = KPKEntry()
            newEntry.title = title
            newEntry.username = username
            newEntry.password = password
            newEntry.url = url?.absoluteString
            newEntry.notes = notes
            newEntry.iconId = resolvedIconId
            newEntry.iconColorId = resolvedIconColorId
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
        guard let row = form.rowBy(tag: RowTag.generatePassword.rawValue) as? ButtonRow else { return }
        row.hidden = Condition(booleanLiteral: isHidden)
        row.evaluateHidden()
    }

    // MARK: - 图标行点击

    private func generatePasswordButtonTapped() {
        let viewController = PasswordGenerateViewController()
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: - 敏感字段菜单（复制 / 显示）

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

    fileprivate func shouldAllowSensitiveMenu(for tag: RowTag) -> Bool {
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

    fileprivate func sensitiveValue(for tag: RowTag) -> String? {
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

    private func presentSensitiveDetail(for tag: RowTag, value: String) {
        let vc = ShowPasswordViewController()
        vc.text = value
        switch tag {
        case .username:
            vc.titleText = NSLocalizedString("User Name", comment: "")
        case .url:
            vc.titleText = NSLocalizedString("URL", comment: "")
        default:
            vc.titleText = NSLocalizedString("Password", comment: "")
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
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
            self?.presentSensitiveDetail(for: tag, value: value)
        }
        return [copyAction, displayAction]
    }
}

// MARK: - Password Generator

extension EntryViewController: PasswordGenerateDelegat {
    func passwordGenerate(_: PasswordGenerateViewController, didGenerate password: String) {
        guard let row = form.rowBy(tag: RowTag.password.rawValue) as? TextRow else { return }
        row.value = password
        row.updateCell()
    }
}

// MARK: - 敏感字段菜单 Handler

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
