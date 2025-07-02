@preconcurrency import AmplitudeSwift
import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation

public final class AnalyticsClient: Sendable {
  private let amplitude: Amplitude

  public static let shared = AnalyticsClient()

  private init() {
#if DEBUG
    let amplitudeConfiguration = AmplitudeSwift.Configuration(
      apiKey: "1be0066636d5569aab0585c8e4ff23fd",
      logLevel: .DEBUG
    )
#else
    let amplitudeConfiguration = AmplitudeSwift.Configuration(
      apiKey: "1be0066636d5569aab0585c8e4ff23fd"
    )
#endif
    self.amplitude = Amplitude(
      configuration: amplitudeConfiguration
    )
  }

  public func track(eventType: any AnalyticsEventType) {
    amplitude.track(
      eventType: eventType.name,
      eventProperties: eventType.properties
    )

    FirebaseAnalytics.Analytics.logEvent(eventType.name, parameters: eventType.properties)
  }

  public func sendUserProperty(propertyType property: any AnalyticsUserPropertyType) {
    let identify = AmplitudeSwift.Identify()
    identify.set(property: property.name, value: property.value)
    amplitude.identify(identify: identify)

    FirebaseAnalytics.Analytics.setUserProperty(property.value, forName: property.name)
  }

  public func setUserID(userID: String) {
    amplitude.setUserId(userId: userID)
    FirebaseAnalytics.Analytics.setUserID(userID)
    Crashlytics.crashlytics().setUserID(userID)
  }

  public func getUserID() -> String? {
    return amplitude.getUserId()
  }

  public func getDeviceID() -> String? {
    return amplitude.getDeviceId()
  }
}
