//
//  SelectIconViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import SnapKit
import UIKit

class SelectIconViewController: UIViewController {
    var didSelectAction: ((_ controller: SelectIconViewController, _ iconId: Int) -> Void)?

    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        let width = 60
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: width, height: width)
        flowLayout.minimumInteritemSpacing = 8
        flowLayout.minimumLineSpacing = 8
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        if #available(iOS 13.0, *) {
            collectionView.backgroundColor = UIColor.systemBackground
        } else {
            collectionView.backgroundColor = UIColor.white
        }
        view.addSubview(collectionView)
        collectionView.register(IconCollectionViewCell.self, forCellWithReuseIdentifier: "IconCollectionViewCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension SelectIconViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return Icons.iconNames.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IconCollectionViewCell", for: indexPath) as! IconCollectionViewCell
        cell.iconImageView.image = UIImage(named: Icons.iconNames[indexPath.row])
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectAction?(self, indexPath.row)
        navigationController?.popViewController(animated: true)
    }
}
