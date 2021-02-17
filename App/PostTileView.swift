import UIKit


class PostTileView: UICollectionViewCell {
    
    var imageView: AsynchronousImageView
    
    override init(frame: CGRect) {
        self.imageView = AsynchronousImageView(frame: frame)
        self.imageView.contentMode = UIView.ContentMode.scaleAspectFill
        self.imageView.clipsToBounds = true
        super.init(frame: frame)
        contentView.addSubview(self.imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.frame = contentView.bounds
    }
}
