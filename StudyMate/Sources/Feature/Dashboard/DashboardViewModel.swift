import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {
  
  private(set) var totalStudyRecords = 0
  private(set) var weeklyStudyCount = 0
  private(set) var currentStreak = 0
  private(set) var monthlyStudyTime: Int = 0
  
  var formattedMonthlyStudyTime: String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .dropAll
    
    let timeInterval = TimeInterval(monthlyStudyTime * 60)
    
    if timeInterval < 60 {
      return String(localized: "less_than_minute")
    }
    
    return formatter.string(from: timeInterval) ?? String(localized: "unknown_duration")
  }
  
  var formattedCurrentStreak: String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day]
    formatter.unitsStyle = .full
    
    let dateComponents = DateComponents(calendar: .current, day: currentStreak)
    
    if currentStreak == 0 {
      return String(format: String(localized: "day_count"), 0)
    }
    
    return formatter.string(from: dateComponents) ?? String(format: String(localized: "day_count"), currentStreak)
  }
  private(set) var recentStudyRecords: [StudyRecordModel] = []
  private(set) var weeklyStats: [WeeklyStatModel] = []
  private(set) var monthlyFeedbackStats: FeedbackStatsModel = FeedbackStatsModel()
  private(set) var isLoading = false
  private(set) var errorMessage: String?
  
  // MARK: - Dependencies
  
  @ObservationIgnored
  private let studyRecordInteractor: StudyRecordInteractor
  @ObservationIgnored
  private nonisolated(unsafe) var observationTask: Task<Void, Never>?
  
  // MARK: - Initialization
  
  init(studyRecordInteractor: StudyRecordInteractor = LiveStudyRecordInteractor()) {
    self.studyRecordInteractor = studyRecordInteractor
    setupDataObservation()
  }
  
  deinit {
    observationTask?.cancel()
  }
  
  // MARK: - Public Methods
  
  func loadDashboardData() async {
    isLoading = true
    errorMessage = nil
    
    do {
      let allRecords = try await studyRecordInteractor.fetchStudyRecords()
      
      await calculateStatistics(from: allRecords)
      await calculateWeeklyStats(from: allRecords)
      await calculateFeedbackStats(from: allRecords)
      
      recentStudyRecords = Array(allRecords.prefix(5))
      
    } catch {
      errorMessage = error.localizedDescription
    }
    
    isLoading = false
  }
  
  func refreshData() async {
    await loadDashboardData()
  }
  
  func clearError() {
    errorMessage = nil
  }
  
  // MARK: - Private Methods
  
  private func calculateStatistics(from records: [StudyRecordModel]) async {
    totalStudyRecords = records.count
    
    let calendar = Calendar.current
    let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    weeklyStudyCount = records.filter { $0.createdTime >= startOfWeek }.count
    
    currentStreak = calculateStudyStreak(from: records)
    
    let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
    let monthlyRecords = records.filter { $0.createdTime >= startOfMonth }
    monthlyStudyTime = Int(monthlyRecords.reduce(0) { $0 + $1.studyDuration } / 60)
  }
  
  private func calculateStudyStreak(from records: [StudyRecordModel]) -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    var streak = 0
    var currentDate = today
    
    let recordsByDate = Dictionary(grouping: records) { record in
      calendar.startOfDay(for: record.createdTime)
    }
    
    while let recordsForDate = recordsByDate[currentDate], !recordsForDate.isEmpty {
      streak += 1
      currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
    }
    
    return streak
  }
  
  private func calculateWeeklyStats(from records: [StudyRecordModel]) async {
    let calendar = Calendar.current
    let today = Date()
    
    var weeklyData: [WeeklyStatModel] = []
    
    for weekOffset in (0..<7).reversed() {
      guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else {
        continue
      }
      
      let weekRecords = records.filter { record in
        weekInterval.contains(record.createdTime)
      }
      
      let weekModel = WeeklyStatModel(
        weekStart: weekInterval.start,
        recordCount: weekRecords.count,
        feedbackCount: weekRecords.reduce(0) { $0 + $1.feedbacks.count }
      )
      
      weeklyData.append(weekModel)
    }
    
    weeklyStats = weeklyData
  }
  
  private func calculateFeedbackStats(from records: [StudyRecordModel]) async {
    let allFeedbacks = records.flatMap { $0.feedbacks }
    
    let totalFeedbacks = allFeedbacks.count
    let recordsWithFeedback = records.filter { !$0.feedbacks.isEmpty }.count
    let averageFeedbackPerRecord = totalFeedbacks > 0 ? Double(totalFeedbacks) / Double(records.count) : 0.0
    
    let calendar = Calendar.current
    let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
    let monthlyRecordsWithFeedback = records.filter { record in
      record.createdTime >= startOfMonth && !record.feedbacks.isEmpty
    }
    
    monthlyFeedbackStats = FeedbackStatsModel(
      totalFeedbacks: totalFeedbacks,
      recordsWithFeedback: recordsWithFeedback,
      averageFeedbackPerRecord: averageFeedbackPerRecord,
      monthlyFeedbackCount: monthlyRecordsWithFeedback.reduce(0) { $0 + $1.feedbacks.count }
    )
  }
  
  private func setupDataObservation() {
    observationTask = Task { [weak self] in
      guard let self = self else { return }
      
      for await _ in self.studyRecordInteractor.observeStudyRecords() {
        await self.loadDashboardData()
      }
    }
  }
}

// MARK: - Supporting Models

struct WeeklyStatModel: Identifiable {
  let id = UUID()
  let weekStart: Date
  let recordCount: Int
  let feedbackCount: Int
  
  var weekDisplayName: String {
    return weekStart.formatted(
      .verbatim(
        "\(month: .defaultDigits)/\(day: .defaultDigits)",
        timeZone: .current,
        calendar: .current
      )
    )
  }
}

struct FeedbackStatsModel {
  let totalFeedbacks: Int
  let recordsWithFeedback: Int
  let averageFeedbackPerRecord: Double
  let monthlyFeedbackCount: Int
  
  init(totalFeedbacks: Int = 0, recordsWithFeedback: Int = 0, averageFeedbackPerRecord: Double = 0.0, monthlyFeedbackCount: Int = 0) {
    self.totalFeedbacks = totalFeedbacks
    self.recordsWithFeedback = recordsWithFeedback
    self.averageFeedbackPerRecord = averageFeedbackPerRecord
    self.monthlyFeedbackCount = monthlyFeedbackCount
  }
} 
