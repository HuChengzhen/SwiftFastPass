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

    lazy var emptyView: UIView = {
        let emptyView = UIView()
        let label = UILabel()
        label.text = NSLocalizedString("Press + to add database", comment: "")
        label.textColor = .secondaryLabel
        label.textAlignment = .center

        emptyView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor),
        ])

        return emptyView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showEmptyViewIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func setupUI() {
        navigationItem.title = NSLocalizedString("Database", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped(sender:)))

        let width = UIScreen.main.bounds.width
        let height: CGFloat = 60
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: width, height: height)
        flowLayout.minimumLineSpacing = 20
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.addSubview(collectionView)
        if #available(iOS 13.0, *) {
            collectionView.backgroundColor = UIColor.systemBackground
        } else {
            collectionView.backgroundColor = UIColor.white
        }
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        collectionView.register(FileCollectionViewCell.self, forCellWithReuseIdentifier: "FileCollectionViewCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }

    func showEmptyViewIfNeeded() {
        emptyView.isHidden = !File.files.isEmpty
    }

    private func appendFileAndReload(_ file: File) {
        File.files.append(file)
        File.save()
        let indexPath = IndexPath(row: File.files.endIndex - 1, section: 0)
        collectionView.insertItems(at: [indexPath])
        showEmptyViewIfNeeded()
    }

    @objc func addButtonTapped(sender _: Any) {
        let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem

        let newDataBase = UIAlertAction(title: NSLocalizedString("New Database", comment: ""), style: .default) { _ in
            let newDatabaseViewController = NewDatabaseViewController()
            newDatabaseViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: newDatabaseViewController)

            self.present(navigationController, animated: true, completion: nil)
        }
        alertViewController.addAction(newDataBase)

        let importDataBase = UIAlertAction(title: NSLocalizedString("Import Database", comment: ""), style: .default) { _ in
            let types: [UTType] = [
                .keepassDatabaseV2,
                .keepassDatabaseV1
            ]

            let documentPicker = UIDocumentPickerViewController(
                forOpeningContentTypes: types
            )

            // 1. App 沙盒里的 Documents 目录
            if let docsURL = FileManager.default.urls(for: .documentDirectory,
                                                      in: .userDomainMask).first
            {
                // 2. 告诉 Document Picker 初始目录
                documentPicker.directoryURL = docsURL
            }

            documentPicker.delegate = self
            self.present(documentPicker, animated: true, completion: nil)
        }
        alertViewController.addAction(importDataBase)

        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alertViewController.addAction(cancel)

        present(alertViewController, animated: true, completion: nil)
    }
}

extension FilesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return File.files.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FileCollectionViewCell",
                                                            for: indexPath) as? FileCollectionViewCell
        else {
            return UICollectionViewCell()
        }

        if cell.scrollView.contentOffset.x > 0 {
            cell.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
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
            let cell = cell as! FileCollectionViewCell
            if cell.scrollView.contentOffset.x > 0 {
                cell.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            }
        }
    }

//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize{
//        let itemSize = CGSize(width: UIScreen.main.bounds.size.width, height: 60)
//        return itemSize
//    }
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let itemSize = CGSize(width: view.bounds.width, height: 60)
        return itemSize
    }
}

extension FilesViewController: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            if url.startAccessingSecurityScopedResource() {
                let name = url.lastPathComponent
                let bookmark: Data
                do {
                    try bookmark = url.bookmarkData(options: .suitableForBookmarkFile)
                } catch {
                    print("FilesViewController.documentPicker error: \(error)")
                    return
                }
                url.stopAccessingSecurityScopedResource()

                let file = File(name: name, bookmark: bookmark)
                appendFileAndReload(file)
            }
        }
    }
}

extension FilesViewController: NewDatabaseDelegate {
    func newDatabase(viewController: NewDatabaseViewController, didNewDatabase file: File) {
        appendFileAndReload(file)
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension FilesViewController: CardCollectionViewCellDelegate {
    func cardCollectionViewCellDeleteButtonTapped(cell: CardCollectionViewCell) {
        let alertController = UIAlertController(title: NSLocalizedString("Do you want to remove this database from this app?", comment: ""), message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceRect = cell.bounds
        alertController.popoverPresentationController?.sourceView = cell.deleteButton

        let removeAction = UIAlertAction(title: NSLocalizedString("Remove", comment: ""), style: .destructive) { _ in
            if let indexPath = self.collectionView.indexPath(for: cell) {
                File.files.remove(at: indexPath.row)
                File.save()
                self.collectionView.deleteItems(at: [indexPath])
                self.showEmptyViewIfNeeded()
            }
        }
        alertController.addAction(removeAction)

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}
