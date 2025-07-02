import AnalyticsClient
import Foundation

extension AnalyticsClient {
  func sendUserProperty(property: DefaultAnalyticsUserProperty) {
    self.sendUserProperty(propertyType: property)
  }
}

enum DefaultAnalyticsUserProperty: AnalyticsUserPropertyType {
  var name: String {
    ""
  }

  var value: String {
    ""
  }
}
