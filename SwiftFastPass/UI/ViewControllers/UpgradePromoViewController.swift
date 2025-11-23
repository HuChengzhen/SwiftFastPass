import SnapKit
import UIKit

final class UpgradePromoViewController: UIViewController {
    var onSubscribeTapped: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let heroContainer = UIView()

    /// FastPass 主题蓝色（与你现有界面保持一致）
    private let accentColor = UIColor(red: 0.24, green: 0.53, blue: 0.99, alpha: 1.0) // #3D86FC

    /// hero 卡片的浅蓝背景
    private let heroBackgroundColor = UIColor(red: 0.93, green: 0.97, blue: 1.0, alpha: 1.0) // 超浅蓝，非常干净

    private lazy var subscribeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Unlock FastPass Pro", comment: ""), for: .normal)
        button.backgroundColor = accentColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 14
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Skip for now", comment: ""), for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupScrollView()
        setupTopMessage()
        setupHero()
        setupBenefitsCard()
        setupButtons()
    }

    // MARK: - ScrollView

    private func setupScrollView() {
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.alignment = .fill
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 24, bottom: 32, right: 24)
        
        // 🔴 之前遗漏了这一段，必须有：
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - 顶部提示文字

    private func setupTopMessage() {
        let label = UILabel()
        label.text = NSLocalizedString("Thanks for staying with us", comment: "")
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = accentColor
        label.textAlignment = .center
        label.numberOfLines = 0

        stackView.addArrangedSubview(label)
        
        // 关键：让顶部文字和 hero 拉开一点距离
        stackView.setCustomSpacing(18, after: label)
    }

    // MARK: - Hero 区

    private func setupHero() {
        heroContainer.layer.cornerRadius = 24
        heroContainer.backgroundColor = heroBackgroundColor

        let badge = UILabel()
        badge.text = NSLocalizedString("FastPass Pro", comment: "")
        badge.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        badge.textColor = accentColor
        badge.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        badge.textAlignment = .center
        badge.layer.cornerRadius = 12
        badge.layer.masksToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("A more secure experience", comment: "Upgrade promo hero title")
        titleLabel.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = NSLocalizedString("Keep your vaults backed up, fill faster across apps, and get priority support.", comment: "Upgrade promo hero subtitle")
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        let iconBackdrop = UIView()
        iconBackdrop.backgroundColor = UIColor.white
        iconBackdrop.layer.cornerRadius = 40

        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        icon.tintColor = accentColor
        icon.contentMode = .scaleAspectFit

        heroContainer.addSubview(iconBackdrop)
        heroContainer.addSubview(badge)
        heroContainer.addSubview(titleLabel)
        heroContainer.addSubview(subtitleLabel)
        iconBackdrop.addSubview(icon)

        // 右侧图标区域
        iconBackdrop.snp.makeConstraints {
            $0.width.height.equalTo(80)
            $0.right.equalToSuperview().offset(-18)
            $0.centerY.equalToSuperview().offset(6)
            $0.top.greaterThanOrEqualToSuperview().offset(18)
        }

        icon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(38)
        }

        // 左侧文字区域：右边都贴到 icon 的左边，留出 12pt 间距
        badge.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.left.equalToSuperview().offset(18)
            $0.right.lessThanOrEqualTo(iconBackdrop.snp.left).offset(-12)
            $0.height.equalTo(26)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(badge.snp.bottom).offset(14)
            $0.left.equalTo(badge)
            $0.right.lessThanOrEqualTo(iconBackdrop.snp.left).offset(-12)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.left.equalTo(badge)
            $0.right.lessThanOrEqualTo(iconBackdrop.snp.left).offset(-12)
            $0.bottom.lessThanOrEqualToSuperview().offset(-18)
        }

        heroContainer.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(180)
        }

        stackView.addArrangedSubview(heroContainer)
    }


    // MARK: - Benefits 卡片

    private func setupBenefitsCard() {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 20

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16

        stack.addArrangedSubview(makeFeature(
            icon: "icloud.and.arrow.up.fill",
            title: NSLocalizedString("Protect every vault", comment: ""),
            desc: NSLocalizedString("Encrypted vaults stored in iCloud Drive so every change is backed up.", comment: "")
        ))

        stack.addArrangedSubview(makeFeature(
            icon: "wand.and.stars",
            title: NSLocalizedString("AutoFill everywhere", comment: ""),
            desc: NSLocalizedString("One-tap fill-ins in Safari, apps, and the FastPass AutoFill extension.", comment: "")
        ))

        stack.addArrangedSubview(makeFeature(
            icon: "sparkles.rectangle.stack",
            title: NSLocalizedString("Unlimited vaults", comment: ""),
            desc: NSLocalizedString("Create as many databases as you need with Pro unlocked.", comment: "")
        ))

        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(20) }

        stackView.addArrangedSubview(card)
    }

    private func makeFeature(icon: String, title: String, desc: String) -> UIView {
        let container = UIView()

        let wrap = UIView()
        wrap.backgroundColor = accentColor.withAlphaComponent(0.12)
        wrap.layer.cornerRadius = 14

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = accentColor

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0

        let v = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        v.axis = .vertical
        v.spacing = 3

        container.addSubview(wrap)
        wrap.addSubview(iconView)
        container.addSubview(v)

        wrap.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
            make.bottom.lessThanOrEqualToSuperview()
        }

        iconView.snp.makeConstraints { $0.center.equalToSuperview() }

        v.snp.makeConstraints { make in
            make.left.equalTo(wrap.snp.right).offset(12)
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        return container
    }

    // MARK: - Buttons

    private func setupButtons() {
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 14

        buttonStack.addArrangedSubview(subscribeButton)
        buttonStack.addArrangedSubview(closeButton)

        subscribeButton.snp.makeConstraints { $0.height.equalTo(52) }

        stackView.addArrangedSubview(buttonStack)
    }

    // MARK: - Actions

    @objc private func subscribeTapped() {
        UpgradeExperience.markSeen()
        dismiss(animated: true) { [weak self] in
            self?.onSubscribeTapped?()
        }
    }

    @objc private func closeTapped() {
        UpgradeExperience.markSeen()
        dismiss(animated: true)
    }
}
