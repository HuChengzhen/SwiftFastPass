//
//  FilesViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import KeePassKit
import SnapKit
import UIKit
import UniformTypeIdentifiers

class FilesViewController: UIViewController {
    var collectionView: UICollectionView!
    private let premiumAccess = PremiumAccessController.shared

    // MARK: - Header UI

    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("你的 FastPass 数据库", comment: "")
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("在这里管理你的所有密码库。订阅 FastPass Pro 可解锁自动填充与无限数据库。", comment: "")
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Bottom Primary Button

    private lazy var addDatabaseButton: UIButton = {
        let button = UIButton(type: .system)
        let title = NSLocalizedString("添加数据库", comment: "")
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        if #available(iOS 13.0, *) {
            button.backgroundColor = UIColor.systemBlue
        } else {
            button.backgroundColor = UIColor.blue
        }
        button.layer.cornerRadius = 22
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(addDatabaseButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Empty View

    lazy var emptyView: UIView = {
        let container = UIView()

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12

        let iconView = UIImageView(image: UIImage(systemName: "shippingbox"))
        iconView.tintColor = .tertiaryLabel
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("还没有数据库", comment: "")
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        let descLabel = UILabel()
        descLabel.text = NSLocalizedString("点击下方“添加数据库”来创建或导入你的第一个密码库。", comment: "")
        descLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(descLabel)

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
            descLabel.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, multiplier: 0.7)
        ])

        return container
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showEmptyViewIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - UI

    private func setupUI() {
        navigationItem.title = NSLocalizedString("Database", comment: "")

        // 左边 Pro 入口保持不变
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("FastPass Pro", comment: ""),
            style: .plain,
            target: self,
            action: #selector(paywallButtonTapped)
        )

        // 订阅页是满屏 + 大按钮，所以这里我们取消右上角的 +
        // 只保留下方大按钮做统一的 CTA
        // navigationItem.rightBarButtonItem = ...

        view.backgroundColor = .systemGroupedBackground

        // Header 文案
        view.addSubview(headerTitleLabel)
        view.addSubview(headerSubtitleLabel)

        headerTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.left.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.right.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-20)
        }

        headerSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerTitleLabel.snp.bottom).offset(6)
            make.left.equalTo(headerTitleLabel)
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }

        // Collection View 作为中间的卡片列表
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 16
        flowLayout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag

        collectionView.register(FileCollectionViewCell.self, forCellWithReuseIdentifier: "FileCollectionViewCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCollectionLongPress(_:)))
        collectionView.addGestureRecognizer(longPressGesture)

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerSubtitleLabel.snp.bottom).offset(12)
            make.left.right.equalTo(view.safeAreaLayoutGuide)
        }

        // 底部大按钮（风格同订阅页）
        view.addSubview(addDatabaseButton)
        addDatabaseButton.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(44)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }

        // Collection View 底部约束连到按钮上方
        collectionView.snp.makeConstraints { make in
            make.bottom.equalTo(addDatabaseButton.snp.top).offset(-12)
        }

        // 空态视图只覆盖列表区域（上面标题、下面按钮仍可见）
        view.insertSubview(emptyView, aboveSubview: collectionView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
        }
    }

    private func showEmptyViewIfNeeded() {
        emptyView.isHidden = !File.files.isEmpty
        if !emptyView.isHidden {
            view.bringSubviewToFront(emptyView)
        }
    }

    private func presentSecuritySettings(for file: File) {
        let settings = DatabaseSettingsViewController(file: file)
        navigationController?.pushViewController(settings, animated: true)
    }

    @objc private func handleCollectionLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let location = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location),
              let cell = collectionView.cellForItem(at: indexPath) else { return }
        let file = File.files[indexPath.row]

        let alertController = UIAlertController(title: file.name,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }
        let editAction = UIAlertAction(title: NSLocalizedString("Edit Security Settings", comment: ""), style: .default) { [weak self] _ in
            self?.presentSecuritySettings(for: file)
        }
        alertController.addAction(editAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    // MARK: - Helpers

    private func appendFileAndReload(_ file: File) {
        File.files.append(file)
        File.save()
        let indexPath = IndexPath(row: File.files.endIndex - 1, section: 0)
        collectionView.insertItems(at: [indexPath])
        showEmptyViewIfNeeded()
    }

    // MARK: - Actions

    /// 底部大按钮点击：弹出“新建 / 导入” action sheet
    @objc private func addDatabaseButtonTapped() {
        presentAddDatabaseActionSheet(sourceView: addDatabaseButton)
    }

    /// 如果以后你还想在别处（例如导航栏 + 按钮）复用，可以调用这个方法
    private func presentAddDatabaseActionSheet(sourceView: UIView?) {
        guard premiumAccess.enforceDatabaseLimit(currentCount: File.files.count, presenter: self) else { return }

        let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let pop = alertViewController.popoverPresentationController {
            if let view = sourceView {
                pop.sourceView = view
                pop.sourceRect = view.bounds
            } else if let barButton = navigationItem.rightBarButtonItem {
                pop.barButtonItem = barButton
            } else {
                pop.sourceView = self.view
                pop.sourceRect = CGRect(x: self.view.bounds.midX,
                                        y: self.view.bounds.midY,
                                        width: 0,
                                        height: 0)
            }
        }

        let newDataBase = UIAlertAction(
            title: NSLocalizedString("New Database", comment: ""),
            style: .default
        ) { _ in
            let newDatabaseViewController = NewDatabaseViewController()
            newDatabaseViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: newDatabaseViewController)
            self.present(navigationController, animated: true, completion: nil)
        }
        alertViewController.addAction(newDataBase)

        let importDataBase = UIAlertAction(
            title: NSLocalizedString("Import Database", comment: ""),
            style: .default
        ) { _ in
            let types: [UTType] = [
                .keepassDatabaseV2,
                .keepassDatabaseV1
            ]

            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types)

            if let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                documentPicker.directoryURL = docsURL
            }

            documentPicker.delegate = self
            self.present(documentPicker, animated: true, completion: nil)
        }
        alertViewController.addAction(importDataBase)

        let cancel = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel,
            handler: nil
        )
        alertViewController.addAction(cancel)

        present(alertViewController, animated: true, completion: nil)
    }

    @objc private func paywallButtonTapped() {
        let paywall = SubscriptionPaywallViewController()
        present(paywall, animated: true)
    }
}

// MARK: - Collection View

extension FilesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return File.files.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "FileCollectionViewCell",
            for: indexPath
        ) as? FileCollectionViewCell else {
            return UICollectionViewCell()
        }

        if cell.scrollView.contentOffset.x > 0 {
            cell.scrollView.setContentOffset(.zero, animated: false)
        }

        let file = File.files[indexPath.row]
        cell.fileImageView.image = file.image ?? UIImage(named: "Directory")
        cell.nameLabel.text = file.name
        cell.delegate = self
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let file = File.files[indexPath.row]
        let lockViewController = LockViewController()
        lockViewController.file = file
        navigationController?.pushViewController(lockViewController, animated: true)
    }

    func scrollViewWillBeginDragging(_: UIScrollView) {
        for cell in collectionView.visibleCells {
            if let cell = cell as? FileCollectionViewCell,
               cell.scrollView.contentOffset.x > 0 {
                cell.scrollView.setContentOffset(.zero, animated: true)
            }
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout _: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.bounds.width - 32 // sectionInset 左右 16+16
        let height: CGFloat = 72
        return CGSize(width: availableWidth, height: height)
    }
}

// MARK: - UIDocumentPickerDelegate

extension FilesViewController: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        guard premiumAccess.enforceDatabaseLimit(currentCount: File.files.count, presenter: self) else { return }

        if url.startAccessingSecurityScopedResource() {
            let name = url.lastPathComponent
            let bookmark: Data
            do {
                bookmark = try url.bookmarkData(options: .suitableForBookmarkFile)
            } catch {
                print("FilesViewController.documentPicker error: \(error)")
                url.stopAccessingSecurityScopedResource()
                return
            }
            url.stopAccessingSecurityScopedResource()

            let file = File(name: name, bookmark: bookmark)
            appendFileAndReload(file)
        }
    }
}

// MARK: - NewDatabaseDelegate

extension FilesViewController: NewDatabaseDelegate {
    func newDatabase(viewController: NewDatabaseViewController, didNewDatabase file: File) {
        if premiumAccess.enforceDatabaseLimit(currentCount: File.files.count, presenter: self) {
            appendFileAndReload(file)
        }
        viewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - CardCollectionViewCellDelegate

extension FilesViewController: CardCollectionViewCellDelegate {
    func cardCollectionViewCellDeleteButtonTapped(cell: CardCollectionViewCell) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Do you want to remove this database from this app?", comment: ""),
            message: nil,
            preferredStyle: .actionSheet
        )
        alertController.popoverPresentationController?.sourceRect = cell.bounds
        alertController.popoverPresentationController?.sourceView = cell.deleteButton

        let removeAction = UIAlertAction(
            title: NSLocalizedString("Remove", comment: ""),
            style: .destructive
        ) { _ in
            if let indexPath = self.collectionView.indexPath(for: cell) {
                File.files.remove(at: indexPath.row)
                File.save()
                self.collectionView.deleteItems(at: [indexPath])
                self.showEmptyViewIfNeeded()
            }
        }
        alertController.addAction(removeAction)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel,
            handler: nil
        )
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}
