//
//  IconCollectionViewCell.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen.
//

import SnapKit
import UIKit

class IconCollectionViewCell: UICollectionViewCell {

    let iconImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Cell 本身透明
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // 图标配置
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .label

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)   // 给 10pt padding 更美观
        }

        // 美化选择效果
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
    }

    /// 配置图标（SF Symbol 名字 + 颜色 + 是否选中）
    func configure(symbolName: String, color: UIColor, selected: Bool) {
        iconImageView.image = UIImage(systemName: symbolName)
        iconImageView.tintColor = color

        if selected {
            // 选中时的背景（浅色高亮）
            contentView.backgroundColor = color.withAlphaComponent(0.15)
            contentView.layer.borderColor = color.withAlphaComponent(0.5).cgColor
            contentView.layer.borderWidth = 1
        } else {
            contentView.backgroundColor = .clear
            contentView.layer.borderWidth = 0
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
