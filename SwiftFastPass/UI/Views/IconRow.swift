//
//  IconRow.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2025/11/23.
//  Copyright © 2025 huchengzhen. All rights reserved.
//

import Eureka
import UIKit

final class IconCell: Cell<UIImage>, CellType {

    private let titleLabel = UILabel()
    private let iconView = UIImageView()

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    internal override func setup() {
        selectionStyle = .default

        // 禁用系统自带 imageView / textLabel
        textLabel?.isHidden = true
        detailTextLabel?.isHidden = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.text = NSLocalizedString("Icon", comment: "")

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit

        contentView.addSubview(titleLabel)
        contentView.addSubview(iconView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            iconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: iconView.leadingAnchor, constant: -8)
        ])
    }

    override func update() {
        super.update()
        iconView.image = row.value
    }
}

final class IconRow: Row<IconCell>, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
        cellProvider = CellProvider<IconCell>()
    }
}
