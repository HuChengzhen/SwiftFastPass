//
//  SelectIconViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen.
//

import SnapKit
import UIKit

// MARK: - Icon / Color 数据

enum Icons {
    static let sfSymbolNames: [String] = [
        // 通用 / 导航
        "square.grid.2x2", "square.grid.3x2", "square.grid.3x3",
        "rectangle.grid.1x2", "rectangle.grid.2x2", "list.bullet",
        "star", "star.fill", "heart", "heart.fill",

        // 安全 / 隐私
        "key", "key.fill", "lock", "lock.fill",
        "lock.shield", "lock.shield.fill", "shield", "shield.fill",
        "eye", "eye.slash",

        // 账号 / 身份
        "person", "person.fill",
        "person.crop.circle", "person.crop.circle.fill",
        "person.2", "person.2.fill",
        "person.crop.rectangle", "person.crop.square",
        "person.crop.circle.badge.checkmark",
        "person.crop.circle.badge.exclamationmark",

        // 通讯 / 消息
        "envelope", "envelope.fill", "envelope.badge",
        "bubble.left", "bubble.left.fill",
        "bubble.right", "bubble.right.fill",
        "message", "message.fill", "at",

        // 网站 / 网络
        "globe", "globe.badge.chevron.backward",
        "safari", "safari.fill",
        "network", "link", "link.circle", "link.circle.fill",
        "antenna.radiowaves.left.and.right", "wifi",

        // 设备 / 平台
        "iphone", "iphone.homebutton", "ipad",
        "laptopcomputer", "desktopcomputer",
        "applewatch", "tv", "gamecontroller",
        "keyboard", "display",

        // 文件 / 云 / 存储
        "doc", "doc.fill",
        "folder", "folder.fill",
        "tray", "tray.fill",
        "externaldrive", "externaldrive.fill",
        "icloud", "icloud.fill",

        // 工具 / 服务
        "gear", "gearshape", "gearshape.fill",
        "wrench", "wrench.and.screwdriver",
        "hammer", "paintbrush", "pencil",
        "doc.text.magnifyingglass", "qrcode",

        // 支付 / 金融
        "creditcard", "creditcard.fill",
        "banknote",
        "dollarsign.circle", "dollarsign.circle.fill",
        "cart", "cart.fill",
        "bag", "bag.fill", "gift",

        // 时间 / 其他
        "calendar", "calendar.badge.clock",
        "clock", "alarm", "timer", "hourglass",
        "bookmark", "bookmark.fill",
        "flag", "flag.fill"
    ]
}

enum IconColors {
    static let palette: [UIColor] = [
        .black, //index 0 can't use it
        .label,            // 跟随系统
        .systemBlue,
        .systemTeal,
        .systemIndigo,
        .systemGreen,
        .systemMint,
        .systemOrange,
        .systemYellow,
        .systemRed,
        .systemPink,
        .systemPurple,
        .systemBrown,
        .systemGray
    ]
}

// MARK: - 底部颜色 cell

private class ColorCollectionViewCell: UICollectionViewCell {
    private let circleView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        circleView.layer.cornerRadius = 14
        circleView.layer.masksToBounds = true

        contentView.addSubview(circleView)
        circleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(28)
        }

        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = false
    }

    func configure(color: UIColor, selected: Bool) {
        circleView.backgroundColor = color

        if selected {
            contentView.layer.shadowColor = color.withAlphaComponent(0.6).cgColor
            contentView.layer.shadowOpacity = 1
            contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
            contentView.layer.shadowRadius = 4
            contentView.layer.borderWidth = 2
            contentView.layer.borderColor = UIColor.systemBackground.cgColor
        } else {
            contentView.layer.shadowOpacity = 0
            contentView.layer.borderWidth = 0
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - SelectIconViewController

class SelectIconViewController: UIViewController {

    /// 选择完成回调：iconIndex + colorIndex
    var didSelectAction: ((_ controller: SelectIconViewController,
                           _ iconIndex: Int,
                           _ colorIndex: Int) -> Void)?

    /// 外部可以在 push 前设置当前已有的图标/颜色
    var initialIconIndex: Int = 0
    var initialColorIndex: Int = 0

    private var iconCollectionView: UICollectionView!
    private var colorCollectionView: UICollectionView!

    private var selectedIconIndex: Int = 0
    private var selectedColorIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        selectedIconIndex = initialIconIndex
        selectedColorIndex = initialColorIndex

        setupUI()
    }

    private func setupUI() {
        title = NSLocalizedString("选择图标", comment: "")
        view.backgroundColor = .systemBackground

        // 图标网格
        let iconLayout = UICollectionViewFlowLayout()
        iconLayout.itemSize = CGSize(width: 60, height: 60)
        iconLayout.minimumInteritemSpacing = 8
        iconLayout.minimumLineSpacing = 8
        iconLayout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        iconCollectionView = UICollectionView(frame: .zero, collectionViewLayout: iconLayout)
        iconCollectionView.backgroundColor = .clear
        iconCollectionView.alwaysBounceVertical = true
        iconCollectionView.dataSource = self
        iconCollectionView.delegate = self
        iconCollectionView.register(IconCollectionViewCell.self,
                                    forCellWithReuseIdentifier: "IconCollectionViewCell")

        view.addSubview(iconCollectionView)

        // 底部颜色选择条
        let colorLayout = UICollectionViewFlowLayout()
        colorLayout.scrollDirection = .horizontal
        colorLayout.itemSize = CGSize(width: 40, height: 40)
        colorLayout.minimumLineSpacing = 8
        colorLayout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)

        colorCollectionView = UICollectionView(frame: .zero, collectionViewLayout: colorLayout)
        colorCollectionView.backgroundColor = .clear
        colorCollectionView.showsHorizontalScrollIndicator = false
        colorCollectionView.dataSource = self
        colorCollectionView.delegate = self
        colorCollectionView.register(ColorCollectionViewCell.self,
                                     forCellWithReuseIdentifier: "ColorCollectionViewCell")

        view.addSubview(colorCollectionView)

        // Layout
        colorCollectionView.snp.makeConstraints { make in
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.height.equalTo(48)
        }

        iconCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(colorCollectionView.snp.top).offset(-8)
        }
    }

    /// 选中某个图标后，回调并返回上一页
    private func finishSelection() {
        didSelectAction?(self, selectedIconIndex, selectedColorIndex)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDataSource / Delegate

extension SelectIconViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if collectionView === iconCollectionView {
            return Icons.sfSymbolNames.count
        } else {
            return IconColors.palette.count - 1
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView === iconCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "IconCollectionViewCell",
                for: indexPath
            ) as! IconCollectionViewCell

            let symbolName = Icons.sfSymbolNames[indexPath.item]
            let tintColor = IconColors.palette[selectedColorIndex ]
            let isSelected = (indexPath.item == selectedIconIndex)

            cell.configure(symbolName: symbolName, color: tintColor, selected: isSelected)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ColorCollectionViewCell",
                for: indexPath
            ) as! ColorCollectionViewCell

            let color = IconColors.palette[indexPath.item+1]
            let isSelected = (indexPath.item+1 == selectedColorIndex)
            cell.configure(color: color, selected: isSelected)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        if collectionView === iconCollectionView {
            selectedIconIndex = indexPath.item
            iconCollectionView.reloadData()
            finishSelection()
        } else {
            selectedColorIndex = indexPath.item + 1
            colorCollectionView.reloadData()
            iconCollectionView.reloadData()   // 让所有图标使用新颜色重绘
        }
    }
}
