import Foundation
import Observation

// MARK: - YearMonth & YearMonthSection

struct YearMonth: Hashable {
  let year: Int
  let month: Int
}

struct YearMonthSection: Identifiable, Hashable {
  let id = UUID()
  let year: Int
  let month: Int
  let records: [StudyRecordModel]
  
  var displayName: String {
    let date = Calendar.current.date(from: DateComponents(calendar: .current, year: year, month: month)) ?? .now
    return date.formatted(.dateTime.month().year())
  }
  
  var yearMonth: String {
    String(format: "%04d-%02d", year, month)
  }
}

@Observable
@MainActor
final class StudyRecordListViewModel {
  
  // MARK: - Published Properties
  
  private(set) var studyRecords: [StudyRecordModel] = []
  private(set) var filteredRecords: [StudyRecordModel] = []
  private(set) var yearMonthSections: [YearMonthSection] = []
  private(set) var isLoading = false
  private(set) var errorMessage: String?
  
  var collapsedSections: Set<String> = []
  
  var searchText = "" {
    didSet {
      filterRecords()
    }
  }
  
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
    self.observationTask?.cancel()
  }
  
  // MARK: - Public Methods
  
  func loadStudyRecords() async {
    guard !isLoading else { return }
    
    isLoading = true
    errorMessage = nil
    
    do {
      let records = try await studyRecordInteractor.fetchStudyRecords()
      studyRecords = records
      filterRecords()
    } catch {
      errorMessage = error.localizedDescription
    }
    
    isLoading = false
  }
  
  func refreshStudyRecords() async {
    await loadStudyRecords()
  }
  
  func addStudyRecord(_ record: StudyRecordModel) {
    studyRecords.insert(record, at: 0)
    filterRecords()
  }
  
  func deleteStudyRecord(_ record: StudyRecordModel) async {
    do {
      try await studyRecordInteractor.deleteStudyRecord(id: record.id)
      studyRecords.removeAll { $0.id == record.id }
      filterRecords()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
  
  func clearError() {
    errorMessage = nil
  }
  
  func toggleSection(_ sectionId: String) {
    if collapsedSections.contains(sectionId) {
      collapsedSections.remove(sectionId)
    } else {
      collapsedSections.insert(sectionId)
    }
  }
  
  func isSectionCollapsed(_ sectionId: String) -> Bool {
    collapsedSections.contains(sectionId)
  }
  
  // MARK: - Private Methods
  
  private func filterRecords() {
    let recordsToGroup: [StudyRecordModel]
    
    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      recordsToGroup = studyRecords
    } else {
      recordsToGroup = studyRecords.filter { record in
        record.title.localizedCaseInsensitiveContains(searchText) ||
        record.content.localizedCaseInsensitiveContains(searchText)
      }
    }
    
    filteredRecords = recordsToGroup
    yearMonthSections = groupRecordsByYearMonth(recordsToGroup)
    updateCollapsedSectionsForCurrentMonth()
  }
  
  private func groupRecordsByYearMonth(_ records: [StudyRecordModel]) -> [YearMonthSection] {
    let calendar = Calendar.current
    let grouped = Dictionary(grouping: records) { record in
      let components = calendar.dateComponents([.year, .month], from: record.createdTime)
      return YearMonth(year: components.year ?? 0, month: components.month ?? 0)
    }
    
    return grouped.map { (yearMonth, records) in
      YearMonthSection(
        year: yearMonth.year,
        month: yearMonth.month,
        records: records.sorted { $0.createdTime > $1.createdTime }
      )
    }.sorted { section1, section2 in
      if section1.year != section2.year {
        return section1.year > section2.year
      }
      return section1.month > section2.month
    }
  }
  
  private func updateCollapsedSectionsForCurrentMonth() {
    let calendar = Calendar.current
    let now = Date()
    let currentComponents = calendar.dateComponents([.year, .month], from: now)
    let currentYearMonth = String(format: "%04d-%02d", currentComponents.year ?? 0, currentComponents.month ?? 0)
    
    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      for section in yearMonthSections {
        if section.yearMonth != currentYearMonth {
          collapsedSections.insert(section.yearMonth)
        }
      }
    } else {
      collapsedSections.removeAll()
    }
  }
  
  private func setupDataObservation() {
    observationTask = Task { [weak self] in
      guard let self = self else { return }
      
      for await _ in self.studyRecordInteractor.observeStudyRecords() {
        await self.loadStudyRecords()
      }
    }
  }
} 
