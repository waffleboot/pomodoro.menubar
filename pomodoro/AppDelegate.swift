//

import Cocoa

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

  @IBOutlet weak var window: NSWindow!
  
  var timer: Timer!
  let statusItem = NSStatusBar.system.statusItem(withLength: -1)
  
  let workTime  = Interval(minutes: 0, seconds: 6)
  let smallTime = Interval(minutes: 0, seconds: 2)
  let largeTime = Interval(minutes: 0, seconds: 4)

  var work = true
  var session = 0
  var timerState = Interval(minutes: 0, seconds: 0)
  
  @objc func start() {
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.tick), userInfo: nil, repeats: true)
    statusItem.action = #selector(AppDelegate.pause)
    if work {
      timerState = workTime
      session += 1
    } else if session < 2 {
      timerState = smallTime
    } else {
      timerState = largeTime
      session = 0
    }
    work = !work
    tick()
  }
  
  @objc func pause() {
    self.timer.invalidate()
    statusItem.title = "hh:mm"
    statusItem.action = #selector(AppDelegate.start)
  }
  
  @objc func tick() {
    if timerState.tick() {
      setTime()
    } else {
      self.timer.invalidate()
      statusItem.title = "hh:mm"
      statusItem.action = #selector(AppDelegate.start)
    }
  }
  
  func setTime() {
    statusItem.title = String(format: "%02d:%02d", timerState.minutes, timerState.seconds)
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

