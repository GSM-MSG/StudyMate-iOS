import AnalyticsClient
import Foundation

extension AnalyticsClient {
  func track(event: DefaultAnalyticsEvent) {
    self.track(eventType: event)
  }
}

enum DefaultAnalyticsEvent: AnalyticsEventType {
  case viewStudyRecords
  case viewDashboard
  case viewSettings
  case viewAddStudyRecord
  case viewEditStudyRecord
  case tapAddStudyRecord
  case viewStudyRecordDetail(entry: ViewStudyRecordDetailEntry)
  case saveStudyRecord(title: String, contentLength: StudyRecordContentLength, studyMinutes: Int, photoCount: Int, pdfCount: Int, audioCount: Int)
  case editStudyRecord(title: String, contentLength: StudyRecordContentLength, studyMinutes: Int, photoCount: Int, pdfCount: Int, audioCount: Int)
  case deleteStudyRecord
  case openStudyRecordContent
  case openStudyRecordAiTutor
  case tapAiTutorAnalyze
  case tapAiTutorReanalyze
  case tapViewAllStudyRecords
  case tapShare
  case tapRate

  var name: String {
    switch self {
    default: String(describing: self)
        .components(separatedBy: "(")
        .first?
        .snakeCased() ?? {
          assertionFailure("Invalid event name")
          return ""
        }()
    }
  }

  var properties: [String: Any]? {
    switch self {
    case let .saveStudyRecord(title, contentLength, studyMinutes, photoCount, pdfCount, audioCount),
      let .editStudyRecord(title, contentLength, studyMinutes, photoCount, pdfCount, audioCount):
      return [
        "title": title,
        "content_length": contentLength.analyticsValue,
        "study_minutes": studyMinutes,
        "photo_count": photoCount,
        "pdf_count": pdfCount,
        "audio_count": audioCount
      ]

    case let .viewStudyRecordDetail(entry):
      return [
        "entry": entry.analyticsValue
      ]

    case .viewStudyRecords, .viewDashboard, .viewSettings, .viewAddStudyRecord, .viewEditStudyRecord,
        .tapAddStudyRecord, .deleteStudyRecord, .openStudyRecordContent, .openStudyRecordAiTutor,
        .tapAiTutorAnalyze, .tapAiTutorReanalyze, .tapViewAllStudyRecords, .tapShare, .tapRate:
      return nil
    }
  }
}

extension DefaultAnalyticsEvent {
  enum StudyRecordContentLength: Sendable {
    case veryShort // ~50
    case short // 50 ~ 200
    case medium // 200 - 500
    case long // 500 ~ 1000
    case veryLong // 1000~

    init(length: Int) {
      if length < 50 {
        self = .veryShort
      } else if length < 200 {
        self = .short
      } else if length < 500 {
        self = .medium
      } else if length < 1000 {
        self = .long
      } else {
        self = .veryLong
      }
    }

    var analyticsValue: String {
      switch self {
      case .veryShort: "very_short"
      case .short: "short"
      case .medium: "medium"
      case .long: "long"
      case .veryLong: "very_long"
      }
    }
  }

  enum ViewStudyRecordDetailEntry: Sendable {
    case studyRecordList
    case dashboard

    var analyticsValue: String {
      switch self {
      case .studyRecordList: "study_record_list"
      case .dashboard: "dashboard"
      }
    }
  }
}

private extension String {
  func snakeCased() -> String {
    let regex = try? NSRegularExpression(pattern: "([a-z]*)([A-Z])")
    return regex?.stringByReplacingMatches(
      in: self,
      range: NSRange(0..<utf16.count),
      withTemplate: "$1 $2"
    )
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .components(separatedBy: " ")
    .joined(separator: "_")
    .lowercased() ?? ""
  }
}
