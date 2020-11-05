import UIKit


class TaggedImageView: AsynchronousImageView {
    
    @IBOutlet weak var delegate: UserTaggingViewController?
    private var tagCalloutViews = [TagCalloutView]()
    var tags = [Tag]() {
        didSet {
            for tagCalloutView in self.tagCalloutViews {
                tagCalloutView.removeFromSuperview()
            }
            self.tagCalloutViews.removeAll()
            
            for tag in self.tags {
                let tagCalloutView = TagCalloutView(tag: tag)
                self.tagCalloutViews.append(tagCalloutView)
                self.addSubview(tagCalloutView)
            }
            
            // This will cause layoutSubviews() to be called when appropriate
            self.setNeedsLayout()
        }
    }
    
    func addTag(_ tag: Tag) {
        self.tags.append(tag)
    }
    
    // MARK: - Placing and dragging callout views
    
    private var draggedTagCalloutView: TagCalloutView?
    private var draggedTagCalloutViewPoint = CGPoint.zero
    private var dragStartLocation = CGPoint.zero
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for tagCalloutView in self.tagCalloutViews {
            if tagCalloutView.point(inside: touches.first!.location(in: tagCalloutView), with: event) {
                self.draggedTagCalloutView = tagCalloutView
                self.draggedTagCalloutViewPoint = self.convert(tagCalloutView.point, from: tagCalloutView)
                self.dragStartLocation = touches.first!.location(in: self)
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        self.moveDraggedTagCalloutView(point: point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        
        if let theDraggedView = self.draggedTagCalloutView {
            // Finalize the position of the dragged callout view
            self.moveDraggedTagCalloutView(point: point)
            if theDraggedView.isHidden {
                self.tags.removeAll { $0 === theDraggedView.representedTag }
                self.tagCalloutViews.removeAll { $0 === theDraggedView }
                theDraggedView.removeFromSuperview()
            } else {
                let absolutePoint = self.convert(theDraggedView.point, from: theDraggedView)
                theDraggedView.representedTag.point = self.convertToRelative(point: absolutePoint)
            }
            self.draggedTagCalloutView = nil
        } else {
            // Create a new callout view
            self.delegate?.tagUserForPointInImage(point: self.convertToRelative(point: point))
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.draggedTagCalloutView?.isHidden = false
        self.draggedTagCalloutView = nil
    }
    
    private func moveDraggedTagCalloutView(point: CGPoint) {
        if let theDraggedView = self.draggedTagCalloutView {
            let dragDistance = CGVector(dx: point.x - self.dragStartLocation.x, dy: point.y - self.dragStartLocation.y)
            let dragEndLocation = CGPoint(x: self.draggedTagCalloutViewPoint.x + dragDistance.dx, y: self.draggedTagCalloutViewPoint.y + dragDistance.dy)
            self.layoutTagCalloutView(theDraggedView, point: dragEndLocation)
            theDraggedView.isHidden = !self.bounds.contains(dragEndLocation)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for tagCalloutView in self.tagCalloutViews {
            let absolutePoint = self.convertToAbsolute(point: tagCalloutView.representedTag.point)
            self.layoutTagCalloutView(tagCalloutView, point: absolutePoint)
        }
    }
    
    private func layoutTagCalloutView(_ tagCalloutView: TagCalloutView, point: CGPoint) {
        var point = point
        if let image = self.image {
            let drawnImageRect = self.getImageRect(image)
            point.x = min(max(point.x, drawnImageRect.minX), drawnImageRect.maxX)
            point.y = min(max(point.y, drawnImageRect.minY), drawnImageRect.maxY)
        }
        var tagCalloutViewFrame = tagCalloutView.frame
        if point.y > tagCalloutViewFrame.height {
            tagCalloutView.isArrowUp = false
            tagCalloutViewFrame.origin.y = min(point.y, self.bounds.maxY) - tagCalloutViewFrame.height
        } else {
            tagCalloutView.isArrowUp = true
            tagCalloutViewFrame.origin.y = max(point.y, self.bounds.minY)
        }
        if point.x > tagCalloutViewFrame.width / 2 {
            if point.x < self.bounds.width - tagCalloutViewFrame.width / 2 {
                tagCalloutViewFrame.origin.x = point.x - tagCalloutViewFrame.width / 2
            } else {
                tagCalloutViewFrame.origin.x = self.bounds.width - tagCalloutViewFrame.width - 1
            }
        } else {
            tagCalloutViewFrame.origin.x = 1
        }
        tagCalloutView.frame = tagCalloutViewFrame
        
        tagCalloutView.point = self.convert(point, to: tagCalloutView)
    }
    
    // MARK: - Point conversion
    
    private func convertToRelative(point: CGPoint) -> Point {
        if let image = self.image {
            let drawnImageRect = self.getImageRect(image)
            return Point(x: min(max(Double((point.x - drawnImageRect.minX) / drawnImageRect.width), 0), 1),
                         y: min(max(Double((point.y - drawnImageRect.minY) / drawnImageRect.height), 0), 1))
        }
        return Point(x: Double(point.x/self.bounds.width), y: Double(point.y/self.bounds.height))
    }
    
    private func convertToAbsolute(point: Point) -> CGPoint {
        if let image = self.image {
            let drawnImageRect = self.getImageRect(image)
            return CGPoint(x: drawnImageRect.minX + CGFloat(point.x) * drawnImageRect.width,
                           y: drawnImageRect.minY + CGFloat(point.y) * drawnImageRect.height)
        }
        return CGPoint(x: CGFloat(point.x) * self.bounds.width, y: CGFloat(point.y) * self.bounds.height)
    }
    
    private func getImageRect(_ image: UIImage) -> CGRect {
        var imageScale: CGFloat
        if self.contentMode == UIView.ContentMode.scaleAspectFit {
            // Image aspect ratio is preserved, the whole image is visible, empty margins added as needed
            imageScale = min(self.bounds.width / image.size.width, self.bounds.height / image.size.height)
        } else {
            // Image aspect ratio is preserved, the image is cropped to fill the view's bounds
            imageScale = max(self.bounds.width / image.size.width, self.bounds.height / image.size.height)
        }
        let drawnImageSize = CGSize(width: imageScale * image.size.width, height: imageScale * image.size.height)
        return CGRect(x: (self.bounds.width - drawnImageSize.width) / 2, y: (self.bounds.height - drawnImageSize.height) / 2, width: drawnImageSize.width, height: drawnImageSize.height)
    }
}
