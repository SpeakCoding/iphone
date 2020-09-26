import UIKit


/**
 This class represents an image view which knows how to download images.
 Downloading images takes time, depending on how large they are
 and on the internet connection speed.
 We don't want to block the app's interface while we download images,
 so the image view makes an **asynchronous** network request,
 meaning it receives a result some time later.
 */
class AsynchronousImageView: UIImageView {
    
    private var currentImageURL: URL?
    private var imageDownloadTask: URLSessionDataTask?
    
    func showImageAsynchronously(imageURL: URL?) {
        // If the new image is nil, cancel the image download in progress and reset the displayed image
        guard let imageURL = imageURL else {
            image = nil
            currentImageURL = nil
            imageDownloadTask?.cancel()
            imageDownloadTask = nil
            return
        }
        
        // If the new image has the same URL as the current image, we don't have to do anything
        if currentImageURL == imageURL {
            return
        }
        currentImageURL = imageURL
        
        // Reset the displayed image while we download the new one
        image = nil
        
        // Cancel the image download in progress we might have
        imageDownloadTask?.cancel()
        
        // Start downloading the new image
        imageDownloadTask = AsynchronousImageView.session.dataTask(with: currentImageURL!) { (downloadedData: Data?, response: URLResponse?, error: Error?) in
            // The completion closure is called on a secondary thread,
            // make sure we assign the image on the main thread
            DispatchQueue.main.async {
                if self.currentImageURL == imageURL {
                    if (downloadedData != nil) {
                        if let uiImage = UIImage(data: downloadedData!) {
                            self.image = uiImage
                        } // else the data we received is not image data, e.g. it's an HTML page with an error message
                    } // else we couldn't download the image due to a network error, etc.
                    self.imageDownloadTask = nil
                } // else showImageAsynchronously() was called again while a previous image was still being downloaded
            }
        }
        imageDownloadTask?.resume()
    }
    
    static let session = initSession()
    private class func initSession() -> URLSession {
        if ProcessInfo().arguments.contains("mock-api") {
            let sharedSessionConfig = URLSessionConfiguration.default;
            sharedSessionConfig.protocolClasses = [MockURLProtocol.self]
            return URLSession(configuration: sharedSessionConfig)
        }
        return URLSession.shared
    }
}
