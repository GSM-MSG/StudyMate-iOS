import Foundation

extension DateComponentsFormatter {
  static let studyDuration: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .full
    formatter.maximumUnitCount = 2
    return formatter
  }()
  
  static let streakCount: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day]
    formatter.unitsStyle = .full
    formatter.maximumUnitCount = 1
    return formatter
  }()
  
  static let totalTime: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour]
    formatter.unitsStyle = .full
    formatter.maximumUnitCount = 1
    return formatter
  }()
}

extension TimeInterval {
  var formattedStudyDuration: String {
    return DateComponentsFormatter.studyDuration.string(from: self) ?? "0 minutes"
  }
  
  var formattedTotalTime: String {
    return DateComponentsFormatter.totalTime.string(from: self) ?? "0 hours"
  }
}

extension Int {
  var formattedStreakCount: String {
    let timeInterval = TimeInterval(self * 24 * 60 * 60) // Convert days to seconds
    return DateComponentsFormatter.streakCount.string(from: timeInterval) ?? "0 days"
  }
}
