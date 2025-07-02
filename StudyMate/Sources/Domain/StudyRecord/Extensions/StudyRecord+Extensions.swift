import CoreDataStack
import Foundation

// MARK: - StudyRecord CoreData Extensions

extension StudyRecord {
  
  // MARK: - Convenience Initializers
  
  convenience init(context: NSManagedObjectContext, input: StudyRecordCreateInput) {
    self.init(context: context)
    
    self.identifier = UUID().uuidString
    self.title = input.title
    self.content = input.content
    self.createdTime = Date()
    self.updatedTime = Date()
    self.deletedTime = nil
    
    // Create attachments
    for attachmentInput in input.attachments {
      let attachment = RecordAttachment(context: context)
      attachment.identifier = UUID().uuidString
      attachment.type = attachmentInput.type.rawValue
      attachment.url = attachmentInput.url
      attachment.createdTime = Date()
      attachment.updatedTime = Date()
      attachment.record = self
    }
  }
  
  // MARK: - Update Methods
  
  func update(with input: StudyRecordUpdateInput) {
    if let title = input.title {
      self.title = title
    }
    
    if let content = input.content {
      self.content = content
    }
    
    if let attachmentInputs = input.attachments {
      // Remove existing attachments
      if let existingAttachments = self.attachments {
        for attachment in existingAttachments {
          if let attachment = attachment as? RecordAttachment {
            managedObjectContext?.delete(attachment)
          }
        }
      }
      
      // Add new attachments
      for attachmentInput in attachmentInputs {
        let attachment = RecordAttachment(context: managedObjectContext!)
        attachment.identifier = UUID().uuidString
        attachment.type = attachmentInput.type.rawValue
        attachment.url = attachmentInput.url
        attachment.createdTime = Date()
        attachment.updatedTime = Date()
        attachment.record = self
      }
    }
    
    self.updatedTime = Date()
  }
  
  // MARK: - Soft Delete
  
  func softDelete() {
    self.deletedTime = Date()
  }
  
  // MARK: - Feedback Management
  
  func addFeedbacks(_ feedbackInputs: [StudyFeedbackCreateInput]) {
    guard let context = managedObjectContext else { return }
    
    // Remove existing feedbacks
    if let existingFeedbacks = self.feedbacks {
      for feedback in existingFeedbacks {
        if let feedback = feedback as? StudyFeedback {
          context.delete(feedback)
        }
      }
    }
    
    // Add new feedbacks
    for feedbackInput in feedbackInputs {
      let feedback = StudyFeedback(context: context)
      feedback.identifier = feedbackInput.id
      feedback.title = feedbackInput.title
      feedback.content = feedbackInput.content
      feedback.icon = feedbackInput.icon
      feedback.primaryColor = feedbackInput.primaryColor
      feedback.createdTime = feedbackInput.createdTime
      feedback.updatedTime = feedbackInput.updatedTime
      feedback.record = self
    }
  }
  
  func clearFeedbacks() {
    guard let context = managedObjectContext else { return }
    
    if let existingFeedbacks = self.feedbacks {
      for feedback in existingFeedbacks {
        if let feedback = feedback as? StudyFeedback {
          context.delete(feedback)
        }
      }
    }
  }
  
  // MARK: - Domain Model Conversion
  
  func toDomainModel() -> StudyRecordModel {
    let attachmentModels = (attachments?.allObjects as? [RecordAttachment] ?? [])
      .compactMap { $0.toDomainModel() }
    
    let feedbackModels = (feedbacks?.allObjects as? [StudyFeedback] ?? [])
      .compactMap { $0.toDomainModel() }
      .sorted { $0.createdTime < $1.createdTime }
    
    return StudyRecordModel(
      id: identifier ?? UUID().uuidString,
      title: title ?? "",
      content: content ?? "",
      createdTime: createdTime ?? Date(),
      updatedTime: updatedTime ?? Date(),
      attachments: attachmentModels,
      feedbacks: feedbackModels
    )
  }
}

// MARK: - RecordAttachment CoreData Extensions

extension RecordAttachment {
  
  func toDomainModel() -> AttachmentModel? {
    guard 
      let id = identifier,
      let typeString = type,
      let attachmentType = AttachmentModel.AttachmentType(rawValue: typeString),
      let url = url
    else { return nil }
    
    return AttachmentModel(
      id: id,
      type: attachmentType,
      url: url,
      createdTime: createdTime ?? Date()
    )
  }
}

// MARK: - StudyFeedback CoreData Extensions

extension StudyFeedback {
  
  func toDomainModel() -> StudyFeedbackModel? {
    guard 
      let id = identifier,
      let title = title,
      let content = content,
      let icon = icon,
      let primaryColor = primaryColor
    else { return nil }
    
    return StudyFeedbackModel(
      id: id,
      title: title,
      content: content,
      icon: icon,
      primaryColor: primaryColor,
      createdTime: createdTime ?? Date(),
      updatedTime: updatedTime ?? Date()
    )
  }
}

// MARK: - Fetch Request Extensions

extension StudyRecord {
  
  static func searchFetchRequest(searchText: String) -> NSFetchRequest<StudyRecord> {
    let request = fetchRequest()
    let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
    let contentPredicate = NSPredicate(format: "content CONTAINS[cd] %@", searchText)
    let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
    
    let activePredicate = NSPredicate(format: "deletedTime == nil")
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [activePredicate, searchPredicate])
    
    return request
  }
} 
