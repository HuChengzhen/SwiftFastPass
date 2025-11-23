final class ShowPasswordViewController: UIViewController {

    /// 文本内容（密码 / 用户名 / URL）
    var text: String = ""
    /// 弹窗标题，默认“Password”
    var titleText: String = NSLocalizedString("Password", comment: "")

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        // 等宽字体，便于辨认
        label.font = UIFont.monospacedSystemFont(ofSize: 22, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left                 // ✅ 左对齐
        label.lineBreakMode = .byCharWrapping       // ✅ 按字符换行
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("Copy", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 32, bottom: 10, right: 32)
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("Close", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        return button
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.masksToBounds = true
        return view
    }()

    private let dimView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.40)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        titleLabel.text = titleText
        contentLabel.text = text

        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    private func setupLayout() {
        view.backgroundColor = .clear

        view.addSubview(dimView)
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // 卡片不要铺太宽，这样每行更短、更好读
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            cardView.widthAnchor.constraint(lessThanOrEqualToConstant: 360)
        ])

        let stack = UIStackView(arrangedSubviews: [titleLabel, contentLabel, makeButtonRow()])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16

        cardView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
    }

    private func makeButtonRow() -> UIStackView {
        let row = UIStackView(arrangedSubviews: [copyButton, UIView(), closeButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 16
        return row
    }

    @objc private func copyTapped() {
        UIPasteboard.general.string = text
        dismiss(animated: true)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
