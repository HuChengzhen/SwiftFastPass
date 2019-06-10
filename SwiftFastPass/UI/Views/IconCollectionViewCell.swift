//
//  IconCollectionViewCell.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import SnapKit

class IconCollectionViewCell: UICollectionViewCell {
    var iconImageView: UIImageView
    
    override init(frame: CGRect) {
        iconImageView = UIImageView()
        super.init(frame: frame)
        
        contentView.addSubview(iconImageView)
        if #available(iOS 13.0, *) {
//            iconImageView.tintColor = UIColor.label
            iconImageView.tintColor = UIColor.black
        } else {
            iconImageView.tintColor = UIColor.black
        }
        
        iconImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
