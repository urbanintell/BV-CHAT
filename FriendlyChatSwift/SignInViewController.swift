
import UIKit

import Firebase

@objc(SignInViewController)
class SignInViewController: UIViewController {

  @IBOutlet weak var emailField: UITextField!
  @IBOutlet weak var passwordField: UITextField!
    var currentUser:User!
    
    var userReference:FIRDatabaseReference!
    
    @IBOutlet weak var logo: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDatabase()
//        userReference.query
        
        emailField.becomeFirstResponder()
       

    }

    override func viewDidAppear(_ animated: Bool) {
        if let user = FIRAuth.auth()?.currentUser {
            self.signedIn(user: user)
        }
    }
    
    @IBAction func didTapSignIn(sender: AnyObject) {
        // Sign In with credentials.
        let email = emailField.text
        let password = passwordField.text
        
        let alert = UIAlertController(title: "Login Error", message: "Something went wrong", preferredStyle: .alert)
        
        let done = UIAlertAction(title: "Try Again", style: .default, handler: nil)
        
        alert.addAction(done)
        
        FIRAuth.auth()?.signIn(withEmail: email!, password: password!) { (user, error) in
            
            self.emailField.text = ""
            self.passwordField.text = ""
            
            if let error = error {
                
                alert.message = error.localizedDescription
                
                self.present(alert, animated: true, completion: nil)
                
                
                return
            }
            
            
            let currentUser = self.userReference.child("users/\(user!.uid)").observe(.value, with: { (snapshot) in
                let data = snapshot.value as! [String:AnyObject]
//                set current user data to use throughout chat session
                self.setCurrentuser(data:data)
                
            })
            
            print(currentUser)
//            setCurrentuser(currentUser: )
            
            
            self.signedIn(user: user!)
        }
    }
    
    
    func setCurrentuser(data:[String:AnyObject]){
        let firstname = data[Constants.UserFields.firstname] as! String
        let lastname = data[Constants.UserFields.lastname] as! String
        let company = data[Constants.UserFields.company] as! String
        let role = data[Constants.UserFields.role] as! String
        let email = data[Constants.UserFields.email] as! String
        currentUser = User(firstname: firstname , lastname: lastname, company: company, email: email, role: role)
    }

    
    func setDisplayName(user: FIRUser) {
        let changeRequest = user.profileChangeRequest()
        changeRequest.displayName = user.email!.components(separatedBy: "@")[0]
        changeRequest.commitChanges(){ (error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.signedIn(user: FIRAuth.auth()?.currentUser)
        }
    }
    
    @IBAction func didRequestPasswordReset(sender: AnyObject) {
        let prompt = UIAlertController.init(title: nil, message: "Email:", preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default) { (action) in
            let userInput = prompt.textFields![0].text
            if (userInput!.isEmpty) {
                return
            }
            FIRAuth.auth()?.sendPasswordReset(withEmail: userInput!) { (error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
            }
        }
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(okAction)
        present(prompt, animated: true, completion: nil);
    }
    
    func configureDatabase(){
        
        self.userReference = FIRDatabase.database().reference()
    }
    
    func signedIn(user: FIRUser?) {
        MeasurementHelper.sendLoginEvent()
        
        AppState.sharedInstance.displayName = user?.displayName ?? user?.email
        AppState.sharedInstance.photoUrl = user?.photoURL
        AppState.sharedInstance.signedIn = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NotificationKeys.SignedIn), object: nil)
        performSegue(withIdentifier: Constants.Segues.SignInToFp, sender: nil)
    }
    
    @IBAction func close(segue:UIStoryboardSegue){
        
    }

    //    Gets rid of keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
}
