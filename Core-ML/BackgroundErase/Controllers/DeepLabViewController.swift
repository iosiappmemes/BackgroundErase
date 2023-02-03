//
//  DeepLabViewController.swift
//  BackgroundErase
//
//  Created by Walter Tyree on 6/7/22.
//

import OSLog
import UIKit
import CoreImage
import Vision
import BackgroundRemoval
import CoreML


class DeepLabViewController: UIViewController {
    
    // MARK: OUTLETS
    
    @IBOutlet weak var addView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sliderView: UIView!
    @IBOutlet var originalImage: UIImageView!
    @IBOutlet weak var backgroundImageSlider: UISlider!
    @IBOutlet weak var mainImageSlider: UISlider!
    
    // MARK: CLASS VARIABLES

    private var request: VNCoreMLRequest?
    private var visionModel: VNCoreMLModel?
    private var original: UIImage?
    private var gaussBlurForMainImage: CGFloat = 20
    private var gaussBlurForBackgroundImage: CGFloat = 1
    private var finalImageMask: UIImage?
    private var croppedImage: UIImage?
    private var backgroundImgaes = ["transparent_white","building","firy","snow","grass","starfield","transparent_black"]
    private var selectedBackgroundImgaes: String = ""
    private let imagePickerController = UIImagePickerController()
    private var imageURL : URL?
    var shownImage: UIImage?


    fileprivate let segmentationModel: DeepLabV3 = {
        do {
            let config = MLModelConfiguration()
            return try DeepLabV3(configuration: config)
        } catch {
            Logger().error("Error loading model.")
            abort()
        }
    }()
    
    // MARK: VIEW LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        self.original = UIImage(named:"modi")
        self.setupMLModel()
        imagePickerController.delegate = self
        mainImageSlider.addTarget(self, action: #selector(onMainSliderValChanged(slider:event:)), for: .valueChanged)
        backgroundImageSlider.addTarget(self, action: #selector(onBackgroundSliderValChanged(slider:event:)), for: .valueChanged)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        originalImage.image = original
        self.addView.layer.cornerRadius = self.addView.frame.size.width/2
        self.originalImage.layer.cornerRadius = self.originalImage.frame.size.width/2

    }
    
    // MARK: CORE-ML SETUP

    private func setupMLModel(){
        
        if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            Logger().error("Could not create request.")
            abort()
        }
    }
    
    // MARK: CORE-ML PREDICTION

    private func predict(with cgImage: CGImage?) {
        guard let request = request else { fatalError() }
        guard let cgImage = cgImage else {
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    // MARK: GET BACKGROUND MASK

    fileprivate func getImageMask(_ image: UIImage) {
        
        self.finalImageMask = image
        self.sliderView.isHidden = false
        applyBackgroundMask(mainGaussBlur: gaussBlurForMainImage, backgroundGaussBlur: gaussBlurForBackgroundImage)
    }
    
    // MARK: APPLY BACKGROUND MASK

    private func applyBackgroundMask(mainGaussBlur:CGFloat,backgroundGaussBlur:CGFloat){
        
        guard let originalCGImage = self.original?.cgImage else {return}
        let mainImage = CIImage(cgImage: originalCGImage)
        let originalSize = mainImage.extent.size
        let maskUIImage = finalImageMask?.resized(to: originalSize)
        guard let maskUICGImage = maskUIImage?.cgImage else {return}
        var maskImage = CIImage(cgImage: maskUICGImage)
        
        ///CORE-ML BACKGROUND POD(if needed)
        let image = BackgroundRemoval.init().removeBackground(image: UIImage(cgImage: originalCGImage))
        self.croppedImage = image

        DispatchQueue.main.async {
            
            // Scale the mask image to fit the bounds of the video frame.
            maskImage = maskImage.applyingGaussianBlur(sigma: mainGaussBlur)
            let backgroundUIImage = UIImage(named: self.selectedBackgroundImgaes)?.resized(to: originalSize)
            guard let backgroundCGImage = backgroundUIImage?.cgImage else {return}
            var background = CIImage(cgImage: backgroundCGImage)
            
            background = background.applyingGaussianBlur(sigma: backgroundGaussBlur)
            let filter = CIFilter(name: "CIBlendWithMask")
            filter?.setValue(background, forKey: kCIInputBackgroundImageKey)
            filter?.setValue(mainImage, forKey: kCIInputImageKey)
            filter?.setValue(maskImage, forKey: kCIInputMaskImageKey)
            
            guard let filterOutput = filter?.outputImage else {return}
            let img = UIImage(ciImage: filterOutput)

            guard let _image = img.resized(withPercentage: 0.99) else{return}
            self.originalImage.image = _image

            ///APPLY BACKGROUND COLOR INSTEAD OF IMAGE(if needed)
     //       self.originalImage.backgroundColor = .red
//            self.originalImage.tintColor = .green
            
            Logger().info("Done: \(Date(), privacy: .public)")
        }

    }
    
    // MARK: IMAGE DETECTION

    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let segmentationmap = observations.first?.featureValue.multiArrayValue {
            guard let maskUIImage = segmentationmap.image(min: 0.0, max: 1.0) else { return }
            
            getImageMask(maskUIImage)
        }
    }

    
    // MARK: BUTTON/SLIDER TARGETS
    
    @objc func onMainSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
              break

            case .moved:
              break

            case .ended:
                let currentValue = CGFloat(slider.value)
                self.gaussBlurForMainImage = currentValue
                applyBackgroundMask(mainGaussBlur: self.gaussBlurForMainImage, backgroundGaussBlur: self.gaussBlurForBackgroundImage)
            default:
                break
            }
        }
    }
    
    @objc func onBackgroundSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
              break

            case .moved:
              break

            case .ended:
                let currentValue = CGFloat(slider.value)
                self.gaussBlurForMainImage = currentValue
                applyBackgroundMask(mainGaussBlur: self.gaussBlurForMainImage, backgroundGaussBlur: self.gaussBlurForBackgroundImage)
            default:
                break
            }
        }
    }
    
    // MARK: BUTTON/ ACTIONS

    
    @IBAction func addImageBtnTap(_ sender: Any) {
        
        self.present(imagePickerController, animated: true, completion: nil)

    }
    
    @IBAction func showBtnTap(_ sender: Any) {
        
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "DisplayImageViewController") as? DisplayImageViewController else {return}
        vc.selectedImage = self.originalImage.image
        vc.cropImage = self.croppedImage

        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBAction func segmentBtnTap(_ sender: UIButton) {
        
        if !(self.imageURL?.pathComponents.isEmpty ?? false){
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "CroppedViewController") as? CroppedViewController else {return}
            vc.imageURL = self.imageURL
            vc.shownImage = self.shownImage
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func filterBtnTap(_ sender: Any) {
        
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "FilterViewController") as? FilterViewController else {return}
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

// MARK: EXTENSION COLLECTION VIEW

extension DeepLabViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        self.backgroundImgaes.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.height/3 + 30, height: self.collectionView.frame.height)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as? ImageCollectionViewCell else{return UICollectionViewCell()}
        cell.backgroundImage.image = UIImage(named:backgroundImgaes[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selectedBackgroundImgaes = backgroundImgaes[indexPath.item]
        
        Logger().info("Start: \(Date(), privacy: .public)")
        predict(with: original?.cgImage)
    }
    
}

// MARK: EXTENSION IMAGE PICKER

extension DeepLabViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let url = info[.imageURL] as? URL {
         self.imageURL = url
        }
        if let image = info[.originalImage] as? UIImage{
            self.shownImage = image
            originalImage.image = image
            original = image
            if !selectedBackgroundImgaes.isEmpty{
                Logger().info("Start: \(Date(), privacy: .public)")
                predict(with: original?.cgImage)
            }
            dismiss(animated: true, completion: nil)
        }
    }
}
