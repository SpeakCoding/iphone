import UIKit


class TagEditorController: UIViewController {
    
    private var image: UIImage
    private var completion: ([Tag]) -> Void
    private var tags: [Tag]
    @IBOutlet private var taggedImageView: TaggedImageView!
    
    init(image: UIImage, tags: [Tag], completion: @escaping ([Tag]) -> Void) {
        self.image = image
        self.tags = tags
        self.completion = completion
        super.init(nibName: "TagEditorController", bundle: nil)
        self.title = "Tag people"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(callCompletion))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.taggedImageView.image = self.image
        self.taggedImageView.tags = self.tags
    }
    
    @objc private func callCompletion() {
        self.completion(self.taggedImageView.tags)
    }
    
    func tagUserForPointInImage(point: Point) {
        let userLookupViewController = UserLookupViewController { (user: User?) in
            if user != nil {
                let newTag = Tag(taggedUser: user!, point: point)
                self.taggedImageView.addTag(newTag)
            }
            self.dismiss(animated: true, completion: nil)
        }
        self.present(userLookupViewController, animated: true, completion: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
