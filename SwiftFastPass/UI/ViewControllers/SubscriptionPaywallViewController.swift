import StoreKit
import UIKit

final class SubscriptionPaywallViewController: UITableViewController {
    private enum Section: Int, CaseIterable {
        case status
        case features
        case products
    }

    private let featureList: [SubscriptionFeature]
    private var products: [SubscriptionProduct] = []
    private var entitlement: SubscriptionEntitlement = .empty()
    private let subscriptionManager: SubscriptionManager

    private lazy var loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    init(subscriptionManager: SubscriptionManager = .shared,
         features: [SubscriptionFeature] = SubscriptionFeature.default)
    {
        self.subscriptionManager = subscriptionManager
        featureList = features
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subscriptionManager.addObserver(self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationItem.title = NSLocalizedString("SwiftFastPass+", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Restore", comment: ""),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(restoreTapped))

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshTriggered), for: .valueChanged)
        tableView.backgroundView = loadingView
        subscriptionManager.start()
        subscriptionManager.fetchProductsIfNeeded(force: true)
    }

    deinit {
        subscriptionManager.removeObserver(self)
    }

    @objc private func refreshTriggered() {
        subscriptionManager.fetchProductsIfNeeded(force: true)
    }

    @objc private func restoreTapped() {
        subscriptionManager.restorePurchases()
    }

    private func endLoading() {
        loadingView.stopAnimating()
        if refreshControl?.isRefreshing == true {
            refreshControl?.endRefreshing()
        }
    }

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
            return (NSLocalizedString("Subscription Active", comment: ""),
                    String(format: NSLocalizedString("Renews on %@", comment: ""), expiration))
        }
        switch entitlement.status {
        case .unknown:
            return (NSLocalizedString("SwiftFastPass Free", comment: ""),
                    NSLocalizedString("Upgrade to unlock AutoFill and premium features.", comment: ""))
        case .gracePeriod:
            return (NSLocalizedString("Subscription Expiring", comment: ""),
                    NSLocalizedString("We could not renew your plan. Please update the payment method to continue enjoying premium features.", comment: ""))
        case .expired:
            return (NSLocalizedString("Subscription Inactive", comment: ""),
                    NSLocalizedString("Renew SwiftFastPass+ to re-enable premium features.", comment: ""))
        case .active:
            return (NSLocalizedString("Subscription Active", comment: ""), "")
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in _: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionKind = Section(rawValue: section) else { return 0 }
        switch sectionKind {
        case .status:
            return 1
        case .features:
            return featureList.count
        case .products:
            return max(products.count, 1)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryType = .none
        cell.selectionStyle = .none
        guard let section = Section(rawValue: indexPath.section) else {
            return cell
        }

        switch section {
        case .status:
            let description = statusText(for: entitlement)
            cell.textLabel?.numberOfLines = 0
            if description.detail.isEmpty {
                cell.textLabel?.text = description.title
            } else {
                cell.textLabel?.text = "\(description.title)\n\(description.detail)"
            }
        case .features:
            let feature = featureList[indexPath.row]
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(feature.title)\n\(feature.detail)"
        case .products:
            if products.isEmpty {
                cell.textLabel?.text = NSLocalizedString("Loading...", comment: "")
                cell.textLabel?.textColor = .secondaryLabel
                return cell
            }
            let product = products[indexPath.row]
            cell.textLabel?.numberOfLines = 0
            let subtitle = "\(product.localizedPrice) • \(product.callToAction)"
            cell.textLabel?.text = "\(product.marketingTitle)\n\(subtitle)"
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        return cell
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionKind = Section(rawValue: section) else { return nil }
        switch sectionKind {
        case .status:
            return NSLocalizedString("Your Plan", comment: "")
        case .features:
            return NSLocalizedString("What's Included", comment: "")
        case .products:
            return NSLocalizedString("Choose a Plan", comment: "")
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section),
              section == .products,
              indexPath.row < products.count else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        let product = products[indexPath.row]
        subscriptionManager.purchase(productID: product.identifier)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SubscriptionPaywallViewController: SubscriptionManagerObserver {
    func subscriptionManager(_: SubscriptionManager, didUpdateProducts products: [SubscriptionProduct]) {
        self.products = products
        endLoading()
        tableView.reloadSections(IndexSet(integer: Section.products.rawValue), with: .automatic)
    }

    func subscriptionManager(_: SubscriptionManager, didUpdate entitlement: SubscriptionEntitlement) {
        self.entitlement = entitlement
        endLoading()
        tableView.reloadSections(IndexSet(integer: Section.status.rawValue), with: .automatic)
    }

    func subscriptionManager(_: SubscriptionManager, didFailWith error: Error) {
        endLoading()
        let alert = UIAlertController(title: NSLocalizedString("Purchase Failed", comment: ""),
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel))
        present(alert, animated: true)
    }
}
