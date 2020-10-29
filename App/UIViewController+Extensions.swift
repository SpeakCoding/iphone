import UIKit
import MobileCoreServices


extension UIViewController {
    func report(error: Error?) {
        guard let error = error else {
            return
        }
        
        let errorDetails = (error as NSError).localizedFailureReason
        let alert = UIAlertController(title: error.localizedDescription, message: errorDetails, preferredStyle: UIAlertController.Style.actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private static var imagePickerDelegate: ImagePickerDelegate? = nil
    func presentImagePicker(completion: ((UIImage) -> Void)?) {
        let delegate = ImagePickerDelegate(presentingViewController: self) { (image: UIImage?, picker: UIImagePickerController) -> Void in
            if image != nil {
                if completion != nil {
                    completion!(image!)
                } else {
                    let vc = PhotoPickerPreviewController(image: image!) { (newPost: Post) in
                        self.dismiss(animated: true, completion: nil)
                        UIViewController.imagePickerDelegate = nil
                    }
                    picker.pushViewController(vc, animated: true)
                    return
                }
            }
            self.dismiss(animated: true, completion: nil)
            UIViewController.imagePickerDelegate = nil
        }
        UIViewController.imagePickerDelegate = delegate
        
        let cameraIsAvailable = UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)
        let libraryIsAvailable = UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary)
        if cameraIsAvailable || libraryIsAvailable {
            // Show the image picker/camera immediately if only one of them is available
            if cameraIsAvailable && !libraryIsAvailable {
                delegate.presentImagePicker(source: UIImagePickerController.SourceType.camera)
                return
            }
            if libraryIsAvailable && !cameraIsAvailable {
                delegate.presentImagePicker(source: UIImagePickerController.SourceType.photoLibrary)
                return
            }
            
            // Ask the user what to show, the image picker or the camera
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
            alert.addAction(UIAlertAction(title: "Take a photo", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                delegate.presentImagePicker(source: UIImagePickerController.SourceType.camera)
            }))
            alert.addAction(UIAlertAction(title: "Upload from library", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                delegate.presentImagePicker(source: UIImagePickerController.SourceType.photoLibrary)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: nil, message: "Sorry neither the camera nor the photo library is available.", preferredStyle: UIAlertController.Style.actionSheet)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}


fileprivate class ImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var presenter: UIViewController
    private var completion: (UIImage?, UIImagePickerController) -> Void
    
    init(presentingViewController: UIViewController, completion: @escaping (UIImage?, UIImagePickerController) -> Void) {
        self.presenter = presentingViewController
        self.completion = completion
        super.init()
    }
    
    func presentImagePicker(source: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = source
        imagePicker.mediaTypes = [kUTTypeImage as String]
        if source == UIImagePickerController.SourceType.camera {
            imagePicker.cameraCaptureMode = UIImagePickerController.CameraCaptureMode.photo
        }
        imagePicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        imagePicker.delegate = self
        self.presenter.present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        self.completion(image, picker)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.completion(nil, picker)
    }
}
