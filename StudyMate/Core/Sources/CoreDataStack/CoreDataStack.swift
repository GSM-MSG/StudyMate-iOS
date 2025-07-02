@_exported import CoreData

public protocol CoreDataStack: Sendable {
  var mainContext: NSManagedObjectContext { get }

  func newDerivedContext() -> NSManagedObjectContext

  func performAndSave<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) throws -> T
  func performAndSaveAsync<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) async throws -> T
  func performAndSave(_ block: sending @escaping (NSManagedObjectContext) throws -> Void) throws
  func performAndSaveAsync(_ block: sending @escaping (NSManagedObjectContext) throws -> Void) async throws
  func observeChangesStream<T: NSManagedObject>(
    for entityType: T.Type,
    observeOption: ObserveOption,
    bufferingPolicy: AsyncStream<Void>.Continuation.BufferingPolicy
  ) -> AsyncStream<Void>
}

extension CoreDataStack {
  public func observeChangesStream<T: NSManagedObject>(
    for entityType: T.Type,
    observeOption: ObserveOption = [.inserted, .updated, .deleted],
    bufferingPolicy: AsyncStream<Void>.Continuation.BufferingPolicy = .bufferingNewest(1)
  ) -> AsyncStream<Void> {
    self.observeChangesStream(
      for: entityType,
      observeOption: observeOption,
      bufferingPolicy: bufferingPolicy
    )
  }

  public func performAndSave<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) throws -> T {
    let context = newDerivedContext()
    return try context.performAndWait {
      let result = try block(context)

      let inserted = Array(context.insertedObjects)

      try context.obtainPermanentIDs(for: inserted)
      try context.save()
      return result
    }
  }

  public func performAndSaveAsync<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
    let context = newDerivedContext()
    return try await context.perform {
      let result = try block(context)

      let inserted = Array(context.insertedObjects)

      try context.obtainPermanentIDs(for: inserted)
      try context.save()
      return result
    }
  }

  public func performAndSave(_ block: sending @escaping (NSManagedObjectContext) throws -> Void) throws {
    let context = newDerivedContext()
    try context.performAndWait {
      try block(context)

      let inserted = Array(context.insertedObjects)

      try context.obtainPermanentIDs(for: inserted)
      try context.save()
    }
  }

  public func performAndSaveAsync(_ block: sending @escaping (NSManagedObjectContext) throws -> Void) async throws {
    let context = newDerivedContext()
    try await context.perform {
      try block(context)

      let inserted = Array(context.insertedObjects)

      try context.obtainPermanentIDs(for: inserted)
      try context.save()
    }
  }

  public func performQuery<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) throws -> T {
    let context = newDerivedContext()
    return try context.performAndWait {
      try block(context)
    }
  }

  public func performQueryAsync<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
    let context = newDerivedContext()
    return try await context.perform {
      try block(context)
    }
  }
}
