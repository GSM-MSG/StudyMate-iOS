import Combine
import SwiftUI

struct DashboardDemoView: View {
  @State private var currentHighlight: DashboardSection = .none
  @State private var isAnimating = false
  @State private var timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
  private static let relativeDatetimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    return formatter
  }()
  private var weekdaySymbols: [String] {
    Calendar.current.shortWeekdaySymbols
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(spacing: 20) {
          demoHeader
            .id("header")

          mockDashboard

          demoInstructions
            .id("instructions")
        }
        .padding(20)
      }
      .onChange(of: currentHighlight) { oldValue, newValue in
        withAnimation(.easeInOut(duration: 0.8)) {
          switch newValue {
          case .none:
            proxy.scrollTo("header", anchor: .top)
          case .totalRecords, .weeklyCount, .streak, .totalTime:
            proxy.scrollTo("stats", anchor: .center)
          case .weeklyChart:
            proxy.scrollTo("chart", anchor: .center)
          case .recentRecords:
            proxy.scrollTo("records", anchor: .center)
          }
        }
      }
    }
    .onAppear {
      startTour()
    }
    .onDisappear {
      isAnimating = false
    }
    .onReceive(timer) { _ in
      guard isAnimating else { return }
      withAnimation(.easeInOut(duration: 0.5)) {
        switch currentHighlight {
        case .none:
          currentHighlight = .totalRecords
        case .totalRecords:
          currentHighlight = .weeklyCount
        case .weeklyCount:
          currentHighlight = .streak
        case .streak:
          currentHighlight = .totalTime
        case .totalTime:
          currentHighlight = .weeklyChart
        case .weeklyChart:
          currentHighlight = .recentRecords
        case .recentRecords:
          currentHighlight = .totalRecords
        }
      }
    }
  }

  private var demoHeader: some View {
    HStack {
      Image(systemName: "chart.bar.fill")
        .font(.title2)
        .foregroundStyle(Color(hex: "27AE60"))

      Text("onboarding_dashboard_demo_title")
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

  private var mockDashboard: some View {
    VStack(spacing: 16) {
      statsCardsSection

      weeklyChart

      recentRecords
    }
  }

  private var statsCardsSection: some View {
    VStack(spacing: 12) {
      HStack {
        Text("onboarding_dashboard_stats_title")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.primary)

        Spacer()

        if [.totalRecords, .weeklyCount, .streak, .totalTime].contains(
          currentHighlight
        ) {
          Image(systemName: "arrow.down.left")
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: "4A90E2"))
            .animation(
              .easeInOut(duration: 0.8).repeatForever(),
              value: currentHighlight
            )
        }
      }

      statsCards
    }
    .padding(16)
    .background {
      let isContainsStep = [.totalRecords, .weeklyCount, .streak, .totalTime].contains(
        currentHighlight
      )

      RoundedRectangle(cornerRadius: 12)
        .fill(
          isContainsStep
          ? Color.blue.opacity(0.03)
          : Color.gray.opacity(0.02)
        )
    }
    .overlay {
      let isContainsStep = [.totalRecords, .weeklyCount, .streak, .totalTime].contains(
        currentHighlight
      )

      RoundedRectangle(cornerRadius: 12)
        .stroke(
          isContainsStep
          ? Color.blue.opacity(0.2)
          : Color.clear,
          lineWidth: 1
        )
    }
    .id("stats")
  }

  private var statsCards: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2),
      spacing: 8
    ) {
      statCard(
        title: String(localized: "onboarding_dashboard_stat_total"),
        value: "24",
        icon: "doc.text.fill",
        color: "4A90E2",
        isHighlighted: currentHighlight == .totalRecords
      )

      statCard(
        title: String(localized: "onboarding_dashboard_stat_weekly"),
        value: "7",
        icon: "calendar.badge.clock",
        color: "27AE60",
        isHighlighted: currentHighlight == .weeklyCount
      )

      statCard(
        title: String(localized: "onboarding_dashboard_stat_streak"),
        value: 5.formattedStreakCount,
        icon: "flame.fill",
        color: "E74C3C",
        isHighlighted: currentHighlight == .streak
      )

      statCard(
        title: String(localized: "onboarding_dashboard_stat_time"),
        value: TimeInterval(42 * 3600).formattedTotalTime,
        icon: "clock.fill",
        color: "9B59B6",
        isHighlighted: currentHighlight == .totalTime
      )
    }
  }

  private func statCard(
    title: String,
    value: String,
    icon: String,
    color: String,
    isHighlighted: Bool
  ) -> some View {
    VStack(spacing: 8) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 16))
          .foregroundStyle(Color(hex: color))

        Spacer()
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(value)
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(.primary)

        Text(title)
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(
          isHighlighted
            ? Color(hex: color).opacity(0.1)
            : Color.gray.opacity(0.05)
        )
    )
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .stroke(
          isHighlighted
          ? Color(hex: color).opacity(0.5)
          : Color.clear,
          lineWidth: 2
        )
    }
    .scaleEffect(isHighlighted ? 1.05 : 1.0)
    .animation(.easeInOut(duration: 0.3), value: isHighlighted)
  }

  private var weeklyChart: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("onboarding_dashboard_weekly_chart")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)

        Spacer()

        if currentHighlight == .weeklyChart {
          Image(systemName: "arrow.down.left")
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: "27AE60"))
            .animation(
              .easeInOut(duration: 0.8).repeatForever(),
              value: currentHighlight
            )
        }
      }

      HStack(alignment: .bottom, spacing: 8) {
        ForEach(0..<7) { index in
          VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
              .fill(Color(hex: "27AE60").opacity(0.7))
              .frame(
                width: 24,
                height: CGFloat([20, 35, 15, 40, 25, 30, 45][index])
              )

            Text(weekdaySymbols[index])
              .font(.system(size: 10))
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: 80)
    }
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(
          currentHighlight == .weeklyChart
          ? Color(hex: "27AE60").opacity(0.05)
          : Color.gray.opacity(0.05)
        )
    }
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .stroke(
          currentHighlight == .weeklyChart
          ? Color(hex: "27AE60").opacity(0.3)
          : Color.clear,
          lineWidth: 2
        )
    }
    .id("chart")
  }

  private var recentRecords: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("onboarding_dashboard_recent_records")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)

        Spacer()

        if currentHighlight == .recentRecords {
          Image(systemName: "arrow.down.left")
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: "4A90E2"))
            .animation(
              .easeInOut(duration: 0.8).repeatForever(),
              value: currentHighlight
            )
        }
      }

      VStack(spacing: 8) {
        recentRecordItem(
          title: String(localized: "onboarding_recent_record_1_title"),
          date: getRelativeDateString(for: 0),
          duration: TimeInterval(2.5 * 3600).formattedStudyDuration
        )
        recentRecordItem(
          title: String(localized: "onboarding_recent_record_2_title"),
          date: getRelativeDateString(for: 1),
          duration: TimeInterval(1.75 * 3600).formattedStudyDuration
        )
        recentRecordItem(
          title: String(localized: "onboarding_recent_record_3_title"),
          date: getRelativeDateString(for: 2),
          duration: TimeInterval(3.25 * 3600).formattedStudyDuration
        )
      }
    }
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(
          currentHighlight == .recentRecords
            ? Color(hex: "4A90E2").opacity(0.05)
            : Color.gray.opacity(0.05)
        )
    }
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .stroke(
          currentHighlight == .recentRecords
            ? Color(hex: "4A90E2").opacity(0.3)
            : Color.clear,
          lineWidth: 2
        )
    }
    .id("records")
  }

  private func getRelativeDateString(for daysAgo: Int) -> String {
    let now = Date.now
    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now) ?? now
    return Self.relativeDatetimeFormatter.localizedString(for: date, relativeTo: now)
  }

  private func recentRecordItem(
    title: String,
    date: String,
    duration: String
  ) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.primary)

        Text(date)
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text(duration)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
  }

  private var demoInstructions: some View {
    VStack(spacing: 12) {
      HStack {
        Image(systemName: "chart.line.uptrend.xyaxis")
          .foregroundStyle(Color(hex: "27AE60"))

        Text("onboarding_dashboard_tips_title")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.primary)

        Spacer()
      }

      VStack(alignment: .leading, spacing: 8) {
        instructionRow(icon: "chart.bar", text: String(localized: "onboarding_dashboard_tip1"))
        instructionRow(icon: "calendar", text: String(localized: "onboarding_dashboard_tip2"))
        instructionRow(icon: "clock.arrow.circlepath", text: String(localized: "onboarding_dashboard_tip3"))
      }
    }
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(hex: "27AE60").opacity(0.05))
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

  private func startTour() {
    Task {
      try await Task.sleep(for: .seconds(0.5))
      isAnimating = true
    }
  }
}

private enum DashboardSection {
  case none
  case totalRecords
  case weeklyCount
  case streak
  case totalTime
  case weeklyChart
  case recentRecords
}

#Preview {
  DashboardDemoView()
    .background(Color.gray.opacity(0.1))
}
