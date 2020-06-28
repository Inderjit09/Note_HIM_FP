

import UIKit
import CoreData
import CoreLocation
import AVFoundation


class ViewController: UIViewController,subjectDataPass,CLLocationManagerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    //MARK:- Variable
    
    var address = ""
    var notesAudioNameStr = ""
    var notesDetail: NotesDB?
    var isEditNotes = Bool()
    var sendingSearchString = String()
    var editindexRow = Int()
    var cellNameStr = String()
    
    var locationManager = CLLocationManager()
    var notesTakenCord = CLLocationCoordinate2D()
    
    
     //MARK:- Outlets
    @IBOutlet weak var subjectTitleLbl: UILabel!
    @IBOutlet weak var notesTitleTxtFld: UITextField!
    
    @IBOutlet weak var notesDescTxtView: UITextView!
    
    @IBOutlet weak var notesIMgView: UIImageView!
    
    @IBOutlet weak var addNotesBtnOL: UIButton!
    @IBOutlet weak var addrecorderBtnOL: UIButton!
    
    @IBOutlet weak var addNotesViewHeight: NSLayoutConstraint!
    @IBOutlet weak var addAudioNotesViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var mainViewHeight: NSLayoutConstraint!
    
    
    // Audio Recorder
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    
    
    //MARK:- View life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        notesTitleTxtFld.setLeftPaddingPoints(15)
        
        
        // Location Manager Delegate
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if isEditNotes {
            self.subjectTitleLbl.text = notesDetail?.subject ?? "Subject"
            self.notesTitleTxtFld.text = notesDetail?.title ?? ""
            self.notesDescTxtView.text = notesDetail?.text ?? ""
            self.notesAudioNameStr = notesDetail?.audioFileName ?? ""
            
            if let imgData = notesDetail?.imageData {
                self.notesIMgView.image = UIImage(data: imgData)
                
                addNotesViewHeight.constant = 364
                addNotesBtnOL.setImage(UIImage(named: "checked"), for: .normal)
            }else{
                addNotesViewHeight.constant = 50
                addNotesBtnOL.setImage(UIImage(named: "unchecked"), for: .normal)
            }
        
            mainViewHeight.constant = 430 + addNotesViewHeight.constant + addAudioNotesViewHeight.constant
        }else{
            
        }
        
        //setup Recorder
        self.setupView()
               
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
         self.view.endEditing(true);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        
       
        
    }
    
    func setupView() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        // failed to record
                    }
                }
            }
        } catch {
            // failed to record
        }
    }
    
    func loadRecordingUI() {
        
        recordButton.layer.cornerRadius = recordButton.frame.size.height/2
        recordButton.clipsToBounds = true;
        
        playButton.layer.cornerRadius = playButton.frame.size.height/2
        playButton.clipsToBounds = true;
        
        if notesAudioNameStr != "" {
            // For Audio Recording
            recordButton.setTitle("Tap to Re-record", for: .normal)
            playButton.isEnabled = true
            recordButton.isEnabled = true
            addrecorderBtnOL.setImage(UIImage(named: "checked"), for: .normal)
        }else{
            recordButton.isEnabled = true
            playButton.isEnabled = false
            recordButton.setTitle("Tap to Record", for: .normal)
            addrecorderBtnOL.setImage(UIImage(named: "unchecked"), for: .normal)
        }
        
        recordButton.addTarget(self, action: #selector(recordAudioButtonTapped), for: .touchUpInside)
    }
    
    @objc func recordAudioButtonTapped(_ sender: UIButton) {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    func startRecording() {
        
        if notesAudioNameStr == "" {
            if self.notesTitleTxtFld.text ?? "" == "" {
                notesAudioNameStr = getTodayString()
            }else{
                notesAudioNameStr = self.notesTitleTxtFld.text!
            }
        }
        
        let audioFilename = getFileURL(audioName: notesAudioNameStr)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            recordButton.setTitle("Tap to Stop", for: .normal)
            playButton.isEnabled = false
        } catch {
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            recordButton.setTitle("Tap to Re-record", for: .normal)
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
        
        playButton.isEnabled = true
        recordButton.isEnabled = true
    }
    
    @IBAction func playAudioButtonTapped(_ sender: UIButton) {
        
        if notesAudioNameStr != "" {
            
            if (sender.titleLabel?.text == "Play"){
                recordButton.isEnabled = false
                sender.setTitle("Stop", for: .normal)
                preparePlayer(audioName: notesAudioNameStr)
                audioPlayer.play()
            } else {
                audioPlayer.stop()
                sender.setTitle("Play", for: .normal)
                recordButton.isEnabled = true
            }
        }
        
        
    }
    
    func preparePlayer(audioName:String) {
        var error: NSError?
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileURL(audioName: audioName) as URL)
        } catch let error1 as NSError {
            error = error1
            audioPlayer = nil
        }
        
        if let err = error {
            print("AVAudioPlayer error: \(err.localizedDescription)")
        } else {
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 100.0
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFileURL(audioName:String) -> URL {
        let path = getDocumentsDirectory().appendingPathComponent("\(audioName).m4a")
        return path as URL
    }
    
    //MARK: Delegates
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Error while recording audio \(error!.localizedDescription)")
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.isEnabled = true
        playButton.setTitle("Play", for: .normal)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error while playing audio \(error!.localizedDescription)")
    }
    
 /*==================================================================================================================================*/
    
    @IBAction func saveNotes(_ sender: Any) {
        
        let subjectStr  = self.subjectTitleLbl.text ?? "Subject"
        let notesTitleStr  = self.notesTitleTxtFld.text ?? ""
        let notesDescStr  = self.notesDescTxtView.text ?? ""
        
        
        if subjectStr.trim() == "Subject"  {
            showAlertDialog(title: "Please Enter Subject Name")
        }
        else if notesTitleStr.trim().count == 0  {
            showAlertDialog(title: "Please Enter Notes title")
        }
        else if notesDescStr.trim().count == 0  {
            showAlertDialog(title: "Please Enter Notes Description")
        }
        else if !isCoordinateValid(latitude: notesTakenCord.latitude, longitude: notesTakenCord.latitude) {
          showAlertDialog(title: "Please on User location")
        }
        else{
            
            let newNotesDict : [String : Any] = ["title":notesTitleStr,"text":notesDescStr,
                                                 "subject":subjectStr,"cellName":"",
                                                 "imageData":self.notesIMgView.image!.pngData()!,"address":self.address,
                                                 "lat":"\(notesTakenCord.latitude)","long":"\(notesTakenCord.longitude)",
                                                 "audioFileName" : notesAudioNameStr
            ]
            
           
            if isEditNotes {
                DatabaseHelper.shareInstance.editNotesData(NotesDict: newNotesDict , index: editindexRow,searchText : sendingSearchString)
                isEditNotes = false
                 
            }else{
                DatabaseHelper.shareInstance.saveNotesData(NotesDict: newNotesDict)
            }
               
            self.navigationController?.popViewController(animated: true)
            
            
        }
        
    }
    
    
    func isCoordinateValid(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Bool {
        guard latitude != 0, longitude != 0, CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
            return false
        }
        return true
    }
    
    
     //MARK:- Button Action
    @IBAction func setSubjectTitleBtnAction(_ sender: Any) {
        let SubjectDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "SubjectListVC") as! SubjectListVC
        SubjectDetailVC.delegate = self
        self.navigationController?.pushViewController(SubjectDetailVC, animated: true)
        
    }
    
     @IBAction func AddnotesImageBtnAction(_ sender: Any) {
        
        if (sender as AnyObject).currentImage == UIImage(named: "checked") {
            (sender as AnyObject).setImage(UIImage(named: "unchecked"), for: .normal)
            addNotesViewHeight.constant = 50
        }
        else {
           (sender as AnyObject).setImage(UIImage(named: "checked"), for: .normal)
            
            addNotesViewHeight.constant = 364
        }
        
        mainViewHeight.constant = 430 + addNotesViewHeight.constant + addAudioNotesViewHeight.constant
        
    }
    
    @IBAction func AddAudioRecorderBtnAction(_ sender: Any) {
        
        if (sender as AnyObject).currentImage == UIImage(named: "checked") {
            (sender as AnyObject).setImage(UIImage(named: "unchecked"), for: .normal)
            addAudioNotesViewHeight.constant = 50
        }
        else {
           (sender as AnyObject).setImage(UIImage(named: "checked"), for: .normal)
            addAudioNotesViewHeight.constant = 100
        }
        
        mainViewHeight.constant = 430 + addNotesViewHeight.constant + addAudioNotesViewHeight.constant

    }
    
    
    
    
    func passSubjectData(subjecttitle: String) {
        print(subjecttitle)
        
        subjectTitleLbl.text = "\(subjecttitle)"
    }
    
    
    @IBAction func motesImagePickerBtnAction(_ sender: Any) {
        
        let alert = UIAlertController(title: "Choose Notes Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))

        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
        
    }
    
    func openCamera()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func openGallery()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    //MARK:-- ImagePicker delegate
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            notesIMgView.contentMode = .scaleToFill
            notesIMgView.image = pickedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    
     //MARK:-- Location upodate Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
           let userLocation = locations[0]
           
//           let myLocationlatitude = userLocation.coordinate.latitude
//           let mylocationlongitude = userLocation.coordinate.longitude
            
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)) {
            [weak self] (placemarks, error) in
            guard self != nil
             else { return }
        
             if let _ = error { return }
             guard let placemark = placemarks?.last else { return }
           
            
        
             if placemark.subThoroughfare != nil {
                self?.address += placemark.subThoroughfare! + " " }
             
             if placemark.thoroughfare != nil {
               self?.address += placemark.thoroughfare! + ","  }
             
             if placemark.subLocality != nil {
                self?.address += placemark.subLocality! + ","  }
             
             if placemark.subAdministrativeArea != nil {
                self?.address += placemark.subAdministrativeArea! + ","  }
             
             if placemark.postalCode != nil {
                self?.address += placemark.postalCode! + ","  }
             
             if placemark.country != nil {
                self?.address += placemark.country! + "," }
            
            
            
            if !(self?.isCoordinateValid(latitude: self!.notesTakenCord.latitude, longitude: self!.notesTakenCord.latitude))! {
                self?.notesTakenCord = userLocation.coordinate
            }else{
                if self!.isEditNotes {
                    self?.address = ""
                    self?.address = (self!.notesDetail?.address!)!
                }else{
                    self?.notesTakenCord = userLocation.coordinate
                }
            }
        }
       }
}

