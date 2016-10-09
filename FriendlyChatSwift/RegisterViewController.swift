//
//  RegisterViewController.swift
//  FriendlyChatSwift
//
//  Created by kromah on 6/12/16.
//  
//

import UIKit
import Firebase



class RegisterViewController: UITableViewController {
    
    
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet weak internal var emailField: UITextField!
    @IBOutlet weak internal var passwordField: UITextField!
    @IBOutlet weak internal var confirmPasswordField: UITextField!
    @IBOutlet weak internal var firstnameField:UITextField!
    @IBOutlet weak internal var lastnameField:UITextField!
    @IBOutlet weak internal var companyField:UITextField!
    
    @IBOutlet weak var internButton: UIButton!
    @IBOutlet weak var fulltimeButton: UIButton!
    
    @IBOutlet weak var profilePicImageView: UIImageView!
    var completionDialog: UIAlertController!
    var ref: FIRDatabaseReference!
    var newuser: [String:String] = [:]
    var currentUser:User!
    var role:String!
    @IBOutlet weak var profilePic: UITableViewCell!
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.hidesWhenStopped = true
        spinner.center = view.center
        
        tableView.addSubview(spinner)
        configureDatabase() 
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapSignUp(_ sender: AnyObject) {
        
        let email = emailField.text
        let password = passwordField.text
        
        newuser[Constants.UserFields.company] = companyField.text
        newuser[Constants.UserFields.firstname]  = firstnameField.text
        newuser[Constants.UserFields.lastname]  = lastnameField.text
        newuser[Constants.UserFields.role] = role
        newuser[Constants.UserFields.email] = email
        
        var alert =  UIAlertController(title: "Invalid Email", message: "", preferredStyle: .alert)
        
       
        let issue =  UIAlertController(title: "Error", message: "", preferredStyle: .alert)
        
        let done = UIAlertAction(title: "Done", style: .default, handler: { (action) in
            print("Clicked")
        })
        

        
        alert.addAction(done)
        issue.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action) in
            self.dismiss(animated: false, completion: nil);
        })
        )
        
        if email!.isEmpty || password!.isEmpty {
         
            present(alert, animated:true){}
            return
        }
        
        else if  (password?.characters.count)! < 5 {
            alert  =  UIAlertController(title: "Invalid Password", message: "Password must have at least 5 characters", preferredStyle: .alert)
            alert.addAction(done)
            present(alert, animated: true){}
        }else{
            spinner.startAnimating()
            FIRAuth.auth()?.createUser(withEmail: email!, password: password!) { (user, error) in

                
//                let filePath = "\(user?.uid)/profielpic.png"
//                
//                let storageRef = FIRStorage.storage().reference(forURL: "gs://bv-chat-10fd4.appspot.com/").child(filePath)
//                
//                if let uploadData = UIImagePNGRepresentation(self.profilePicImageView.image!){
//                    storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
//                        if error != nil{
//                            print(error)
//                            return
//                        }
//  
//                    })
//                }
//                
                
                
                
                if let error = error {
                    issue.title = error.localizedDescription
                    issue.addAction(done)
                    self.present(issue,animated:true,completion:nil)
               
                    return
                }
        
                self.spinner.stopAnimating()
                self.newuser[Constants.UserFields.uid] = user!.uid
                self.setDisplayName(user: user!)
                self.registerUser(data:self.newuser)
                
            }
            
        }
    
    }
    
    func registerUser(data: [String: String]) {
        
        
        print(data)
        // Push data to Firebase Database
        
        self.ref.child("users/"+data[Constants.UserFields.uid]!).setValue(data)
        
//        Successfully created
        let success =  UIAlertController(title: "Successfully Created", message: "", preferredStyle: .alert)
        success.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action) in
            self.dismiss(animated: false, completion: nil);
        }))
        
        self.present(success, animated: true, completion: nil)
    }

    func configureDatabase(){
        
    self.ref = FIRDatabase.database().reference()
    }
    
 
    
    
    @IBAction func roleButtonSelected(sender:UIButton){
        
        if sender.tag == 0{
            role = "intern"
            internButton.backgroundColor = UIColor(red:175/255,green:200/255,blue:45/255,alpha:1)
            
            fulltimeButton.backgroundColor = UIColor(red: 201/255, green: 196/255, blue: 195/255, alpha: 1)
        
        }else if sender.tag == 1 {
            role = "fulltime"
            internButton.backgroundColor = UIColor(red: 201/255, green: 196/255, blue: 195/255, alpha: 1)

            fulltimeButton.backgroundColor = UIColor(red:175/255,green:200/255,blue:45/255,alpha:1)
        }
        
    }
    
    //    Gets rid of keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func setDisplayName(user: FIRUser) {
        let changeRequest = user.profileChangeRequest()
        changeRequest.displayName = "\(newuser[Constants.UserFields.firstname]!) \(newuser[Constants.UserFields.lastname]!)"
        changeRequest.commitChanges(){ (error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.signedIn(user: FIRAuth.auth()?.currentUser)
        }
    }
    
    func signedIn(user: FIRUser?) {
        MeasurementHelper.sendLoginEvent()
        
        AppState.sharedInstance.displayName = "\(newuser[Constants.UserFields.firstname]!) \(newuser[Constants.UserFields.lastname]!)"
        AppState.sharedInstance.photoUrl = user?.photoURL
        AppState.sharedInstance.signedIn = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NotificationKeys.SignedIn), object: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.allowsEditing = true
                imagePicker.sourceType = .photoLibrary
                
                present(imagePicker,animated:false, completion:nil)
            }
        }
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selecedImage = info[UIImagePickerControllerOriginalImage]as? UIImage{
            profilePicImageView.image = selecedImage
            profilePicImageView.contentMode = .scaleAspectFill
            profilePicImageView.clipsToBounds = true
        }else if let editiedImage = info[UIImagePickerControllerEditedImage] as? UIImage{
            profilePicImageView.image = editiedImage
//            profilePicImageView.contentMode = .scaleAspectFit
            profilePicImageView.clipsToBounds = true
        }
        
        dismiss(animated: true, completion: nil)
    }

}
