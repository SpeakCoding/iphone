import UIKit


class PhotoPickerPreviewController: UIViewController {
    
    private var image: UIImage
    private var completion: (_ newPost: Post) -> Void
    private var imageView: UIImageView!
    
    init(image: UIImage, completion: @escaping (_ newPost: Post) -> Void) {
        self.image = image
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(showPostComposer))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(imageView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imageView.frame = self.view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    @objc private func showPostComposer() {
        let postComposer = PostComposerViewController(image: imageView.image!, completion: completion)
        self.navigationController?.pushViewController(postComposer, animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
