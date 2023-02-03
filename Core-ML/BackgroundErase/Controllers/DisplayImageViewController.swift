//
//  DisplayImageViewController.swift
//  BackgroundErase
//
//  Created by iApp on 13/01/23.
//

import UIKit
import Photos


class DisplayImageViewController: UIViewController {

    @IBOutlet weak var cropedImage: UIImageView!
    @IBOutlet weak var displayImage: UIImageView!
    var selectedImage: UIImage?
    var cropImage: UIImage?

    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.displayImage.image = selectedImage
        self.cropedImage.image = cropImage
        guard let _image = selectedImage?.resized(withPercentage: 1) else{return}
        guard let _maskimage = cropedImage?.image?.resized(withPercentage: 1) else{return}

        ///SAVING IMAGE IN CREATED ALBUM
        CustomPhotoAlbum.sharedInstance.saveImage(image: _image)
        CustomPhotoAlbum.sharedInstance.saveImage(image: _maskimage)
      
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

}

