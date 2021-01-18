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
        func handlePickedImage(image: UIImage?, picker: UIImagePickerController) {
            if image != nil {
                if completion != nil {
                    completion!(image!)
                } else {
                    let postComposer = PostComposerViewController(image: image!) { (newPost: Post) in
                        self.dismiss(animated: true, completion: nil)
                        UIViewController.imagePickerDelegate = nil
                    }
                    if picker.sourceType == UIImagePickerController.SourceType.camera {
                        postComposer.navigationItem.hidesBackButton = true
                    }
                    picker.pushViewController(postComposer, animated: true)
                    return
                }
            }
            self.dismiss(animated: true, completion: nil)
            UIViewController.imagePickerDelegate = nil
        }
        let delegate = ImagePickerDelegate(presentingViewController: self, completion: handlePickedImage)
        UIViewController.imagePickerDelegate = delegate
        
        let cameraIsAvailable = UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)
        let libraryIsAvailable = UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary)
        if cameraIsAvailable || libraryIsAvailable {
            func takePhoto(_: UIAlertAction?) {
                delegate.presentImagePicker(source: UIImagePickerController.SourceType.camera)
            }
            func selectPhoto(_: UIAlertAction?) {
                delegate.presentImagePicker(source: UIImagePickerController.SourceType.photoLibrary)
            }
            
            // Show the image picker/camera immediately if only one of them is available
            if cameraIsAvailable && !libraryIsAvailable {
                takePhoto(nil)
                return
            }
            if libraryIsAvailable && !cameraIsAvailable {
                selectPhoto(nil)
                return
            }
            
            // Ask the user what to show, the image picker or the camera
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
            alert.addAction(UIAlertAction(title: "Take a photo", style: UIAlertAction.Style.default, handler: takePhoto))
            alert.addAction(UIAlertAction(title: "Upload from library", style: UIAlertAction.Style.default, handler: selectPhoto))
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
