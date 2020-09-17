import UIKit


extension UIViewController {
    func report(error: Error?) {
        guard let error = error else {
            return
        }
        
        let errorDetails = (error as NSError).localizedFailureReason
        let alert = UIAlertController(title: error.localizedDescription, message: errorDetails, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
