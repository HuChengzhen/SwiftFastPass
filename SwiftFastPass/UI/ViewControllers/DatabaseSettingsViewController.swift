//
//  DatabaseSettingsViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2025/1/2.
//  Copyright © 2025 huchengzhen. All rights reserved.
//

import Eureka
import UIKit

final class DatabaseSettingsViewController: FormViewController {
    private enum FormTag {
        static let securityLevel = "settings_security_level_row"
        static let securityDescription = "settings_security_detail_row"
    }

    private let file: File
    private let premiumAccess = PremiumAccessController.shared
    private var selectedSecurityLevel: File.SecurityLevel

    init(file: File) {
        self.file = file
        self.selectedSecurityLevel = file.securityLevel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Database Settings", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(saveButtonTapped))
        buildForm()
        updateSecurityDetailRow(for: selectedSecurityLevel)
    }

    private func buildForm() {
        form +++ Section(NSLocalizedString("Security Level", comment: ""))
            <<< SegmentedRow<File.SecurityLevel>(FormTag.securityLevel) { [weak self] row in
                guard let self = self else { return }
                row.title = NSLocalizedString("Protection", comment: "")
                row.options = File.SecurityLevel.allCases
                row.value = self.selectedSecurityLevel
                row.displayValueFor = { $0?.localizedTitle }
            }.onChange { [weak self] row in
                guard let level = row.value else { return }
                self?.handleSecurityLevelSelection(level)
            }
            <<< TextAreaRow(FormTag.securityDescription) { [weak self] row in
                row.disabled = true
                row.textAreaHeight = .fixed(cellHeight: 120)
                row.value = self?.selectedSecurityLevel.localizedDescription
            }.cellUpdate { cell, _ in
                cell.textView.backgroundColor = .clear
                if #available(iOS 13.0, *) {
                    cell.textView.textColor = .secondaryLabel
                } else {
                    cell.textView.textColor = .darkGray
                }
            }
    }

    private func handleSecurityLevelSelection(_ level: File.SecurityLevel) {
        guard level != selectedSecurityLevel else {
            return
        }

        if level != .paranoid,
           !premiumAccess.enforce(feature: .advancedSecurity, presenter: self)
        {
            revertSecurityLevelSelection()
            return
        }

        if level.usesBiometrics {
            requestBiometricAuthorization(for: level)
        } else {
            applySecurityLevel(level)
        }
    }

    private func applySecurityLevel(_ level: File.SecurityLevel) {
        selectedSecurityLevel = level
        updateSecurityDetailRow(for: level)
    }

    private func revertSecurityLevelSelection() {
        if let row: SegmentedRow<File.SecurityLevel> = form.rowBy(tag: FormTag.securityLevel) {
            row.value = selectedSecurityLevel
            row.updateCell()
        }
        updateSecurityDetailRow(for: selectedSecurityLevel)
    }

    private func updateSecurityDetailRow(for level: File.SecurityLevel) {
        if let row: TextAreaRow = form.rowBy(tag: FormTag.securityDescription) {
            row.value = level.localizedDescription
            row.updateCell()
        }
    }

    private func requestBiometricAuthorization(for level: File.SecurityLevel) {
        biometrics(onSuccess: { [weak self] in
            self?.applySecurityLevel(level)
        }, onFailure: { [weak self] error in
            self?.presentBiometricFailureAlert(error: error)
            self?.revertSecurityLevelSelection()
        })
    }

    private func presentBiometricFailureAlert(error: Error?) {
        let title = NSLocalizedString("Unable to enable biometric unlock", comment: "")
        let message: String
        if let error = error {
            message = error.localizedDescription
        } else {
            message = NSLocalizedString("Biometric authentication failed. You can enable it later in database settings.", comment: "")
        }

        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let ok = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

    @objc private func saveButtonTapped() {
        let newLevel = selectedSecurityLevel
        guard newLevel != file.securityLevel else {
            navigationController?.popViewController(animated: true)
            return
        }

        file.updateSecurityLevel(newLevel)
        File.save()
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        navigationController?.popViewController(animated: true)
    }
}
