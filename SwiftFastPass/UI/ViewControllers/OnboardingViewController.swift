import SnapKit
import UIKit

final class OnboardingViewController: UIViewController {
    var onPrimaryAction: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let heroContainer = UIView()
    private let heroGradient = CAGradientLayer()
    private let accentColor = UIColor(red: 0.24, green: 0.53, blue: 0.99, alpha: 1.0) // #3D86FC

    private let privacyBadgeLabel: UILabel = {
        let label = UILabel()
        // 🔥 在文字前后各加一个空格，保证左右一定有留白
        let text = NSLocalizedString("Private by design", comment: "")
        label.text = "  " + text + "  "
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(red: 0.24, green: 0.53, blue: 0.99, alpha: 1.0)
        label.backgroundColor = .white.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.layer.masksToBounds = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()


    
    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = accentColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 14
        button.layer.masksToBounds = true
        button.setTitle(NSLocalizedString("Create or import", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        return button
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.setTitle(NSLocalizedString("Maybe later", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupScrollView()
        setupHero()
        setupProPromoCard()
        setupFeatureCard()
        setupButtons()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradient.frame = heroContainer.bounds
        // ✅ 关键：根据最终高度设置圆角，真正的“胶囊形”
        privacyBadgeLabel.layer.cornerRadius = privacyBadgeLabel.bounds.height / 2
    }

    // MARK: - Setup

    private func setupProPromoCard() {
        let card = UIView()
        card.backgroundColor = UIColor.systemBackground
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = true
        card.layer.borderWidth = 1
        card.layer.borderColor = accentColor.withAlphaComponent(0.15).cgColor

        let iconWrap = UIView()
        iconWrap.backgroundColor = accentColor.withAlphaComponent(0.12)
        iconWrap.layer.cornerRadius = 16
        iconWrap.layer.masksToBounds = true

        let iconView = UIImageView(image: UIImage(systemName: "crown.fill"))
        iconView.tintColor = accentColor
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("Upgrade to FastPass Pro", comment: "")
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = NSLocalizedString(
            "Sync across devices, unlock advanced AutoFill, and support ongoing development.",
            comment: ""
        )
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        let learnMoreButton = UIButton(type: .system)
        learnMoreButton.setTitle(NSLocalizedString("Learn more about Pro", comment: ""), for: .normal)
        learnMoreButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        learnMoreButton.setTitleColor(.white, for: .normal)
        learnMoreButton.backgroundColor = accentColor
        learnMoreButton.layer.cornerRadius = 10
        learnMoreButton.layer.masksToBounds = true
        learnMoreButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        learnMoreButton.addTarget(self, action: #selector(showProTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, learnMoreButton])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.alignment = .leading
        textStack.setCustomSpacing(10, after: subtitleLabel)

        card.addSubview(iconWrap)
        card.addSubview(iconView)
        card.addSubview(textStack)

        iconWrap.snp.makeConstraints { make in
            make.width.height.equalTo(48)
            make.left.top.equalToSuperview().inset(18)
        }

        iconView.snp.makeConstraints { make in
            make.center.equalTo(iconWrap)
            make.width.height.equalTo(26)
        }

        textStack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.left.equalTo(iconWrap.snp.right).offset(14)
            make.right.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().inset(16)
        }

        // 让按钮不要占满整行，只按内容宽度
        learnMoreButton.snp.makeConstraints { make in
            make.height.equalTo(32)
        }

        stackView.addArrangedSubview(card)
    }

    
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
        stackView.spacing = 22
        stackView.alignment = .fill
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 32, left: 24, bottom: 32, right: 24)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupHero() {
        heroContainer.layer.cornerRadius = 24
        heroContainer.layer.masksToBounds = true
        heroContainer.backgroundColor = accentColor

        heroGradient.colors = [
            accentColor.withAlphaComponent(0.95).cgColor,
            accentColor.withAlphaComponent(0.75).cgColor,
            UIColor.systemBackground.withAlphaComponent(0.08).cgColor
        ]
        heroGradient.startPoint = CGPoint(x: 0, y: 0)
        heroGradient.endPoint = CGPoint(x: 1, y: 1)
        heroContainer.layer.insertSublayer(heroGradient, at: 0)

        // ✅ 使用属性 privacyBadgeLabel
        let badgeContainer = UIView()
        badgeContainer.backgroundColor = .clear
        badgeContainer.layer.masksToBounds = true

        badgeContainer.addSubview(privacyBadgeLabel)
        privacyBadgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: 7, left: 32, bottom: 7, right: 32)   // ⬅️ 这里从 18 改成 32
            )
            make.height.greaterThanOrEqualTo(30)
        }



        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("Welcome to FastPass", comment: "")
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = NSLocalizedString(
            "Protect your KeePass vaults, sync securely, and keep autofill close at hand.",
            comment: ""
        )
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.numberOfLines = 0

        let iconBackdrop = UIView()
        iconBackdrop.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        iconBackdrop.layer.cornerRadius = 42
        iconBackdrop.layer.masksToBounds = true

        let iconView = UIImageView(image: UIImage(systemName: "seal.fill"))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        heroContainer.addSubview(badgeContainer)
        heroContainer.addSubview(titleLabel)
        heroContainer.addSubview(subtitleLabel)
        heroContainer.addSubview(iconBackdrop)
        heroContainer.addSubview(iconView)

        badgeContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.left.equalToSuperview().offset(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(badgeContainer.snp.bottom).offset(16)
            make.left.equalTo(badgeContainer)
            make.right.lessThanOrEqualToSuperview().offset(-24)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(badgeContainer)
            make.right.equalToSuperview().offset(-24)
        }

        iconBackdrop.snp.makeConstraints { make in
            make.width.height.equalTo(84)
            make.right.equalToSuperview().offset(-24)
            make.bottom.equalToSuperview().offset(-24)
        }

        iconView.snp.makeConstraints { make in
            make.center.equalTo(iconBackdrop)
            make.width.height.equalTo(48)
        }

        heroContainer.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(260)
        }

        stackView.addArrangedSubview(heroContainer)
    }

    private func setupFeatureCard() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let card = UIVisualEffectView(effect: blurEffect)
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = true

        let cardContent = UIView()
        cardContent.backgroundColor = UIColor.secondarySystemGroupedBackground.withAlphaComponent(0.75)
        cardContent.layer.cornerRadius = 20
        cardContent.layer.masksToBounds = true

        let featuresStack = UIStackView()
        featuresStack.axis = .vertical
        featuresStack.spacing = 14
        featuresStack.alignment = .fill

        featuresStack.addArrangedSubview(makeFeatureRow(
            iconName: "tray.and.arrow.down.fill",
            title: NSLocalizedString("Bring your KeePass vaults", comment: ""),
            detail: NSLocalizedString("Open existing .kdbx files or create a brand-new vault in seconds.", comment: "")
        ))
        featuresStack.addArrangedSubview(makeFeatureRow(
            iconName: "sparkles",
            title: NSLocalizedString("Generate stronger passwords", comment: ""),
            detail: NSLocalizedString("Use the built-in creator to craft long, unique passwords tailored to your rules.", comment: "")
        ))
        featuresStack.addArrangedSubview(makeFeatureRow(
            iconName: "faceid",
            title: NSLocalizedString("Unlock with biometrics", comment: ""),
            detail: NSLocalizedString("Face ID / Touch ID keeps sign-in fast without compromising security.", comment: "")
        ))

        card.contentView.addSubview(cardContent)
        cardContent.addSubview(featuresStack)

        cardContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        featuresStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        stackView.addArrangedSubview(card)
    }

    private func setupButtons() {
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.alignment = .fill

        buttonStack.addArrangedSubview(startButton)
        buttonStack.addArrangedSubview(skipButton)

        startButton.snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        stackView.addArrangedSubview(buttonStack)
    }

    private func makeFeatureRow(iconName: String, title: String, detail: String) -> UIView {
        let container = UIView()

        let iconWrap = UIView()
        iconWrap.backgroundColor = accentColor.withAlphaComponent(0.12)
        iconWrap.layer.cornerRadius = 14
        iconWrap.layer.masksToBounds = true

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = accentColor
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.text = title
        titleLabel.numberOfLines = 0

        let detailLabel = UILabel()
        detailLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        detailLabel.textColor = .secondaryLabel
        detailLabel.text = detail
        detailLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        container.addSubview(iconWrap)
        container.addSubview(iconView)
        container.addSubview(textStack)

        iconWrap.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.left.top.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.center.equalTo(iconWrap)
            make.width.height.equalTo(22)
        }

        textStack.snp.makeConstraints { make in
            make.left.equalTo(iconWrap.snp.right).offset(12)
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        return container
    }

    // MARK: - Actions

    @objc private func startTapped() {
        OnboardingExperience.markSeen()
        UpgradeExperience.markSeen()
        let action = onPrimaryAction
        dismiss(animated: true) {
            action?()
        }
    }

    @objc private func skipTapped() {
        OnboardingExperience.markSeen()
        UpgradeExperience.markSeen()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func showProTapped() {
        // 根据你的项目实际改，这里假设你已经有 SubscriptionPaywallViewController
        let paywall = SubscriptionPaywallViewController()
        present(paywall, animated: true, completion: nil)
    }

}
