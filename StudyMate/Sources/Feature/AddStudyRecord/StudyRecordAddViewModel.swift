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
      var seenAudio = false
      let attachmentInputs = attachments.compactMap { attachment -> AttachmentCreateInput? in
        let url: String?
        
        if let image = attachment.image {
          url = image.saveToDocuments()
        } else if let tempURL = attachment.url {
          url = tempURL.saveToDocuments()
        } else {
          url = nil
        }
        
        guard let finalURL = url else { return nil }
        
        let type: AttachmentModel.AttachmentType = {
          switch attachment.type {
          case .image: return .image
          case .pdf: return .document
          case .audio: return .audio
          }
        }()
        if type == .audio {
          if seenAudio { return nil }
          seenAudio = true
        }
        return AttachmentCreateInput(type: type, url: finalURL)
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
          pdfCount: attachments.filter { $0.type == .pdf }.count,
          audioCount: attachments.filter { $0.type == .audio }.count
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
    if let originalURL = attachment.url, let tempURL = copyToTemporaryIfNeeded(originalURL) {
      let updated = AttachmentItem(
        type: attachment.type,
        image: attachment.image,
        url: tempURL,
        name: attachment.name
      )
      attachments.append(updated)
    } else {
      attachments.append(attachment)
    }
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
  private func copyToTemporaryIfNeeded(_ url: URL) -> URL? {
    let fileManager = FileManager.default
    let tempDir = fileManager.temporaryDirectory.appendingPathComponent("StudyMateTemp", isDirectory: true)

    do {
      try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
    } catch {
      print("Failed to create temp dir: \(error)")
      return nil
    }

    let ext = url.pathExtension
    let fileName = ext.isEmpty ? UUID().uuidString : "\(UUID().uuidString).\(ext)"
    let destURL = tempDir.appendingPathComponent(fileName)
    
    var didStartAccessing = false
    if url.startAccessingSecurityScopedResource() {
      didStartAccessing = true
    }
    defer {
      if didStartAccessing { url.stopAccessingSecurityScopedResource() }
    }

    do {
      if fileManager.fileExists(atPath: destURL.path) {
        try fileManager.removeItem(at: destURL)
      }
      try fileManager.copyItem(at: url, to: destURL)
      return destURL
    } catch {
      print("Failed to copy to temp: \(error)")
      return nil
    }
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
    case audio
  }
  
  init(type: AttachmentType, image: UIImage? = nil, url: URL? = nil, name: String) {
    self.type = type
    self.image = image
    self.url = url
    self.name = name
  }
}

// MARK: - Extensions for saving

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

private extension URL {
  func saveToDocuments() -> String? {
    guard let documentsDirectory = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    ).first else {
      return nil
    }
    let fileManager = FileManager.default
    let attachmentsDir = documentsDirectory
      .appending(path: "attachments", directoryHint: .isDirectory)
    do {
      try fileManager.createDirectory(at: attachmentsDir, withIntermediateDirectories: true)
    } catch {
      print("Failed to create attachments dir: \(error)")
      return nil
    }

    let fileName = "\(UUID().uuidString).\(self.pathExtension)"
    let destinationURL = attachmentsDir.appendingPathComponent(fileName)
    
    do {
      try fileManager.copyItem(at: self, to: destinationURL)
      return destinationURL.absoluteString
    } catch {
      print("Failed to save file: \(error)")
      return nil
    }
  }
}
