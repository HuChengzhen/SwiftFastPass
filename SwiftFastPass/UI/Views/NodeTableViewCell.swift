import SnapKit
import UIKit
import KeePassKit

final class NodeTableViewCell: UITableViewCell {

    // 和其它页面统一主色
    private let accentColor = UIColor(red: 0.25, green: 0.49, blue: 1.0, alpha: 1.0)

    /// 卡片容器（圆角 + 阴影）
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = false
        // 阴影尽量轻一点，不要很油腻
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowRadius = 10
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        return v
    }()

    private let iconBackgroundView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.layer.masksToBounds = true
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .label
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = .label
        return label
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false

        contentView.addSubview(cardView)
        cardView.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(chevronImageView)

        // 卡片四周留白
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }

        iconBackgroundView.snp.makeConstraints { make in
            make.left.equalTo(cardView.snp.left).offset(16)
            make.centerY.equalTo(cardView.snp.centerY)
            make.width.height.equalTo(32)
        }

        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(6)
        }

        chevronImageView.snp.makeConstraints { make in
            make.right.equalTo(cardView.snp.right).offset(-16)
            make.centerY.equalTo(cardView.snp.centerY)
            make.width.height.equalTo(14)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconBackgroundView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(chevronImageView.snp.left).offset(-8)
            make.centerY.equalTo(cardView.snp.centerY)
        }

        // 选中/高亮时做一个轻微的背景变化
        let selectedBg = UIView()
        selectedBg.backgroundColor = .clear
        selectedBackgroundView = selectedBg
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let alpha: CGFloat = highlighted ? 0.9 : 1.0
        if animated {
            UIView.animate(withDuration: 0.15) {
                self.cardView.alpha = alpha
            }
        } else {
            cardView.alpha = alpha
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // MARK: - Public

    func configure(with node: KPKNode) {
        titleLabel.text = node.title
        iconImageView.image = node.image()

        if node.usesSFSymbolIcon() {
            // 让 SF Symbols 图标和自选颜色保持一致的浅底色
            let tint = IconColors.resolvedColor(for: node.iconColorId)
            iconBackgroundView.backgroundColor = tint.withAlphaComponent(0.14)
            iconImageView.tintColor = tint
        } else {
            // 旧版或自定义图标维持中性底色，避免复用残留
            iconBackgroundView.backgroundColor = UIColor.label.withAlphaComponent(0.06)
            iconImageView.tintColor = nil
        }
    }
}
