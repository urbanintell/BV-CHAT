//
//  RegisterViewController.swift
//  FriendlyChatSwift
//
//  Created by kromah on 6/12/16.
//  
//

import UIKit
import Firebase



class RegisterViewController: UIViewController {
    
    @IBOutlet weak internal var emailField: UITextField!
    
    @IBOutlet weak internal var passwordField: UITextField!
    
    var completionDialog: UIAlertController!

    override func viewDidLoad() {
        super.viewDidLoad()
     
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapSignUp(_ sender: AnyObject) {
        
        let email = emailField.text
        let password = passwordField.text
        
        var alert =  UIAlertController(title: "Invalid Email", message: "", preferredStyle: .alert)
        
         var success =  UIAlertController(title: "Successfully Created", message: "", preferredStyle: .alert)
        
        let done = UIAlertAction(title: "Done", style: .default, handler: { (action) in
            print("Clicked")
        })
        
        alert.addAction(done)
        success.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action) in
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
        
            FIRAuth.auth()?.createUser(withEmail: email!, password: password!) { (user, error) in
                if let error = error {
                    print("Here is the error: \(error.localizedDescription)")
                    return
                }
                self.setDisplayName(user: user!)
                
            }
            self.present(success, animated: true, completion: nil)
        }
        
    }
    
    
    
  
    //    Gets rid of keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    
//    @IBAction func didTapSignUp(sender: AnyObject) {
//        let email = emailField.text
//        let password = passwordField.text
//        FIRAuth.auth()?.createUser(withEmail: email!, password: password!) { (user, error) in
//            if let error = error {
//                print("Here is the error: \(error.localizedDescription)")
//                return
//            }
//            self.setDisplayName(user: user!)
//            
//        }
//        self.dismiss(animated: false, completion: nil);
//    }
    
    
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
    
    func signedIn(user: FIRUser?) {
        MeasurementHelper.sendLoginEvent()
        
        AppState.sharedInstance.displayName = user?.displayName ?? user?.email
        AppState.sharedInstance.photoUrl = user?.photoURL
        AppState.sharedInstance.signedIn = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NotificationKeys.SignedIn), object: nil)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
