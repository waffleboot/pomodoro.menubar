//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  
  let statusItem = NSStatusBar.system.statusItem(withLength: -1)
  
  @objc func start() {
  }
  

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    statusItem.title = "hh:mm"
    statusItem.action = #selector(AppDelegate.start)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }


}

