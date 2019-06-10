//
//  NodeTableViewCell.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import SnapKit

class NodeTableViewCell: UITableViewCell {
    
    let iconImageView: UIImageView
    let nameLabel: UILabel
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        iconImageView = UIImageView()
        nameLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(iconImageView)
        if #available(iOS 13.0, *) {
//            iconImageView.tintColor = UIColor.label
        } else {
            iconImageView.tintColor = UIColor.black
        }
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        self.contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
