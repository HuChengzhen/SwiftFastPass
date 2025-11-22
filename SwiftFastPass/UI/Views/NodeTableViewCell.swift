//
//  NodeTableViewCell.swift
//  SwiftFastPass
//

import SnapKit
import UIKit
import KeePassKit

final class NodeTableViewCell: UITableViewCell {

    let iconContainerView = UIView()
    let iconImageView = UIImageView()
    let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .default
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // 圆角图标容器
        iconContainerView.layer.cornerRadius = 12
        iconContainerView.layer.masksToBounds = true
        iconContainerView.backgroundColor = UIColor.secondarySystemBackground
        contentView.addSubview(iconContainerView)

        iconContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        // 图标
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .label
        iconContainerView.addSubview(iconImageView)

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }

        // 标题
        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(iconContainerView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 统一配置节点：根据 iconColorId 决定颜色
    func configure(with node: KPKNode) {
        nameLabel.text = node.title

        let baseImage = node.image()
        let color = IconColors.resolvedColor(for: node.iconColorId)

        if #available(iOS 13.0, *),
           Icons.sfSymbolNames.indices.contains(node.iconId) {
            iconContainerView.backgroundColor = color.withAlphaComponent(0.12)
            iconImageView.image = baseImage.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = color
        } else {
            iconContainerView.backgroundColor = UIColor.secondarySystemBackground
            iconImageView.image = baseImage.withRenderingMode(.alwaysOriginal)
            iconImageView.tintColor = .label
        }
    }
}
