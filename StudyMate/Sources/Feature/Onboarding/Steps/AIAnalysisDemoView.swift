import Combine
import SwiftUI

struct AIAnalysisDemoView: View {
  @State private var showAnalysis = false
  @State private var currentFeedbackIndex = 0
  @State private var isAnimating = false
  @State private var timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

  private let mockFeedbacks = [
    MockFeedback(
      title: String(localized: "onboarding_ai_feedback_1_title"),
      content: String(localized: "onboarding_ai_feedback_1_content"),
      iconName: "checkmark.circle.fill",
      color: "27AE60"
    ),
    MockFeedback(
      title: String(localized: "onboarding_ai_feedback_2_title"),
      content: String(localized: "onboarding_ai_feedback_2_content"),
      iconName: "lightbulb.fill",
      color: "F39C12"
    ),
    MockFeedback(
      title: String(localized: "onboarding_ai_feedback_3_title"),
      content: String(localized: "onboarding_ai_feedback_3_content"),
      iconName: "arrow.right.circle.fill",
      color: "9B59B6"
    ),
  ]

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(spacing: 20) {
          demoHeader
            .id("header")

          studyRecordPreview
            .id("preview")

          if showAnalysis {
            aiAnalysisResults
              .id("results")
          } else {
            analyzeButton
              .id("button")
          }

          demoInstructions
            .id("instructions")
        }
        .padding(20)
      }
      .onChange(of: showAnalysis) { oldValue, newValue in
        if newValue {
          withAnimation(.easeInOut(duration: 1.0)) {
            proxy.scrollTo("results", anchor: .center)
          }
        }
      }
      .onChange(of: currentFeedbackIndex) { oldValue, newValue in
        withAnimation(.easeInOut(duration: 0.5)) {
          proxy.scrollTo("feedback-\(newValue)", anchor: .center)
        }
      }
    }
    .onAppear {
      startDemo()
    }
    .onDisappear {
      isAnimating = false
    }
    .onReceive(timer) { _ in
      guard isAnimating && showAnalysis else { return }
      withAnimation(.easeInOut(duration: 0.5)) {
        currentFeedbackIndex = (currentFeedbackIndex + 1) % mockFeedbacks.count
      }
    }
  }

  private var demoHeader: some View {
    HStack {
      Image(systemName: "brain.filled.head.profile")
        .font(.title2)
        .foregroundStyle(Color(hex: "9B59B6"))

      Text("onboarding_ai_demo_title")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(.primary)

      Spacer()

      Text("onboarding_demo")
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
          RoundedRectangle(cornerRadius: 6)
            .fill(Color.secondary.opacity(0.1))
        }
    }
  }

  private var studyRecordPreview: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("onboarding_ai_demo_record_title")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)

        Spacer()

        Text(TimeInterval(2.5 * 3600).formattedStudyDuration)
          .font(.system(size: 14))
          .foregroundStyle(.secondary)
      }

      Text("onboarding_demo_content_title")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.primary)

      Text("onboarding_demo_content_description")
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .lineLimit(4)

      HStack {
        Image(systemName: "doc.text.fill")
          .foregroundStyle(Color(hex: "4A90E2"))

        Text("SwiftUI_Notes.pdf")
          .font(.system(size: 12))
          .foregroundStyle(.primary)

        Spacer()
      }
    }
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray.opacity(0.05))
    }
  }

  private var analyzeButton: some View {
    Button {
      withAnimation(.easeInOut(duration: 0.8)) {
        showAnalysis = true
      }
    } label: {
      HStack {
        if !showAnalysis {
          Image(systemName: "brain.filled.head.profile")
            .font(.system(size: 16))
        }

        Text("onboarding_ai_start_analysis")
          .font(.system(size: 16, weight: .semibold))

        if !showAnalysis {
          Image(systemName: "sparkles")
            .font(.system(size: 14))
        }
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 48)
      .background {
        LinearGradient(
          colors: [Color(hex: "9B59B6"), Color(hex: "8E44AD")],
          startPoint: .leading,
          endPoint: .trailing
        )
      }
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .disabled(showAnalysis)
  }

  private var aiAnalysisResults: some View {
    VStack(spacing: 16) {
      HStack {
        Image(systemName: "sparkles")
          .foregroundStyle(Color(hex: "9B59B6"))

        Text("onboarding_ai_analysis_results")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)

        Spacer()
      }

      VStack(spacing: 12) {
        ForEach(Array(mockFeedbacks.enumerated()), id: \.offset) { index, feedback in
          feedbackCard(
            feedback: feedback,
            isHighlighted: index == currentFeedbackIndex
          )
          .scaleEffect(index == currentFeedbackIndex ? 1.02 : 1.0)
          .animation(.easeInOut(duration: 0.3), value: currentFeedbackIndex)
          .id("feedback-\(index)")
        }
      }
    }
  }

  private func feedbackCard(
    feedback: MockFeedback,
    isHighlighted: Bool
  ) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: feedback.iconName)
        .font(.system(size: 16))
        .foregroundStyle(Color(hex: feedback.color))
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 4) {
        Text(feedback.title)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.primary)

        Text(feedback.content)
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
          .lineLimit(3)
      }

      Spacer()
    }
    .padding(12)
    .background {
      RoundedRectangle(cornerRadius: 10)
        .fill(
          isHighlighted
          ? Color(hex: feedback.color).opacity(0.1)
          : Color.gray.opacity(0.05)
        )
    }
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .stroke(
          isHighlighted
          ? Color(hex: feedback.color).opacity(0.3)
          : Color.clear,
          lineWidth: 1
        )
    }
  }

  private var demoInstructions: some View {
    VStack(spacing: 12) {
      HStack {
        Image(systemName: "brain.fill")
          .foregroundStyle(Color(hex: "9B59B6"))

        Text("onboarding_ai_benefits_title")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.primary)

        Spacer()
      }

      VStack(alignment: .leading, spacing: 8) {
        instructionRow(icon: "magnifyingglass", text: String(localized: "onboarding_ai_benefit1"))
        instructionRow(icon: "target", text: String(localized: "onboarding_ai_benefit2"))
        instructionRow(
          icon: "arrow.triangle.2.circlepath",
          text: String(localized: "onboarding_ai_benefit3")
        )
      }
    }
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(hex: "9B59B6").opacity(0.05))
    }
  }

  private func instructionRow(icon: String, text: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .frame(width: 16)

      Text(text)
        .font(.system(size: 13))
        .foregroundStyle(.secondary)

      Spacer()
    }
  }

  private func startDemo() {
    Task {
      try await Task.sleep(for: .seconds(1))
      withAnimation(.easeInOut(duration: 0.8)) {
        showAnalysis = true
      }

      try await Task.sleep(for: .seconds(2))
      isAnimating = true
    }
  }
}

private struct MockFeedback {
  let title: String
  let content: String
  let iconName: String
  let color: String
}

#Preview {
  AIAnalysisDemoView()
    .background(Color.gray.opacity(0.1))
}
