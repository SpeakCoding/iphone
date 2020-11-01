import UIKit


class TaggedImageView: AsynchronousImageView {
    
    private var tagCalloutViews = [TagCalloutView]()
    var isTagEditingEnabled = false {
        didSet {
            self.isUserInteractionEnabled = self.isTagEditingEnabled
        }
    }
    
    // MARK: - Placing and dragging callout views
    
    private var draggedTagCalloutView: TagCalloutView?
    private var draggedTagCalloutViewPoint = CGPoint.zero
    private var dragStartLocation = CGPoint.zero
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for tagCalloutView in self.tagCalloutViews {
            if tagCalloutView.point(inside: touches.first!.location(in: tagCalloutView), with: event) {
                self.draggedTagCalloutView = tagCalloutView
                self.draggedTagCalloutViewPoint = tagCalloutView.convert(tagCalloutView.point, to: self)
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
        
        if self.draggedTagCalloutView != nil {
            // Finalize the position of the dragged callout view
            self.moveDraggedTagCalloutView(point: point)
            self.draggedTagCalloutView = nil
        } else {
            // Create a new callout view
            let tagCalloutView = TagCalloutView(frame: CGRect.zero)
            tagCalloutView.text = "George Hamilton"
            self.tagCalloutViews.append(tagCalloutView)
            self.addSubview(tagCalloutView)

            // Now that the tag callout view has adjusted its size to fit the text, calculate its position
            self.layoutTagCalloutView(tagCalloutView, point: point)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.draggedTagCalloutView = nil
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//
//        for tagCalloutView in self.tagCalloutViews {
//            tagCalloutView.center = tagCalloutView.point
//        }
//    }
    
    private func moveDraggedTagCalloutView(point: CGPoint) {
        if let theView = self.draggedTagCalloutView {
            let dragDistance = CGVector(dx: point.x - self.dragStartLocation.x, dy: point.y - self.dragStartLocation.y)
            let dragEndLocation = CGPoint(x: self.draggedTagCalloutViewPoint.x + dragDistance.dx, y: self.draggedTagCalloutViewPoint.y + dragDistance.dy)
            self.layoutTagCalloutView(theView, point: dragEndLocation)
        }
    }
    
    private func layoutTagCalloutView(_ tagCalloutView: TagCalloutView, point: CGPoint) {
        var tagCalloutViewFrame = tagCalloutView.frame
        if point.y > tagCalloutViewFrame.height {
            tagCalloutView.isArrowUp = false
            tagCalloutViewFrame.origin.y = point.y - tagCalloutViewFrame.height
        } else {
            tagCalloutView.isArrowUp = true
            tagCalloutViewFrame.origin.y = point.y
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
        
        tagCalloutView.point = tagCalloutView.convert(point, from: self)
    }
}
