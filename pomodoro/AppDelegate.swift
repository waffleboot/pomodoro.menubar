
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
    var sessions: Int
    var workTime: Interval
    var smallTime: Interval
    var largeTime: Interval
  }

  static let fastTimerSettings = TimerSettings(
    autostart: true,
    notify: Interval(minutes: 0, seconds: 1),
    sessions: 2,
    workTime: Interval(minutes: 0, seconds: 3),
    smallTime: Interval(minutes: 0, seconds: 3),
    largeTime: Interval(minutes: 0, seconds: 3))
  
  static let debugTimerSettings = TimerSettings(
    autostart: true,
    notify: Interval(minutes: 0, seconds: 5),
    sessions: 2,
    workTime: Interval(minutes: 0, seconds: 10),
    smallTime: Interval(minutes: 0, seconds: 3),
    largeTime: Interval(minutes: 0, seconds: 3))
  
  static let releaseTimerSettings = TimerSettings(
    autostart: false,
    notify: Interval(minutes: 1, seconds: 0),
    sessions: 2,
    workTime: Interval(minutes: 25, seconds: 0),
    smallTime: Interval(minutes: 5, seconds: 0),
    largeTime: Interval(minutes: 20, seconds: 0))
  
  var timerSettings = AppDelegate.releaseTimerSettings

  var timer: Timer!
  var ctrl: MyWindowController!
  let statusItem = NSStatusBar.system.statusItem(withLength: -1)

  var session = 0
  var color = false
  var running = false
  var timerState = Interval(minutes: 0, seconds: 0)
  
  func timerInit() {
    running = false
    setPreWorkingMenu()
    updateStatusBar(timerSettings.workTime)
    statusItem.action = #selector(AppDelegate.startWorkTimerWithTick)
  }
  
  @objc func startWorkTimerWithTick() {
    startWorkTimer()
    workTimerTick()
  }
  
  func startWorkTimer() {
    session += 1
    running = true
    timerState = timerSettings.workTime
    statusItem.action = #selector(AppDelegate.stopWorkTimer)
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.workTimerTick), userInfo: nil, repeats: true)
    setWorkingTimerMenu()
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
    if session >= timerSettings.sessions {
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

  @objc func onMenuStart() {
    startWorkTimerWithTick()
  }
  
  @objc func onMenuStop() {
    stopWorkTimer()
  }
  
  @objc func onMenuQuit() {
    NSApplication.shared.terminate(nil)
  }
  
  @objc func onMenuFast() {
    setPredefinedSettings(AppDelegate.fastTimerSettings)
  }
  
  @objc func onMenuDebug() {
    setPredefinedSettings(AppDelegate.debugTimerSettings)
  }
  
  @objc func onMenuRelease() {
    setPredefinedSettings(AppDelegate.releaseTimerSettings)
  }
  
  func setPredefinedSettings(_ settings: TimerSettings) {
    self.timerSettings = settings
    if !running {
      timerInit()
    }
  }
  
  func setPreWorkingMenu() {
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Start Pomodoro", action: #selector(AppDelegate.onMenuStart), keyEquivalent: "S"))
    addSettingsMenuItems(menu)
    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.onMenuQuit), keyEquivalent: "Q"))
    statusItem.menu = menu
  }
  
  func setWorkingTimerMenu() {
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Stop Pomodoro", action: #selector(AppDelegate.onMenuStop), keyEquivalent: "S"))
    addSettingsMenuItems(menu)
    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.onMenuQuit), keyEquivalent: "Q"))
    statusItem.menu = menu
  }
  
  static let sessionsMenuTag = 100
  static let workTimeMenuTag = 101
  static let smallTimeMenuTag = 102
  static let largeTimeMenuTag = 103
  
  func addSettingsMenuItems(_ menu: NSMenu) {
    menu.addItem(.separator())
    
    let constructor = { (_ title: String, _ tag: Int, _ items: () -> NSMenu) in
      let submenu = NSMenuItem(title: title, action: nil, keyEquivalent: "")
      submenu.tag = tag
      submenu.submenu = items()
      menu.addItem(submenu)
    }
    
    constructor("Sessions", AppDelegate.sessionsMenuTag, createSessionsMenu)
    constructor("Work Time", AppDelegate.workTimeMenuTag, createWorkTimeMenu)
    constructor("Small Time", AppDelegate.smallTimeMenuTag, createSmallTimeMenu)
    constructor("Large Time", AppDelegate.largeTimeMenuTag, createLargeTimeMenu)

    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "Fast Pomodoro", action: #selector(AppDelegate.onMenuFast), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Debug Pomodoro", action: #selector(AppDelegate.onMenuDebug), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Release Pomodoro", action: #selector(AppDelegate.onMenuRelease), keyEquivalent: ""))
  }
  
  func setAndUpdateMenu(_ target: Int, _ tag: Int) {
    if let x = statusItem.menu, let y = x.item(withTag: tag), let z = y.submenu {
      for submenu in z.items {
        submenu.state = submenu.tag == target ? .on : .off
      }
    }
  }
  
  @objc func onSessionsMenu(_ sender: NSMenuItem) {
    timerSettings.sessions = sender.tag
    setAndUpdateMenu(sender.tag, AppDelegate.sessionsMenuTag)
  }
  
  @objc func onWorkTimeMenu(_ sender: NSMenuItem) {
    timerSettings.workTime.minutes = sender.tag
    if !running {
      updateStatusBar(timerSettings.workTime)
    }
    setAndUpdateMenu(sender.tag, AppDelegate.workTimeMenuTag)
  }
  
  @objc func onSmallTimeMenu(_ sender: NSMenuItem) {
    timerSettings.smallTime.minutes = sender.tag
    setAndUpdateMenu(sender.tag, AppDelegate.smallTimeMenuTag)
  }

  @objc func onLargeTimeMenu(_ sender: NSMenuItem) {
    timerSettings.largeTime.minutes = sender.tag
    setAndUpdateMenu(sender.tag, AppDelegate.largeTimeMenuTag)
  }

  struct item {
    let value: Int
    let selector: Selector
  }

  func createItemsMenu(_ items: [item], _ matcher: (Int) -> Bool) -> NSMenu {
    let menu = NSMenu()
    for i in items {
      let submenu = NSMenuItem(title: "\(i.value)", action: i.selector, keyEquivalent: "")
      submenu.tag = i.value
      if matcher(i.value) {
        submenu.state = .on
      }
      menu.addItem(submenu)
    }
    return menu
  }
  
  func createSessionsMenu() -> NSMenu {
    let items: [item] = [
      item(value:2, selector: #selector(AppDelegate.onSessionsMenu)),
      item(value:3, selector: #selector(AppDelegate.onSessionsMenu)),
      item(value:4, selector: #selector(AppDelegate.onSessionsMenu)),
      item(value:5, selector: #selector(AppDelegate.onSessionsMenu))]
    return createItemsMenu(items) { (_ value: Int) in timerSettings.sessions == value }
  }
  
  func createWorkTimeMenu() -> NSMenu {
    let items: [item] = [
      item(value:20, selector: #selector(AppDelegate.onWorkTimeMenu)),
      item(value:25, selector: #selector(AppDelegate.onWorkTimeMenu)),
      item(value:30, selector: #selector(AppDelegate.onWorkTimeMenu))]
    return createItemsMenu(items) { (_ value: Int) in timerSettings.workTime.minutes == value }
  }

  func createSmallTimeMenu() -> NSMenu {
    let items: [item] = [
      item(value:3, selector: #selector(AppDelegate.onSmallTimeMenu)),
      item(value:4, selector: #selector(AppDelegate.onSmallTimeMenu)),
      item(value:5, selector: #selector(AppDelegate.onSmallTimeMenu)),
      item(value:7, selector: #selector(AppDelegate.onSmallTimeMenu)),
      item(value:10, selector: #selector(AppDelegate.onSmallTimeMenu))]
    return createItemsMenu(items) { (_ value: Int) in timerSettings.smallTime.minutes == value }
  }
  
  func createLargeTimeMenu() -> NSMenu {
    let items: [item] = [
      item(value:10, selector: #selector(AppDelegate.onLargeTimeMenu)),
      item(value:15, selector: #selector(AppDelegate.onLargeTimeMenu)),
      item(value:20, selector: #selector(AppDelegate.onLargeTimeMenu))]
    return createItemsMenu(items) { (_ value: Int) in timerSettings.largeTime.minutes == value }
  }
  
}

