//
//  AddGroupViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen.
//

import Eureka
import KeePassKit
import UIKit

protocol AddGroupDelegate: AnyObject {
    func addGroup(_ controller: AddGroupViewController, didAddGroup group: KPKGroup)
    func addGroup(_ controller: AddGroupViewController, didEditGroup group: KPKGroup)
}

extension AddGroupDelegate {
    func addGroup(_: AddGroupViewController, didEditGroup _: KPKGroup) {}
}

class AddGroupViewController: FormViewController {
    weak var delegate: AddGroupDelegate?

    var iconId: Int?
    var iconColorId: Int?
    private enum FormTag {
        static let icon = "icon"
        static let title = "title"
    }

    private enum Mode {
        case create
        case edit(KPKGroup)
    }

    private var mode: Mode = .create

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyModeToUI()
    }

    // MARK: - UI

    func setupUI() {
        navigationItem.title = NSLocalizedString("New Group", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped(sender:))
        )

        form +++ Section()
            <<< ImageRow(FormTag.icon) { [weak self] row in
                row.title = NSLocalizedString("Icon", comment: "")
                row.sourceTypes = []   // 不弹系统相册，只当展示行用
                row.value = nil        // 不用 ImageRow 自带的图片机制

                // 初次进入时，根据当前 iconId / iconColorId 设置 accessoryView
                if let self = self,
                   let cell = row.cell as? ImageCell
                {
                    self.updateIconAccessoryView(for: cell)
                }
            }
            .cellSetup { [weak self] cell, _ in
                guard let self = self else { return }
                cell.height = { 56 }

                // 初始 accessoryView：如果上面的 rowInit 没跑到，这里再兜一层
                if cell.accessoryView == nil {
                    self.updateIconAccessoryView(for: cell)
                }
            }
            .onCellSelection(imageRowSelected)

            +++ Section()
            <<< TextRow(FormTag.title) { row in
                row.title = NSLocalizedString("Title", comment: "")
                if case let .edit(group) = mode {
                    row.value = group.title
                }
            }
    }

    private func applyModeToUI() {
        switch mode {
        case .create:
            navigationItem.title = NSLocalizedString("New Group", comment: "")
        case let .edit(group):
            navigationItem.title = NSLocalizedString("Edit Group", comment: "")
            if let titleRow: TextRow = form.rowBy(tag: FormTag.title) {
                titleRow.value = group.title
                titleRow.updateCell()
            }
            if let imageRow: ImageRow = form.rowBy(tag: FormTag.icon),
               let imageCell = imageRow.cell as? ImageCell {
                updateIconAccessoryView(for: imageCell)
            }
        }
    }

    func configure(with group: KPKGroup) {
        mode = .edit(group)
        iconId = Int(group.iconId)
        iconColorId = group.iconColorId
        if isViewLoaded {
            applyModeToUI()
        }
    }

    // MARK: - 自定义右侧图标视图（完全居中）

    private func updateIconAccessoryView(for cell: ImageCell) {
        if #available(iOS 13.0, *) {
            let iconIndex = iconId ?? 0
            let colorIndex = IconColors.normalizedIndex(iconColorId)

            let symbolName = Icons.sfSymbolNames[safe: iconIndex] ?? "folder"
            let tint = IconColors.resolvedColor(for: colorIndex)

            cell.accessoryView = makeIconAccessoryView(
                symbolName: symbolName,
                color: tint
            )
        } else {
            let imageView = UIImageView(image: UIImage(named: "48_FolderTemplate"))
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
            cell.accessoryView = imageView
        }
    }

    private func makeIconAccessoryView(symbolName: String, color: UIColor) -> UIView {
        let size: CGFloat = 32
        let container = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))

        let bgView = UIView()
        bgView.translatesAutoresizingMaskIntoConstraints = false
        bgView.backgroundColor = color.withAlphaComponent(0.12)
        bgView.layer.cornerRadius = size / 2
        bgView.layer.masksToBounds = true

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = color

        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            imageView.image = UIImage(systemName: symbolName, withConfiguration: config)
        } else {
            imageView.image = UIImage(named: "48_FolderTemplate")
        }

        container.addSubview(bgView)
        bgView.addSubview(imageView)

        NSLayoutConstraint.activate([
            bgView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bgView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            bgView.widthAnchor.constraint(equalToConstant: size),
            bgView.heightAnchor.constraint(equalToConstant: size),

            imageView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        return container
    }

    // MARK: - 图标选择

    func imageRowSelected(cell: ImageCell, row: ImageRow) {
        if row.isDisabled { return }

        let selectIconViewController = SelectIconViewController()
        selectIconViewController.initialIconIndex = iconId ?? 0
        selectIconViewController.initialColorIndex = iconColorId ?? 0

        selectIconViewController.didSelectAction = { [weak self, weak cell] _, iconIndex, colorIndex in
            guard let self = self, let cell = cell else { return }

            self.iconId = iconIndex
            self.iconColorId = IconColors.normalizedIndex(colorIndex)

            self.updateIconAccessoryView(for: cell)
            cell.setNeedsLayout()
        }

        navigationController?.pushViewController(selectIconViewController, animated: true)
    }

    // MARK: - Done

    @objc func doneButtonTapped(sender _: Any) {
        let titleValue = (form.rowBy(tag: FormTag.title) as? TextRow)?.value
        let updatedIconId = iconId ?? 0
        let updatedIconColorId = IconColors.normalizedIndex(iconColorId)

        switch mode {
        case .create:
            let group = KPKGroup()
            group.title = titleValue
            group.iconId = updatedIconId
            group.iconColorId = updatedIconColorId
            delegate?.addGroup(self, didAddGroup: group)
        case let .edit(group):
            group.title = titleValue
            group.iconId = updatedIconId
            group.iconColorId = updatedIconColorId
            delegate?.addGroup(self, didEditGroup: group)
        }
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - 小工具：安全下标

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
