//
//  StudyMateApp.swift
//  StudyMate
//
//  Created by 최형우 on 6/2/25.
//

import AmplitudeSwift
import FirebaseAppCheck
import FirebaseCore
import RevenueCat
import SwiftUI

@main
struct StudyMateApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  init() {
    configureFirebase()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
  
  private func configureFirebase() {
    let providerFactory = StudyMateAppCheckProviderFactory()
    AppCheck.setAppCheckProviderFactory(providerFactory)

    FirebaseApp.configure()
  }

  private func configurePurchases() {
    Purchases.configure(with: .init(withAPIKey: ""))
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
}

class StudyMateAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    return AppAttestProvider(app: app)
  }
}
