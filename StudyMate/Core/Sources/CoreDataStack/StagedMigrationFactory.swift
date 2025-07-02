import CoreData
import Foundation
import OSLog

extension NSManagedObjectModelReference {
  convenience init(in database: URL, modelName: String) {
    let modelURL = database.appending(component: "\(modelName).mom")
    guard let model = NSManagedObjectModel(contentsOf: modelURL) else { fatalError() }

    self.init(model: model, versionChecksum: model.versionChecksum)
  }
}

struct StagedMigrationFactory {
  private let databaseURL: URL
  private let jsonDecoder: JSONDecoder
  private let logger: Logger

  init?(
    bundle: Bundle = .main,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    logger: Logger = .studyMateCoreData
  ) {
    guard let databaseURL = bundle.url(forResource: "StudyMateDB", withExtension: "momd") else { return nil }
    self.databaseURL = databaseURL
    self.jsonDecoder = jsonDecoder
    self.logger = logger
  }

  func create() -> NSStagedMigrationManager {
    let allStages: [NSCustomMigrationStage] = []

    return NSStagedMigrationManager(allStages)
  }
}
