import UIKit
import CoreLocation
import MapKit


class NotesListVC: UIViewController,UISearchBarDelegate,subjectDataPass {
   
    
    
    //MARK:- Variable
    var Notes = [NotesDB]()
    var searchString = String()
    
    var categoryResult = ""
    
    var moveToFolderDetails = NotesDB()
    var moveToFolderindex = Int()
    
      // var delegate :subjectDataPass?
    
    @IBOutlet weak var tblView: UITableView!
    
    @IBOutlet weak var searchbarheight: NSLayoutConstraint!
    @IBOutlet weak var listSearchBar: UISearchBar!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = categoryResult
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        self.Notes = DatabaseHelper.shareInstance.getAllsubjectTypeData(catType: categoryResult)
        self.tblView.reloadData()
        self.tblView.tableFooterView = UIView()
        
        self.tblView.rowHeight = UITableView.automaticDimension;
        self.tblView.estimatedRowHeight = 44.0;
        listSearchBar.delegate = self
        listSearchBar.text = ""
        
        if self.Notes.count > 0 {
            self.searchbarheight.constant = 50
        }else{
            self.searchbarheight.constant = 0
        }
        
       }

    @IBAction func addNewNotesAction(_ sender: Any) {
        
        let editnotesVC = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        editnotesVC.subjectName = categoryResult
        self.navigationController?.pushViewController(editnotesVC, animated: true)
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //print("searchText \(searchText)")
        
        searchString = searchText
        
        if searchText != "" {
            self.Notes = DatabaseHelper.shareInstance.GetFilteredData(searchText:searchText, catType: categoryResult)
        }else{
            self.Notes = DatabaseHelper.shareInstance.getAllsubjectTypeData(catType: categoryResult)
        }
        
        
        self.tblView.reloadData()
        self.tblView.tableFooterView = UIView()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
         searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
    
        self.Notes = DatabaseHelper.shareInstance.getAllsubjectTypeData(catType: categoryResult)
        self.tblView.reloadData()
        self.tblView.tableFooterView = UIView()
    }

}


// MARK: - Table view Delegate & Datasource

extension NotesListVC: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotesTVC", for: indexPath) as! NotesTVC
        cell.subjectNameLbl.text = Notes[indexPath.row].subject
        cell.notesTitleLbl.text = Notes[indexPath.row].title
        cell.descLbl.text = Notes[indexPath.row].text
        cell.addressLbl.text = Notes[indexPath.row].address
        
        if Notes[indexPath.row].imageData != nil {
            cell.notesImgVW.image = UIImage(data: Notes[indexPath.row].imageData ?? Data())
           
        }else{
          cell.notesImgVW.backgroundColor = UIColor.blue
             
        }
        
        
        
        cell.notesImgVW.layer.cornerRadius = cell.notesImgVW.frame.size.height/2
        cell.notesImgVW.clipsToBounds = true
        
        
        cell.editBtnAction.tag = indexPath.row
        cell.editBtnAction.addTarget(self, action: #selector(self.btnCheck(_:)), for: .touchUpInside)
        
        cell.viewmapBtnAction.tag = indexPath.row
        cell.viewmapBtnAction.addTarget(self, action: #selector(self.showMap(_:)), for: .touchUpInside)
        
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // self.navigationController?.popViewController(animated: true)
        //self.delegate?.passSubjectData(subjecttitle: Subjects[indexPath.row].title ?? "")
        
        
        
        let SubjectDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "NotesDetailsVC") as! NotesDetailsVC
        SubjectDetailVC.detailsNotes = self.Notes[indexPath.row]
       
        self.navigationController?.pushViewController(SubjectDetailVC, animated: true)
        
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.Notes = DatabaseHelper.shareInstance.deleteNotesData(index: indexPath.row, catType: self.categoryResult)
            self.tblView.deleteRows(at: [indexPath], with: .top)
            
            if self.Notes.count > 0 {
                self.searchbarheight.constant = 50
            }else{
                self.searchbarheight.constant = 0
            }
            return
        }
        
        let moveSubjectButton = UITableViewRowAction(style: .default, title: "Move To Subject") { (action, indexPath) in
            
            self.moveToFolderDetails = self.Notes[indexPath.row]
            self.moveToFolderindex = indexPath.row
            
            let SubjectDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "SubjectListVC") as! SubjectListVC
            SubjectDetailVC.delegate = self
            SubjectDetailVC.comingFromScreen = "task"
            self.navigationController?.pushViewController(SubjectDetailVC, animated: true)
            return
        }
        
        deleteButton.backgroundColor = UIColor.red
        moveSubjectButton.backgroundColor = UIColor.green
        return [deleteButton,moveSubjectButton]
    }
    
    func passSubjectData(subjecttitle: String) {
           //print(subjecttitle)
        
       
        
        let newNotesDict : [String : Any] = ["title":self.moveToFolderDetails.title!,"text":self.moveToFolderDetails.title!,
                                              "subject":subjecttitle,"cellName":"",
                                              "imageData":self.moveToFolderDetails.imageData!,"address":self.moveToFolderDetails.address!,
                                              "lat":self.moveToFolderDetails.lat!,"long":self.moveToFolderDetails.long!,
                                              "audioFileName" : self.moveToFolderDetails.audioFileName!
         ]

             DatabaseHelper.shareInstance.editNotesData(NotesDict: newNotesDict , index: self.moveToFolderindex,searchText : searchString, catType: categoryResult)
        
        
       }
    
    @objc func btnCheck(_ sender: UIButton) {
        let editnotesVC = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        editnotesVC.editindexRow = sender.tag
        editnotesVC.notesDetail = self.Notes[sender.tag]
        editnotesVC.sendingSearchString = searchString
        editnotesVC.isEditNotes = true
        editnotesVC.subjectName = categoryResult
        editnotesVC.notesTakenCord = CLLocationCoordinate2D(latitude: Double(Notes[sender.tag].lat!)! , longitude: Double(Notes[sender.tag].long!)! )
        self.navigationController?.pushViewController(editnotesVC, animated: true)
        
    }
    
    @objc func showMap(_ sender: UIButton) {
           
        let MapVC = self.storyboard?.instantiateViewController(withIdentifier: "MapViewControler") as! MapViewControler
        
        MapVC.notesCord = CLLocationCoordinate2D(latitude: Double(Notes[sender.tag].lat!)! , longitude: Double(Notes[sender.tag].long!)! )
            self.navigationController?.pushViewController(MapVC, animated: true)
            
        }
}
