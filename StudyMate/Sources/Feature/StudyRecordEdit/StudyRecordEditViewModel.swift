import AnalyticsClient
import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class StudyRecordEditViewModel {
  var title = ""
  var content = ""
  var studyDuration: TimeInterval = 30 * 60
  var attachments: [AttachmentItem] = []
  private(set) var isLoading = false
  private(set) var errorMessage: String?
  
  private let originalRecord: StudyRecordModel
  private let studyRecordInteractor: StudyRecordInteractor
  
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
  
  init(record: StudyRecordModel, studyRecordInteractor: StudyRecordInteractor = LiveStudyRecordInteractor()) {
    self.originalRecord = record
    self.studyRecordInteractor = studyRecordInteractor
    
    self.title = record.title
    self.content = record.content
    self.studyDuration = record.studyDuration
    
    self.attachments = record.attachments.map { attachment in
      AttachmentItem(
        type: attachment.type == .image ? .image : .pdf,
        url: URL(string: attachment.url),
        name: URL(string: attachment.url)?.lastPathComponent ?? "File"
      )
    }
  }
  
  func updateStudyRecord() async -> StudyRecordModel? {
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
      
      let input = StudyRecordUpdateInput(
        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
        content: content.trimmingCharacters(in: .whitespacesAndNewlines),
        studyDuration: studyDuration,
        attachments: attachmentInputs
      )
      
      let updatedRecord = try await studyRecordInteractor.updateStudyRecord(id: originalRecord.id, input: input)

      AnalyticsClient.shared.track(
        event: .editStudyRecord(
          title: title,
          contentLength: .init(length: content.count),
          studyMinutes: Int(studyDuration / 60.0),
          photoCount: attachments.filter { $0.type == .image }.count,
          pdfCount: attachments.filter { $0.type == .pdf }.count
        )
      )
      
      isLoading = false
      return updatedRecord
      
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
