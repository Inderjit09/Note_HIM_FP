import UIKit
import CoreData

class DatabaseHelper: NSObject {

    static let shareInstance = DatabaseHelper()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    //MARK:-  NOTES DB Methods
    
    func saveNotesData(NotesDict: [String:Any]){
        let notes = NSEntityDescription.insertNewObject(forEntityName: "NotesDB", into: context) as! NotesDB
        notes.title = NotesDict["title"] as? String ?? ""
        notes.text = NotesDict["text"] as? String ?? ""
        notes.subject = NotesDict["subject"] as? String ?? ""
        notes.address = NotesDict["address"] as? String ?? ""
        notes.cellName = NotesDict["cellName"] as? String ?? ""
        notes.imageData = NotesDict["imageData"] as? Data ?? Data()
        notes.lat = NotesDict["lat"] as? String ?? ""
        notes.long = NotesDict["long"] as? String ?? ""
        notes.audioFileName = NotesDict["audioFileName"] as? String ?? ""
        
        do{
            try context.save()
        }catch let err{
            //print("Notes save error :- \(err.localizedDescription)")
        }
    }
    
    func getAllNotesData() -> [NotesDB]{
        var arrNotes = [NotesDB]()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "NotesDB")
        do{
            arrNotes = try context.fetch(fetchRequest) as! [NotesDB]
        }catch let err{
            //print("Error in Subject fetch :- \(err.localizedDescription)")
        }
        return arrNotes
    }
    
    func getAllsubjectTypeData(catType : String) -> [NotesDB] {
        
        var arrNotes = getAllNotesData()
        let myRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NotesDB")
        myRequest.predicate = NSPredicate(format: "subject = %@", catType)

        do{
            arrNotes = try context.fetch(myRequest) as! [NotesDB]

        } catch let error{
            //print(error)
        }
        
        return arrNotes
               
    }
    
    
    func deleteNotesData(index: Int , catType : String) -> [NotesDB]{
        var NotesData = getAllsubjectTypeData(catType: catType) // GetData
        context.delete(NotesData[index]) // Remove From Coredata
        NotesData.remove(at: index) // Remove in array Notes
        do{
            try context.save()
        }catch let err{
            //print("delete Notes data :- \(err.localizedDescription)")
        }
        return NotesData
    }
    
    func editNotesData(NotesDict: [String : Any], index:Int , searchText : String , catType : String){
        
        let Notes = (searchText == "") ? getAllsubjectTypeData(catType: catType) : self.GetFilteredData(searchText: searchText, catType: catType)
    // original data
        Notes[index].title = NotesDict["title"] as? String ?? ""
        Notes[index].text = NotesDict["text"] as? String ?? ""
        Notes[index].subject = NotesDict["subject"] as? String ?? ""
        Notes[index].address = NotesDict["address"] as? String ?? ""
        Notes[index].cellName = NotesDict["cellName"] as? String ?? ""
        Notes[index].imageData = NotesDict["imageData"] as? Data ?? Data()
        Notes[index].lat = NotesDict["lat"] as? String ?? ""
        Notes[index].long = NotesDict["long"] as? String ?? ""
        Notes[index].audioFileName = NotesDict["audioFileName"] as? String ?? ""
               
        do{
            try context.save()
        }catch{
            //print("error in edit data")
        }
    }
    
    func GetFilteredData(searchText : String , catType : String) -> [NotesDB]{
    
        var arrNotes = getAllsubjectTypeData(catType: catType)
        let myRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NotesDB")
        
        myRequest.predicate = NSPredicate(format: "subject = %@ AND (title CONTAINS [cd] %@ OR text CONTAINS [cd] %@ )",catType,searchText,searchText)
        
//        myRequest.predicate = NSCompoundPredicate(type: .and, subpredicates:[
//               NSPredicate(format: "title CONTAINS[cd] %@", searchText),
//               NSPredicate(format: "subject = %@", catType)])

        do{
            arrNotes = try context.fetch(myRequest) as! [NotesDB]

        } catch let error{
            //print(error)
        }
        
        return arrNotes
    }
    
    
/*========================================================================================================================================*/
    
    
    //MARK:- SUBJECTSDB Methods
    
    func saveSubjectData(SubjectDict: [String:String]){
        let Subject = NSEntityDescription.insertNewObject(forEntityName: "SubjectsDB", into: context) as! SubjectsDB
        Subject.title = SubjectDict["subjectName"]
        
        do{
            try context.save()
        }catch let err{
            //print("Subjects save error :- \(err.localizedDescription)")
        }
    }
    
    func getAllSubjectData() -> [SubjectsDB]{
        var arrSubject = [SubjectsDB]()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SubjectsDB")
        do{
            arrSubject = try context.fetch(fetchRequest) as! [SubjectsDB]
        }catch let err{
            //print("Error in Subject fetch :- \(err.localizedDescription)")
        }
        return arrSubject
    }
    
    func deleteSubjectData(index: Int) -> [SubjectsDB]{
        var SubjectData = self.getAllSubjectData() // GetData
        context.delete(SubjectData[index]) // Remove From Coredata
        SubjectData.remove(at: index) // Remove in array Subject
        do{
            try context.save()
        }catch let err{
            //print("delete Subject data :- \(err.localizedDescription)")
        }
        return SubjectData
    }
    
    func editSubjectData(SubjectDict: [String : String], index:Int,searchText : String){
        
         let Subject = (searchText == "") ? self.getAllSubjectData() : GetFilteredSubjectData(searchText : searchText)
        
    // original data
        Subject[index].title = SubjectDict["subjectName"] // edit data
        do{
            try context.save()
        }catch{
            //print("error in edit data")
        }
    }
    
    
    func GetFilteredSubjectData(searchText : String) -> [SubjectsDB]{
    
        var arrNotes = self.getAllSubjectData()
        let myRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SubjectsDB")
        myRequest.predicate = NSCompoundPredicate(type: .and, subpredicates:[
               NSPredicate(format: "title CONTAINS[cd] %@", searchText)])

        do{
            arrNotes = try context.fetch(myRequest) as! [SubjectsDB]

        } catch let error{
            //print(error)
        }
        
        return arrNotes
    }
    
    
    
    
    
}
