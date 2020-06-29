import UIKit

class NotesDetailsVC: UIViewController {
    
    
    var detailsNotes = NotesDB()
    
    
    
    @IBOutlet weak var subjectTitleLBl: UILabel!
    @IBOutlet weak var NameLBl: UILabel!
    @IBOutlet weak var descLBl: UILabel!
    @IBOutlet weak var addressLBl: UILabel!
    
    @IBOutlet weak var imgVw: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = detailsNotes.title
        
        
        subjectTitleLBl.text = detailsNotes.subject
        NameLBl.text = detailsNotes.title
        descLBl.text = detailsNotes.text
        addressLBl.text = detailsNotes.address
        
        
        if detailsNotes.imageData != nil {
            imgVw.image = UIImage(data: detailsNotes.imageData!)
        }
        
         

        // Do any additional setup after loading the view.
    }


}
