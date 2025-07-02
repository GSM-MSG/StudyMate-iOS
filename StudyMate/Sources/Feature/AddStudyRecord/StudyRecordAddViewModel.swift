import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class StudyRecordAddViewModel {
  var title = ""
  var content = ""
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
        attachments: attachmentInputs
      )
      
      let newRecord = try await studyRecordInteractor.createStudyRecord(input)
      
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
