import AnalyticsClient
import Charts
import SwiftUI

struct DashboardView: View {
  @State private var viewModel = DashboardViewModel()
  @State private var selectedRecord: StudyRecordModel?
  @Namespace private var zoomNamespace
  @Environment(TabCoordinator.self) private var tabCoordinator
  
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 24) {
          WelcomeSection()
          
          StatisticsCardsSection(viewModel: viewModel)
          
          WeeklyProgressSection(weeklyStats: viewModel.weeklyStats)
          
          AIFeedbackStatsSection(feedbackStats: viewModel.monthlyFeedbackStats)
          
          RecentStudyRecordsSection(
            records: viewModel.recentStudyRecords,
            namespace: zoomNamespace,
            onRecordTap: { record in
              selectedRecord = record
            }
          )
          
          Spacer(minLength: 100)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
      }
      .navigationTitle(String(localized: "dashboard"))
      .navigationBarTitleDisplayMode(.large)
      .refreshable {
        await viewModel.refreshData()
      }
      .task {
        await viewModel.loadDashboardData()
      }
      .alert(String(localized: "error"), isPresented: .constant(viewModel.errorMessage != nil)) {
        Button(String(localized: "confirm")) {
          viewModel.clearError()
        }
      } message: {
        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
        }
      }
      .navigationDestination(item: $selectedRecord) { record in
        StudyRecordDetailView(
          record: record,
          entry: .dashboard
        )
        .navigationTransition(.zoom(sourceID: "record-\(record.id)", in: zoomNamespace))
        .toolbarVisibility(.hidden, for: .tabBar)
      }
      .onAppear {
        AnalyticsClient.shared.track(event: .viewDashboard)
      }
      .analyticsScreen(name: "dashboard")
    }
  }
}

// MARK: - Welcome Section

private struct WelcomeSection: View {
  private var currentHour: Int {
    Calendar.current.component(.hour, from: Date())
  }
  
  private var greetingMessage: String {
    switch currentHour {
    case 5..<12:
      return String(localized: "good_morning")
    case 12..<17:
      return String(localized: "good_afternoon")
    case 17..<21:
      return String(localized: "good_evening")
    default:
      return String(localized: "keep_up_good_work")
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(greetingMessage)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.primary)
      
      Text(String(localized: "learn_something_new_today"))
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 16)
  }
}

// MARK: - Statistics Cards Section

private struct StatisticsCardsSection: View {
  let viewModel: DashboardViewModel
  
  var body: some View {
    VStack(spacing: 16) {
      HStack(spacing: 16) {
        StatCard(
          title: String(localized: "total_study_records"),
          value: "\(viewModel.totalStudyRecords)",
          icon: "book.fill",
          color: .blue
        )
        
        StatCard(
          title: String(localized: "this_week"),
          value: "\(viewModel.weeklyStudyCount)",
          icon: "calendar.badge.plus",
          color: .green
        )
      }
      
      HStack(spacing: 16) {
        StatCard(
          title: String(localized: "study_streak"),
          value: viewModel.formattedCurrentStreak,
          icon: "flame.fill",
          color: .orange
        )
        
        StatCard(
          title: String(localized: "monthly_study_time"),
          value: viewModel.formattedMonthlyStudyTime,
          icon: "clock.fill",
          color: .purple
        )
      }
    }
  }
}

private struct StatCard: View {
  let title: String
  let value: String
  let icon: String
  let color: Color
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: icon)
          .font(.title3)
          .foregroundColor(color)
        
        Spacer()
      }
      
      VStack(alignment: .leading, spacing: 4) {
        Text(value)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
        
        Text(title)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
  }
}

// MARK: - Weekly Progress Section

private struct WeeklyProgressSection: View {
  let weeklyStats: [WeeklyStatModel]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(String(localized: "weekly_progress"))
        .font(.headline)
        .fontWeight(.semibold)
      
      if !weeklyStats.isEmpty {
        Chart(weeklyStats) { stat in
          BarMark(
            x: .value(String(localized: "week_axis_label"), stat.weekDisplayName),
            y: .value(String(localized: "study_count_axis_label"), stat.recordCount)
          )
          .foregroundStyle(Color.blue.gradient)
          .cornerRadius(4)
        }
        .frame(height: 180)
        .chartYAxis {
          AxisMarks(position: .leading)
        }
        .chartXAxis {
          AxisMarks(position: .bottom) { _ in
            AxisGridLine()
            AxisTick()
            AxisValueLabel()
          }
        }
      } else {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.gray.opacity(0.1))
          .frame(height: 180)
          .overlay(
            Text(String(localized: "no_data_available"))
              .foregroundColor(.secondary)
          )
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
  }
}

// MARK: - AI Feedback Stats Section

private struct AIFeedbackStatsSection: View {
  let feedbackStats: FeedbackStatsModel
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "brain.head.profile")
          .font(.title3)
          .foregroundColor(.pink)
        
        Text(String(localized: "ai_feedback_status"))
          .font(.headline)
          .fontWeight(.semibold)
      }
      
      VStack(spacing: 12) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "total_feedback"))
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text("\(feedbackStats.totalFeedbacks)")
              .font(.title3)
              .fontWeight(.semibold)
          }
          
          Spacer()
          
          VStack(alignment: .trailing, spacing: 4) {
            Text(String(localized: "this_month"))
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text("\(feedbackStats.monthlyFeedbackCount)")
              .font(.title3)
              .fontWeight(.semibold)
          }
        }
        
        Divider()
        
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "feedback_adoption_rate"))
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text(String(format: String(localized: "records_with_feedback"), feedbackStats.recordsWithFeedback))
              .font(.caption)
              .foregroundColor(.secondary)
          }
          
          Spacer()
          
          VStack(alignment: .trailing, spacing: 4) {
            Text(String(localized: "average_feedback"))
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text(String(format: String(localized: "average_feedback_per_record"), feedbackStats.averageFeedbackPerRecord))
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
  }
}

// MARK: - Recent Study Records Section

private struct RecentStudyRecordsSection: View {
  let records: [StudyRecordModel]
  let namespace: Namespace.ID
  let onRecordTap: (StudyRecordModel) -> Void
  @Environment(TabCoordinator.self) private var tabCoordinator
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(String(localized: "recent_study_records"))
          .font(.headline)
          .fontWeight(.semibold)
        
        Spacer()
        
        if !records.isEmpty {
          Button(String(localized: "view_all")) {
            AnalyticsClient.shared.track(event: .tapViewAllStudyRecords)
            tabCoordinator.selectStudyRecordList()
          }
          .font(.subheadline)
          .foregroundColor(.blue)
        }
      }
      
      if records.isEmpty {
        VStack(spacing: 16) {
          Image(systemName: "book.closed")
            .font(.system(size: 48))
            .foregroundColor(.gray)
          
          Text(String(localized: "no_study_records_yet"))
            .font(.headline)
            .fontWeight(.semibold)
          
          Text(String(localized: "record_first_study"))
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
      } else {
        LazyVStack(spacing: 12) {
          ForEach(records) { record in
            Button {
              onRecordTap(record)
            } label: {
              RecentRecordRow(record: record, namespace: namespace)
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
  }
}

private struct RecentRecordRow: View {
  let record: StudyRecordModel
  let namespace: Namespace.ID
  
  var body: some View {
    Group {
      if #available(iOS 18.0, *) {
        contentView
          .matchedTransitionSource(id: "record-\(record.id)", in: namespace)
      } else {
        contentView
      }
    }
  }
  
  @ViewBuilder
  private var contentView: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text(record.title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .lineLimit(1)
          .foregroundColor(.primary)
        
        Text(record.content)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(2)
      }
      
      Spacer()
      
      VStack(alignment: .trailing, spacing: 4) {
        Text(record.formattedDate)
          .font(.caption2)
          .foregroundColor(.secondary)
        
        Text(record.formattedDuration)
          .font(.caption2)
          .foregroundColor(.orange)
        
        HStack(spacing: 4) {
          if record.hasAttachment {
            Image(systemName: "paperclip")
              .font(.caption2)
              .foregroundColor(.blue)
          }
          
          if record.hasFeedback {
            Image(systemName: "brain.head.profile")
              .font(.caption2)
              .foregroundColor(.pink)
          }
        }
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color(.systemGray5), lineWidth: 1)
        )
    )
  }
}

#Preview {
  DashboardView()
} 
