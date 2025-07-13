import Foundation
import CoreDataStack
import Observation

protocol StudyRecordInteractor: Sendable {
  func fetchStudyRecords() async throws -> [StudyRecordModel]
  func searchStudyRecords(searchText: String) async throws -> [StudyRecordModel]
  func createStudyRecord(_ input: StudyRecordCreateInput) async throws -> StudyRecordModel
  func updateStudyRecord(id: String, input: StudyRecordUpdateInput) async throws -> StudyRecordModel
  func deleteStudyRecord(id: String) async throws
  func fetchStudyRecord(id: String) async throws -> StudyRecordModel?
  func saveFeedbacks(for recordId: String, feedbacks: [StudyFeedbackCreateInput]) async throws -> StudyRecordModel
  func clearFeedbacks(for recordId: String) async throws -> StudyRecordModel
  func observeStudyRecords() -> AsyncStream<Void>
}

struct LiveStudyRecordInteractor: StudyRecordInteractor, Sendable {
  private let coreDataStack: any CoreDataStack
  
  init(coreDataStack: any CoreDataStack = ContextManager.shared) {
    self.coreDataStack = coreDataStack
  }
  
  func fetchStudyRecords() async throws -> [StudyRecordModel] {
    try await coreDataStack.performQueryAsync { context in
      let request = StudyRecord.fetchRequest()
      let records = try context.fetch(request)
      return records.map { $0.toDomainModel() }
    }
  }
  
  func searchStudyRecords(searchText: String) async throws -> [StudyRecordModel] {
    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return try await fetchStudyRecords()
    }
    
    return try await coreDataStack.performQueryAsync { context in
      let request = StudyRecord.searchFetchRequest(searchText: searchText)
      let records = try context.fetch(request)
      return records.map { $0.toDomainModel() }
    }
  }
  
  func fetchStudyRecord(id: String) async throws -> StudyRecordModel? {
    try await coreDataStack.performQueryAsync { context in
      let request = StudyRecord.fetchRequest()
      request.predicate = \StudyRecord.identifier == id
      request.fetchLimit = 1
      
      guard let record = try context.fetch(request).first else { return nil }
      return record.toDomainModel()
    }
  }
  
  func createStudyRecord(_ input: StudyRecordCreateInput) async throws -> StudyRecordModel {
    try await coreDataStack.performAndSaveAsync { context in
      let record = StudyRecord(context: context, input: input)
      context.insert(record)
      return record.toDomainModel()
    }
  }
  
  func updateStudyRecord(id: String, input: StudyRecordUpdateInput) async throws -> StudyRecordModel {
    try await coreDataStack.performAndSaveAsync { context in
      let request = StudyRecord.fetchRequest()
      request.predicate = \StudyRecord.identifier == id
      request.fetchLimit = 1
      
      guard let record = try context.fetch(request).first else {
        throw StudyRecordError.recordNotFound
      }
      
      record.update(with: input)
      return record.toDomainModel()
    }
  }
  
  func deleteStudyRecord(id: String) async throws {
    try await coreDataStack.performAndSaveAsync { context in
      let request = StudyRecord.fetchRequest()
      request.predicate = \StudyRecord.identifier == id
      request.fetchLimit = 1
      
      guard let record = try context.fetch(request).first else {
        throw StudyRecordError.recordNotFound
      }

      context.delete(record)
    }
  }
  
  func saveFeedbacks(for recordId: String, feedbacks: [StudyFeedbackCreateInput]) async throws -> StudyRecordModel {
    try await coreDataStack.performAndSaveAsync { context in
      let request = StudyRecord.fetchRequest()
      request.predicate = \StudyRecord.identifier == recordId
      request.fetchLimit = 1
      
      guard let record = try context.fetch(request).first else {
        throw StudyRecordError.recordNotFound
      }
      
      record.addFeedbacks(feedbacks)
      return record.toDomainModel()
    }
  }
  
  func clearFeedbacks(for recordId: String) async throws -> StudyRecordModel {
    try await coreDataStack.performAndSaveAsync { context in
      let request = StudyRecord.fetchRequest()
      request.predicate = \StudyRecord.identifier == recordId
      request.fetchLimit = 1
      
      guard let record = try context.fetch(request).first else {
        throw StudyRecordError.recordNotFound
      }
      
      record.clearFeedbacks()
      return record.toDomainModel()
    }
  }
  
  func observeStudyRecords() -> AsyncStream<Void> {
    coreDataStack.observeChangesStream(for: StudyRecord.self)
  }
}

enum StudyRecordError: LocalizedError, Sendable {
  case recordNotFound
  case invalidInput
  case coreDataError(Error)
  
  var errorDescription: String? {
    switch self {
    case .recordNotFound:
      return "Study record not found"
    case .invalidInput:
      return "Invalid input"
    case .coreDataError(let error):
      return "Database error: \(error.localizedDescription)"
    }
  }
} 
