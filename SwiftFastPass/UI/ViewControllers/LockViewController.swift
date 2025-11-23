//
//  LockViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/7.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import Eureka
import KeePassKit
import LocalAuthentication
import UIKit

final class LockViewController: FormViewController {
    var file: File!

    var keyFileContent: Data?
    private let premiumAccess = PremiumAccessController.shared

    // 和其它页面统一的主色
    private let accentColor = UIColor(red: 0.25, green: 0.49, blue: 1.0, alpha: 1.0)

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        openDatabaseIfHasPassword()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 让 tableHeaderView 自适应高度
        if let header = tableView.tableHeaderView {
            let size = header.systemLayoutSizeFitting(
                CGSize(width: tableView.bounds.width,
                       height: UIView.layoutFittingCompressedSize.height)
            )
            if header.frame.height != size.height {
                header.frame.size.height = size.height
                tableView.tableHeaderView = header
            }
        }
    }

    // MARK: - 自动解锁

    private func openDatabaseIfHasPassword() {
        guard premiumAccess.isPremiumUnlocked, file.securityLevel.usesBiometrics else {
            return
        }

        var hasCredentials = file.password != nil || file.keyFileContent != nil
        var loadedFromKeychain = false
        if !hasCredentials {
            loadedFromKeychain = file.loadCachedCredentials()
            hasCredentials = loadedFromKeychain
        }

        guard hasCredentials else {
            return
        }

        let openBlock = {
            self.openDatabase(password: self.file.password,
                              keyFileContent: self.file.keyFileContent,
                              updateFile: false)
        }

        if loadedFromKeychain, file.securityLevel.keychainRequiresUserPresence {
            openBlock()
        } else {
            biometrics(onSuccess: openBlock)
        }
    }

    // 允许老用户在已有密钥文件的情况下跳过 Pro 限制
    private func canBypassKeyFilePaywall() -> Bool {
        return file.requiresKeyFileContent
            || file.keyFileContent != nil
            || file.hasCachedCredentials
    }

    // MARK: - Public

    func openDatabase(password: String?, keyFileContent: Data?, updateFile: Bool) {
        guard let url = resolveBookmarkURL() else {
            return
        }

        let document = Document(fileURL: url)
        document.key = buildCompositeKey(password: password, keyFileContent: keyFileContent)

        document.open { [weak self] success in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if success {
                    if updateFile {
                        self.file.attach(password: password, keyFileContent: keyFileContent)
                        self.file.image = document.tree?.root?.image()
                    }

                    let databaseViewController = DatabaseViewController()
                    databaseViewController.document = document
                    databaseViewController.group = document.tree?.root

                    if let navigationController = self.navigationController {
                        navigationController.pushViewController(databaseViewController, animated: true)
                        if let index = navigationController.viewControllers.firstIndex(of: self) {
                            navigationController.viewControllers.remove(at: index)
                        }
                    }
                } else {
                    self.presentInvalidKeyAlert()
                }
            }
        }
    }

    // MARK: - Private helpers

    private func resolveBookmarkURL() -> URL? {
        var isStale = false

        do {
            let url = try URL(resolvingBookmarkData: file.bookmark,
                              bookmarkDataIsStale: &isStale)

            if isStale {
                do {
                    let newBookmark = try url.bookmarkData(options: .suitableForBookmarkFile)
                    file.updateBookmark(newBookmark)
                } catch {
                    print("LockViewController.openDatabase bookmark update error: \(error)")
                    // 这里选择继续使用旧 url，视需求可以 return nil
                }
            }

            return url
        } catch {
            print("LockViewController.openDatabase bookmark resolve error: \(error)")
            return nil
        }
    }

    private func buildCompositeKey(password: String?, keyFileContent: Data?) -> KPKCompositeKey {
        let compositeKey = KPKCompositeKey()

        if let password = password,
           !password.isEmpty,
           let passwordKey = KPKPasswordKey(password: password)
        {
            compositeKey.add(passwordKey)
        }

        if let keyFileContent = keyFileContent,
           let fileKey = try? KPKFileKey(keyFileData: keyFileContent)
        {
            compositeKey.add(fileKey)
        }

        return compositeKey
    }

    private func presentInvalidKeyAlert() {
        let title = NSLocalizedString("Password or key file is not correct", comment: "")
        let message = NSLocalizedString("Please check password and key file", comment: "")

        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)

        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                   style: .cancel,
                                   handler: nil)
        alertController.addAction(cancel)

        present(alertController, animated: true, completion: nil)
    }

    // MARK: - UI

    private func setupUI() {
        navigationItem.title = file.name

        // 导航栏按钮：右侧「编辑」+「打开」
        let editItem = UIBarButtonItem(
            title: NSLocalizedString("Edit", comment: ""),
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
        let openItem = UIBarButtonItem(
            title: NSLocalizedString("Open", comment: ""),
            style: .done,
            target: self,
            action: #selector(openButtonTapped(sender:))
        )
        navigationItem.rightBarButtonItems = [editItem, openItem]

        // 整体背景和列表样式
        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        navigationController?.navigationBar.tintColor = accentColor

        setupHeaderCard()
        setupForm()
    }

    /// 顶部文件信息卡片
    private func setupHeaderCard() {
        let container = UIView()
        container.backgroundColor = .clear

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = file.name
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = NSLocalizedString("Enter your password or select a key file to unlock this database.", comment: "")
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        container.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        // 先给一个大致高度，后面在 viewDidLayoutSubviews 里会自动调整
        container.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 80)
        tableView.tableHeaderView = container
    }

    /// 表单部分：密码 + 密钥文件按钮
    private func setupForm() {
        form.removeAll()

        // Password Section
        form +++ Section()
            <<< TextRow("password") { row in
                row.title = NSLocalizedString("Password", comment: "")
                row.placeholder = NSLocalizedString("Enter password here", comment: "")
            }
            .cellSetup { cell, _ in
                cell.selectionStyle = .none
                cell.textField.isSecureTextEntry = true
                cell.textField.returnKeyType = .done
                cell.textField.clearButtonMode = .whileEditing
                if #available(iOS 12.0, *) {
                    // oneTimeCode 可以避免系统自动保存密码弹窗
                    cell.textField.textContentType = .oneTimeCode
                } else {
                    cell.textField.textContentType = nil
                }

                cell.backgroundColor = .clear
                let bg = UIView()
                bg.backgroundColor = .secondarySystemBackground
                bg.layer.cornerRadius = 12
                bg.layer.masksToBounds = true
                cell.backgroundView = bg
            }
            .cellUpdate { cell, _ in
                cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
                cell.textField.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)
                cell.textLabel?.textColor = .secondaryLabel
            }

        // Key file button section
        form +++ Section()
            <<< ButtonRow("keyFile") { row in
                row.title = NSLocalizedString("Select Key File", comment: "")
            }
            .cellSetup { cell, _ in
                cell.selectionStyle = .default
                cell.tintColor = self.accentColor
                cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
                cell.textLabel?.textAlignment = .center

                cell.backgroundColor = .clear
                let bg = UIView()
                bg.backgroundColor = .secondarySystemBackground
                bg.layer.cornerRadius = 12
                bg.layer.masksToBounds = true
                cell.backgroundView = bg
            }
            .cellUpdate { cell, _ in
                cell.textLabel?.textAlignment = .center
            }
            .onCellSelection(keyFileButtonTapped)
    }

    // MARK: - Actions

    @objc func openButtonTapped(sender _: Any) {
        let password = (form.rowBy(tag: "password") as! TextRow).value
        openDatabase(password: password, keyFileContent: keyFileContent, updateFile: true)
    }

    @objc private func editButtonTapped() {
        let settings = DatabaseSettingsViewController(file: file)
        navigationController?.pushViewController(settings, animated: true)
    }

    func keyFileButtonTapped(cell: ButtonCellOf<String>, row _: ButtonRow) {
        // 兼容旧用户：已有密钥文件的数据库不再弹订阅限制
        if !premiumAccess.isPremiumUnlocked && !canBypassKeyFilePaywall() {
            guard premiumAccess.enforce(feature: .keyFile, presenter: self) else { return }
        }
        if keyFileContent == nil {
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
            documentPicker.delegate = self
            present(documentPicker, animated: true, completion: nil)
        } else {
            keyFileContent = nil
            let buttonRow = form.rowBy(tag: "keyFile") as! ButtonRow
            buttonRow.title = NSLocalizedString("Select Key File", comment: "")
            cell.tintColor = accentColor
            buttonRow.updateCell()
        }
    }
}

// MARK: - UIDocumentPickerDelegate

extension LockViewController: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                print(error)
                return
            }
            keyFileContent = data
            let buttonRow = form.rowBy(tag: "keyFile") as! ButtonRow
            buttonRow.title = NSLocalizedString("File: ", comment: "") + url.lastPathComponent
            buttonRow.cell.tintColor = UIColor.systemRed
            buttonRow.updateCell()
        }
    }
}
