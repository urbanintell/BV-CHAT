

import Foundation

class AppState: NSObject {

  static let sharedInstance = AppState()

  var signedIn = false
  var displayName: String?
  var photoUrl: URL?
}
