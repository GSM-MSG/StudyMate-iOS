import CoreData
import OSLog

public final class ContextManager: CoreDataStack, Sendable {
  private enum Constants: Sendable {
    static let appGroup = "group.msg.studymate"
    static let cloudContainerIdentifier: String = "iCloud.msg.studymate"
    static let inMemoryStoreURL: URL = URL(fileURLWithPath: "/dev/null")
    static let databaseName: String = "StudyMateDB"
  }

  private let modelName: String
  private let storeURL: URL
  private let persistentContainer: NSPersistentCloudKitContainer

  public var mainContext: NSManagedObjectContext {
    persistentContainer.viewContext
  }

  public static let shared: ContextManager = {
    ContextManager(
      modelName: Constants.databaseName,
      store: FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: Constants.appGroup
      )!
    )
  }()

  init(modelName: String, store storeURL: URL) {
    self.modelName = modelName
    self.storeURL = storeURL
    self.persistentContainer = Self.createPersistentContainer(
      storeURL: storeURL,
      modelName: modelName
    )

    mainContext.automaticallyMergesChangesFromParent = true
    mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
  }

  public func newDerivedContext() -> NSManagedObjectContext {
    let context = persistentContainer.newBackgroundContext()
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    return context
  }

  public struct CoreDataChange<T>: Sendable {
    nonisolated(unsafe) let inserted: [T]
    nonisolated(unsafe) let updated: [T]
    nonisolated(unsafe) let deleted: [T]

    var hasChanges: Bool {
      !inserted.isEmpty || !updated.isEmpty || !deleted.isEmpty
    }
  }

  public func observeChangesStream<T>(
    for entityType: T.Type,
    observeOption: ObserveOption,
    bufferingPolicy: AsyncStream<Void>.Continuation.BufferingPolicy
  ) -> AsyncStream<Void> where T: NSManagedObject {
    return AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
      let notificationCenter = NotificationCenter.default

      let observeTask = Task {
        for await notification in notificationCenter.notifications(named: .NSManagedObjectContextObjectsDidChange) {
          guard
            Task.isCancelled == false,
            let userInfo = notification.userInfo
          else { break }

          let inserted = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? [])
            .filter({ objectID in objectID.entity == T.entity() })
            .compactMap { $0 as? T }
          let updated = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? [])
            .filter({ objectID in objectID.entity == T.entity() })
            .compactMap { $0 as? T }
          let deleted = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? [])
            .filter({ objectID in objectID.entity == T.entity() })
            .compactMap { $0 as? T }

          let change = CoreDataChange(
            inserted: inserted,
            updated: updated,
            deleted: deleted
          )

          guard change.hasChanges else { continue }

          if observeOption.contains(.inserted) && !change.inserted.isEmpty {
            continuation.yield()
            continue

          } else if observeOption.contains(.updated) && !change.updated.isEmpty {
            continuation.yield()
            continue

          } else if observeOption.contains(.deleted) && !change.deleted.isEmpty {
            continuation.yield()
            continue
          }
        }
      }

      continuation.onTermination = { _ in
        observeTask.cancel()
      }
    }
  }
}

extension ContextManager {
  private static func createPersistentContainer(
    storeURL: URL,
    modelName: String
  ) -> NSPersistentCloudKitContainer {
    guard
      let modelFileURL = Bundle.module.url(forResource: modelName, withExtension: "momd")
    else {
      fatalError("Can't find StudyMateDatabase.momd")
    }

    guard
      let objectModel = NSManagedObjectModel(contentsOf: modelFileURL)
    else {
      fatalError("Can't create object model named \(modelName) at \(modelFileURL)")
    }

    guard
      let stagedMigrationFactory = StagedMigrationFactory(
        bundle: Bundle.module,
        jsonDecoder: .init(),
        logger: .studyMateCoreData
      )
    else {
      fatalError("Can't create StagedMigrationFactory")
    }

    let baseURL = storeURL
      .appendingPathComponent("StudyMate", isDirectory: true)
      .appendingPathComponent("Database", isDirectory: true)

    if !FileManager.default.fileExists(atPath: baseURL.path(percentEncoded: false)) {
      do {
        try FileManager.default.createDirectory(
          at: baseURL,
          withIntermediateDirectories: true
        )
      } catch {
        Logger.studyMateCoreData.error("Can't create directory: \(error)")
      }
    }

    let sqliteURL = baseURL
      .appending(component: "StudyMateDB", directoryHint: .notDirectory)
      .appendingPathExtension("sqlite")

    Logger.studyMateCoreData.debug("\(sqliteURL)")
    let storeDescription = NSPersistentStoreDescription(url: sqliteURL)
//    storeDescription.url = Constants.inMemoryStoreURL
    storeDescription.type = NSSQLiteStoreType
    storeDescription.setOption(stagedMigrationFactory.create(), forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
    storeDescription.shouldAddStoreAsynchronously = false

    let isEnablediCloud = CloudKitOptionInteractor.live.fetchEnablediCloud()
    if isEnablediCloud {
      storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
        containerIdentifier: Constants.cloudContainerIdentifier
      )
    }
    storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    storeDescription.setOption(
      true as NSNumber,
      forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
    )

    let persistentContainer = NSPersistentCloudKitContainer(name: modelName, managedObjectModel: objectModel)
    persistentContainer.persistentStoreDescriptions = [storeDescription]

    persistentContainer.viewContext.automaticallyMergesChangesFromParent = true

    persistentContainer.loadPersistentStores { _, error in
      if let error {
        Logger.studyMateCoreData.error("\(error)")

        assertionFailure("Can't initialize Core Data stack")
      }
    }

    return persistentContainer
  }

  private static func storeURL() -> URL {
    guard
      let fileContainer = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: Constants.appGroup
      )
    else {
      fatalError()
    }
    return fileContainer
  }
}
