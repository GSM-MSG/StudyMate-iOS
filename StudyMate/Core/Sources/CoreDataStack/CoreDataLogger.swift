import OSLog

extension Logger {
  private static var subsystem = Bundle.main.bundleIdentifier!

  static let studyMateCoreData = Logger(subsystem: subsystem, category: "StudyMateCoreData")
}
