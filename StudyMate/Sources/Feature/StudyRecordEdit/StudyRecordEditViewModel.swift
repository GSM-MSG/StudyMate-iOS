import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class StudyRecordEditViewModel {
  var title = ""
  var content = ""
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
  
  init(record: StudyRecordModel, studyRecordInteractor: StudyRecordInteractor = LiveStudyRecordInteractor()) {
    self.originalRecord = record
    self.studyRecordInteractor = studyRecordInteractor
    
    self.title = record.title
    self.content = record.content
    
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
        attachments: attachmentInputs
      )
      
      let updatedRecord = try await studyRecordInteractor.updateStudyRecord(id: originalRecord.id, input: input)
      
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
