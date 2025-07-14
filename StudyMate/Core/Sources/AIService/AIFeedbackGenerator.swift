import FirebaseAI
import FirebaseCore
import Foundation
import UIKit

public struct AIFeedbackGenerator: Sendable {
  private let models: [GenerativeModel]
  private let modelNames = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-2.0-flash-lite"]
  
  public init() {
    let schema = Schema.object(
      properties: [
        "feedbacks": Schema.array(
          items: Schema.object(properties: [
            "title": Schema.string(),
            "content": Schema.string(),
            "icon": Schema.string(),
            "color": Schema.string()
          ])
        )
      ]
    )
    
    let generationConfig = GenerationConfig(
      responseMIMEType: "application/json",
      responseSchema: schema
    )
    
    self.models = modelNames.map { modelName in
      FirebaseAI.firebaseAI(app: FirebaseApp.app(), backend: .googleAI()).generativeModel(
        modelName: modelName,
        generationConfig: generationConfig
      )
    }
  }
  
  public func generateFeedback(
    for studyRecord: StudyRecordDTO,
    userLanguage: String = "Korean"
  ) async throws -> [StudyFeedbackDTO] {
    let prompt = createPrompt(for: studyRecord, userLanguage: userLanguage)
    
    let contentModels: [ModelContent] = studyRecord.attachments.compactMap { attachment -> ModelContent? in
      switch attachment.type {
      case .image:
        guard
          let image = UIImage(contentsOfFile: attachment.url)
        else { return nil }
        return ModelContent(parts: image.partsValue)

      case .pdf:
        let url = URL(filePath: attachment.url)
        
        url.startAccessingSecurityScopedResource()
        do {
          let content = try ModelContent(parts: InlineDataPart(data: Data(contentsOf: url), mimeType: "application/pdf"))
          url.stopAccessingSecurityScopedResource()
          return content
        } catch {
          url.stopAccessingSecurityScopedResource()
          return nil
        }
      }
    } + [.init(parts: prompt)]
    
    var lastError: Error?
    
    for (index, model) in models.enumerated() {
      do {
        let response = try await model.generateContent(contentModels)
        
        guard let responseText = response.text else {
          throw AIFeedbackError.noResponse
        }
        
        return try parseFeedbackResponse(responseText)
      } catch {
        lastError = error
        print("Model \(modelNames[index]) failed with error: \(error.localizedDescription)")
        
        if index < models.count - 1 {
          continue
        }
      }
    }
    
    throw lastError ?? AIFeedbackError.networkError
  }
  
  private func createPrompt(for record: StudyRecordDTO, userLanguage: String) -> String {
    return """
    You are an AI tutor analyzing a student's study record. Please provide comprehensive feedback in \(userLanguage) language.
    
    Study Record:
    Title: \(record.title)
    Content: \(record.content)
    
    Please analyze this study record and provide feedback in the following areas (but feel free to add other relevant feedback categories):
    - Summary of what was learned
    - Understanding level assessment
    - Improvement suggestions
    - Next learning steps guide
    - Recommended resources
    - Learning method advice
    
    Provide your response as a JSON object with an array of feedback items. Each feedback item should have:
    - title: A concise title for the feedback category
    - content: Detailed feedback content
    - icon: An appropriate SF Symbols icon name (e.g., "book.fill", "lightbulb.fill", "chart.bar.fill", "arrow.right.circle.fill", "brain.head.profile.fill", "star.fill", etc.)
    - color: A hex color code (e.g., "#007AFF", "#34C759", "#FF9500", "#AF52DE", "#5AC8FA", "#FF3B30", etc.)
    
    Choose icons and colors that are semantically appropriate for each feedback category. Make sure your response is helpful, constructive, and encouraging. Tailor the feedback to the specific content and learning level demonstrated in the study record.
    """
  }
  
  private func parseFeedbackResponse(_ responseText: String) throws -> [StudyFeedbackDTO] {
    guard let data = responseText.data(using: .utf8) else {
      throw AIFeedbackError.invalidResponse
    }
    
    let decoder = JSONDecoder()
    let response = try decoder.decode(AIFeedbackResponse.self, from: data)
    
    return response.feedbacks.map { feedback in
      StudyFeedbackDTO(
        id: UUID().uuidString,
        title: feedback.title,
        content: feedback.content,
        icon: feedback.icon,
        primaryColor: feedback.color,
        createdTime: Date(),
        updatedTime: Date()
      )
    }
  }
  

}

public enum AIFeedbackError: LocalizedError {
  case noResponse
  case invalidResponse
  case networkError
  
  public var errorDescription: String? {
    switch self {
    case .noResponse:
      return "No Response"
    case .invalidResponse:
      return "Invalid Response"
    case .networkError:
      return "Network error ocuured"
    }
  }
}

private struct AIFeedbackResponse: Codable {
  let feedbacks: [AIFeedbackItem]
}

private struct AIFeedbackItem: Codable {
  let title: String
  let content: String
  let icon: String
  let color: String
}
