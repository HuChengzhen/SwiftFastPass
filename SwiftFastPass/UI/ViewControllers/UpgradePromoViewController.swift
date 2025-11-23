import SnapKit
import UIKit

final class UpgradePromoViewController: UIViewController {
    var onSubscribeTapped: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let heroContainer = UIView()
    private let heroGradient = CAGradientLayer()
    private let accentColor = UIColor(red: 0.92, green: 0.44, blue: 0.29, alpha: 1.0) // #EA704A

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
        setupHero()
        setupBenefitsCard()
        setupButtons()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradient.frame = heroContainer.bounds
    }

    // MARK: - UI

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

        heroGradient.colors = [
            accentColor.withAlphaComponent(0.95).cgColor,
            accentColor.withAlphaComponent(0.7).cgColor,
            UIColor.systemBackground.withAlphaComponent(0.1).cgColor
        ]
        heroGradient.startPoint = CGPoint(x: 0, y: 0)
        heroGradient.endPoint = CGPoint(x: 1, y: 1)
        heroContainer.layer.insertSublayer(heroGradient, at: 0)

        let badge = UILabel()
        badge.text = NSLocalizedString("Thanks for staying with us", comment: "")
        badge.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        badge.textColor = accentColor
        badge.backgroundColor = .white.withAlphaComponent(0.9)
        badge.textAlignment = .center
        badge.layer.cornerRadius = 12
        badge.layer.masksToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("Upgrade to FastPass Pro", comment: "")
        titleLabel.font = UIFont.systemFont(ofSize: 27, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = NSLocalizedString("Keep your vaults backed up, fill faster across apps, and get priority support.", comment: "")
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.numberOfLines = 0

        let iconBackdrop = UIView()
        iconBackdrop.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        iconBackdrop.layer.cornerRadius = 42
        iconBackdrop.layer.masksToBounds = true

        let iconView = UIImageView(image: UIImage(systemName: "bolt.fill"))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        heroContainer.addSubview(badge)
        heroContainer.addSubview(titleLabel)
        heroContainer.addSubview(subtitleLabel)
        heroContainer.addSubview(iconBackdrop)
        heroContainer.addSubview(iconView)

        badge.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.left.equalToSuperview().offset(24)
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(10)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(badge.snp.bottom).offset(16)
            make.left.equalTo(badge)
            make.right.lessThanOrEqualToSuperview().offset(-24)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(badge)
            make.right.equalToSuperview().offset(-24)
        }

        iconBackdrop.snp.makeConstraints { make in
            make.width.height.equalTo(84)
            make.right.equalToSuperview().offset(-24)
            make.bottom.equalToSuperview().offset(-24)
        }

        iconView.snp.makeConstraints { make in
            make.center.equalTo(iconBackdrop)
            make.width.height.equalTo(44)
        }

        heroContainer.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(260)
        }

        stackView.addArrangedSubview(heroContainer)
    }

    private func setupBenefitsCard() {
        let card = UIView()
        card.backgroundColor = UIColor.secondarySystemGroupedBackground
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = true

        let featuresStack = UIStackView()
        featuresStack.axis = .vertical
        featuresStack.spacing = 14
        featuresStack.alignment = .fill

        featuresStack.addArrangedSubview(makeFeatureRow(
            iconName: "icloud.and.arrow.up.fill",
            title: NSLocalizedString("Protect every vault", comment: ""),
            detail: NSLocalizedString("Encrypted backups in iCloud Drive keep your KeePass files safe across devices.", comment: "")
        ))
        featuresStack.addArrangedSubview(makeFeatureRow(
            iconName: "wand.and.stars",
            title: NSLocalizedString("AutoFill everywhere", comment: ""),
            detail: NSLocalizedString("One-tap fill-ins in Safari, apps, and the FastPass AutoFill extension.", comment: "")
        ))
        featuresStack.addArrangedSubview(makeFeatureRow(
            iconName: "sparkles.rectangle.stack",
            title: NSLocalizedString("Unlimited vaults", comment: ""),
            detail: NSLocalizedString("Create as many databases as you need with Pro unlocked.", comment: "")
        ))

        card.addSubview(featuresStack)
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

        buttonStack.addArrangedSubview(subscribeButton)
        buttonStack.addArrangedSubview(closeButton)

        subscribeButton.snp.makeConstraints { make in
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

    @objc private func subscribeTapped() {
        UpgradeExperience.markSeen()
        dismiss(animated: true) { [weak self] in
            self?.onSubscribeTapped?()
        }
    }

    @objc private func closeTapped() {
        UpgradeExperience.markSeen()
        dismiss(animated: true, completion: nil)
    }
}
