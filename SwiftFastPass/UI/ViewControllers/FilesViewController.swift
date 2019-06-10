//
//  FilesViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import SnapKit
import KeePassKit

class FilesViewController: UIViewController {

    var collectionView: UICollectionView!
    
    lazy var emptyView: UIView = {
        let emptyView = UIView(frame: view.bounds)
        let label = UILabel()
        label.text = NSLocalizedString("Press + to add database", comment: "")
        label.sizeToFit()
        emptyView.addSubview(label)
        label.center = emptyView.center
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
        self.navigationItem.title = NSLocalizedString("Database", comment: "")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped(sender:)))
        
        let width = UIScreen.main.bounds.width
        let height: CGFloat = 60
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: width, height: height)
        flowLayout.minimumLineSpacing = 20
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        self.view.addSubview(collectionView)
        if #available(iOS 13.0, *) {
//            collectionView.backgroundColor = UIColor.systemBackground
        } else {
            collectionView.backgroundColor = UIColor.white
        }
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        collectionView.register(FileCollectionViewCell.self, forCellWithReuseIdentifier: "FileCollectionViewCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        view.addSubview(emptyView)
    }
    
    func showEmptyViewIfNeeded() {
        emptyView.isHidden = !File.files.isEmpty
    }
    
    @objc func addButtonTapped(sender: Any) {
        let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        let newDataBase = UIAlertAction(title: NSLocalizedString("New Database", comment: ""), style: .default) { (alertAction) in
            let newDatabaseViewController = NewDatabaseViewController()
            newDatabaseViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: newDatabaseViewController)
            
            self.present(navigationController, animated: true, completion: nil)
        }
        alertViewController.addAction(newDataBase)
        
        let importDataBase = UIAlertAction(title: NSLocalizedString("Import Database", comment: ""), style: .default) { (alertAction) in
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.jflan.MiniKeePass.kdbx", "com.jflan.MiniKeePass.kdb"], in: .open)
            documentPicker.delegate = self
            self.present(documentPicker, animated: true, completion: nil)
        }
        alertViewController.addAction(importDataBase)
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alertViewController.addAction(cancel)
        
        self.present(alertViewController, animated: true, completion: nil)
    }

}

extension FilesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return File.files.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FileCollectionViewCell", for: indexPath) as! FileCollectionViewCell
        if cell.scrollView.contentOffset.x > 0 {
            cell.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
        let file = File.files[indexPath.row]
        cell.fileImageView.image = file.image ?? UIImage(named: "Directory")
        cell.nameLabel.text = file.name
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let file = File.files[indexPath.row]
        let lockViewController = LockViewController()
        lockViewController.file = file
        self.navigationController?.pushViewController(lockViewController, animated: true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        collectionView.visibleCells.forEach { (cell) in
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
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemSize = CGSize(width: view.bounds.width, height: 60)
        return itemSize
    }
}

extension FilesViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
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
                File.files.append(file)
                
                let indexPath = IndexPath(row: File.files.endIndex - 1, section: 0)
                self.collectionView.insertItems(at: [indexPath])
                self.showEmptyViewIfNeeded()
            }
        }
    }
}

extension FilesViewController: NewDatabaseDelegate {
    func newDatabase(viewController: NewDatabaseViewController, didNewDatabase file: File) {
        File.files.append(file)
        let indexPath = IndexPath(row: File.files.endIndex - 1, section: 0)
        self.collectionView.insertItems(at: [indexPath])
        self.showEmptyViewIfNeeded()
    }
}

extension FilesViewController: CardCollectionViewCellDelegate {
    func cardCollectionViewCellDeleteButtonTapped(cell: CardCollectionViewCell) {
        let alertController = UIAlertController(title: NSLocalizedString("Do you want to remove this database from this app?", comment: ""), message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceRect = cell.bounds
        alertController.popoverPresentationController?.sourceView = cell.deleteButton
        
        let removeAction = UIAlertAction(title: NSLocalizedString("Remove", comment: ""), style: .destructive) { (action) in
            if let indexPath = self.collectionView.indexPath(for: cell) {
                File.files.remove(at: indexPath.row)
                self.collectionView.deleteItems(at: [indexPath])
                self.showEmptyViewIfNeeded()
            }
        }
        alertController.addAction(removeAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
