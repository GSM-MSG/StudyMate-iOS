import AmplitudeSwift
import AnalyticsClient
import CoreDataStack
import Firebase
import FirebaseAppCheck
import RevenueCat
import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {
  private var trackingStudyRecordTask: Task<Void, Error>?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    _ = ContextManager.shared
    configureFirebase()
    configurePurchases()
    configureAnalytics()
    integrateRevenueCatWithAmplitude()
    trackingStudyRecordUserProperties()
    return true
  }

  private func configureFirebase() {
    let providerFactory = StudyMateAppCheckProviderFactory()
    AppCheck.setAppCheckProviderFactory(providerFactory)

    FirebaseApp.configure()
  }

  private func configurePurchases() {
    let apiKey = Bundle.main.infoDictionary?["REVENUECAT_API_KEY"] as? String
    assert(apiKey != nil)

    if let apiKey {
      Purchases.configure(with: .init(withAPIKey: apiKey))
    }
  }

  private func configureAnalytics() {
    let userID = Purchases.shared.appUserID
    AnalyticsClient.shared.setUserID(userID: userID)
  }

  private func integrateRevenueCatWithAmplitude() {
    guard let deviceID = AnalyticsClient.shared.getDeviceID() else {
      assertionFailure("Amplitude device id is nil")
      return
    }
    Purchases.shared.attribution
      .setAttributes(["$amplitudeDeviceId": deviceID])
  }

  private func trackingStudyRecordUserProperties() {
    Task.detached {
      let count = try await ContextManager.shared.performQueryAsync { context in
        let fetchRequest = StudyRecord.fetchRequest()
        let count = try context.count(for: fetchRequest)
        return count
      }

      AnalyticsClient.shared.sendUserProperty(property: .studyRecordCount(count))
    }

    trackingStudyRecordTask?.cancel()
    trackingStudyRecordTask = Task.detached {
      let changesStream = ContextManager.shared.observeChangesStream(
        for: StudyRecord.self,
        observeOption: [.inserted, .deleted]
      )

      for await _ in changesStream {
        guard Task.isCancelled == false else { break }

        let count = try await ContextManager.shared.performQueryAsync { context in
          let fetchRequest = StudyRecord.fetchRequest()
          let count = try context.count(for: fetchRequest)
          return count
        }

        AnalyticsClient.shared.sendUserProperty(property: .studyRecordCount(count))
      }
    }
  }
}

final class StudyMateAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    return AppAttestProvider(app: app)
  }
}
