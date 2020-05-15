//

import Cocoa

class MyWindowController: NSWindowController, NSWindowDelegate {
  
  @IBAction func exit(_ sender: Any) {
    NSApplication.shared.terminate(nil)
  }
  
  func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
    var ans = proposedOptions
    if proposedOptions.contains(NSApplication.PresentationOptions.fullScreen) {
      print("has")
    }
    ans.insert(NSApplication.PresentationOptions.disableProcessSwitching)
    return ans
  }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  struct Interval {

    var minutes: Int
    var seconds: Int

    mutating func tick() -> Bool {
      if seconds > 0 {
        seconds -= 1
      } else if minutes > 0 {
        minutes -= 1
        seconds = 59
      }
      return minutes > 0 || seconds > 0
    }
    
  }

  var timer: Timer!
  let statusItem = NSStatusBar.system.statusItem(withLength: -1)
  var ctrl: MyWindowController!
  
  let workTime  = Interval(minutes: 0, seconds: 6)
  let smallTime = Interval(minutes: 0, seconds: 2)
  let largeTime = Interval(minutes: 0, seconds: 4)

  var work = true
  var session = 0
  var timerState = Interval(minutes: 0, seconds: 0)
  
  func next() -> Interval {
    return work ? workTime : session < 2 ? smallTime : largeTime
  }
  
  @objc func start() {
    statusItem.action = #selector(AppDelegate.stop)
    if work {
      timerState = workTime
      session += 1
    } else if session < 2 {
      timerState = smallTime
    } else {
      timerState = largeTime
      session = 0
    }
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.tick), userInfo: nil, repeats: true)
    tick()
  }
  
  @objc func stop() {
    self.timer.invalidate()
    if work {
      timerState = session < 2 ? smallTime : largeTime
    } else {
      timerState = workTime
    }
    setTime()
    work = !work
    statusItem.action = #selector(AppDelegate.start)
  }
  
  @objc func tick() {
    if timerState.tick() {
      setTime()
    } else {
      if work {
        ctrl = MyWindowController(windowNibName: NSNib.Name("Window"))
//        var opts = ctrl.window?.collectionBehavior
//        opts?.insert(NSWindow.CollectionBehavior.fullScreenPrimary)
//        ctrl.window?.collectionBehavior = opts!
        ctrl.window?.toggleFullScreen(nil)
        ctrl.showWindow(nil)
      }
      stop()
    }
  }
  
  func setTime() {
    statusItem.title = String(format: "%02d:%02d", timerState.minutes, timerState.seconds)
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    timerState = workTime
    setTime()
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

