//
//  LockViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/7.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import Eureka

class LockViewController: FormViewController {

    var file: File!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if let password = file.password {
            
        }
    }
    
    private func setupUI() {
        navigationItem.title = file.name
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Open", comment: ""), style: .done, target: self, action: #selector(openButtonTapped(sender:)))
        form +++ Section()
            <<< PasswordRow("password") { row in
                row.title = NSLocalizedString("Password", comment: "")
                row.placeholder = NSLocalizedString("Enter password here", comment: "")
            }
            +++ Section()
            <<< ButtonRow("keyFile") { row in
                row.title = NSLocalizedString("Select Key File", comment: "")
                }.onCellSelection(self.keyFileButtonTapped)
    }
    
    @objc func openButtonTapped(sender: Any) {
        
    }
    
    func keyFileButtonTapped(cell: ButtonCellOf<String>, row: ButtonRow) {
        
    }
}
