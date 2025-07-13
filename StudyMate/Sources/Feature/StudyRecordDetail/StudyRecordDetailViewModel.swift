import AIService
import AnalyticsClient
import Foundation
import Observation

@Observable
@MainActor
final class StudyRecordDetailViewModel {
  
  // MARK: - Published Properties
  
  private(set) var currentRecord: StudyRecordModel
  private(set) var feedbacks: [StudyFeedbackModel] = []
  private(set) var isGeneratingAIContent = false
  private(set) var errorMessage: String?
  
  var showingEditView = false
  var showingDeleteAlert = false
  var showingReanalyzeAlert = false
  
  // MARK: - Dependencies
  
  @ObservationIgnored
  private let studyRecordInteractor: StudyRecordInteractor
  @ObservationIgnored
  private let aiGenerator = AIFeedbackGenerator()
  
  // MARK: - Initialization
  
  init(record: StudyRecordModel, studyRecordInteractor: StudyRecordInteractor = LiveStudyRecordInteractor()) {
    self.currentRecord = record
    self.studyRecordInteractor = studyRecordInteractor
    self.feedbacks = record.feedbacks
  }
  
  // MARK: - Public Methods
  
  func deleteRecord() async -> Bool {
    do {
      try await studyRecordInteractor.deleteStudyRecord(id: currentRecord.id)
      return true
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }
  
  func generateAIFeedback() {
    if !feedbacks.isEmpty {
      showingReanalyzeAlert = true
      return
    }
    
    performAIFeedbackGeneration()
  }
  
  func performAIFeedbackGeneration() {
    isGeneratingAIContent = true
    errorMessage = nil
    
    Task {
      do {
        let aiRecord = AIService.StudyRecordDTO(
          id: currentRecord.id,
          title: currentRecord.title,
          content: currentRecord.content,
          createdTime: currentRecord.createdTime,
          updatedTime: currentRecord.updatedTime,
          attachments: currentRecord.attachments.map { attachment in
            AIService.AttachmentDTO(
              id: attachment.id,
              type: AIService.AttachmentDTO.AttachmentType(rawValue: attachment.type.rawValue) ?? .pdf,
              url: attachment.url,
              createdTime: attachment.createdTime
            )
          }
        )
        
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        let generatedFeedbacks = try await aiGenerator.generateFeedback(for: aiRecord, userLanguage: language)
        
        let feedbackInputs = generatedFeedbacks.map { aiFeedback in
          StudyFeedbackCreateInput(
            id: aiFeedback.id,
            title: aiFeedback.title,
            content: aiFeedback.content,
            icon: aiFeedback.icon,
            primaryColor: aiFeedback.primaryColor,
            createdTime: aiFeedback.createdTime,
            updatedTime: aiFeedback.updatedTime
          )
        }
        
        let updatedRecord = try await studyRecordInteractor.saveFeedbacks(for: currentRecord.id, feedbacks: feedbackInputs)
        
        await MainActor.run {
          currentRecord = updatedRecord
          feedbacks = updatedRecord.feedbacks
          isGeneratingAIContent = false
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          isGeneratingAIContent = false
        }
      }
    }
  }
  
  func updateRecord(_ updatedRecord: StudyRecordModel) {
    let recordWithFeedbacks = StudyRecordModel(
      id: updatedRecord.id,
      title: updatedRecord.title,
      content: updatedRecord.content,
      createdTime: updatedRecord.createdTime,
      updatedTime: updatedRecord.updatedTime,
      attachments: updatedRecord.attachments,
      feedbacks: currentRecord.feedbacks
    )
    currentRecord = recordWithFeedbacks
  }
  
  func clearError() {
    errorMessage = nil
  }
} 
