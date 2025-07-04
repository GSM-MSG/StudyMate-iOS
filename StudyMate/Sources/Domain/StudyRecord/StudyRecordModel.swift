import Foundation

// MARK: - Domain Models

struct StudyRecordModel: Identifiable, Hashable {
  let id: String
  let title: String
  let content: String
  let createdTime: Date
  let updatedTime: Date
  let studyDuration: TimeInterval // 초 단위
  let attachments: [AttachmentModel]
  let feedbacks: [StudyFeedbackModel]
  
  var hasAttachment: Bool {
    !attachments.isEmpty
  }
  
  var hasFeedback: Bool {
    !feedbacks.isEmpty
  }
  
  var formattedDate: String {
    createdTime.formatted(.dateTime.month().day())
  }
  
  var formattedDuration: String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .dropAll
    
    if studyDuration < 60 {
      // 1분 미만인 경우 "1분 미만"으로 표시
      return String(localized: "less_than_minute")
    }
    
    return formatter.string(from: studyDuration) ?? String(localized: "unknown_duration")
  }
  
  init(id: String, title: String, content: String, createdTime: Date, updatedTime: Date, studyDuration: TimeInterval = 0, attachments: [AttachmentModel], feedbacks: [StudyFeedbackModel] = []) {
    self.id = id
    self.title = title
    self.content = content
    self.createdTime = createdTime
    self.updatedTime = updatedTime
    self.studyDuration = studyDuration
    self.attachments = attachments
    self.feedbacks = feedbacks
  }
}

struct AttachmentModel: Identifiable, Hashable {
  let id: String
  let type: AttachmentType
  let url: String
  let createdTime: Date
  
  enum AttachmentType: String, CaseIterable {
    case image = "image"
    case document = "document"
    case audio = "audio"
  }
}

// MARK: - StudyRecord Creation Input

struct StudyRecordCreateInput {
  let title: String
  let content: String
  let studyDuration: TimeInterval
  let attachments: [AttachmentCreateInput]
}

struct AttachmentCreateInput {
  let type: AttachmentModel.AttachmentType
  let url: String
}

// MARK: - StudyRecord Update Input

struct StudyRecordUpdateInput {
  let title: String?
  let content: String?
  let studyDuration: TimeInterval?
  let attachments: [AttachmentCreateInput]?
}

// MARK: - StudyFeedback Input

struct StudyFeedbackCreateInput {
  let id: String
  let title: String
  let content: String
  let icon: String
  let primaryColor: String
  let createdTime: Date
  let updatedTime: Date
} 
