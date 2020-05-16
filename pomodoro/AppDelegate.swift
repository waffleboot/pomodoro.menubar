
import Cocoa

class MyWindowController: NSWindowController, NSWindowDelegate {
  
  @IBOutlet weak var mmLabel: NSTextField!
  @IBOutlet weak var ssLabel: NSTextField!
  @IBOutlet weak var tickerView: NSView!
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
  
  struct Interval: Equatable {

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
    
    static func == (lhs: Interval, rhs: Interval) -> Bool {
      return lhs.minutes == rhs.minutes && lhs.seconds == rhs.seconds
    }
    
    var done: Bool {
      return minutes == 0 && seconds == 0
    }
    
  }
  
  struct PomodoroNotification {
    var when: Interval
    var title: String
  }
  
  struct TimerSettings {
    var autostart: Bool
    var notification: PomodoroNotification
    var sessions: Int
    var workTime: Interval
    var smallTime: Interval
    var largeTime: Interval
  }

  static let fastTimerSettings = TimerSettings(
    autostart: true,
    notification: PomodoroNotification(when: Interval(minutes: 0, seconds: 1), title: "Last Second!"),
    sessions: 2,
    workTime: Interval(minutes: 0, seconds: 3),
    smallTime: Interval(minutes: 0, seconds: 3),
    largeTime: Interval(minutes: 0, seconds: 3))
  
  static let debugTimerSettings = TimerSettings(
    autostart: true,
    notification: PomodoroNotification(when: Interval(minutes: 0, seconds: 5), title: "Last Seconds!"),
    sessions: 2,
    workTime: Interval(minutes: 0, seconds: 10),
    smallTime: Interval(minutes: 0, seconds: 3),
    largeTime: Interval(minutes: 0, seconds: 3))
  
  static let releaseTimerSettings = TimerSettings(
    autostart: false,
    notification: PomodoroNotification(when: Interval(minutes: 1, seconds: 0), title: "Last Minute!"),
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
    } else if timerState == timerSettings.notification.when {
      notify()
    }
  }
  
  func notify() {
    let note = NSUserNotification()
    note.title = timerSettings.notification.title
    note.informativeText = session >= timerSettings.sessions
      ? "Almost time to take a long break!"
      : "Almost time to take a short break!"
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
      ctrl.tickerView.isHidden = true
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
    ctrl.mmLabel.stringValue = String(format: "%02d", time.minutes)
    ctrl.ssLabel.stringValue = String(format: "%02d", time.seconds)
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
      if timerSettings.autostart {
        startWorkTimer()
      }
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
  
  enum SettingsMenu: Int {
    case notifyMenuTag = 100,
    sessionsMenuTag,
    workTimeMenuTag,
    smallTimeMenuTag,
    largeTimeMenuTag
  }
  
  
  func addSettingsMenuItems(_ menu: NSMenu) {
    menu.addItem(.separator())
    
    let constructor = { (_ title: String, _ tag: SettingsMenu, _ items: () -> NSMenu) in
      let submenu = NSMenuItem(title: title, action: nil, keyEquivalent: "")
      submenu.tag = tag.rawValue
      submenu.submenu = items()
      menu.addItem(submenu)
    }
    
    constructor("Notify", .notifyMenuTag, createNotifyMenu)
    constructor("Sessions", .sessionsMenuTag, createSessionsMenu)
    constructor("Work Time", .workTimeMenuTag, createWorkTimeMenu)
    constructor("Small Time", .smallTimeMenuTag, createSmallTimeMenu)
    constructor("Large Time", .largeTimeMenuTag, createLargeTimeMenu)

    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "Fast Pomodoro", action: #selector(AppDelegate.onMenuFast), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Debug Pomodoro", action: #selector(AppDelegate.onMenuDebug), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Release Pomodoro", action: #selector(AppDelegate.onMenuRelease), keyEquivalent: ""))
  }
  
  func setAndUpdateMenu<T>(_ target: Int, _ tag: SettingsMenu, _ items: [item<T>], _ updater: (T) -> ()) {
    var i = 0
    for item in items {
      if target == i {
        updater(item.value)
        break
      }
      i += 1
    }
    if let x = statusItem.menu, let y = x.item(withTag: tag.rawValue), let z = y.submenu {
      for submenu in z.items {
        submenu.state = submenu.tag == target ? .on : .off
      }
    }
  }
  
  @objc func onNotifyMenu(_ sender: NSMenuItem) {
    setAndUpdateMenu(sender.tag, .notifyMenuTag, notifyItems, { timerSettings.notification = $0 })
  }
  
  @objc func onSessionsMenu(_ sender: NSMenuItem) {
    setAndUpdateMenu(sender.tag, .sessionsMenuTag, sessionItems, { timerSettings.sessions = $0 })
  }
  
  @objc func onWorkTimeMenu(_ sender: NSMenuItem) {
    setAndUpdateMenu(sender.tag, .workTimeMenuTag, workTimeItems, { timerSettings.workTime = $0 })
    if !running {
      updateStatusBar(timerSettings.workTime)
    }
  }
  
  @objc func onSmallTimeMenu(_ sender: NSMenuItem) {
    setAndUpdateMenu(sender.tag, .smallTimeMenuTag, smallTimeItems, { timerSettings.smallTime = $0 })
  }

  @objc func onLargeTimeMenu(_ sender: NSMenuItem) {
    setAndUpdateMenu(sender.tag, .largeTimeMenuTag, largeTimeItems, { timerSettings.largeTime = $0 })
  }

  struct item<T> {
    let title: String
    let value: T
  }

  func createItemsMenu<T>(_ items: [item<T>], _ selector: Selector, _ matcher: (T) -> Bool) -> NSMenu {
    var tag = 0
    let menu = NSMenu()
    for i in items {
      let submenu = NSMenuItem(title: i.title, action: selector, keyEquivalent: "")
      submenu.tag = tag
      if matcher(i.value) {
        submenu.state = .on
      }
      menu.addItem(submenu)
      tag += 1
    }
    return menu
  }
  
  let notifyItems = [
    item(title: "30 сек", value: PomodoroNotification(when: Interval(minutes: 0, seconds: 30), title: "Last Seconds!")),
    item(title: "1 мин", value: PomodoroNotification(when: Interval(minutes: 1, seconds: 0), title: "Last Minute!"))
  ]
  
  let sessionItems = [
    item(title: "2", value:2),
    item(title: "3", value:3),
    item(title: "4", value:4),
    item(title: "5", value:5)]
  
  let workTimeItems = [
    item(title: "20 мин", value: Interval(minutes: 20, seconds: 0)),
    item(title: "25 мин", value: Interval(minutes: 25, seconds: 0)),
    item(title: "30 мин", value: Interval(minutes: 30, seconds: 0)),
    item(title: "40 мин", value: Interval(minutes: 40, seconds: 0))]
  
  let smallTimeItems = [
    item(title: "3 мин", value: Interval(minutes: 3, seconds: 0)),
    item(title: "4 мин", value: Interval(minutes: 4, seconds: 0)),
    item(title: "5 мин", value: Interval(minutes: 5, seconds: 0)),
    item(title: "7 мин", value: Interval(minutes: 7, seconds: 0)),
    item(title: "10 мин", value: Interval(minutes: 10, seconds: 0))]
  
  let largeTimeItems = [
    item(title: "10 мин", value: Interval(minutes: 10, seconds: 0)),
    item(title: "15 мин", value: Interval(minutes: 15, seconds: 0)),
    item(title: "20 мин", value: Interval(minutes: 20, seconds: 0))]
  
  func createNotifyMenu() -> NSMenu {
    return createItemsMenu(notifyItems, #selector(AppDelegate.onNotifyMenu)) { timerSettings.notification.when == $0.when }
  }
  
  func createSessionsMenu() -> NSMenu {
    return createItemsMenu(sessionItems, #selector(AppDelegate.onSessionsMenu)) { timerSettings.sessions == $0 }
  }
  
  func createWorkTimeMenu() -> NSMenu {
    return createItemsMenu(workTimeItems, #selector(AppDelegate.onWorkTimeMenu)) { timerSettings.workTime == $0 }
  }

  func createSmallTimeMenu() -> NSMenu {
    return createItemsMenu(smallTimeItems, #selector(AppDelegate.onSmallTimeMenu)) { timerSettings.smallTime == $0 }
  }
  
  func createLargeTimeMenu() -> NSMenu {
    return createItemsMenu(largeTimeItems, #selector(AppDelegate.onLargeTimeMenu)) { timerSettings.largeTime == $0 }
  }
  
}

