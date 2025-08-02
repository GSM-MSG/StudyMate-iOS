import Foundation

@Observable
final class OnboardingViewModel {
  var currentStep: OnboardingStep = .addStudyContent
  var isOnboardingCompleted: Bool = false

  @ObservationIgnored
  private let userDefaults = UserDefaults.standard
  @ObservationIgnored
  private let onboardingCompletedKey = "isOnboardingCompleted"

  init() {
    checkOnboardingStatus()
  }

  var totalSteps: Int {
    OnboardingStep.allCases.count
  }

  var currentStepIndex: Int {
    OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
  }

  var progress: Double {
    Double(currentStepIndex + 1) / Double(totalSteps)
  }

  var canGoNext: Bool {
    currentStep != OnboardingStep.allCases.last
  }

  var canGoBack: Bool {
    currentStep != OnboardingStep.allCases.first
  }

  func nextStep() {
    guard canGoNext else { return }

    if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
      currentIndex + 1 < OnboardingStep.allCases.count
    {
      currentStep = OnboardingStep.allCases[currentIndex + 1]
    }
  }

  func previousStep() {
    guard canGoBack else { return }

    if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
      currentIndex > 0
    {
      currentStep = OnboardingStep.allCases[currentIndex - 1]
    }
  }

  func completeOnboarding() {
    userDefaults.set(true, forKey: onboardingCompletedKey)
    isOnboardingCompleted = true
  }

  private func checkOnboardingStatus() {
    isOnboardingCompleted = userDefaults.bool(forKey: onboardingCompletedKey)
  }

  func resetOnboarding() {
    userDefaults.set(false, forKey: onboardingCompletedKey)
    isOnboardingCompleted = false
    currentStep = .addStudyContent
  }
}

enum OnboardingStep: CaseIterable {
  case addStudyContent
  case aiAnalysis
  case dashboard

  var title: String {
    switch self {
    case .addStudyContent:
      return String(localized: "onboarding_step1_title")
    case .aiAnalysis:
      return String(localized: "onboarding_step2_title")
    case .dashboard:
      return String(localized: "onboarding_step3_title")
    }
  }

  var subtitle: String {
    switch self {
    case .addStudyContent:
      return String(localized: "onboarding_step1_subtitle")
    case .aiAnalysis:
      return String(localized: "onboarding_step2_subtitle")
    case .dashboard:
      return String(localized: "onboarding_step3_subtitle")
    }
  }

  var iconName: String {
    switch self {
    case .addStudyContent:
      return "plus.circle.fill"
    case .aiAnalysis:
      return "brain.filled.head.profile"
    case .dashboard:
      return "chart.bar.fill"
    }
  }

  var primaryColor: String {
    switch self {
    case .addStudyContent:
      return "4A90E2"
    case .aiAnalysis:
      return "9B59B6"
    case .dashboard:
      return "27AE60"
    }
  }
}
