import Foundation

struct PomodoroNotification: Codable {
  var when: Interval
  var title: String
}

struct TimerSettings {
  var debug: Bool
  var autostart: Bool
  var notification: PomodoroNotification
  var sessions: Int
  var workTime: Interval
  var smallTime: Interval
  var largeTime: Interval
  var autoClose: Bool

  static let fastTimerSettings = TimerSettings(
    debug: true,
    autostart: true,
    notification: PomodoroNotification(when: Interval(minutes: 0, seconds: 1), title: "Last Second!"),
    sessions: 2,
    workTime: Interval(minutes: 0, seconds: 4),
    smallTime: Interval(minutes: 0, seconds: 3),
    largeTime: Interval(minutes: 0, seconds: 7),
    autoClose: false)

  static let debugTimerSettings = TimerSettings(
    debug: true,
    autostart: true,
    notification: PomodoroNotification(when: Interval(minutes: 0, seconds: 10), title: "Last Seconds!"),
    sessions: 2,
    workTime: Interval(minutes: 1, seconds: 10),
    smallTime: Interval(minutes: 0, seconds: 3),
    largeTime: Interval(minutes: 0, seconds: 3),
    autoClose: false)

  static let releaseTimerSettings = TimerSettings(
    debug: true,
    autostart: false,
    notification: PomodoroNotification(when: Interval(minutes: 1, seconds: 0), title: "Last Minute!"),
    sessions: 2,
    workTime: Interval(minutes: 25, seconds: 0),
    smallTime: Interval(minutes: 5, seconds: 0),
    largeTime: Interval(minutes: 20, seconds: 0),
    autoClose: false)

}

