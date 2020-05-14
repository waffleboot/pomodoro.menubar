//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  
  let statusItem = NSStatusBar.system.statusItem(withLength: -1)
  
  var minutes = 0
  var seconds = 0
  var timer: Timer!
  
  @objc func start() {
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.tick), userInfo: nil, repeats: true)
    statusItem.action = #selector(AppDelegate.pause)
    minutes = 25
    seconds = 00
    tick()
  }
  
  @objc func pause() {
    self.timer.invalidate()
    statusItem.title = "hh:mm"
    statusItem.action = #selector(AppDelegate.start)
  }
  
  @objc func tick() {
    if seconds > 0 {
      seconds -= 1
    } else if minutes > 0 {
      minutes -= 1
      seconds = 59
    }
    if minutes > 0 || seconds > 0 {
      setTime()
    } else {
      self.timer.invalidate()
      statusItem.title = "hh:mm"
      statusItem.action = #selector(AppDelegate.start)
    }
  }
  
  func setTime() {
    statusItem.title = String(format: "%02d:%02d", minutes, seconds)
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    statusItem.title = "hh:mm"
    statusItem.target = self
    statusItem.action = #selector(AppDelegate.start)
//    statusItem.image = NSImage(named: NSImage.Name("TimerIcon"))
//    self.statusItem = NSStatusBar.system.statusItem(withLength: 32)
//    self.statusItem.button?.image = NSImage(named: "TimerIcon")
//    self.statusItem.length = 64
//    self.statusItem.button?.title = "15:30"
  }

  func applicationWillTerminate(_ aNotification: Notification) {
//    NSStatusBar.system.removeStatusItem(self.statusItem)
  }

}

