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
    
    private static let imageCache: ImageCache = {
        let imageCacheURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!.appendingPathComponent("Images")
        return ImageCache(__memoryCapacity: 0, diskCapacity: 50 * 1024 * 1024, directoryURL: imageCacheURL)
    }()
    
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = AsynchronousImageView.imageCache
        configuration.requestCachePolicy = URLRequest.CachePolicy.returnCacheDataElseLoad
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()
    
    private var currentImageURL: URL?
    private var imageDownloadTask: URLSessionDataTask?
    
    func showImageAsynchronously(imageURL: URL?) {
        // If the new image is nil, cancel the image download in progress and reset the displayed image
        guard let imageURL = imageURL else {
            self.image = nil
            self.currentImageURL = nil
            self.imageDownloadTask?.cancel()
            self.imageDownloadTask = nil
            return
        }
        
        // If the new image has the same URL as the current image, we don't have to do anything
        if self.currentImageURL == imageURL {
            return
        }
        self.currentImageURL = imageURL
        
        // Cancel the image download in progress we might have
        self.imageDownloadTask?.cancel()
        
        // Use a cached image if any
        if let cachedImage = AsynchronousImageView.imageCache.cachedImageFor(url: self.currentImageURL!) {
            self.image = cachedImage
            self.imageDownloadTask = nil
            return
        }
        
        // Reset the displayed image while we download the new one
        self.image = nil
        
        // Start downloading the new image
        func processImageRequestResult(downloadedData: Data?, response: URLResponse?, error: Error?) {
            // If we have cancelled the task with self.imageDownloadTask?.cancel(), do nothing
            if error != nil && (error! as NSError).code == NSURLErrorCancelled {
                return
            }
            
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
        self.imageDownloadTask = AsynchronousImageView.session.dataTask(with: self.currentImageURL!, completionHandler: processImageRequestResult)
        self.imageDownloadTask?.resume()
    }
}


class ImageCache: URLCache {
    override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) {
        // By default the URLCache processes HTTP redirections by associating the received data with the last request made.
        // That is, if the server redirects to a random URL for every image request (say, in the name of security),
        // we cannot look up cached images by their original URLs.
        // This implementation associates the received data with the original request instead.
        if let originalRequest = dataTask.originalRequest, let currentRequest = dataTask.currentRequest {
            if originalRequest.url != currentRequest.url {
                super.storeCachedResponse(cachedResponse, for: originalRequest)
                return
            }
        }
        super.storeCachedResponse(cachedResponse, for: dataTask)
    }
    
    func cachedImageFor(url: URL) -> UIImage? {
        let request = URLRequest(url: url)
        if let cachedResponse = self.cachedResponse(for: request) {
            return UIImage(data: cachedResponse.data)
        }
        return nil
    }
}
