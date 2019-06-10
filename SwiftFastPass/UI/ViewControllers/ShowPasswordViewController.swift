//
//  ShowPasswordViewController.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/10.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import SnapKit
class ShowPasswordViewController: UIViewController {
    
    var password: String!
    var outerView: UIView!
    var passwordLabel: UILabel!
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor.clear
        
        outerView = UIView()
        view.addSubview(outerView)
        outerView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        if #available(iOS 13.0, *) {
//            outerView.backgroundColor = UIColor.label.withAlphaComponent(0.1)
            outerView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        } else {
            outerView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        }
        outerView.layer.cornerRadius = 10
        
        passwordLabel = UILabel()
        outerView.addSubview(passwordLabel)
        passwordLabel.font = UIFont(name: "DejaVuSansMono-Bold", size: 40)
        passwordLabel.text = password
        passwordLabel.lineBreakMode = .byCharWrapping
        passwordLabel.numberOfLines = 0

        passwordLabel.snp.makeConstraints { (make) in
            make.width.lessThanOrEqualTo(UIScreen.main.bounds.width * 0.80)
            make.edges.equalToSuperview().inset(10)
        }
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewDidTapped(sender:))))
    }
    
    @objc func viewDidTapped(sender: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
}
