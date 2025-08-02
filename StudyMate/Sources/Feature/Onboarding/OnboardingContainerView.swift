import SwiftUI

struct OnboardingContainerView: View {
  @State private var viewModel = OnboardingViewModel()
  let onComplete: () -> Void

  var body: some View {
    ZStack {
      backgroundGradient
        .ignoresSafeArea(.all, edges: .top)

      VStack(spacing: 0) {
        header

        content

        navigationControls
      }
      .padding(.horizontal, 24)
    }
  }

  private var backgroundGradient: some View {
    LinearGradient(
      colors: [
        Color(hex: viewModel.currentStep.primaryColor).opacity(0.1),
        Color(hex: viewModel.currentStep.primaryColor).opacity(0.05),
        Color.clear,
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea()
  }

  private var header: some View {
    VStack(spacing: 16) {
      ProgressView(value: viewModel.progress)
        .progressViewStyle(
          LinearProgressViewStyle(
            tint: Color(hex: viewModel.currentStep.primaryColor)
          )
        )
        .scaleEffect(y: 2)
    }
    .padding(.bottom, 40)
  }

  private var content: some View {
    VStack(spacing: 0) {
      switch viewModel.currentStep {
      case .addStudyContent:
        OnboardingStepView(step: .addStudyContent) {
          AddStudyContentDemoView()
        }
      case .aiAnalysis:
        OnboardingStepView(step: .aiAnalysis) {
          AIAnalysisDemoView()
        }
      case .dashboard:
        OnboardingStepView(step: .dashboard) {
          DashboardDemoView()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var navigationControls: some View {
    VStack(spacing: 16) {
      HStack(spacing: 16) {
        if viewModel.canGoBack {
          Button {
            withAnimation(.snappy) {
              viewModel.previousStep()
            }
          } label: {
            HStack {
              Image(systemName: "chevron.left")
              Text(String(localized: "onboarding_previous"))
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
          }
        }

        Button {
          if viewModel.canGoNext {
            withAnimation(.snappy) {
              viewModel.nextStep()
            }
          } else {
            viewModel.completeOnboarding()
            onComplete()
          }
        } label: {
          HStack {
            Text(viewModel.canGoNext ? String(localized: "onboarding_next") : String(localized: "onboarding_get_started"))
            if viewModel.canGoNext {
              Image(systemName: "chevron.right")
            }
          }
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(Color(hex: viewModel.currentStep.primaryColor))
          .cornerRadius(12)
        }
      }

      Text("\(viewModel.currentStepIndex + 1) / \(viewModel.totalSteps)")
        .font(.system(size: 14))
        .foregroundColor(.secondary)
    }
    .padding(.bottom, 40)
  }
}
