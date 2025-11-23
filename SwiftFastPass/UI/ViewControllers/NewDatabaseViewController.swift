//
//  NewDatabaseViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import Eureka
import KeePassKit
import UIKit

protocol NewDatabaseDelegate: AnyObject {
    func newDatabase(viewController: NewDatabaseViewController, didNewDatabase file: File)
}

class NewDatabaseViewController: FormViewController {

    // 和其他页面保持同一主色
    private let accentColor = UIColor(red: 0.25, green: 0.49, blue: 1.0, alpha: 1.0)

    var keyFileContent: Data?
    weak var delegate: NewDatabaseDelegate?
    private let premiumAccess = PremiumAccessController.shared
    
    private var animatedIndexPaths = Set<IndexPath>()

    private enum FormTag {
        static let securityLevel = "security_level_row"
        static let securityDescription = "security_level_detail_row"
    }

    private var selectedSecurityLevel: File.SecurityLevel =
        PremiumAccessController.shared.isPremiumUnlocked ? .balanced : .paranoid

    private enum FieldGroupPosition {
        case single
        case top
        case middle
        case bottom
    }

    // MARK: - Header

    private lazy var headerContainerView: UIView = {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 148))
        container.backgroundColor = .clear

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 24
        card.layer.cornerCurve = .continuous
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 16
        card.layer.shadowOffset = CGSize(width: 0, height: 10)

        let gradient = CAGradientLayer()
        gradient.colors = [
            accentColor.withAlphaComponent(0.25).cgColor,
            accentColor.withAlphaComponent(0.05).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 200)


        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.layer.insertSublayer(gradient, at: 0)
        gradientView.layer.cornerRadius = 16
        gradientView.layer.masksToBounds = true

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("New Database", comment: "")
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = NSLocalizedString("Create a new secure vault to store your passwords.", comment: "")
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        let hintLabel = UILabel()
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.text = NSLocalizedString("Use a strong password and keep it in a safe place.", comment: "")
        hintLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        hintLabel.textColor = .secondaryLabel.withAlphaComponent(0.8)
        hintLabel.numberOfLines = 1


        
        let iconBackground = UIView()
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.backgroundColor = accentColor.withAlphaComponent(0.15)
        iconBackground.layer.cornerRadius = 24
        iconBackground.layer.cornerCurve = .continuous

        let lockIcon = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.tintColor = accentColor

        container.addSubview(card)
        card.addSubview(gradientView)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        card.addSubview(iconBackground)
        iconBackground.addSubview(lockIcon)

        // ✅ 这一行一定要有（或者改成 gradientView.addSubview(...)）
        // 因为下面的约束是以 gradientView 为参照系的
        gradientView.addSubview(hintLabel)


        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            card.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            card.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),

            gradientView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            gradientView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            gradientView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            gradientView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),


            iconBackground.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -12),
            iconBackground.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 48),
            iconBackground.heightAnchor.constraint(equalToConstant: 48),

            lockIcon.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 26),
            lockIcon.heightAnchor.constraint(equalToConstant: 26),

            titleLabel.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: iconBackground.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: gradientView.topAnchor, constant: 12),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -14),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            // ⬇️ 新增：副标题在上，hint 在下
            subtitleLabel.bottomAnchor.constraint(equalTo: hintLabel.topAnchor, constant: -4),

            hintLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            hintLabel.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -14),
            hintLabel.bottomAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: -10)
        ])


        return container
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // ❗️让 NavigationBar 透明（否则背景会挡住横杠）
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true

        // ❗️隐藏默认标题
        navigationItem.title = ""

        // 添加 grabber 作为 titleView
        let grabber = UIView()
        grabber.translatesAutoresizingMaskIntoConstraints = false
        grabber.backgroundColor = UIColor.label.withAlphaComponent(0.15)
        grabber.layer.cornerRadius = 3
        grabber.layer.cornerCurve = .continuous

        let grabberContainer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 24))
        grabberContainer.addSubview(grabber)

        NSLayoutConstraint.activate([
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 6),
            grabber.centerXAnchor.constraint(equalTo: grabberContainer.centerXAnchor),
            grabber.centerYAnchor.constraint(equalTo: grabberContainer.centerYAnchor, constant: 4)
        ])

        navigationItem.titleView = grabberContainer
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancelButtonTapped(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(doneButtonTapped(sender:)))
        navigationItem.rightBarButtonItem?.isEnabled = false

        tableView.backgroundColor = .systemGroupedBackground
        tableView.tableHeaderView = headerContainerView
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false

        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.tintColor = accentColor
        }

        buildForm()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        animatedIndexPaths.removeAll()
    }




    // MARK: - Form building

    private func buildForm() {
        form
        +++ Section()
            <<< TextRow("name") { row in
                row.title = NSLocalizedString("Name", comment: "")
                row.placeholder = NSLocalizedString("Enter name here", comment: "")
                row.add(rule: RuleRequired())
                row.validationOptions = .validatesOnChange
            }
            .cellSetup { cell, _ in
                self.styleTextRowCell(cell, position: .single)

                // ✅ 关键：强制左对齐，这样前导空格会真正可见
                cell.textField.textAlignment = .left

                // 可选：清除按钮
                cell.textField.clearButtonMode = .whileEditing

                cell.textField.autocorrectionType = .no
                cell.textField.autocapitalizationType = .none
                cell.textField.spellCheckingType = .no
                if #available(iOS 11.0, *) {
                    cell.textField.smartQuotesType = .no
                    cell.textField.smartDashesType = .no
                    // 保留你原来的设置
                    cell.textField.smartInsertDeleteType = .no
                    cell.textField.textContentType = .nickname
                }

                // （可选）给 textField 一点很小的内部左边距，不动外面的卡片 layout
                let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 10))
                cell.textField.leftView = paddingView
                cell.textField.leftViewMode = .always
            }
            .onChange { [weak self] row in
                row.value = row.cell.textField.text
                self?.validateInputUpdateAddButtonState()
            }
            .cellUpdate { cell, row in
                // 🔁 再次锁死左对齐，防止 Eureka 在重用 cell 时改回去
                cell.textField.textAlignment = .left

                if !row.isValid {
                    cell.textLabel?.textColor = .systemRed
                    cell.textField.textColor = .systemRed
                } else {
                    cell.textLabel?.textColor = .secondaryLabel
                    cell.textField.textColor = .label
                }
            }



            +++ Section()
        <<< TextRow("password") { row in
            row.title = NSLocalizedString("Password", comment: "")
            row.placeholder = NSLocalizedString("Enter password here", comment: "")
            row.add(rule: RuleRequired())
            row.validationOptions = .validatesOnChange
        }
        .cellSetup { cell, _ in
            self.styleTextRowCell(cell, position: .top)

            cell.textField.isSecureTextEntry = true

            // ✅ 保持右对齐，这样和左边的标题在一条水平线上
            cell.textField.textAlignment = .right

            // ✅ 关键 1：只用 ASCII 键盘，避免中文输入法/特殊键盘吞空格
            cell.textField.keyboardType = .asciiCapable

            // ✅ 关键 2：不要再用 oneTimeCode / password 类型
            if #available(iOS 12.0, *) {
                cell.textField.textContentType = .none
            } else {
                cell.textField.textContentType = nil
            }

            // 建议都关掉：密码不需要这些智能功能
            cell.textField.autocorrectionType = .no
            cell.textField.autocapitalizationType = .none
            cell.textField.spellCheckingType = .no
            if #available(iOS 11.0, *) {
                cell.textField.smartQuotesType = .no
                cell.textField.smartDashesType = .no
                cell.textField.smartInsertDeleteType = .no
            }
        }
        .onChange { [weak self] _ in
            self?.validateInputUpdateAddButtonState()
        }
        .cellUpdate { cell, row in
            // 防止重用时被 Eureka 改掉
            cell.textField.textAlignment = .right

            if !row.isValid {
                cell.textLabel?.textColor = .systemRed
                cell.textField.textColor = .systemRed
            } else {
                cell.textLabel?.textColor = .secondaryLabel
                cell.textField.textColor = .label
            }
        }




        <<< TextRow("confirmPassword") { [weak self] row in
            row.title = NSLocalizedString("Confirm password", comment: "")
            row.placeholder = NSLocalizedString("Confirm password here", comment: "")
            row.add(rule: RuleRequired())
            row.add(rule: RuleClosure { [weak self] value -> ValidationError? in
                guard let self = self else { return nil }

                let passwordRow: TextRow? = self.form.rowBy(tag: "password")
                let password = passwordRow?.value ?? ""
                let confirm = value ?? ""

                if !password.isEmpty, !confirm.isEmpty, password != confirm {
                    return ValidationError(msg: NSLocalizedString("Passwords are different.", comment: ""))
                }
                return nil
            })
            row.validationOptions = .validatesOnChange
        }
        .cellSetup { cell, _ in
            self.styleTextRowCell(cell, position: .bottom)
            cell.textField.isSecureTextEntry = true

            // ✅ 和上面保持一致
            cell.textField.textAlignment = .right
            cell.textField.keyboardType = .asciiCapable

            if #available(iOS 12.0, *) {
                cell.textField.textContentType = .none
            } else {
                cell.textField.textContentType = nil
            }

            cell.textField.autocorrectionType = .no
            cell.textField.autocapitalizationType = .none
            cell.textField.spellCheckingType = .no
            if #available(iOS 11.0, *) {
                cell.textField.smartQuotesType = .no
                cell.textField.smartDashesType = .no
                cell.textField.smartInsertDeleteType = .no
            }
        }
        .onChange { [weak self] _ in
            self?.validateInputUpdateAddButtonState()
        }
        .cellUpdate { cell, row in
            cell.textField.textAlignment = .right

            if !row.isValid {
                cell.textLabel?.textColor = .systemRed
                cell.textField.textColor = .systemRed
            } else {
                cell.textLabel?.textColor = .secondaryLabel
                cell.textField.textColor = .label
            }
        }




            +++ Section()
            <<< ButtonRow("keyFile") { row in
                row.title = NSLocalizedString("New Key File", comment: "")
            }
            .cellSetup { cell, _ in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
                cell.tintColor = self.accentColor
                cell.accessoryType = .disclosureIndicator
                cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

                cell.layer.cornerRadius = 16
                cell.clipsToBounds = true

                // ⬇️ 新增：左右内边距
                cell.preservesSuperviewLayoutMargins = false
                if #available(iOS 11.0, *) {
                    cell.contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                        top: 0,
                        leading: 24,
                        bottom: 0,
                        trailing: 24
                    )
                } else {
                    cell.contentView.layoutMargins = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
                }
            }

            .onCellSelection(keyFileButtonTapped)

            +++ Section(NSLocalizedString("Security Level", comment: ""))
            <<< SegmentedRow<File.SecurityLevel>(FormTag.securityLevel) { [weak self] row in
                row.title = NSLocalizedString("Protection", comment: "")
                row.options = File.SecurityLevel.allCases
                row.value = self?.selectedSecurityLevel ?? .balanced
                row.displayValueFor = { $0?.localizedTitle }
            }
            .cellSetup { cell, _ in
                cell.backgroundColor = .secondarySystemGroupedBackground
                if #available(iOS 13.0, *) {
                    cell.segmentedControl.selectedSegmentTintColor = self.accentColor
                    cell.segmentedControl.setTitleTextAttributes([
                        .foregroundColor: UIColor.white,
                        .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
                    ], for: .selected)
                    cell.segmentedControl.setTitleTextAttributes([
                        .foregroundColor: UIColor.label.withAlphaComponent(0.6),
                        .font: UIFont.systemFont(ofSize: 13, weight: .medium)
                    ], for: .normal)
                }
                cell.layer.cornerRadius = 16
                cell.clipsToBounds = true
                
                // ⬇️ 新增：左右内边距 + 让 segmented 贴着内边距
                cell.preservesSuperviewLayoutMargins = false
                cell.segmentedControl.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    cell.segmentedControl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 24),
                    cell.segmentedControl.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -24),
                    cell.segmentedControl.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
                ])
            }
            .onChange { [weak self] row in
                guard let level = row.value else { return }
                self?.handleSecurityLevelSelection(level)
            }

            <<< TextAreaRow(FormTag.securityDescription) { [weak self] row in
                row.disabled = true
                row.textAreaHeight = .fixed(cellHeight: 120)
                row.value = self?.selectedSecurityLevel.localizedDescription
            }
            .cellUpdate { cell, _ in
                cell.textView.backgroundColor = .secondarySystemGroupedBackground
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textView.isEditable = false
                cell.textView.isScrollEnabled = true
                cell.textView.font = UIFont.systemFont(ofSize: 13, weight: .regular)
                if #available(iOS 13.0, *) {
                    cell.textView.textColor = .secondaryLabel
                } else {
                    cell.textView.textColor = .darkGray
                }
                cell.layer.cornerRadius = 16
                cell.clipsToBounds = true
                
                // ⬇️ 新增：说明文字左右内边距更大一些
                cell.textView.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
                cell.preservesSuperviewLayoutMargins = false
                if #available(iOS 11.0, *) {
                    cell.contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                        top: 0,
                        leading: 20,
                        bottom: 0,
                        trailing: 20
                    )
                } else {
                    cell.contentView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
                }
            }

        updateSecurityDetailRow(for: selectedSecurityLevel)
    }

    // MARK: - Cell styling helper

    private func styleTextRowCell(_ cell: TextCell, position: FieldGroupPosition) {
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        cell.textLabel?.textColor = .secondaryLabel
        cell.textField.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        cell.textField.textColor = .label
        cell.tintColor = accentColor
        cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        // ✅ 只用这一套控制左右间距，其他都不要
        cell.preservesSuperviewLayoutMargins = false
        if #available(iOS 11.0, *) {
            cell.contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 0,
                leading: 24,   // 左边距
                bottom: 0,
                trailing: 24   // 右边距
            )
        } else {
            cell.contentView.layoutMargins = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        }

        let radius: CGFloat = 16
        cell.layer.cornerRadius = radius
        cell.clipsToBounds = true

        if #available(iOS 11.0, *) {
            switch position {
            case .single:
                cell.layer.maskedCorners = [
                    .layerMinXMinYCorner,
                    .layerMaxXMinYCorner,
                    .layerMinXMaxYCorner,
                    .layerMaxXMaxYCorner
                ]
            case .top:
                cell.layer.maskedCorners = [
                    .layerMinXMinYCorner,
                    .layerMaxXMinYCorner
                ]
            case .middle:
                cell.layer.cornerRadius = 0
                cell.layer.maskedCorners = []
            case .bottom:
                cell.layer.maskedCorners = [
                    .layerMinXMaxYCorner,
                    .layerMaxXMaxYCorner
                ]
            }
        }
    }



    // MARK: - 让需要的行整体左右缩进（包括安全级别那块）
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {

        let section = form[indexPath.section]
        let row = section[indexPath.row]

        // 清掉旧的 mask，避免复用问题
        cell.layer.mask = nil

        guard let tag = row.tag else { return }

        let insetTags: Set<String> = [
            "name",
            "password",
            "confirmPassword",
            "keyFile",
            FormTag.securityLevel,
            FormTag.securityDescription
        ]

        // 不需要缩进/卡片化的行直接返回
        guard insetTags.contains(tag) else { return }

        let inset: CGFloat = 16
        let bounds = cell.bounds
        let maskedRect = bounds.insetBy(dx: inset, dy: 0)
        let radius: CGFloat = 16

        var corners: UIRectCorner = []

        switch tag {
        case "password":
            // 密码：顶部圆角
            corners = [.topLeft, .topRight]
        case "confirmPassword":
            // 确认密码：底部圆角
            corners = [.bottomLeft, .bottomRight]

        case FormTag.securityLevel:
            // 安全等级 segmented：顶部圆角
            corners = [.topLeft, .topRight]
        case FormTag.securityDescription:
            // 安全等级说明：底部圆角
            corners = [.bottomLeft, .bottomRight]

        default:
            // 其他（例如 name、keyFile）保持完整圆角
            corners = [.allCorners]
        }

        let path = UIBezierPath(
            roundedRect: maskedRect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )

        // mask：控制可见区域 & 圆角
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = path.cgPath
        cell.layer.mask = maskLayer

        // 先清掉旧的描边 layer（避免复用叠加）
        cell.layer.sublayers?.removeAll(where: { $0.name == "cardBorder" })

        // 再加一条很淡的描边，强化卡片边界
        let borderLayer = CAShapeLayer()
        borderLayer.name = "cardBorder"
        borderLayer.frame = bounds
        borderLayer.path = path.cgPath
        borderLayer.strokeColor = UIColor.black.withAlphaComponent(0.06).cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 0.5

        cell.layer.addSublayer(borderLayer)

        // ⬇️⬇️ 在这里加入场动画（每个 indexPath 只执行一次）
        if !animatedIndexPaths.contains(indexPath) {
            animatedIndexPaths.insert(indexPath)

            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 18)

            UIView.animate(
                withDuration: 0.42,
                delay: 0.03 * Double(indexPath.row),   // 轻微错位，列表有“级联感”
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0.6,
                options: [.curveEaseOut],
                animations: {
                    cell.alpha = 1
                    cell.transform = .identity
                },
                completion: nil
            )
        }
    }







    // MARK: - Security level handling

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

        if let row: TextAreaRow = form.rowBy(tag: FormTag.securityDescription),
           let cell = row.cell as? TextAreaCell
        {
            cell.textView.alpha = 0
            UIView.animate(withDuration: 0.25) {
                cell.textView.alpha = 1
            }
        }
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

    // MARK: - Key file

    func keyFileButtonTapped(cell: ButtonCellOf<String>, row: ButtonRow) {
        guard premiumAccess.enforce(feature: .keyFile, presenter: self) else { return }

        let isRemoving = keyFileContent != nil

        if isRemoving {
            keyFileContent = nil
            row.title = NSLocalizedString("New Key File", comment: "")
            cell.tintColor = accentColor
        } else {
            keyFileContent = NSData.kpk_generateKeyfileData(of: .xmlVersion2)
            row.title = NSLocalizedString("Remove Key File", comment: "")
            cell.tintColor = .systemRed
        }
        row.updateCell()

        UIView.animate(withDuration: 0.12,
                       animations: {
                           cell.contentView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
                       }, completion: { _ in
                           UIView.animate(withDuration: 0.18) {
                               cell.contentView.transform = .identity
                           }
                       })
    }

    // MARK: - Validation & buttons

    private func currentNameInput() -> String? {
        guard let nameRow: TextRow = form.rowBy(tag: "name") else { return nil }
        // Prefer the live text field to avoid any formatting that might trim spaces.
        if let text = nameRow.cell.textField.text {
            return text
        }
        return nameRow.value
    }

    func validateInputUpdateAddButtonState() {
        // Use the live text from the field to avoid any formatter/IME trimming side effects.
        let nameHasInput = !(currentNameInput() ?? "").isEmpty
        let validationErrors = form.validate()
        navigationItem.rightBarButtonItem?.isEnabled = nameHasInput && validationErrors.isEmpty
    }


    @objc func cancelButtonTapped(sender _: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc func doneButtonTapped(sender: UIButton) {
        sender.isEnabled = false
        view.endEditing(true)

        // 1. 先拿到两次密码
        let passwordRow: TextRow? = form.rowBy(tag: "password")
        let confirmRow: TextRow? = form.rowBy(tag: "confirmPassword")
        let password = passwordRow?.value ?? ""
        let confirm = confirmRow?.value ?? ""

        // 2. 如果有空的，交给必填校验去处理
        //   （validateInputUpdateAddButtonState 会把按钮置灰）
        if password.isEmpty || confirm.isEmpty {
            sender.isEnabled = true
            return
        }

        // 3. 不一致时弹出提示
        if password != confirm {
            sender.isEnabled = true
            let alert = UIAlertController(
                title: NSLocalizedString("Passwords do not match", comment: ""),
                message: NSLocalizedString("Please enter the same password in both fields.", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        let tree = KPKTree(templateContents: ())
        DefaultGroupIconRewriter.apply(to: tree.root)
        let targetDirURL = premiumAccess.documentsDirectoryURL()
        guard let name = currentNameInput(), !name.isEmpty else {
            sender.isEnabled = true
            return
        }
        let fileName = name + ".kdbx"
        let fileURL = targetDirURL.appendingPathComponent(fileName)

        let effectiveKeyFileContent = premiumAccess.isPremiumUnlocked ? keyFileContent : nil

        guard !FileManager.default.fileExists(atPath: fileURL.path) else {
            let alertController = UIAlertController(
                title: NSLocalizedString("The file with the same name already exists in the folder", comment: ""),
                message: NSLocalizedString("Please use a different file name", comment: ""),
                preferredStyle: .alert
            )
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            alertController.addAction(cancel)
            present(alertController, animated: true, completion: nil)
            sender.isEnabled = true
            return
        }

        if let keyData = effectiveKeyFileContent {
            let keyFileName = name + ".key"
            let keyFileURL = targetDirURL.appendingPathComponent(keyFileName)
            do {
                try keyData.write(to: keyFileURL, options: .atomic)
            } catch {
                print("NewDatabaseViewController.addButtonTapped error: \(error)")
                sender.isEnabled = true
                return
            }
        }

        let document = Document(fileURL: fileURL)
        document.tree = tree
        let key = KPKCompositeKey()

        // 添加密码（如果有）
        if let passwordKey = KPKPasswordKey(password: password) {
            key.add(passwordKey)
        }

        // 添加 keyfile（如果有）
        if let keyFileContent = keyFileContent,
           let fileKey = try? KPKFileKey(keyFileData: keyFileContent)
        {
            key.add(fileKey)
        }

        document.key = key
        document.save(to: document.fileURL, for: .forCreating) { success in
            if success {
                do {
                    let bookmark = try document.fileURL.bookmarkData(options: .suitableForBookmarkFile)
                    let securityRow: SegmentedRow<File.SecurityLevel>? = self.form.rowBy(tag: FormTag.securityLevel)
                    let securityLevel = securityRow?.value ?? self.selectedSecurityLevel
                    let file = File(name: fileName,
                                    bookmark: bookmark,
                                    requiresKeyFileContent: effectiveKeyFileContent != nil,
                                    securityLevel: securityLevel)
                    let shouldCacheCredentials = securityLevel.cachesCredentials
                    let storedPassword = shouldCacheCredentials ? password : nil
                    let storedKeyFileContent = shouldCacheCredentials ? effectiveKeyFileContent : nil
                    file.attach(password: storedPassword,
                                keyFileContent: storedKeyFileContent,
                                requiresKeyFileContent: effectiveKeyFileContent != nil,
                                securityLevel: securityLevel)
                    file.image = document.tree?.root?.image()

                    self.delegate?.newDatabase(viewController: self, didNewDatabase: file)
                    return
                } catch {
                    print("NewDatabaseViewController.addButtonTapped error: \(error)")
                }
            }
            sender.isEnabled = true
        }
    }
}

// MARK: - Default template icon mapping

private enum DefaultGroupIconRewriter {
    /// KeePass 模板里自带的图标 id → 我们的 SF Symbols
    private static let replacements: [Int: String] = [
        48: "folder.fill",        // General
        38: "desktopcomputer",    // Windows
        3: "network",             // Network
        1: "globe",               // Internet
        19: "envelope.fill",      // Email
        37: "creditcard.fill"     // Homebanking
    ]

    static func apply(to rootGroup: KPKGroup?) {
        guard let rootGroup else { return }
        update(group: rootGroup)
    }

    private static func update(group: KPKGroup) {
        if let symbolName = replacements[Int(group.iconId)],
           let index = Icons.sfSymbolNames.firstIndex(of: symbolName) {
            group.iconId = index
            group.iconColorId = IconColors.normalizedIndex(1)
        }

        group.groups.forEach { update(group: $0) }
    }
}
