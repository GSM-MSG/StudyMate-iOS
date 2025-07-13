import AnalyticsClient
import FirebaseAnalytics
import MessageUI
import StoreKit
import SwiftUI

struct SettingsView: View {
  @Environment(\.requestReview) var requestReview
  @State private var showingMailComposer = false
  @State private var showingShareSheet = false
  @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
  
  var body: some View {
    NavigationStack {
      List {
        Section(String(localized: "support")) {
          SettingsRowView(
            icon: "envelope.fill",
            iconColor: .green,
            title: String(localized: "contact_us"),
            subtitle: String(localized: "contact_us_subtitle")
          ) {
            if MFMailComposeViewController.canSendMail() {
              showingMailComposer = true
            } else {
              if let url = URL(string: "mailto:support@msg-team.com?subject=[StudyMate] Feedback") {
                UIApplication.shared.open(url)
              }
            }
          }
          
          SettingsRowView(
            icon: "star.fill",
            iconColor: .orange,
            title: String(localized: "rate_app"),
            subtitle: String(localized: "rate_app_subtitle")
          ) {
            AnalyticsClient.shared.track(event: .tapRate)
            rateApp()
          }
          
          SettingsRowView(
            icon: "square.and.arrow.up.fill",
            iconColor: .blue,
            title: String(localized: "share_app"),
            subtitle: String(localized: "share_app_subtitle")
          ) {
            AnalyticsClient.shared.track(event: .tapShare)
            showingShareSheet = true
          }
        }
        
        Section {
          HStack {
            Image(.appIconSymbol)
              .resizable()
              .frame(width: 32, height: 32)
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .shadow(radius: 2)
            
            VStack(alignment: .leading, spacing: 2) {
              Text(String(localized: "app_name"))
                .font(.headline)
              Text("\(String(localized: "version")) \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
          }
          .padding(.vertical, 4)

        } header: {
          Text(String(localized: "app_info").uppercased())
        }
      }
      .navigationTitle(String(localized: "settings"))
      .navigationBarTitleDisplayMode(.large)
      .onAppear {
        AnalyticsClient.shared.track(event: .viewSettings)
      }
      .analyticsScreen(name: "settings")
    }
    .sheet(isPresented: $showingMailComposer) {
      MailComposeView(result: $mailResult)
    }
    .sheet(isPresented: $showingShareSheet) {
      ShareSheet(items: [shareText])
    }
  }
  
  private var shareText: String {
    String(localized: "share_message")
  }
  
  private func rateApp() {
    requestReview()
  }
  
  private func openPrivacyPolicy() {
    if let url = URL(string: "https://studymate.app/privacy") {
      UIApplication.shared.open(url)
    }
  }
  
  private func openTermsOfService() {
    if let url = URL(string: "https://studymate.app/terms") {
      UIApplication.shared.open(url)
    }
  }
  
  private func getAppID() -> String {
    return "6747303987"
  }
}

struct SettingsRowView: View {
  let icon: String
  let iconColor: Color
  let title: String
  let subtitle: String
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .foregroundColor(iconColor)
          .frame(width: 24, height: 24)
          .padding(4)
          .background(iconColor.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 6))
        
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.body)
            .foregroundColor(.primary)
          
          Text(subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        
        Spacer()
        
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Mail Composer

struct MailComposeView: UIViewControllerRepresentable {
  @Binding var result: Result<MFMailComposeResult, Error>?
  @Environment(\.presentationMode) var presentation
  
  func makeUIViewController(context: Context) -> MFMailComposeViewController {
    let composer = MFMailComposeViewController()
    composer.mailComposeDelegate = context.coordinator
    composer.setToRecipients(["support@msg-team.com"])
    composer.setSubject("[StudyMate] - Feedback")
    composer.setMessageBody("""
    
    ---
    App Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
    iOS Version: \(UIDevice.current.systemVersion)
    Device: \(UIDevice.current.model)
    Report ID: \(AnalyticsClient.shared.getUserID()?.data(using: .utf8)?.base64EncodedString() ?? "N/A")
    """, isHTML: false)
    
    return composer
  }
  
  func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  @MainActor
  final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
    let parent: MailComposeView
    
    init(_ parent: MailComposeView) {
      self.parent = parent
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
      defer {
        parent.presentation.wrappedValue.dismiss()
      }
      
      if let error = error {
        parent.result = .failure(error)
        return
      }
      
      parent.result = .success(result)
    }
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let items: [Any]
  
  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
  SettingsView()
}
