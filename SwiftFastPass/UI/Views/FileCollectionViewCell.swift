//
//  FileCollectionViewCell.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen.
//

import SnapKit
import UIKit

class FileCollectionViewCell: CardCollectionViewCell {

    let fileImageView = UIImageView()
    let iconBackground = UIView()
    let nameLabel = UILabel()
    private let chevronView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        // 让 cell 自己不要有白底
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        scrollView.backgroundColor = .clear   // 来自 CardCollectionViewCell

        setupCardStyle()
        setupSubviews()
        setupConstraints()
    }

    private func setupCardStyle() {
        // 卡片本身用系统的分组背景色，和整页融在一起
        if #available(iOS 13.0, *) {
            cardView.backgroundColor = UIColor.secondarySystemGroupedBackground
        } else {
            cardView.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        }

        cardView.layer.cornerRadius = 20
        cardView.layer.masksToBounds = false

        // 比较淡的阴影，避免“白砖头”感觉
        cardView.layer.shadowColor = UIColor.black.withAlphaComponent(0.04).cgColor
        cardView.layer.shadowOpacity = 1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
    }

    private func setupSubviews() {
        // 左侧圆形背景
        if #available(iOS 13.0, *) {
            iconBackground.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        } else {
            iconBackground.backgroundColor = UIColor.blue.withAlphaComponent(0.12)
        }
        iconBackground.layer.cornerRadius = 22
        iconBackground.layer.masksToBounds = true
        cardView.addSubview(iconBackground)

        // 图标
        fileImageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            fileImageView.tintColor = .systemBlue
        } else {
            fileImageView.tintColor = .blue
        }
        iconBackground.addSubview(fileImageView)

        // 标题
        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        cardView.addSubview(nameLabel)

        // 右侧箭头
        if #available(iOS 13.0, *) {
            chevronView.image = UIImage(systemName: "chevron.right")
            chevronView.tintColor = .quaternaryLabel
        }
        cardView.addSubview(chevronView)
    }

    private func setupConstraints() {
        iconBackground.snp.makeConstraints { make in
            make.left.equalTo(cardView).offset(16)
            make.centerY.equalTo(cardView)
            make.width.height.equalTo(44)
        }

        fileImageView.snp.makeConstraints { make in
            make.center.equalTo(iconBackground)
            make.width.height.equalTo(24)
        }

        chevronView.snp.makeConstraints { make in
            make.centerY.equalTo(cardView)
            make.right.equalTo(cardView).offset(-16)
            make.width.height.equalTo(16)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(iconBackground.snp.right).offset(14)
            make.right.equalTo(chevronView.snp.left).offset(-10)
            make.centerY.equalTo(cardView)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
