import StoreKit
import UIKit

final class SubscriptionPaywallViewController: UIViewController {
    // MARK: - Section Model (同原逻辑的概念，只是 UI 不再用 UITableView 的 section)
    private enum Section: Int, CaseIterable {
        case status
        case features
        case products
    }

    // MARK: - Data

    private let featureList: [SubscriptionFeature]
    private var products: [SubscriptionProduct] = []
    private var entitlement: SubscriptionEntitlement = .empty()
    private let subscriptionManager: SubscriptionManager

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Hero 顶部区域
    private let heroContainer = UIView()
    private let heroIconView = UIImageView()
    private let heroTitleLabel = UILabel()
    private let heroSubtitleLabel = UILabel()
    private let heroGradientLayer = CAGradientLayer()
    private let restoreButton = UIButton(type: .custom)

    // “你的方案 / 状态” 卡片
    private let planTitleLabel = UILabel()
    private let planCardView = UIView()
    private let planHeadlineLabel = UILabel()
    private let planDetailLabel = UILabel()

    // Features 区域
    private let reasonsTitleLabel = UILabel()
    private let reasonsStackView = UIStackView()

    // Products 区域
    private let pricingTitleLabel = UILabel()
    private let productsStackView = UIStackView()

    // 底部订阅按钮
    private let subscribeButton = UIButton(type: .system)

    // Loading
    private lazy var loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let accentColor = UIColor(red: 0.25, green: 0.49, blue: 1.0, alpha: 1.0) // #3F7CFF

    // MARK: - Init

    init(subscriptionManager: SubscriptionManager = .shared,
         features: [SubscriptionFeature] = SubscriptionFeature.default)
    {
        self.subscriptionManager = subscriptionManager
        self.featureList = features
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let sheet = self.sheetPresentationController {
            sheet.prefersGrabberVisible = true
        }
    }
    
    private let grabberView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.systemGray3
        v.layer.cornerRadius = 3
        return v
    }()
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradientLayer.frame = heroContainer.bounds
        restoreButton.layer.cornerRadius = restoreButton.bounds.height / 2   // 完美胶囊
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        title = NSLocalizedString("FastPass Pro", comment: "")

        subscriptionManager.addObserver(self)

        setupScrollView()
        setupGrabber()
        setupHeroSection()
        setupPlanSection()
        setupReasonsSection()
        setupProductsSection()
        setupSubscribeButton()
        setupLoading()

        // 下拉刷新
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTriggered), for: .valueChanged)
        scrollView.refreshControl = refreshControl

        // 业务逻辑保持不变
        loadingView.startAnimating()
        subscriptionManager.start()
        subscriptionManager.fetchProductsIfNeeded(force: true)
    }

    private func setupGrabber() {
        view.addSubview(grabberView)

        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            grabberView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: 36),
            grabberView.heightAnchor.constraint(equalToConstant: 5)
        ])
    }
    
    deinit {
        subscriptionManager.removeObserver(self)
    }

    // MARK: - Setup UI

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.alwaysBounceVertical = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupHeroSection() {
        heroContainer.translatesAutoresizingMaskIntoConstraints = false
        heroIconView.translatesAutoresizingMaskIntoConstraints = false
        heroTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        heroSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        restoreButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(heroContainer)
        heroContainer.addSubview(heroIconView)
        heroContainer.addSubview(heroTitleLabel)
        heroContainer.addSubview(heroSubtitleLabel)
        heroContainer.addSubview(restoreButton)

        // 渐变背景
        heroGradientLayer.colors = [
            accentColor.withAlphaComponent(0.9).cgColor,
            accentColor.withAlphaComponent(0.6).cgColor
        ]
        heroGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        heroGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        heroGradientLayer.cornerRadius = 24
        heroContainer.layer.insertSublayer(heroGradientLayer, at: 0)

        heroContainer.layer.cornerRadius = 24
        heroContainer.layer.masksToBounds = true

        // 图标
        heroIconView.image = UIImage(systemName: "key.fill")
        heroIconView.tintColor = .white
        heroIconView.contentMode = .scaleAspectFit

        // 标题
        heroTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        heroTitleLabel.textColor = .white
        heroTitleLabel.text = NSLocalizedString("FastPass Pro", comment: "")

        // 副标题
        heroSubtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        heroSubtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        heroSubtitleLabel.numberOfLines = 0
        heroSubtitleLabel.text = NSLocalizedString("AutoFill, unlimited vaults, and secure iCloud sync in one simple subscription.", comment: "")

        // Restore 按钮（右上角白色小胶囊）
        restoreButton.setTitle(NSLocalizedString("Restore", comment: ""), for: .normal)
        restoreButton.setTitleColor(accentColor, for: .normal)
        restoreButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        restoreButton.backgroundColor = .white
        restoreButton.layer.cornerRadius = 16
        restoreButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            heroContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            heroContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            heroIconView.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 16),
            heroIconView.topAnchor.constraint(equalTo: heroContainer.topAnchor, constant: 18),
            heroIconView.widthAnchor.constraint(equalToConstant: 36),
            heroIconView.heightAnchor.constraint(equalTo: heroIconView.widthAnchor),

            restoreButton.centerYAnchor.constraint(equalTo: heroIconView.centerYAnchor),
            restoreButton.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor, constant: -16),

            heroTitleLabel.topAnchor.constraint(equalTo: heroIconView.bottomAnchor, constant: 16),
            heroTitleLabel.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 16),
            heroTitleLabel.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor, constant: -16),

            heroSubtitleLabel.topAnchor.constraint(equalTo: heroTitleLabel.bottomAnchor, constant: 8),
            heroSubtitleLabel.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 16),
            heroSubtitleLabel.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor, constant: -16),
            heroSubtitleLabel.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: -18)
        ])
    }

    private func setupPlanSection() {
        planTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        planCardView.translatesAutoresizingMaskIntoConstraints = false
        planHeadlineLabel.translatesAutoresizingMaskIntoConstraints = false
        planDetailLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(planTitleLabel)
        contentView.addSubview(planCardView)

        planCardView.addSubview(planHeadlineLabel)
        planCardView.addSubview(planDetailLabel)

        planTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        planTitleLabel.textColor = .label
        planTitleLabel.text = NSLocalizedString("Your FastPass Plan", comment: "")

        planCardView.backgroundColor = .secondarySystemBackground
        planCardView.layer.cornerRadius = 16
        planCardView.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        planCardView.layer.shadowOpacity = 1
        planCardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        planCardView.layer.shadowRadius = 10

        planHeadlineLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        planHeadlineLabel.textColor = .label
        planHeadlineLabel.numberOfLines = 0

        planDetailLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        planDetailLabel.textColor = .secondaryLabel
        planDetailLabel.numberOfLines = 0

        // 初始状态（未拿到 entitlement 时）
        let initialStatus = statusText(for: entitlement)
        planHeadlineLabel.text = initialStatus.title
        planDetailLabel.text = initialStatus.detail

        NSLayoutConstraint.activate([
            planTitleLabel.topAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: 24),
            planTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            planTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            planCardView.topAnchor.constraint(equalTo: planTitleLabel.bottomAnchor, constant: 8),
            planCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            planCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            planHeadlineLabel.topAnchor.constraint(equalTo: planCardView.topAnchor, constant: 16),
            planHeadlineLabel.leadingAnchor.constraint(equalTo: planCardView.leadingAnchor, constant: 16),
            planHeadlineLabel.trailingAnchor.constraint(equalTo: planCardView.trailingAnchor, constant: -16),

            planDetailLabel.topAnchor.constraint(equalTo: planHeadlineLabel.bottomAnchor, constant: 6),
            planDetailLabel.leadingAnchor.constraint(equalTo: planCardView.leadingAnchor, constant: 16),
            planDetailLabel.trailingAnchor.constraint(equalTo: planCardView.trailingAnchor, constant: -16),
            planDetailLabel.bottomAnchor.constraint(equalTo: planCardView.bottomAnchor, constant: -14)
        ])
    }

    private func setupReasonsSection() {
        reasonsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        reasonsStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(reasonsTitleLabel)
        contentView.addSubview(reasonsStackView)

        reasonsTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        reasonsTitleLabel.textColor = .label
        reasonsTitleLabel.text = NSLocalizedString("Why Upgrade to Pro", comment: "")

        reasonsStackView.axis = .vertical
        reasonsStackView.spacing = 10
        reasonsStackView.alignment = .fill
        reasonsStackView.distribution = .fill

        // 根据 featureList 生成卡片
        for feature in featureList {
            let card = makeFeatureCard(feature: feature)
            reasonsStackView.addArrangedSubview(card)
        }

        NSLayoutConstraint.activate([
            reasonsTitleLabel.topAnchor.constraint(equalTo: planCardView.bottomAnchor, constant: 24),
            reasonsTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            reasonsTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            reasonsStackView.topAnchor.constraint(equalTo: reasonsTitleLabel.bottomAnchor, constant: 12),
            reasonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            reasonsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    private func setupProductsSection() {
        pricingTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        productsStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(pricingTitleLabel)
        contentView.addSubview(productsStackView)

        pricingTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        pricingTitleLabel.textColor = .label
        pricingTitleLabel.text = NSLocalizedString("FastPass Pro Monthly", comment: "")

        productsStackView.axis = .vertical
        productsStackView.spacing = 10
        productsStackView.alignment = .fill
        productsStackView.distribution = .fill

        // 初始是“Loading...”
        reloadProductsUI()

        NSLayoutConstraint.activate([
            pricingTitleLabel.topAnchor.constraint(equalTo: reasonsStackView.bottomAnchor, constant: 24),
            pricingTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            pricingTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            productsStackView.topAnchor.constraint(equalTo: pricingTitleLabel.bottomAnchor, constant: 8),
            productsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    private func setupSubscribeButton() {
        subscribeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subscribeButton)

        subscribeButton.setTitle(NSLocalizedString("Subscribe to FastPass Pro", comment: ""), for: .normal)
        subscribeButton.setTitleColor(.white, for: .normal)
        subscribeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        subscribeButton.backgroundColor = accentColor
        subscribeButton.layer.cornerRadius = 18
        subscribeButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        subscribeButton.addTarget(self, action: #selector(primarySubscribeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            subscribeButton.topAnchor.constraint(equalTo: productsStackView.bottomAnchor, constant: 24),
            subscribeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subscribeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            subscribeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }

    private func setupLoading() {
        view.addSubview(loadingView)

        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - UI Helpers

    private func makeFeatureCard(feature: SubscriptionFeature) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        let detailLabel = UILabel()

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(detailLabel)

        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 14

        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.text = feature.title

        detailLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        detailLabel.text = feature.detail

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            detailLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            detailLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])

        return container
    }

    private func reloadProductsUI() {
        // 清空旧的
        productsStackView.arrangedSubviews.forEach { view in
            productsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        if products.isEmpty {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = .secondarySystemBackground
            container.layer.cornerRadius = 14

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            label.text = NSLocalizedString("Loading...", comment: "")

            container.addSubview(label)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
            ])

            productsStackView.addArrangedSubview(container)
            return
        }

        for (index, product) in products.enumerated() {
            let card = makeProductCard(for: product, index: index)
            productsStackView.addArrangedSubview(card)
        }

        // 更新主按钮文案（默认取第一个订阅）
        if let first = products.first {
            let title = String(
                format: NSLocalizedString("Subscribe • %@ / month", comment: ""),
                first.localizedPrice
            )
            subscribeButton.setTitle(title, for: .normal)
        }
    }

    private func makeProductCard(for product: SubscriptionProduct, index: Int) -> UIControl {
        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.backgroundColor = .secondarySystemBackground
        control.layer.cornerRadius = 14
        control.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        control.layer.shadowOpacity = 1
        control.layer.shadowOffset = CGSize(width: 0, height: 3)
        control.layer.shadowRadius = 8
        control.tag = index

        let nameLabel = UILabel()
        let subtitleLabel = UILabel()
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        chevron.translatesAutoresizingMaskIntoConstraints = false

        control.addSubview(nameLabel)
        control.addSubview(subtitleLabel)
        control.addSubview(chevron)

        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.text = product.marketingTitle

        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        let subtitle = String(
            format: NSLocalizedString("%@ per month • %@", comment: ""),
            product.localizedPrice,
            product.callToAction
        )
        subtitleLabel.text = subtitle

        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: control.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -14),

            chevron.centerYAnchor.constraint(equalTo: control.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -14),
            chevron.widthAnchor.constraint(equalToConstant: 10),
            chevron.heightAnchor.constraint(equalToConstant: 16)
        ])

        control.addTarget(self, action: #selector(productCardTapped(_:)), for: .touchUpInside)
        return control
    }

    private func updateStatusUI() {
        let description = statusText(for: entitlement)
        planHeadlineLabel.text = description.title
        planDetailLabel.text = description.detail
    }

    private func endLoading() {
        loadingView.stopAnimating()
        if let rc = scrollView.refreshControl, rc.isRefreshing {
            rc.endRefreshing()
        }
    }

    // MARK: - Status Text (完全沿用你原来的逻辑)

    private func statusText(for entitlement: SubscriptionEntitlement) -> (title: String, detail: String) {
        if entitlement.isActive {
            let expiration: String
            if let expiresAt = entitlement.expiresAt {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                expiration = formatter.string(from: expiresAt)
            } else {
                expiration = NSLocalizedString("No expiration date", comment: "")
            }
            return (NSLocalizedString("FastPass Pro Active", comment: ""),
                    String(format: NSLocalizedString("Renews automatically on %@", comment: ""), expiration))
        }
        switch entitlement.status {
        case .unknown:
            return (NSLocalizedString("Unlock AutoFill Protection", comment: ""),
                    NSLocalizedString("Subscribe to FastPass Pro Monthly to enable AutoFill, unlimited vaults, and secure sync.", comment: ""))
        case .gracePeriod:
            return (NSLocalizedString("Payment Issue Detected", comment: ""),
                    NSLocalizedString("Update your App Store billing info to keep AutoFill, sync, and priority support running.", comment: ""))
        case .expired:
            return (NSLocalizedString("FastPass Pro Expired", comment: ""),
                    NSLocalizedString("Restart your monthly plan to restore AutoFill and secure sync.", comment: ""))
        case .active:
            return (NSLocalizedString("FastPass Pro Active", comment: ""), "")
        }
    }

    // MARK: - Actions

    @objc private func refreshTriggered() {
        subscriptionManager.fetchProductsIfNeeded(force: true)
    }

    @objc private func restoreTapped() {
        subscriptionManager.restorePurchases()
    }

    // 底部大按钮：默认购买第一个 Product
    @objc private func primarySubscribeTapped() {
        guard let first = products.first else { return }
        subscriptionManager.purchase(productID: first.identifier)
    }

    @objc private func productCardTapped(_ sender: UIControl) {
        let index = sender.tag
        guard index >= 0, index < products.count else { return }
        let product = products[index]
        subscriptionManager.purchase(productID: product.identifier)
    }
}

// MARK: - SubscriptionManagerObserver

extension SubscriptionPaywallViewController: SubscriptionManagerObserver {
    func subscriptionManager(_ manager: SubscriptionManager, didUpdateProducts products: [SubscriptionProduct]) {
        DispatchQueue.main.async {
            self.products = products
            self.endLoading()
            self.reloadProductsUI()
        }
    }

    func subscriptionManager(_ manager: SubscriptionManager, didUpdate entitlement: SubscriptionEntitlement) {
        DispatchQueue.main.async {
            self.entitlement = entitlement
            self.endLoading()
            self.updateStatusUI()
        }
    }

    func subscriptionManager(_ manager: SubscriptionManager, didFailWith error: Error) {
        DispatchQueue.main.async {
            self.endLoading()
            let alert = UIAlertController(title: NSLocalizedString("Purchase Failed", comment: ""),
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel))
            self.present(alert, animated: true)
        }
    }
}
