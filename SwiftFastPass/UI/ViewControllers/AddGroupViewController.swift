//
//  AddGroupViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/9.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import KeePassKit
import Eureka

protocol AddGroupDelegate: class {
    func addGroup(_ controller: AddGroupViewController, didAddGroup group: KPKGroup)
}


class AddGroupViewController: FormViewController {

    weak var delegate: AddGroupDelegate?
    var iconId: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Do any additional setup after loading the view.
    }
    
    func setupUI() {
        navigationItem.title = NSLocalizedString("New Group", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(sender:)))
        
        form +++ Section()
            <<< ImageRow("icon") { row in
                row.title = NSLocalizedString("Icon", comment: "")
                row.sourceTypes = []
                row.value = UIImage(named: "48_FolderTemplate")
                
                }
                .cellSetup({ (cell, row) in
                    if #available(iOS 13.0, *) {
                        cell.accessoryView?.tintColor = UIColor.label
                    } else {
                        cell.accessoryView?.tintColor = UIColor.black
                    }
                })
                .onCellSelection(self.imageRowSelected)
            +++ Section()
            <<< TextRow("title") { row in
                row.title = NSLocalizedString("Title", comment: "")
        }
    }
    
    func imageRowSelected(cell: ImageCell, row: ImageRow) {
        if !row.isDisabled {
            let selectIconViewController =  SelectIconViewController()
            selectIconViewController.didSelectAction = { (viewController, iconId) in
                self.iconId = iconId
                row.value = UIImage(named: Icons.iconNames[iconId])
                row.updateCell()
            }
            
            self.navigationController?.pushViewController(selectIconViewController, animated: true)
        }
    }
    
    @objc func doneButtonTapped(sender: Any) {
        let group = KPKGroup()
        group.title = (form.rowBy(tag: "title") as! TextRow).value
        group.iconId = iconId ?? 48
        
        delegate?.addGroup(self, didAddGroup: group)
        self.navigationController?.popViewController(animated: true)
    }
}
