//
//  ImageCollectionViewCell.swift
//  BackgroundErase
//
//  Created by iApp on 16/01/23.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    
    override var isSelected: Bool {
        didSet{
            if self.isSelected {
                UIView.animate(withDuration: 0.3) { // for animation effect
                    self.backgroundColor = UIColor(red: 115/255, green: 190/255, blue: 170/255, alpha: 1.0)
                }
            }
            else {
                UIView.animate(withDuration: 0.3) { // for animation effect
                    self.backgroundColor = .clear
                }
            }
        }
    }
}


