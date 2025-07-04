//
//  ContentView.swift
//  StudyMate
//
//  Created by 최형우 on 6/2/25.
//

import SwiftUI

struct ContentView: View {
  @State private var tabCoordinator = TabCoordinator()
  
  var body: some View {
    TabView(selection: $tabCoordinator.selectedTab) {
      Tab(value: StudyMateTab.dashboard) {
        DashboardView()
      } label: {
        Label(StudyMateTab.dashboard.title, systemImage: StudyMateTab.dashboard.systemImage)
      }
      
      Tab(value: StudyMateTab.studyRecordList) {
        StudyRecordListView()
      } label: {
        Label(StudyMateTab.studyRecordList.title, systemImage: StudyMateTab.studyRecordList.systemImage)
      }
      
      Tab(value: StudyMateTab.settings) {
        SettingsView()
      } label: {
        Label(StudyMateTab.settings.title, systemImage: StudyMateTab.settings.systemImage)
      }
    }
    .environment(tabCoordinator)
  }
}

#Preview {
  ContentView()
}
