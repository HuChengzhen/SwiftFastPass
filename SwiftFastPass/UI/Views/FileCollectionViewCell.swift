//
//  FileCollectionViewCell.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import SnapKit

class FileCollectionViewCell: CardCollectionViewCell {
    let fileImageView: UIImageView
    let nameLabel: UILabel
    
    override init(frame: CGRect) {
        fileImageView = UIImageView()
        nameLabel = UILabel()
        super.init(frame: frame)
        
        cardView.addSubview(fileImageView)
        if #available(iOS 13.0, *) {
//            fileImageView.tintColor = UIColor.label
        } else {
            fileImageView.tintColor = UIColor.black
        }
        
        fileImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(44)
            make.left.equalTo(cardView).offset(8)
            make.centerY.equalTo(cardView)
        }
        
        cardView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(fileImageView.snp.right).offset(8)
            make.right.equalTo(cardView).offset(-8)
            make.centerY.equalTo(cardView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
