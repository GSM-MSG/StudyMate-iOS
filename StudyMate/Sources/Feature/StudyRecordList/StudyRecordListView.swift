//
//  StudyRecordListView.swift
//  StudyMate
//
//  Created by 최형우 on 6/2/25.
//

import AnalyticsClient
import SwiftUI

struct StudyRecordListView: View {
  @State private var viewModel = StudyRecordListViewModel()
  @State private var isShowingAddView = false

  @State private var selectedRecord: StudyRecordModel?
  @Namespace private var zoomNamespace
  @Namespace private var addNamespace

  var body: some View {
    NavigationStack {
      ZStack {
        VStack(spacing: 0) {
          if viewModel.isLoading && viewModel.yearMonthSections.isEmpty {
            ProgressView(String(localized: "loading"))
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else {
            List {
              ForEach(viewModel.yearMonthSections, id: \.id) { section in
                Section {
                  if !viewModel.isSectionCollapsed(section.yearMonth) {
                    ForEach(section.records) { record in
                      Button {
                        selectedRecord = record
                      } label: {
                        StudyRecordRow(record: record, namespace: zoomNamespace)
                      }
                      .buttonStyle(PlainButtonStyle())
                      .listRowInsets(
                        EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
                      )
                      .listRowSeparator(.hidden)
                      .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                          Task {
                            await viewModel.deleteStudyRecord(record)
                          }
                        } label: {
                          Label(String(localized: "delete"), systemImage: "trash")
                        }
                      }
                    }
                  }
                } header: {
                  Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                      viewModel.toggleSection(section.yearMonth)
                    }
                  } label: {
                    HStack(spacing: 12) {
                      Text(section.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                      
                      Text("(\(section.records.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                      
                      Spacer()
                      
                      Image(systemName: viewModel.isSectionCollapsed(section.yearMonth) ? "chevron.right" : "chevron.down")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                        .rotationEffect(.degrees(viewModel.isSectionCollapsed(section.yearMonth) ? 0 : 0))
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isSectionCollapsed(section.yearMonth))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                  }
                  .buttonStyle(PlainButtonStyle())
                }
              }
            }
            .listStyle(.plain)
            .refreshable {
              await viewModel.refreshStudyRecords()
            }
          }
        }
        .navigationTitle(String(localized: "study_record_list_title"))
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: String(localized: "study_record_search_prompt"))
        .task {
          await viewModel.loadStudyRecords()
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
        
        VStack {
          Spacer()

          HStack {
            Spacer()

            Button {
              AnalyticsClient.shared.track(event: .tapAddStudyRecord)
              isShowingAddView = true
            } label: {
              if #available(iOS 26.0, *) {
                Image(systemName: "plus")
                  .font(.title2)
                  .fontWeight(.semibold)
                  .foregroundColor(.white)
                  .frame(width: 56, height: 56)
                  .matchedTransitionSource(id: "add-record", in: addNamespace)
                  .background {
                    Circle()
                      .fill(Color.primary)
                      .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                  }
//                  .glassEffect(.regular.tint(Color.accentColor).interactive(), in: Circle())
              } else if #available(iOS 18.0, *) {
                Image(systemName: "plus")
                  .font(.title2)
                  .fontWeight(.semibold)
                  .foregroundStyle(.white)
                  .frame(width: 56, height: 56)
                  .matchedTransitionSource(id: "add-record", in: addNamespace)
                  .background {
                    Circle()
                      .fill(Color.primary)
                      .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                  }
              } else {
                Image(systemName: "plus")
                  .font(.title2)
                  .fontWeight(.semibold)
                  .foregroundStyle(.white)
                  .frame(width: 56, height: 56)
                  .background {
                    Circle()
                      .fill(Color.primary)
                      .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                  }
              }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 34)
          }
        }
      }
      .navigationDestination(isPresented: $isShowingAddView) {
        StudyRecordAddView { newRecord in
          viewModel.addStudyRecord(newRecord)
        }
        .navigationTransition(ZoomNavigationTransition.zoom(sourceID: "add-record", in: addNamespace))
        .toolbarVisibility(.hidden, for: .tabBar)
      }
      .navigationDestination(item: $selectedRecord) { record in
        StudyRecordDetailView(
          record: record,
          entry: .studyRecordList
        )
        .navigationTransition(.zoom(sourceID: "record-\(record.id)", in: zoomNamespace))
        .toolbarVisibility(.hidden, for: .tabBar)
      }
      .onAppear {
        AnalyticsClient.shared.track(event: .viewStudyRecords)
      }
      .analyticsScreen(name: "study_records")
    }
  }
}

private struct StudyRecordRow: View {
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
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
    )
  }

  @ViewBuilder
  private var contentView: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 6) {
          Text(record.title)
            .font(.headline)
            .fontWeight(.semibold)
            .lineLimit(2)
            .foregroundColor(.primary)
          
          Text(record.content)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          Text(record.formattedDate)
            .font(.caption)
            .fontWeight(.medium)
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
    }
  }
}

#Preview {
  StudyRecordListView()
}
