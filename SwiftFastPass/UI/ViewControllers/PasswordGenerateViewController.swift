//
//  PasswordGenerateViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/10.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import Eureka
import SnapKit

protocol PasswordGenerateDelegat: class {
    func passwordGenerate(_ viewController: PasswordGenerateViewController, didGenerate password: String)
}

class PasswordGenerateViewController: FormViewController {

    weak var delegate: PasswordGenerateDelegat?
    
    lazy var passwordView: UIView  = {
        let view =  UIView()
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 220)
        return view
    }()
    
    var passwordLabel: UILabel = {
        let lable = UILabel()
        lable.font = UIFont(name: "DejaVuSansMono-Bold", size: 40)
        lable.adjustsFontSizeToFitWidth = true
        lable.textAlignment = .center
        return lable
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updatePassword()
    }

    func setupUI() {
        navigationItem.title = NSLocalizedString("Generate Password", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(sender:)))
        
        form +++ Section() { section in
            let header = HeaderFooterView(.callback({ () -> UIView in
                self.passwordView.addSubview(self.passwordLabel)
                
                self.passwordLabel.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview().inset(10)
                }
                
                return self.passwordView
            }))
            section.header = header
            }
            +++ Section("Allowed Character Set")
            <<< CheckRow("A-Z") { row in
                row.title = "A - Z"
                row.value = true
            }.onChange(self.checkRowOnChange(row:))
            <<< CheckRow("a-z") { row in
            row.title = "a - z"
            row.value = true
            }.onChange(self.checkRowOnChange(row:))
            <<< CheckRow("0-9") { row in
                row.title = "0 - 9"
                row.value = true
                }.onChange(self.checkRowOnChange(row:))
            <<< CheckRow("#!?") { row in
                row.title = "#!?"
                row.value = true
                }.onChange(self.checkRowOnChange(row:))
            
            +++ Section()
            <<< SliderRow("length") { row in
                row.title = NSLocalizedString("Length", comment: "")
                row.value = 16
                row.steps = 119
                row.displayValueFor =  {
                    return String(Int($0 ?? 0))
                }
                }.cellSetup({ (cell, row) in
                    cell.slider.minimumValue = 1
                    cell.slider.maximumValue = 120
                }).onChange(self.lengthRowOnChange(row:))
    }

    @objc func doneButtonTapped(sender: Any) {
        delegate?.passwordGenerate(self, didGenerate: passwordLabel.text ?? "")
        self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate func updatePassword() {
        let upCell = form.rowBy(tag: "A-Z") as! CheckRow
        let lowCell = form.rowBy(tag: "a-z") as! CheckRow
        let numberCell = form.rowBy(tag: "0-9") as! CheckRow
        let symbolCell  = form.rowBy(tag: "#!?") as! CheckRow
        
        let up: UInt = upCell.value! ? (1<<0) : 0
        let low: UInt = lowCell.value! ? (1<<1) : 0
        let number: UInt = numberCell.value! ? (1<<2) : 0
        let symbol: UInt = symbolCell.value! ? (1<<3) : 0
        
        let flag: MPPasswordCharacterFlags = MPPasswordCharacterFlags(rawValue: up | low | number | symbol)
        
        if flag.rawValue == 0 {
            form.delegate = nil
            [upCell, lowCell, numberCell, symbolCell].forEach { (row) in
                row.value = true
                row.updateCell()
            }
            form.delegate = self
            updatePassword()
            return
        }
        
        let length = UInt((form.rowBy(tag: "length") as! SliderRow).value!)
        
        let password = NSString.password(withCharactersets: flag, withCustomCharacters: nil, ensureOccurence: false, length: length)
        print(flag)
        self.passwordLabel.text = password
        
    }
    
    func checkRowOnChange(row: CheckRow) {
        updatePassword()
    }
    
    func lengthRowOnChange(row: SliderRow) {
        updatePassword()
    }
}
