//

import Cocoa

class MyWindowController: NSWindowController, NSWindowDelegate {
  
  @IBOutlet weak var label: NSTextField!
  @IBOutlet weak var stopButton: NSButton!
  
  weak var main: AppDelegate!
  
  @IBAction func stop(_ sender: Any) {
    main.wndStop()
  }
  
  @IBAction func next(_ sender: Any) {
    main.wndNext()
  }
  
  @IBAction func exit(_ sender: Any) {
    NSApplication.shared.terminate(nil)
  }
  
  func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
    print("full")
    var ans = proposedOptions
//    ans.insert(NSApplication.PresentationOptions.hideDock)
//    ans.insert(NSApplication.PresentationOptions.autoHideMenuBar)
//    ans.insert(NSApplication.PresentationOptions.disableAppleMenu)
//    ans.insert(NSApplication.PresentationOptions.disableProcessSwitching)
//    ans.insert(NSApplication.PresentationOptions.disableForceQuit)
//    ans.insert(NSApplication.PresentationOptions.disableSessionTermination)
//    ans.insert(NSApplication.PresentationOptions.disableHideApplication)
//    ans.insert(NSApplication.PresentationOptions.autoHideToolbar)
    return ans
  }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  struct Interval {

    var minutes: Int
    var seconds: Int

    mutating func tick() {
      if seconds > 0 {
        seconds -= 1
      } else if minutes > 0 {
        minutes -= 1
        seconds = 59
      }
    }
    
    var done: Bool {
      return minutes == 0 && seconds == 0
    }
    
  }

  var timer: Timer!
  var ctrl: MyWindowController!
  let statusItem = NSStatusBar.system.statusItem(withLength: -1)
  
  let workTime  = Interval(minutes: 0, seconds: 10)
  let smallTime = Interval(minutes: 0, seconds: 4)
  let largeTime = Interval(minutes: 0, seconds: 6)

  var work = false
  var session = 0
  var timerState = Interval(minutes: 0, seconds: 0)
  
  func next() -> Interval {
    return work ? workTime : session < 2 ? smallTime : largeTime
  }
  
  
  
  func timerInit() {
    updateStatusBar(time: workTime)
    statusItem.action = #selector(AppDelegate.startWorkTimerWithTick)
  }

  @objc func startWorkTimerWithTick() {
    startWorkTimer()
    workTimerTick()
  }
  
  func startWorkTimer() {
    session += 1
    timerState = workTime
    statusItem.action = #selector(AppDelegate.stopWorkTimer)
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.workTimerTick), userInfo: nil, repeats: true)
  }
  
  @objc func workTimerTick() {
    timerState.tick()
    updateStatusBar(time: timerState)
    if timerState.done {
      timer.invalidate()
      startRelaxTimer()
    }
  }
  
  @objc func stopWorkTimer() {
    timer.invalidate()
    timerInit()
  }
  
  func startRelaxTimer() {
    if ctrl == nil {
      ctrl = MyWindowController(windowNibName: NSNib.Name("Window"))
      ctrl.main = self
      //        let rect = NSScreen.main?.frame
      //        ctrl.window?.setFrame(rect!, display: false)
      //        ctrl.window?.toggleFullScreen(nil)
    }
    ctrl.showWindow(nil)
    if session == 2 {
      session = 0
      timerState = largeTime
    } else {
      timerState = smallTime
    }
    updateStatusBar(time: timerState)
    updateWindowTimer(time: timerState)
    statusItem.action = #selector(AppDelegate.stopRelaxTimer)
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.relaxTimerTick), userInfo: nil, repeats: true)
  }

  @objc func relaxTimerTick() {
    timerState.tick()
    updateStatusBar(time: timerState)
    updateWindowTimer(time: timerState)
    if timerState.done {
      timer.invalidate()
      ctrl.stopButton.isEnabled = false
    }
  }
  
  @objc func stopRelaxTimer() {
    timer.invalidate()
    ctrl.stopButton.isEnabled = false
  }
  
  func wndNext() {
    timer.invalidate()
    wndClose()
    startWorkTimer()
    workTimerTick()
  }
  
  func wndStop() {
    timer.invalidate()
    timerInit()
    wndClose()
  }
  
  func wndClose() {
    ctrl.close()
    ctrl.stopButton.isEnabled = true
  }
  
  func updateStatusBar(time: Interval) {
    statusItem.title = String(format: "%02d:%02d", time.minutes, time.seconds)
  }
  
  func updateWindowTimer(time: Interval) {
    ctrl.label.stringValue = String(format: "%02d:%02d", time.minutes, time.seconds)
  }
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    timerInit()
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

