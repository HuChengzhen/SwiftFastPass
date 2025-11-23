//
//  LockViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/7.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import KeePassKit
import LocalAuthentication
import UIKit

// MARK: - 通用卡片视图，带圆角和阴影（不会出现奇怪的 1px 线）

final class CardView: UIView {
    init(cornerRadius: CGFloat = 18) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        layer.shadowRadius = 10
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 明确 shadowPath，避免系统自动算出来在边缘留下细线
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: layer.cornerRadius
        ).cgPath
    }
}

// MARK: - LockViewController

final class LockViewController: UIViewController {

    // MARK: - Public data

    var file: File!
    var keyFileContent: Data?

    private let premiumAccess = PremiumAccessController.shared

    // 和其它页面统一的主色
    private let accentColor = UIColor(red: 0.25, green: 0.49, blue: 1.0, alpha: 1.0)

    // MARK: - UI elements

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let passwordTextField = UITextField()
    private let keyFileButton = UIButton(type: .system)

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        openDatabaseIfHasPassword()
    }

    // MARK: - 自动解锁

    private func openDatabaseIfHasPassword() {
        guard premiumAccess.isPremiumUnlocked,
              file.securityLevel.usesBiometrics
        else { return }

        var hasCredentials = file.password != nil || file.keyFileContent != nil
        var loadedFromKeychain = false
        if !hasCredentials {
            loadedFromKeychain = file.loadCachedCredentials()
            hasCredentials = loadedFromKeychain
        }

        guard hasCredentials else { return }

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
        guard let url = resolveBookmarkURL() else { return }

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
        navigationController?.navigationBar.tintColor = accentColor

        view.backgroundColor = .systemGroupedBackground

        // ScrollView 基础结构
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // scrollView 填满
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // contentView 约束到 scrollView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // stackView 内边距
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        // 1. Hero 区（小圆点 + 文本，不再是卡片背景）
        stackView.addArrangedSubview(makeHeroHeader())

        // 2. 密码卡片
        stackView.addArrangedSubview(makePasswordCard())

        // 3. 密钥文件按钮卡片
        stackView.addArrangedSubview(makeKeyFileButton())
    }

    /// 顶部文件信息（不再单独卡片背景，避免多余的交界线）
    private func makeHeroHeader() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = accentColor.withAlphaComponent(0.15)
        iconContainer.layer.cornerRadius = 16

        let innerDot = UIView()
        innerDot.translatesAutoresizingMaskIntoConstraints = false
        innerDot.backgroundColor = accentColor
        innerDot.layer.cornerRadius = 8
        iconContainer.addSubview(innerDot)

        NSLayoutConstraint.activate([
            innerDot.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            innerDot.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
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

        container.addSubview(iconContainer)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconContainer.topAnchor.constraint(equalTo: container.topAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 32),
            iconContainer.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    /// 密码输入卡片
    private func makePasswordCard() -> UIView {
        let card = CardView()

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
        passwordTextField.borderStyle = .none
        passwordTextField.backgroundColor = .clear
        passwordTextField.layer.borderWidth = 0

        if #available(iOS 12.0, *) {
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
        keyFileButton.layer.masksToBounds = true
        keyFileButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        keyFileButton.addTarget(self, action: #selector(keyFileButtonTapped), for: .touchUpInside)

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
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true, completion: nil)

        guard let url = urls.first else { return }

        do {
            let data = try Data(contentsOf: url)
            keyFileContent = data
            keyFileButton.setTitle(NSLocalizedString("File: ", comment: "") + url.lastPathComponent, for: .normal)
            keyFileButton.setTitleColor(.systemRed, for: .normal)
            keyFileButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        } catch {
            print("Load key file error: \(error)")
        }
    }
}
