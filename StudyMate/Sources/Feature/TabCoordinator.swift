import SwiftUI

enum StudyMateTab: Int, CaseIterable {
  case dashboard = 0
  case studyRecordList = 1
  case settings = 2
  
  var title: String {
    switch self {
    case .dashboard:
      return String(localized: "dashboard")
    case .studyRecordList:
      return String(localized: "study_record_list_title")
    case .settings:
      return String(localized: "settings")
    }
  }
  
  var systemImage: String {
    switch self {
    case .dashboard:
      return "chart.line.uptrend.xyaxis"
    case .studyRecordList:
      return "book.fill"
    case .settings:
      return "gearshape.fill"
    }
  }
}

@Observable
@MainActor
final class TabCoordinator {
  var selectedTab: StudyMateTab = .studyRecordList
  
  func selectTab(_ tab: StudyMateTab) {
    selectedTab = tab
  }
  
  func selectStudyRecordList() {
    selectedTab = .studyRecordList
  }
  
  func selectDashboard() {
    selectedTab = .dashboard
  }
  
  func selectSettings() {
    selectedTab = .settings
  }
} 
