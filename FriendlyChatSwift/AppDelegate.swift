
//

import UIKit

import Firebase
import IQKeyboardManagerSwift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions
      launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    
    UINavigationBar.appearance().barTintColor = UIColor.black
    UINavigationBar.appearance().tintColor = UIColor.white

    
    
    if let barFont = UIFont(name: "Avenir-Light", size: 24.0) {
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white, NSFontAttributeName:barFont]
    }
    
   
    
    FIRApp.configure()
    IQKeyboardManager.sharedManager().enable = true
    return true
  }

}
