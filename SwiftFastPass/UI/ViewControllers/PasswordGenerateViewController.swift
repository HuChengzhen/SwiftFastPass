//
//  PasswordGenerateViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/10.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import Eureka
import SnapKit
import UIKit

protocol PasswordGenerateDelegat: AnyObject {
    func passwordGenerate(_ viewController: PasswordGenerateViewController, didGenerate password: String)
}

final class PasswordGenerateViewController: FormViewController {

    weak var delegate: PasswordGenerateDelegat?

    // 和 EntryViewController 使用同一主色
    private let accentColor = UIColor(red: 0.25, green: 0.49, blue: 1.0, alpha: 1.0)

    private let minimumPasswordLength: Int = 6   // 👉 想改多少就写多少

    
    // MARK: - Header / Password 卡片

    // 整个 header 容器（放在 tableHeaderView 里的）
    private let headerContainer: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0,
                            width: UIScreen.main.bounds.width,
                            height: 220)
        view.backgroundColor = .clear
        return view
    }()

    // 白色圆角卡片
    private let passwordCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 24
        v.layer.masksToBounds = false
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius = 16
        v.layer.shadowOffset = CGSize(width: 0, height: 8)
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            iv.image = UIImage(systemName: "key.fill", withConfiguration: config)
        }
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Generated Password", comment: "")
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Adjust the options below to regenerate a new password.", comment: "")
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    // 水平滚动视图，保证长密码也能完全看到
    private let passwordScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.bounces = true
        scrollView.clipsToBounds = true
        return scrollView
    }()

    // 真正显示密码的 Label
    private let passwordLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedSystemFont(ofSize: 34, weight: .bold)
        label.textAlignment = .left
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = false     // 交给滚动处理
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        return label
    }()

    // Header 只搭建一次的标记
    private var didSetupHeaderLayout = false

    // MARK: - 生命周期 & 初始化

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false

        setupNavigation()
        setupHeaderCard()
        setupForm()

        updatePassword(animated: false)
    }

    // MARK: - UI 搭建

    private func setupNavigation() {
        navigationItem.title = NSLocalizedString("Generate Password", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped(sender:))
        )
    }

    /// 搭建顶部密码卡片，并作为 tableHeaderView
    private func setupHeaderCard() {
        guard !didSetupHeaderLayout else { return }
        didSetupHeaderLayout = true

        headerContainer.addSubview(passwordCardView)
        passwordCardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 24, left: 20, bottom: 12, right: 20))
        }

        let topStack = UIStackView(arrangedSubviews: [iconView, headerTitleLabel])
        topStack.axis = .horizontal
        topStack.alignment = .center
        topStack.spacing = 8

        passwordCardView.addSubview(topStack)
        passwordCardView.addSubview(headerSubtitleLabel)
        passwordCardView.addSubview(passwordScrollView)
        passwordScrollView.addSubview(passwordLabel)

        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        topStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        headerSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(topStack.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        passwordScrollView.snp.makeConstraints { make in
            make.top.equalTo(headerSubtitleLabel.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-18)
            make.height.greaterThanOrEqualTo(60)
        }

        passwordLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(passwordScrollView.contentLayoutGuide)
            make.leading.trailing.equalTo(passwordScrollView.contentLayoutGuide)
            make.height.equalTo(passwordScrollView.frameLayoutGuide)
        }

        // 计算 header 高度
        let width = view.bounds.width
        headerContainer.frame = CGRect(x: 0, y: 0, width: width, height: 1)
        headerContainer.layoutIfNeeded()
        let targetSize = headerContainer.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        )
        headerContainer.frame.size.height = targetSize.height

        tableView.tableHeaderView = headerContainer
    }

    private func setupForm() {
        form.removeAll()          // 先清一次，避免旧的 section 还在

        // MARK: Section 1: Allowed Character Set（用系统默认 CheckRow 样式）

        let charsetSection = Section(NSLocalizedString("Allowed Character Set", comment: ""))
        form +++ charsetSection

        // A-Z
        charsetSection <<< CheckRow("A-Z") {
            $0.title = "A - Z"
            $0.value = true          // 默认选中
        }.cellUpdate { cell, row in
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.textLabel?.textColor = .label
            // 不再动 accessoryView / background，不覆盖 Eureka 默认的 ✓
        }.onChange { [weak self] _ in
            self?.updatePassword(animated: true)
        }

        // a-z
        charsetSection <<< CheckRow("a-z") {
            $0.title = "a - z"
            $0.value = true
        }.cellUpdate { cell, row in
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.textLabel?.textColor = .label
        }.onChange { [weak self] _ in
            self?.updatePassword(animated: true)
        }

        // 0-9
        charsetSection <<< CheckRow("0-9") {
            $0.title = "0 - 9"
            $0.value = true
        }.cellUpdate { cell, row in
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.textLabel?.textColor = .label
        }.onChange { [weak self] _ in
            self?.updatePassword(animated: true)
        }

        // #!?
        charsetSection <<< CheckRow("#!?") {
            $0.title = "#!?"
            $0.value = true
        }.cellUpdate { cell, row in
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.textLabel?.textColor = .label
        }.onChange { [weak self] _ in
            self?.updatePassword(animated: true)
        }

        // MARK: Section 2: Length Slider

        form +++ Section()
        <<< SliderRow("length") { row in
            row.title = NSLocalizedString("Length", comment: "")
            row.value = 16
            row.steps = 119
            row.displayValueFor = { value in
                String(Int(value ?? 0))
            }
        }
        .cellSetup { [weak self] cell, _ in
            cell.slider.minimumValue = Float(self!.minimumPasswordLength)
            cell.slider.maximumValue = 120
            cell.slider.tintColor = self?.accentColor
            cell.textLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        }
        .onChange { [weak self] row in
            guard let self = self else { return }

            // ---- 最小长度限制 ----
            if let v = row.value, Int(v) < minimumPasswordLength {
                row.value = Cell<Float>.Value(minimumPasswordLength)
                row.updateCell()
            }

            self.updatePassword(animated: true)
        }

    }


    /// 统一设置字符集 CheckRow 的卡片圆角样式 + 选中提示
    private func styleCheckCell(_ cell: CheckCell, row: CheckRow) {
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .secondarySystemGroupedBackground

        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .regular)

        // ---- 先处理勾选提示（不依赖 indexPath） ----
        let imageView: UIImageView
        if let iv = cell.accessoryView as? UIImageView {
            imageView = iv
        } else {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFit
            cell.accessoryView = iv
            imageView = iv
        }

        if row.value == true {
            // 已选中：蓝色实心勾
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            imageView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
            imageView.tintColor = accentColor
            cell.textLabel?.textColor = .label
        } else {
            // 未选中：灰色空心圆
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            imageView.image = UIImage(systemName: "circle", withConfiguration: config)
            imageView.tintColor = .tertiaryLabel
            cell.textLabel?.textColor = .secondaryLabel
        }

        // 让 cell 高一点
        row.cell.height = { 48 }   // 注意：用 row.cell.height，而不是 cell.height

        // ---- 再根据 indexPath 做圆角（如果拿得到的话）----
        let radius: CGFloat = 14

        guard
            let tableView = self.tableView,
            let indexPath = row.indexPath
        else {
            // 刚创建时 indexPath 可能为 nil，这里先给一个统一圆角
            cell.contentView.layer.cornerRadius = radius
            cell.contentView.layer.masksToBounds = true
            return
        }

        let rowCount = tableView.numberOfRows(inSection: indexPath.section)

        if #available(iOS 11.0, *) {
            var corners: CACornerMask = []

            if rowCount == 1 {
                corners = [
                    .layerMinXMinYCorner, .layerMaxXMinYCorner,
                    .layerMinXMaxYCorner, .layerMaxXMaxYCorner
                ]
            } else if indexPath.row == 0 {
                corners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            } else if indexPath.row == rowCount - 1 {
                corners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                corners = []
            }

            cell.contentView.layer.cornerRadius = radius
            cell.contentView.layer.masksToBounds = true
            cell.contentView.layer.maskedCorners = corners
        } else {
            cell.contentView.layer.cornerRadius = radius
            cell.contentView.layer.masksToBounds = true
        }

        tableView.separatorStyle = .none
    }




    // MARK: - Actions

    @objc
    private func doneButtonTapped(sender _: Any) {
        delegate?.passwordGenerate(self, didGenerate: passwordLabel.text ?? "")
        navigationController?.popViewController(animated: true)
    }

    // MARK: - 密码生成 & 动画

    private func updatePassword(animated: Bool = true) {
        guard
            let upCell = form.rowBy(tag: "A-Z") as? CheckRow,
            let lowCell = form.rowBy(tag: "a-z") as? CheckRow,
            let numberCell = form.rowBy(tag: "0-9") as? CheckRow,
            let symbolCell = form.rowBy(tag: "#!?") as? CheckRow
        else { return }

        let up: UInt     = upCell.value == true ? (1 << 0) : 0
        let low: UInt    = lowCell.value == true ? (1 << 1) : 0
        let number: UInt = numberCell.value == true ? (1 << 2) : 0
        let symbol: UInt = symbolCell.value == true ? (1 << 3) : 0

        let flag = MPPasswordCharacterFlags(rawValue: up | low | number | symbol)

        // 全部取消时，自动还原为全选
        if flag.rawValue == 0 {
            form.delegate = nil
            for row in [upCell, lowCell, numberCell, symbolCell] {
                row.value = true
                row.updateCell()
            }
            form.delegate = self
            updatePassword(animated: false)
            return
        }

        let lengthValue = (form.rowBy(tag: "length") as? SliderRow)?.value ?? 16
        let length = UInt(lengthValue)

        let passwordObj = NSString.password(
            withCharactersets: flag,
            withCustomCharacters: nil,
            ensureOccurence: false,
            length: length
        )

        let newPassword = passwordObj! as String

        let applyText: () -> Void = {
            self.passwordLabel.text = newPassword
            // 每次重生成后回到最左边，避免用户以为内容没变
            self.passwordScrollView.setContentOffset(.zero, animated: false)
        }

        if animated {
            UIView.transition(
                with: passwordLabel,
                duration: 0.22,
                options: [.transitionCrossDissolve, .curveEaseInOut],
                animations: applyText,
                completion: nil
            )
        } else {
            applyText()
        }
    }

    // MARK: - Row 回调

    func checkRowOnChange(row _: CheckRow) {
        updatePassword(animated: true)
    }

    func lengthRowOnChange(row _: SliderRow) {
        updatePassword(animated: true)
    }
}

// MARK: - 小动画：按压缩放

private extension UITableViewCell {
    func addPressAnimation() {
        let g = UILongPressGestureRecognizer(target: self, action: #selector(handlePressAnimation(_:)))
        g.minimumPressDuration = 0
        addGestureRecognizer(g)
    }

    @objc func handlePressAnimation(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.12) {
                self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.18) {
                self.transform = .identity
            }
        default:
            break
        }
    }
}
