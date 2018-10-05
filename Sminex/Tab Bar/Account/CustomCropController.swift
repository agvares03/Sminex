//
//  ViewController.swift
//  ImageCropper2
//
//  Created by Aatish Rajkarnikar on 2/14/17.
//  Copyright © 2017 Aatish Rajkarnikar. All rights reserved.
//

import UIKit

class CustomCropController: UIViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var imageViewWidth: NSLayoutConstraint!
    @IBOutlet var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var imgTop: NSLayoutConstraint!
    @IBOutlet weak var imgBottom: NSLayoutConstraint!
    @IBOutlet var view2: UIView!
    @IBOutlet var image2: UIImageView!
    var imageCrop: UIImage!
    
    @IBAction func backBtn(_ sender: UIButton) {
        self.removeFromParentViewController()
        self.view.removeFromSuperview()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        setImageToCrop(image: imageCrop)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        navigationController?.isNavigationBarHidden = false
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    var scle: CGFloat = 0
    func setImageToCrop(image:UIImage){
        imageView.image = image
//        self.imgTop.constant = 150
        self.imgBottom.constant = image.size.height / 2
        imageViewWidth.constant = image.size.width
        imageViewHeight.constant = image.size.height
        let scaleHeight = scrollView.frame.size.width/image.size.width
        let scaleWidth = scrollView.frame.size.height/image.size.height
        scrollView.minimumZoomScale = max(scaleWidth, scaleHeight)
        scrollView.zoomScale = max(scaleWidth, scaleHeight)
        scle = max(281.5/image.size.height, scaleHeight)
        print(scaleHeight, scaleWidth, scrollView.zoomScale)
    }
    
    @IBAction func cropButtonPressed(_ sender: Any) {
//        let scale:CGFloat = 1/scrollView.zoomScale
        let scale:CGFloat = 1/scle
        let x:CGFloat = scrollView.contentOffset.x * scale
        let y:CGFloat = scrollView.contentOffset.y + imgTop.constant * scale
        print(x, y, scale, scrollView.zoomScale)
        let height:CGFloat = scrollView.frame.size.width * scale
        let width:CGFloat = scrollView.frame.size.width * scale
        let croppedCGImage = imageView.image?.cgImage?.cropping(to: CGRect(x: x, y: y, width: width, height: height))
        print(x, y, width, height)
        let croppedImage = UIImage(cgImage: croppedCGImage!)
        
        DispatchQueue.global(qos: .background).async {
            UserDefaults.standard.setValue(UIImagePNGRepresentation(resizeImageWith(image: croppedImage, newSize: CGSize(width: 128, height: 128))), forKey: "accountIcon")
        }
        self.removeFromParentViewController()
        self.view.removeFromSuperview()
    }
}
