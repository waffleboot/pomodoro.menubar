import Foundation

struct Interval: Equatable, Codable {

  var minutes: Int
  var seconds: Int
  var elapsed: Int

  init(minutes: Int, seconds: Int) {
    self.minutes = minutes
    self.seconds = seconds
    self.elapsed = 0
  }

  mutating func tick() {
    elapsed += 1
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

  var zero: Bool {
    return minutes == 0 && seconds == 0
  }

}
