import Foundation

public struct StudyRecordDTO: Identifiable, Hashable, Sendable {
  public let id: String
  public let title: String
  public let content: String
  public let createdTime: Date
  public let updatedTime: Date
  public let attachments: [AttachmentDTO]
  
  public var hasAttachment: Bool {
    !attachments.isEmpty
  }
  
  public var formattedDate: String {
    createdTime.formatted(.dateTime.month().day())
  }
  
  public init(id: String, title: String, content: String, createdTime: Date, updatedTime: Date, attachments: [AttachmentDTO]) {
    self.id = id
    self.title = title
    self.content = content
    self.createdTime = createdTime
    self.updatedTime = updatedTime
    self.attachments = attachments
  }
}

public struct AttachmentDTO: Identifiable, Hashable, Sendable {
  public let id: String
  public let type: AttachmentType
  public let url: String
  public let createdTime: Date
  
  public enum AttachmentType: String, CaseIterable, Sendable {
    case image = "image"
    case pdf = "pdf"
  }
  
  public init(id: String, type: AttachmentType, url: String, createdTime: Date) {
    self.id = id
    self.type = type
    self.url = url
    self.createdTime = createdTime
  }
}

public struct StudyFeedbackDTO: Identifiable, Sendable {
  public let id: String
  public let title: String
  public let content: String
  public let icon: String
  public let primaryColor: String
  public let createdTime: Date
  public let updatedTime: Date
  
  public init(id: String, title: String, content: String, icon: String, primaryColor: String, createdTime: Date, updatedTime: Date) {
    self.id = id
    self.title = title
    self.content = content
    self.icon = icon
    self.primaryColor = primaryColor
    self.createdTime = createdTime
    self.updatedTime = updatedTime
  }
} 
