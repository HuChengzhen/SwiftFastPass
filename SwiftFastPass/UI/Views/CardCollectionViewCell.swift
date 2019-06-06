//
//  CardCollectionViewCell.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit
import SnapKit

protocol CardCollectionViewCellDelegate: class {
    func cardCollectionViewCellDeleteButtonTapped(cell: CardCollectionViewCell)
}

class CardCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    let scrollView: SendEventScrollView
    let cardView: UIView
    let deleteButton: UIButton
    weak var delegate: CardCollectionViewCellDelegate?
    
    override init(frame: CGRect) {
        scrollView = SendEventScrollView()
        cardView = UIView()
        deleteButton = UIButton(type: .system)
        super.init(frame: frame)
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = UIColor.systemBackground
        } else {
            contentView.backgroundColor = UIColor.white
        }
    
        contentView.addSubview(scrollView)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(contentView)
        }
        
        scrollView.addSubview(cardView)
        if #available(iOS 13.0, *) {
            cardView.backgroundColor = UIColor.secondarySystemGroupedBackground
        } else {
            cardView.backgroundColor = UIColor.white
        }
        cardView.layer.cornerRadius = 10
        cardView.layer.shadowColor = UIColor.darkGray.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 0)
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowRadius = 10
        cardView.clipsToBounds = false
        cardView.layer.masksToBounds = false
        cardView.snp.makeConstraints { (make) in
            make.left.equalTo(self.scrollView).offset(10)
            make.top.bottom.equalTo(self.scrollView)
            make.height.equalTo(self.contentView)
            make.width.equalTo(UIScreen.main.bounds.size.width - 10 * 2)
        }
        
        scrollView.addSubview(deleteButton)
        deleteButton.backgroundColor = UIColor.red
        deleteButton.tintColor = UIColor.white
        deleteButton.layer.cornerRadius = 22
        deleteButton.setImage(UIImage(named: "Delete"), for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped(sender:)), for: .touchUpInside)
        deleteButton.snp.makeConstraints { (make) in
            make.left.equalTo(cardView.snp.right).offset(32)
            make.right.equalTo(scrollView).offset(-20)
            make.centerY.equalTo(scrollView)
            make.width.height.equalTo(44)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func deleteButtonTapped(sender: Any) {
        delegate?.cardCollectionViewCellDeleteButtonTapped(cell: self)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if targetContentOffset.pointee.x > 30 {
            targetContentOffset.pointee.x = scrollView.contentSize.width - UIScreen.main.bounds.width
        } else {
            targetContentOffset.pointee.x = 0
        }
    }
    
    func didHighlight() {
        if scrollView.contentOffset.x == 0 {
            UIView.animate(withDuration: 0.3) {
                self.cardView.transform = CGAffineTransform(scaleX: 0.99, y: 0.9)
            }
            
            cardView.layer.removeAnimation(forKey: "shadowAnimation")
            
            let animation = CABasicAnimation(keyPath: "shadowRadius")
            animation.fromValue = cardView.layer.presentation()?.shadowRadius
            animation.toValue = 30
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            animation.duration = 0.3
            
            cardView.layer.add(animation, forKey: "shadowAnimation")
        }
    }
    
    func didUnhighlight() {
        if (scrollView.contentOffset.x == 0) {
            UIView.animate(withDuration: 0.3) {
                self.cardView.transform = .identity
            }
            cardView.layer.removeAnimation(forKey: "shadowAnimation")
            
            cardView.layer.removeAllAnimations()
            let animation = CABasicAnimation(keyPath: "shadowRadius")
            animation.fromValue = cardView.layer.presentation()?.shadowRadius
            animation.toValue = 10
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            animation.duration = 0.3
            
            cardView.layer.add(animation, forKey: "shadowAnimation")
        }
    }
}
