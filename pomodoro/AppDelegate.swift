
import Cocoa

class MyWindowController: NSWindowController, NSWindowDelegate {
  
  @IBOutlet weak var label: NSTextField!
  @IBOutlet weak var nextButton: NSButton!
  @IBOutlet weak var messageLabel: NSTextField!

  weak var app: AppDelegate!
  
  @IBAction func stop(_ sender: Any) {
    app.stopButtonPressed()
  }
  
  @IBAction func next(_ sender: Any) {
    app.nextButtonPressed()
  }
  
  @IBAction func exit(_ sender: Any) {
    NSApplication.shared.terminate(nil)
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
    
    func notify(_ o: Interval) -> Bool {
      return minutes == o.minutes && seconds == o.seconds
    }
    
  }
  
  struct TimerSettings {
    var autostart: Bool
    var notify: Interval
    var workTime: Interval
    var smallTime: Interval
    var largeTime: Interval
  }

  static let fastTimerSettings = TimerSettings(
    autostart: true,
    notify: Interval(minutes: 0, seconds: 1),
    workTime: Interval(minutes: 0, seconds: 3),
    smallTime: Interval(minutes: 0, seconds: 3),
    largeTime: Interval(minutes: 0, seconds: 3))
  
  static let debugTimerSettings = TimerSettings(
    autostart: true,
    notify: Interval(minutes: 0, seconds: 5),
    workTime: Interval(minutes: 0, seconds: 10),
    smallTime: Interval(minutes: 0, seconds: 3),
    largeTime: Interval(minutes: 0, seconds: 3))
  
  static let releaseTimerSettings = TimerSettings(
    autostart: false,
    notify: Interval(minutes: 1, seconds: 0),
    workTime: Interval(minutes: 25, seconds: 0),
    smallTime: Interval(minutes: 5, seconds: 0),
    largeTime: Interval(minutes: 20, seconds: 0))
  
  var timerSettings = AppDelegate.releaseTimerSettings

  var timer: Timer!
  var ctrl: MyWindowController!
  let statusItem = NSStatusBar.system.statusItem(withLength: -1)

  var session = 0
  var color = false
  var timerState = Interval(minutes: 0, seconds: 0)
  
  func timerInit() {
    initialTimerMenu()
    updateStatusBar(timerSettings.workTime)
    statusItem.action = #selector(AppDelegate.startWorkTimerWithTick)
  }
  
  @objc func startWorkTimerWithTick() {
    startWorkTimer()
    workTimerTick()
  }
  
  func startWorkTimer() {
    session += 1
    timerState = timerSettings.workTime
    statusItem.action = #selector(AppDelegate.stopWorkTimer)
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.workTimerTick), userInfo: nil, repeats: true)
    workingTimerMenu()
  }
  
  @objc func workTimerTick() {
    timerState.tick()
    updateStatusBar(timerState)
    if timerState.done {
      timer.invalidate()
      startRelaxTimer()
    } else if timerState.notify(timerSettings.notify) {
      notify()
    }
  }
  
  func notify() {
    let note = NSUserNotification()
    note.title = "Pomodoro"
    note.informativeText = "Ready!"
    NSUserNotificationCenter.default.deliver(note)
  }
  
  @objc func stopWorkTimer() {
    timer.invalidate()
    timerInit()
  }
  
  func startRelaxTimer() {
    if session == 2 {
      session = 0
      timerState = timerSettings.largeTime
    } else {
      timerState = timerSettings.smallTime
    }
    createFullScreenWindow()
    updateStatusBar(timerState)
    updateFullScreenWindow(timerState)
    openFullScreenWindow()
    statusItem.action = #selector(AppDelegate.stopRelaxTimer)
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.relaxTimerTick), userInfo: nil, repeats: true)
  }

  @objc func relaxTimerTick() {
    timerState.tick()
    if timerState.done {
      timer.invalidate()
      ctrl.messageLabel.stringValue = "Back to work!"
      ctrl.nextButton.isHidden = false
      ctrl.label.isHidden = true
      timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.blink), userInfo: nil, repeats: true)
    } else {
      updateStatusBar(timerState)
      updateFullScreenWindow(timerState)
    }
  }
  
  @objc func blink() {
    ctrl.messageLabel.textColor = color ? NSColor.white : NSColor.red
    color = !color
  }
  
  @objc func stopRelaxTimer() {
    stopButtonPressed()
  }
  
  func nextButtonPressed() {
    timer.invalidate()
    closeFullScreenWindow()
    startWorkTimer()
    workTimerTick()
  }
  
  func stopButtonPressed() {
    timer.invalidate()
    timerInit()
    closeFullScreenWindow()
  }
  
  func createFullScreenWindow() {
    ctrl = MyWindowController(windowNibName: NSNib.Name("Window"))
    ctrl.app = self
    let rect = NSScreen.main?.frame
    ctrl.window?.setFrame(rect!, display: false)
    ctrl.window?.backgroundColor = NSColor.black
    ctrl.nextButton.isHidden = true
  }
  
  func openFullScreenWindow() {
    ctrl.window?.toggleFullScreen(nil)
  }
  
  func closeFullScreenWindow() {
    ctrl.close()
    ctrl = nil
  }
  
  func updateStatusBar(_ time: Interval) {
    statusItem.title = String(format: "%02d:%02d", time.minutes, time.seconds)
  }
  
  func updateFullScreenWindow(_ time: Interval) {
    ctrl.label.stringValue = String(format: "%02d:%02d", time.minutes, time.seconds)
  }
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    timerInit()
    if timerSettings.autostart {
      startWorkTimer()
    }
  }

  func applicationWillTerminate(_ aNotification: Notification) {
//    NSStatusBar.system.removeStatusItem(self.statusItem)
  }

  @objc func menuStart() {
    startWorkTimer()
  }
  
  @objc func menuStop() {
    stopWorkTimer()
  }
  
  @objc func menuQuit() {
    NSApplication.shared.terminate(nil)
  }
  
  func initialTimerMenu() {
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Start Pomodoro", action: #selector(AppDelegate.menuStart), keyEquivalent: "S"))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.menuQuit), keyEquivalent: "Q"))
    statusItem.menu = menu
  }
  
  func workingTimerMenu() {
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Stop Pomodoro", action: #selector(AppDelegate.menuStop), keyEquivalent: "S"))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.menuQuit), keyEquivalent: "Q"))
    statusItem.menu = menu
  }
  
}

