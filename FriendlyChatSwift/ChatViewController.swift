

import Photos
import UIKit

import Firebase



class ChatViewController: UIViewController,
    UITextFieldDelegate, UINavigationControllerDelegate {

  // Instance variables
  @IBOutlet var spinner: UIActivityIndicatorView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var sendButton: UIButton!
  var ref: FIRDatabaseReference!
  var messages: [FIRDataSnapshot]! = []
  var msglength: NSNumber = 150
  fileprivate var _refHandle: FIRDatabaseHandle!
var currentUser:User!
  var storageRef: FIRStorageReference!
  var remoteConfig: FIRRemoteConfig!

  @IBOutlet weak var banner: GADBannerView!
  @IBOutlet weak var clientTable: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    spinner.hidesWhenStopped = true
    spinner.center = view.center
    
    clientTable.addSubview(spinner)
    spinner.startAnimating()
    

    self.clientTable.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")

    configureDatabase()
    configureStorage()
    configureRemoteConfig()
    textField.delegate = self
    clientTable.delegate = self
    
    
    
    //rotate the tableView upside down so that messages appear from bottom-top, not top-bottom
    clientTable.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI))
    
    //makes it so that row height is dynamic for each cell, which wraps around the text.
    clientTable.rowHeight = UITableViewAutomaticDimension
    clientTable.estimatedRowHeight = 60
    
    // for tapping
    self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard)))
    
  }
    
    
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // for tapping
    func dismissKeyboard() {
        textField.resignFirstResponder()
    }
    
    // for hitting return
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    deinit {
        self.ref.child("messages").removeObserver(withHandle: _refHandle)
    }
    
    
    func configureDatabase() {
        
        self.ref = FIRDatabase.database().reference()
        // Listen for new messages in the Firebase database
        self._refHandle = self.ref.child("messages").observe(.childAdded, with: { (snapshot) -> Void in
            self.messages.append(snapshot)
            
            let row = [IndexPath(row: self.messages.count-1, section: 0) ]
            
            self.clientTable.insertRows(at: row, with: .automatic)
            
            DispatchQueue.main.async {
                self.clientTable.reloadData()
                self.spinner.stopAnimating()
            }
        })
    
    }
    
    func configureStorage() {
        storageRef = FIRStorage.storage().reference(forURL: "gs://bv-chat-10fd4.appspot.com")
    }

  func configureRemoteConfig() {
    remoteConfig = FIRRemoteConfig.remoteConfig()
    // Create Remote Config Setting to enable developer mode.
    // Fetching configs from the server is normally limited to 5 requests per hour.
    // Enabling developer mode allows many more requests to be made per hour, so developers
    // can test different config values during development.
    let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
    remoteConfig.configSettings = remoteConfigSettings!
  }

  @IBAction func didSendMessage(_ sender: UIButton) {
    textFieldShouldReturn(textField)
    
    textField.text = ""
  }


  @objc(textField:shouldChangeCharactersInRange:replacementString:) func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let text = textField.text else { return true }

    let newLength = text.utf16.count + string.utf16.count - range.length
    return newLength <= self.msglength.intValue // Bool
  }

  // UITextViewDelegate protocol methods
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    let data = [Constants.MessageFields.text: textField.text! as String]
    sendMessage(data)
    
    DispatchQueue.main.async {
        self.clientTable.reloadData()
    }
    return true
  }
    
    func getCurrentTime() -> String{
    
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
       
        
      return dateFormatter.string(from: date )
     
    }
    
    func setCurrentuser(data:[String:AnyObject]){
        
//        let currentUser = self.ref.child("users/\(FIRAuth.auth()?.currentUser!.uid)").observe(.value, with: { (snapshot) in
//            let data = snapshot.value as! [String:AnyObject]
//            //                set current user data to use throughout chat session
//            let firstname = data[Constants.UserFields.firstname] as! String
//            let lastname = data[Constants.UserFields.lastname] as! String
//            let company = data[Constants.UserFields.company] as! String
//            let role = data[Constants.UserFields.role] as! String
//            let email = data[Constants.UserFields.email] as! String
//            
//            self.currentUser = User(firstname: firstname , lastname: lastname, company: company, email: email, role: role)
//            
//        })
//        
//        
        
    }

    
  func sendMessage(_ data: [String: String]) {
    
   
    
    
    var mdata = data
    mdata[Constants.MessageFields.name] = AppState.sharedInstance.displayName
    mdata[Constants.MessageFields.uid] = FIRAuth.auth()?.currentUser?.uid
    mdata[Constants.MessageFields.date] = getCurrentTime()
    if let photoUrl = AppState.sharedInstance.photoUrl {
        mdata[Constants.MessageFields.photoUrl] = photoUrl.absoluteString
    }
    // Push data to Firebase Database
    self.ref.child("messages").childByAutoId().setValue(mdata)
    
  }

  // MARK: - Image Picker

  @IBAction func didTapAddPhoto(_ sender: AnyObject) {
    let picker = UIImagePickerController()
    picker.delegate = self
    if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
      picker.sourceType = UIImagePickerControllerSourceType.camera
    } else {
      picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
    }

    present(picker, animated: true, completion:nil)
  }


    
    @IBAction func signOut(_ sender: UIBarButtonItem) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            AppState.sharedInstance.signedIn = false
            dismiss(animated: true, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: \(signOutError)")
        }
    }
   

}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate{
    
    // UITableViewDataSource protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue cell
        let cell: MessageViewCell = self.clientTable.dequeueReusableCell(withIdentifier: "ClientCell", for: indexPath) as! MessageViewCell
        
        
        
        
        cell.messageLabel?.numberOfLines = 0
        cell.firstnameLabel?.numberOfLines = 0
        cell.messageLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        // Reverse unpack message from Firebase DataSnapshot
        let messageSnapshot: FIRDataSnapshot! = self.messages[messages.count - 1 - indexPath.row]
        
        let message = messageSnapshot.value as! Dictionary<String, String>
        let name = message[Constants.MessageFields.name] as String!
        let text = message[Constants.MessageFields.text] as String!
        
        
        
        cell.firstnameLabel?.text = name
        cell.messageLabel?.text = text!
        cell.profilePic?.image = UIImage(named: "ic_account_circle")
        
//        if let imageUrl = message[Constants.MessageFields.imageUrl] {
//            if imageUrl.hasPrefix("gs://") {
//                FIRStorage.storage().reference(forURL: imageUrl).data(withMaxSize: INT64_MAX){ (data, error) in
//                    if let error = error {
//                        print("Error downloading: \(error)")
//                        return
//                    }
//                    cell.imageView?.image = UIImage.init(data: data!)
//                }
//            } else if let url = NSURL(string:imageUrl), let data = NSData(contentsOf: url as URL) {
//                cell.imageView?.image = UIImage.init(data: data as Data)
//            }
//           
//        } else {
//    
//            if let photoUrl = message[Constants.MessageFields.photoUrl], let url = NSURL(string:photoUrl), let data = NSData(contentsOf: url as URL) {
//                cell.profilePic?.image = UIImage(data: data as Data)
//            }
//        }
        
        //since tableView is rotated, cell has to be rotated to be upright.
        cell.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        
        return cell
    }

}

extension ChatViewController:UIImagePickerControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.dismiss(animated: true, completion:nil)
        
        // if it's a photo from the library, not an image from the camera
        if #available(iOS 8.0, *), let referenceUrl = info[UIImagePickerControllerReferenceURL] {
            let assets = PHAsset.fetchAssets(withALAssetURLs: [(referenceUrl as! NSURL) as URL], options: nil)
            let asset = assets.firstObject
            asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                let imageFile = contentEditingInput?.fullSizeImageURL
                let filePath = "\(FIRAuth.auth()?.currentUser?.uid)/\(Int(NSDate.timeIntervalSinceReferenceDate * 1000))/\((referenceUrl as AnyObject).lastPathComponent!)"
                self.storageRef.child(filePath)
                    .putFile(imageFile!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading: \(error.localizedDescription)")
                            return
                        }
                        self.sendMessage([Constants.MessageFields.imageUrl: self.storageRef.child((metadata?.path)!).description])
                }
            })
        } else {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            let imageData = UIImageJPEGRepresentation(image, 0.8)
            let imagePath = FIRAuth.auth()!.currentUser!.uid +
            "/\(Int(NSDate.timeIntervalSinceReferenceDate * 1000)).jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            self.storageRef.child(imagePath)
                .put(imageData!, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading: \(error)")
                        return
                    }
                    self.sendMessage([Constants.MessageFields.imageUrl: self.storageRef.child((metadata?.path)!).description])
            }
        }
    }
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }


}
