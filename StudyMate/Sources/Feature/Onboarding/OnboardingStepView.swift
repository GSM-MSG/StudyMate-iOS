import SwiftUI

struct OnboardingStepView<Content: View>: View {
  let step: OnboardingStep
  let content: () -> Content

  var body: some View {
    VStack(spacing: 32) {
      stepHeader

      demoContent

      Spacer()
    }
    .padding(.horizontal, 8)
  }

  private var stepHeader: some View {
    VStack(spacing: 16) {
      VStack(spacing: 8) {
        Text(step.title)
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.primary)
          .multilineTextAlignment(.center)

        Text(step.subtitle)
          .font(.system(size: 16))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .lineLimit(3)
      }
    }
  }

  private var demoContent: some View {
    VStack {
      content()
    }
    .frame(maxWidth: .infinity)
    .background(.ultraThinMaterial)
    .cornerRadius(16)
    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
  }
}

#Preview {
  OnboardingStepView(step: .addStudyContent) {
    Rectangle()
      .fill(Color.blue.opacity(0.3))
      .frame(height: 200)
  }
}
