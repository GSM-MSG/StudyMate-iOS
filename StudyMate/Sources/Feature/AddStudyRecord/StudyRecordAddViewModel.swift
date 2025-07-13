import AnalyticsClient
import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class StudyRecordAddViewModel {
  var title = ""
  var content = ""
  var studyDuration: TimeInterval = 30 * 60 // 기본값 30분
  var attachments: [AttachmentItem] = []
  private(set) var isLoading = false
  private(set) var errorMessage: String?
  
  var isValidInput: Bool {
    !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  var hasAttachment: Bool {
    !attachments.isEmpty
  }
  
  var formattedDuration: String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .dropAll
    
    if studyDuration < 60 {
      return String(localized: "less_than_minute")
    }
    
    return formatter.string(from: studyDuration) ?? String(localized: "unknown_duration")
  }
  
  private let studyRecordInteractor: StudyRecordInteractor
  
  init(studyRecordInteractor: StudyRecordInteractor = LiveStudyRecordInteractor()) {
    self.studyRecordInteractor = studyRecordInteractor
  }
  
  func saveStudyRecord() async -> StudyRecordModel? {
    guard isValidInput else {
      errorMessage = String(localized: "title_content_required")
      return nil
    }
    
    isLoading = true
    errorMessage = nil
    
    do {
      let attachmentInputs = attachments.compactMap { attachment -> AttachmentCreateInput? in
        guard let url = attachment.url?.absoluteString ?? attachment.image?.saveToDocuments() else {
          return nil
        }
        
        let type: AttachmentModel.AttachmentType = attachment.type == .image ? .image : .document
        return AttachmentCreateInput(type: type, url: url)
      }
      
      let input = StudyRecordCreateInput(
        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
        content: content.trimmingCharacters(in: .whitespacesAndNewlines),
        studyDuration: studyDuration,
        attachments: attachmentInputs
      )
      
      let newRecord = try await studyRecordInteractor.createStudyRecord(input)

      AnalyticsClient.shared.track(
        event: .saveStudyRecord(
          title: title,
          contentLength: .init(length: content.count),
          studyMinutes: Int(studyDuration / 60.0),
          photoCount: attachments.filter { $0.type == .image }.count,
          pdfCount: attachments.filter { $0.type == .pdf }.count
        )
      )
      
      resetForm()
      
      isLoading = false
      return newRecord
      
    } catch {
      errorMessage = error.localizedDescription
      isLoading = false
      return nil
    }
  }
  
  func addAttachment(_ attachment: AttachmentItem) {
    attachments.append(attachment)
  }
  
  func removeAttachment(_ attachment: AttachmentItem) {
    attachments.removeAll { $0.id == attachment.id }
  }
  
  func appendTextFromScanner(_ text: String) {
    if content.isEmpty {
      content = text
    } else {
      content += "\n\n" + text
    }
  }
  
  func clearError() {
    errorMessage = nil
  }
  
  // MARK: - Private Methods
  
  private func resetForm() {
    title = ""
    content = ""
    studyDuration = 30 * 60 // 30분으로 리셋
    attachments = []
  }
}

// MARK: - AttachmentItem

struct AttachmentItem: Identifiable, Sendable {
  let id = UUID()
  let type: AttachmentType
  let image: UIImage?
  let url: URL?
  let name: String
  
  enum AttachmentType: Sendable {
    case image
    case pdf
  }
  
  init(type: AttachmentType, image: UIImage? = nil, url: URL? = nil, name: String) {
    self.type = type
    self.image = image
    self.url = url
    self.name = name
  }
}

// MARK: - UIImage Extension for saving

private extension UIImage {
  func saveToDocuments() -> String? {
    guard let data = self.jpegData(compressionQuality: 0.8) else { return nil }
    
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
    let fileName = "\(UUID().uuidString).jpg"
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    
    do {
      try data.write(to: fileURL)
      return fileURL.absoluteString
    } catch {
      print("Failed to save image: \(error)")
      return nil
    }
  }
}
