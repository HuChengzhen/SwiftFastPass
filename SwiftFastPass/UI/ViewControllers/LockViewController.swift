//
//  LockViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/7.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import Eureka          // 仍然继承 FormViewController 用 tableView
import KeePassKit
import LocalAuthentication
import UIKit

final class LockViewController: FormViewController {

    // MARK: - Public data

    var file: File!
    var keyFileContent: Data?

    private let premiumAccess = PremiumAccessController.shared

    // 和其它页面统一的主色
    private let accentColor = UIColor(red: 0.25, green: 0.49, blue: 1.0, alpha: 1.0)

    // MARK: - UI elements

    private let passwordTextField = UITextField()
    private let keyFileButton = UIButton(type: .system)

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
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        navigationController?.navigationBar.tintColor = accentColor

        // Eureka 的 form 不再使用，仅保持空
        form.removeAll()

        setupHeader()
    }

    /// 整个 header：Hero 卡片 + 密码卡片 + 密钥文件按钮（全部是卡片风格）
    private func setupHeader() {
        let container = UIView()
        container.backgroundColor = .clear

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        // 1. Hero 卡片
        stack.addArrangedSubview(makeHeroCard())

        // 2. 密码输入卡片
        stack.addArrangedSubview(makePasswordCard())

        // 3. 密钥文件按钮（卡片式主按钮）
        stack.addArrangedSubview(makeKeyFileButton())

        // 先给一个大致高度，后面在 viewDidLayoutSubviews 里会自动调整
        container.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 260)
        tableView.tableHeaderView = container
    }

    /// 顶部文件信息卡片（hero）
    private func makeHeroCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 18
        card.layer.masksToBounds = false
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        card.layer.shadowRadius = 10
        card.layer.shadowOpacity = 1
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.backgroundColor = accentColor.withAlphaComponent(0.15)
        iconView.layer.cornerRadius = 16

        let innerDot = UIView()
        innerDot.translatesAutoresizingMaskIntoConstraints = false
        innerDot.backgroundColor = accentColor
        innerDot.layer.cornerRadius = 8
        iconView.addSubview(innerDot)

        NSLayoutConstraint.activate([
            innerDot.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            innerDot.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            innerDot.widthAnchor.constraint(equalToConstant: 16),
            innerDot.heightAnchor.constraint(equalToConstant: 16)
        ])

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = file.name
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = NSLocalizedString("Enter your password or select a key file to unlock this database.", comment: "")
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    /// 密码输入卡片
    private func makePasswordCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 18
        card.layer.masksToBounds = false
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        card.layer.shadowRadius = 8
        card.layer.shadowOpacity = 1
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        card.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("Password", comment: "")
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.placeholder = NSLocalizedString("Enter password here", comment: "")
        passwordTextField.isSecureTextEntry = true
        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.returnKeyType = .done
        passwordTextField.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        passwordTextField.textColor = .label
        passwordTextField.tintColor = accentColor
        if #available(iOS 12.0, *) {
            // 使用 oneTimeCode 避免系统自动保存密码弹窗
            passwordTextField.textContentType = .oneTimeCode
        } else {
            passwordTextField.textContentType = nil
        }

        card.addSubview(titleLabel)
        card.addSubview(passwordTextField)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            passwordTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            passwordTextField.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            passwordTextField.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            passwordTextField.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            passwordTextField.heightAnchor.constraint(equalToConstant: 32)
        ])

        return card
    }

    /// 密钥文件按钮（卡片式主按钮）
    private func makeKeyFileButton() -> UIView {
        keyFileButton.translatesAutoresizingMaskIntoConstraints = false
        keyFileButton.setTitle(NSLocalizedString("Select Key File", comment: ""), for: .normal)
        keyFileButton.setTitleColor(.white, for: .normal)
        keyFileButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        keyFileButton.backgroundColor = accentColor
        keyFileButton.layer.cornerRadius = 18
        keyFileButton.layer.masksToBounds = false
        keyFileButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        keyFileButton.addTarget(self, action: #selector(keyFileButtonTapped), for: .touchUpInside)

        // 外面再包一层透明 view，和其它卡片对齐
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(keyFileButton)

        NSLayoutConstraint.activate([
            keyFileButton.topAnchor.constraint(equalTo: wrapper.topAnchor),
            keyFileButton.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            keyFileButton.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            keyFileButton.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            keyFileButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])

        return wrapper
    }

    // MARK: - Actions

    @objc private func openButtonTapped(sender _: Any) {
        let password = passwordTextField.text
        openDatabase(password: password, keyFileContent: keyFileContent, updateFile: true)
    }

    @objc private func editButtonTapped() {
        let settings = DatabaseSettingsViewController(file: file)
        navigationController?.pushViewController(settings, animated: true)
    }

    /// 点击「选择密钥文件」按钮
    @objc private func keyFileButtonTapped() {
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
            keyFileButton.setTitle(NSLocalizedString("Select Key File", comment: ""), for: .normal)
            keyFileButton.setTitleColor(.white, for: .normal)
            keyFileButton.backgroundColor = accentColor
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
            keyFileButton.setTitle(NSLocalizedString("File: ", comment: "") + url.lastPathComponent, for: .normal)
            keyFileButton.setTitleColor(.systemRed, for: .normal)
            keyFileButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        }
    }
}
