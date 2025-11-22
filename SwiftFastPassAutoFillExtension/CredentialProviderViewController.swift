//
//  CredentialProviderViewController.swift
//  SwiftFastPassAutoFillExtension
//
//  Created by 胡诚真 on 2025/11/22.
//  Copyright © 2025 huchengzhen. All rights reserved.
//

import AuthenticationServices
import UIKit

class CredentialProviderViewController: ASCredentialProviderViewController {
    private var allCredentials: [AutoFillCredentialSnapshot] = []
    private var filteredCredentials: [AutoFillCredentialSnapshot] = []
    private var currentServiceIdentifiers: [ASCredentialServiceIdentifier] = []
    private var isPremiumUnlocked: Bool {
        SubscriptionStatus.isPremiumUnlocked
    }

    private let cellIdentifier = "CredentialCell"

    private lazy var navigationBar: UINavigationBar = {
        let bar = UINavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        let item = UINavigationItem(title: NSLocalizedString("Passwords", comment: ""))
        item.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                 target: self,
                                                 action: #selector(cancel(_:)))
        bar.setItems([item], animated: false)
        return bar
    }()

    private lazy var tableView: UITableView = {
        let style: UITableView.Style
        if #available(iOS 13.0, *) {
            style = .insetGrouped
        } else {
            style = .grouped
        }
        let tableView = UITableView(frame: .zero, style: style)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        return tableView
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = secondaryTextColor
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        reloadCredentials()
    }

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        currentServiceIdentifiers = serviceIdentifiers
        reloadCredentials(filtering: serviceIdentifiers)
    }

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard isPremiumUnlocked else {
            let error = NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue)
            extensionContext.cancelRequest(withError: error)
            return
        }
        guard let snapshot = snapshot(for: credentialIdentity.recordIdentifier) else {
            let error = NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.credentialIdentityNotFound.rawValue)
            extensionContext.cancelRequest(withError: error)
            return
        }
        complete(with: snapshot)
    }

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard isPremiumUnlocked else {
            updateEmptyState()
            return
        }
        if let snapshot = snapshot(for: credentialIdentity.recordIdentifier) {
            complete(with: snapshot)
        } else {
            reloadCredentials()
        }
    }

    private func configureLayout() {
        view.subviews.forEach { $0.removeFromSuperview() }
        view.backgroundColor = baseBackgroundColor
        view.addSubview(navigationBar)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func reloadCredentials(filtering serviceIdentifiers: [ASCredentialServiceIdentifier]? = nil) {
        guard isPremiumUnlocked else {
            allCredentials = []
            filteredCredentials = []
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateEmptyState()
            }
            return
        }
        allCredentials = AutoFillCredentialStore.shared.credentials()
        filteredCredentials = filter(credentials: allCredentials,
                                     serviceIdentifiers: serviceIdentifiers ?? currentServiceIdentifiers)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }

    private func filter(credentials: [AutoFillCredentialSnapshot],
                        serviceIdentifiers: [ASCredentialServiceIdentifier]) -> [AutoFillCredentialSnapshot] {
        let normalizedIdentifiers = normalized(serviceIdentifiers: serviceIdentifiers)
        guard !normalizedIdentifiers.isEmpty else { return credentials }
        return credentials.filter { snapshot in
            guard let candidate = (snapshot.domain ?? snapshot.url)?.lowercased() else {
                return false
            }
            return normalizedIdentifiers.contains(where: { candidate.contains($0) })
        }
    }

    private func normalized(serviceIdentifiers: [ASCredentialServiceIdentifier]) -> [String] {
        serviceIdentifiers.map { identifier in
            let lowercased = identifier.identifier.lowercased()
            switch identifier.type {
            case .domain:
                return lowercased
            case .URL:
                if let host = URL(string: lowercased)?.host?.lowercased() {
                    return host
                }
                return lowercased
            @unknown default:
                return lowercased
            }
        }
    }

    private func snapshot(for recordIdentifier: String?) -> AutoFillCredentialSnapshot? {
        guard let recordIdentifier = recordIdentifier else { return nil }
        return AutoFillCredentialStore.shared.credentials().first { $0.uuid == recordIdentifier }
    }

    private func complete(with snapshot: AutoFillCredentialSnapshot) {
        let credential = ASPasswordCredential(user: snapshot.username, password: snapshot.password)
        extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
    }

    private func updateEmptyState() {
        guard isPremiumUnlocked else {
            tableView.isHidden = true
            emptyStateLabel.isHidden = false
            emptyStateLabel.text = NSLocalizedString("FastPass Pro subscription required to use AutoFill. Open the main app to upgrade.", comment: "")
            return
        }
        let hasContent = !filteredCredentials.isEmpty
        tableView.isHidden = !hasContent
        emptyStateLabel.isHidden = hasContent
        if !hasContent {
            emptyStateLabel.text = currentServiceIdentifiers.isEmpty ?
                NSLocalizedString("No passwords available.\nAdd entries in SwiftFastPass to use AutoFill.", comment: "") :
                NSLocalizedString("No saved passwords match this app or website.", comment: "")
        }
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain,
                                                          code: ASExtensionError.userCanceled.rawValue))
    }

    @IBAction func passwordSelected(_ sender: AnyObject?) {
        guard let snapshot = filteredCredentials.first ?? allCredentials.first else {
            extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain,
                                                              code: ASExtensionError.credentialIdentityNotFound.rawValue))
            return
        }
        complete(with: snapshot)
    }
}

extension CredentialProviderViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        filteredCredentials.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ??
            UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        let snapshot = filteredCredentials[indexPath.row]
        cell.textLabel?.text = snapshot.displayTitle
        cell.detailTextLabel?.text = snapshot.detailSummary
        cell.detailTextLabel?.textColor = secondaryTextColor
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let snapshot = filteredCredentials[indexPath.row]
        complete(with: snapshot)
    }
}

private extension CredentialProviderViewController {
    var baseBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }

    var secondaryTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .darkGray
        }
    }
}
