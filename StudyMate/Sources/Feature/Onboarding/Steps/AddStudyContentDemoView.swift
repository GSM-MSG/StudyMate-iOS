import Combine
import SwiftUI

struct AddStudyContentDemoView: View {
  @State private var currentDemo: DemoStep = .title
  @State private var isAnimating = false
  @State private var timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(spacing: 20) {
          demoHeader
            .id("header")

          mockStudyRecordForm

          demoInstructions
            .id("instructions")
        }
        .padding(20)
      }
      .onChange(of: currentDemo) { oldValue, newValue in
        withAnimation(.easeInOut(duration: 0.8)) {
          switch newValue {
          case .title:
            proxy.scrollTo("title", anchor: .center)
          case .content:
            proxy.scrollTo("content", anchor: .center)
          case .duration:
            proxy.scrollTo("duration", anchor: .center)
          case .attachment:
            proxy.scrollTo("attachment", anchor: .center)
          }
        }
      }
    }
    .onAppear {
      isAnimating = true
    }
    .onDisappear {
      isAnimating = false
    }
    .onReceive(timer) { _ in
      guard isAnimating else { return }
      withAnimation(.easeInOut(duration: 0.5)) {
        switch currentDemo {
        case .title:
          currentDemo = .content
        case .content:
          currentDemo = .duration
        case .duration:
          currentDemo = .attachment
        case .attachment:
          currentDemo = .title
        }
      }
    }
  }

  private var demoHeader: some View {
    HStack {
      Image(systemName: "plus.circle.fill")
        .font(.title2)
        .foregroundStyle(Color(hex: "4A90E2"))

      Text("onboarding_add_content_demo_title")
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

  private var mockStudyRecordForm: some View {
    VStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("onboarding_add_content_field_title")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.primary)

          if currentDemo == .title {
            Image(systemName: "arrow.down")
              .font(.system(size: 12))
              .foregroundStyle(Color(hex: "4A90E2"))
              .animation(
                .easeInOut(duration: 0.8).repeatForever(),
                value: currentDemo
              )
          }
        }

        TextField(
          "onboarding_add_content_placeholder_title",
          text: .constant(
            currentDemo.rawValue >= DemoStep.title.rawValue
              ? String(localized: "onboarding_demo_content_title") : ""
          )
        )
        .padding(12)
        .background {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.1))
        }
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(
              currentDemo == .title ? Color(hex: "4A90E2") : Color.clear,
              lineWidth: 2
            )
        )
      }
      .id("title")

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("onboarding_add_content_field_content")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.primary)

          if currentDemo == .content {
            Image(systemName: "arrow.down")
              .font(.system(size: 12))
              .foregroundStyle(Color(hex: "4A90E2"))
              .animation(
                .easeInOut(duration: 0.8).repeatForever(),
                value: currentDemo
              )
          }
        }

        VStack(alignment: .leading, spacing: 0) {
          Text(
            currentDemo.rawValue >= DemoStep.content.rawValue
              ? String(localized: "onboarding_demo_content_description")
              : ""
          )
          .font(.system(size: 14))
          .foregroundStyle(.primary)
          .frame(minHeight: 80, alignment: .topLeading)
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.gray.opacity(0.1))
          }
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(
                currentDemo == .content ? Color(hex: "4A90E2") : Color.clear,
                lineWidth: 2
              )
          )
        }
      }
      .id("content")

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("onboarding_add_content_field_duration")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.primary)

          if currentDemo == .duration {
            Image(systemName: "arrow.down")
              .font(.system(size: 12))
              .foregroundStyle(Color(hex: "4A90E2"))
              .animation(
                .easeInOut(duration: 0.8).repeatForever(),
                value: currentDemo
              )
          }
        }

        HStack {
          Image(systemName: "clock")
            .foregroundStyle(.secondary)

          Text(
            currentDemo.rawValue >= DemoStep.duration.rawValue
            ? TimeInterval(2.5 * 3600).formattedStudyDuration
            : String(localized: "onboarding_add_content_placeholder_duration")
          )
          .foregroundStyle(
            currentDemo.rawValue >= DemoStep.duration.rawValue ? .primary : .secondary
          )

          Spacer()
        }
        .padding(12)
        .background {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.1))
        }
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(
              currentDemo == .duration ? Color(hex: "4A90E2") : Color.clear,
              lineWidth: 2
            )
        )
      }
      .id("duration")

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("onboarding_add_content_field_attachments")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.primary)

          if currentDemo == .attachment {
            Image(systemName: "arrow.down")
              .font(.system(size: 12))
              .foregroundStyle(Color(hex: "4A90E2"))
              .animation(
                .easeInOut(duration: 0.8).repeatForever(),
                value: currentDemo
              )
          }
        }

        if currentDemo.rawValue >= DemoStep.attachment.rawValue {
          HStack {
            Image(systemName: "doc.text.fill")
              .foregroundStyle(Color(hex: "4A90E2"))

            Text("SwiftUI_Notes.pdf")
              .font(.system(size: 14))
              .foregroundStyle(.primary)

            Spacer()

            Text("2.3MB")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          }
          .padding(12)
          .background {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color(hex: "4A90E2").opacity(0.1))
          }
        } else {
          Button(action: {}) {
            HStack {
              Image(systemName: "plus")
                .foregroundStyle(Color(hex: "4A90E2"))

              Text("onboarding_add_content_add_file")
                .foregroundStyle(Color(hex: "4A90E2"))
            }
            .font(.system(size: 14, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(12)
            .background {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "4A90E2").opacity(0.1))
            }
            .overlay {
              RoundedRectangle(cornerRadius: 8)
                .stroke(
                  currentDemo == .attachment
                  ? Color(hex: "4A90E2")
                  : Color.clear,
                  lineWidth: 2
                )
            }
          }
          .disabled(true)
        }
      }
      .id("attachment")
    }
  }

  private var demoInstructions: some View {
    VStack(spacing: 12) {
      HStack {
        Image(systemName: "lightbulb.fill")
          .foregroundStyle(.orange)

        Text("onboarding_add_content_tips_title")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.primary)

        Spacer()
      }

      VStack(alignment: .leading, spacing: 8) {
        instructionRow(icon: "pencil", text: String(localized: "onboarding_add_content_tip1"))
        instructionRow(icon: "camera", text: String(localized: "onboarding_add_content_tip2"))
        instructionRow(icon: "clock", text: String(localized: "onboarding_add_content_tip3"))
      }
    }
    .padding(16)
    .background(Color.orange.opacity(0.05))
    .cornerRadius(12)
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

}

private enum DemoStep: Int, CaseIterable {
  case title = 0
  case content = 1
  case duration = 2
  case attachment = 3
}

#Preview {
  AddStudyContentDemoView()
    .background(Color.gray.opacity(0.1))
}
