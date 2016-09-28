

import Photos
import UIKit

import Firebase


@objc(FCViewController)
class FCViewController: UIViewController,
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

  var storageRef: FIRStorageReference!
  var remoteConfig: FIRRemoteConfig!

  @IBOutlet weak var banner: GADBannerView!
  @IBOutlet weak var clientTable: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()

    self.clientTable.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")

    configureDatabase()
    configureStorage()
    configureRemoteConfig()
    textField.delegate = self
    tableView.delegate = self
    
    //rotate the tableView upside down so that messages appear from bottom-top, not top-bottom
    tableView.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI))
    
    //makes it so that row height is dynamic for each cell, which wraps around the text.
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 60
    
    // for tapping
    self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(FCViewController.dismissKeyboard)))
    
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
        self.tableView.reloadData()
    }
    return true
  }
    
  func sendMessage(_ data: [String: String]) {
    var mdata = data
    mdata[Constants.MessageFields.name] = AppState.sharedInstance.displayName
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

extension FCViewController: UITableViewDataSource, UITableViewDelegate{
    
    // UITableViewDataSource protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue cell
        let cell: UITableViewCell! = self.clientTable .dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
        
        cell.textLabel?.numberOfLines=0
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        // Reverse unpack message from Firebase DataSnapshot
        let messageSnapshot: FIRDataSnapshot! = self.messages[messages.count - 1 - indexPath.row]
        
        let message = messageSnapshot.value as! Dictionary<String, String>
        let name = message[Constants.MessageFields.name] as String!
        let text = message[Constants.MessageFields.text] as String!
        
        if let imageUrl = message[Constants.MessageFields.imageUrl] {
            if imageUrl.hasPrefix("gs://") {
                FIRStorage.storage().reference(forURL: imageUrl).data(withMaxSize: INT64_MAX){ (data, error) in
                    if let error = error {
                        print("Error downloading: \(error)")
                        return
                    }
                    cell.imageView?.image = UIImage.init(data: data!)
                }
            } else if let url = NSURL(string:imageUrl), let data = NSData(contentsOf: url as URL) {
                cell.imageView?.image = UIImage.init(data: data as Data)
            }
            cell!.textLabel?.text = "sent by: \(name)"
        } else {
            
            cell!.textLabel?.text = name! + ": " + text!
            cell!.imageView?.image = UIImage(named: "ic_account_circle")
            if let photoUrl = message[Constants.MessageFields.photoUrl], let url = NSURL(string:photoUrl), let data = NSData(contentsOf: url as URL) {
                cell!.imageView?.image = UIImage(data: data as Data)
            }
        }
        
        //since tableView is rotated, cell has to be rotated to be upright.
        cell.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        
        return cell!
    }

}

extension FCViewController:UIImagePickerControllerDelegate{
    
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
