//
//  StudyRecordDetailView.swift
//  StudyMate
//
//  Created by 최형우 on 6/2/25.
//

import AnalyticsClient
import SwiftUI

struct StudyRecordDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: StudyRecordDetailViewModel
  private let entry: DefaultAnalyticsEvent.ViewStudyRecordDetailEntry
  
  init(
    record: StudyRecordModel,
    entry: DefaultAnalyticsEvent.ViewStudyRecordDetailEntry,
    studyRecordInteractor: StudyRecordInteractor = LiveStudyRecordInteractor()
  ) {
    self.entry = entry
    self._viewModel = State(initialValue: StudyRecordDetailViewModel(record: record, studyRecordInteractor: studyRecordInteractor))
  }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        TabView {
          Tab {
            StudyContentTabView(record: viewModel.currentRecord)
              .onAppear {
                AnalyticsClient.shared.track(event: .openStudyRecordContent)
              }
          } label: {
            Label(String(localized: "study_content"), systemImage: "book.fill")
          }

          Tab {
            AITutorTabView(
              record: viewModel.currentRecord,
              isGeneratingContent: viewModel.isGeneratingAIContent,
              feedbacks: viewModel.feedbacks,
              errorMessage: viewModel.errorMessage,
              generateAIFeedback: {
                if viewModel.feedbacks.isEmpty {
                  AnalyticsClient.shared.track(event: .tapAiTutorAnalyze)
                } else {
                  AnalyticsClient.shared.track(event: .tapAiTutorReanalyze)
                }
                viewModel.generateAIFeedback()
              }
            )
            .onAppear {
              AnalyticsClient.shared.track(event: .openStudyRecordAiTutor)
            }
          } label: {
            Label(String(localized: "ai_tutor"), systemImage: "brain.head.profile")
          }
        }
      }
      .onAppear {
        AnalyticsClient.shared.track(event: .viewStudyRecordDetail(entry: entry))
      }
      .analyticsScreen(name: "study_record_detail", extraParameters: ["entry": entry.analyticsValue])
      .navigationTitle(viewModel.currentRecord.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            Button {
              viewModel.showingEditView = true
            } label: {
              Label(String(localized: "edit"), systemImage: "pencil")
            }
            
            Button(role: .destructive) {
              viewModel.showingDeleteAlert = true
            } label: {
              Label(String(localized: "delete"), systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
              .font(.body)
              .foregroundColor(.blue)
          }
        }
      }
      .sheet(isPresented: $viewModel.showingEditView) {
        StudyRecordEditView(record: viewModel.currentRecord) { updatedRecord in
          viewModel.updateRecord(updatedRecord)
        }
      }
      .alert(String(localized: "delete"), isPresented: $viewModel.showingDeleteAlert) {
        Button(String(localized: "cancel"), role: .cancel) { }
        Button(String(localized: "delete"), role: .destructive) {
          Task {
            if await viewModel.deleteRecord() {
              AnalyticsClient.shared.track(event: .deleteStudyRecord)
              dismiss()
            }
          }
        }
      } message: {
        Text(String(localized: "delete_confirmation_message"))
      }
      .alert(String(localized: "reanalyze"), isPresented: $viewModel.showingReanalyzeAlert) {
        Button(String(localized: "cancel"), role: .cancel) { }
        Button(String(localized: "reanalyze"), role: .destructive) {
          viewModel.performAIFeedbackGeneration()
        }
      } message: {
        Text(String(localized: "reanalyze_confirmation_message"))
      }
    }
  }

}

struct StudyContentTabView: View {
  let record: StudyRecordModel
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        StudyInfoCard(record: record)
        
        StudyContentCard(content: record.content)
        
        if record.hasAttachment {
          AttachmentsCard(attachments: record.attachments)
        }
        
        Spacer(minLength: 50)
      }
      .padding(20)
    }
  }
}

struct StudyInfoCard: View {
  let record: StudyRecordModel
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 8) {
        Image(systemName: "info.circle.fill")
          .font(.title3)
          .foregroundColor(.green)
        
        Text(String(localized: "study_info"))
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
      }
      
      VStack(spacing: 12) {
        HStack {
          HStack(spacing: 6) {
            Image(systemName: "clock.fill")
              .font(.caption)
              .foregroundColor(.orange)
            Text(String(localized: "study_duration"))
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          
          Spacer()
          
          Text(record.formattedDuration)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)
        }
        
        HStack {
          HStack(spacing: 6) {
            Image(systemName: "calendar")
              .font(.caption)
              .foregroundColor(.blue)
            Text(String(localized: "creation_date"))
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          
          Spacer()
          
          Text(record.createdTime.formatted(.dateTime.year().month().day().hour().minute()))
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color(.systemGray5), lineWidth: 1)
        )
    )
  }
}

struct StudyContentCard: View {
  let content: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 8) {
        Image(systemName: "book.fill")
          .font(.title3)
          .foregroundColor(.blue)
        
        Text(String(localized: "study_content"))
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
          .textSelection(.enabled)
      }
      
      Text(.init(content))
        .font(.body)
        .lineSpacing(6)
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color(.systemGray5), lineWidth: 1)
        )
    )
  }
}

struct AttachmentsCard: View {
  let attachments: [AttachmentModel]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 8) {
        Image(systemName: "paperclip")
          .font(.title3)
          .foregroundColor(.orange)
        
        Text(String(localized: "attachments"))
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
      }
      
      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
      ], spacing: 12) {
        ForEach(attachments) { attachment in
          AttachmentDisplayView(attachment: attachment)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color(.systemGray5), lineWidth: 1)
        )
    )
  }
}

struct AttachmentDisplayView: View {
  let attachment: AttachmentModel
  
  var body: some View {
    VStack(spacing: 8) {
      if attachment.type == .image {
        AsyncImage(url: URL(string: attachment.url)) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Image(systemName: "photo")
            .font(.title2)
            .foregroundColor(.gray)
        }
        .frame(width: 100, height: 100)
        .clipped()
        .cornerRadius(8)
      } else {
        Image(systemName: getFileIcon())
          .font(.title2)
          .foregroundColor(.blue)
          .frame(width: 100, height: 100)
          .background(Color.blue.opacity(0.1))
          .cornerRadius(8)
      }
      
      Text(URL(string: attachment.url)?.lastPathComponent ?? String(localized: "file"))
        .font(.caption)
        .lineLimit(1)
        .foregroundColor(.secondary)
    }
  }
  
  private func getFileIcon() -> String {
    guard let url = URL(string: attachment.url) else { return "doc" }
    
    let pathExtension = url.pathExtension.lowercased()
    switch pathExtension {
    case "pdf":
      return "doc.richtext"
    case "txt":
      return "doc.text"
    case "doc", "docx":
      return "doc"
    default:
      return "doc"
    }
  }
}

struct AITutorTabView: View {
  let record: StudyRecordModel
  let isGeneratingContent: Bool
  let feedbacks: [StudyFeedbackModel]
  let errorMessage: String?
  let generateAIFeedback: () -> Void
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "ai_tutor_feedback"))
              .font(.title2)
              .fontWeight(.bold)
            
            Text(String(localized: "ai_feedback_description"))
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          
          Spacer()
          
          if !isGeneratingContent {
            if feedbacks.isEmpty {
              Button(String(localized: "analyze"), action: generateAIFeedback)
                .buttonStyle(.borderedProminent)
                .fontWeight(.semibold)
            } else {
              Button(String(localized: "reanalyze"), action: generateAIFeedback)
                .buttonStyle(.bordered)
                .fontWeight(.semibold)
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        
        if isGeneratingContent {
          VStack(spacing: 16) {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .blue))
              .scaleEffect(1.2)
            
            Text(String(localized: "ai_analyzing"))
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 40)
          
        } else if let errorMessage = errorMessage {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
              .font(.system(size: 48))
              .foregroundColor(.orange)
            
            Text(String(localized: "analysis_error"))
              .font(.headline)
              .fontWeight(.semibold)
            
            Text(errorMessage)
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
            
            Button(String(localized: "retry"), action: generateAIFeedback)
              .buttonStyle(.borderedProminent)
              .fontWeight(.semibold)
              .padding(.top, 8)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 60)
          
        } else if !feedbacks.isEmpty {
          LazyVStack(spacing: 16) {
            ForEach(feedbacks) { feedback in
              AIFeedbackCard(
                title: feedback.title,
                icon: feedback.icon,
                content: feedback.content,
                color: Color(hex: feedback.primaryColor)
              )
              .frame(maxWidth: .infinity)
            }
          }
          .padding(.horizontal, 20)
          .frame(maxWidth: .infinity)
          
        } else {
          VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
              .font(.system(size: 48))
              .foregroundColor(.gray)
            
            Text(String(localized: "start_ai_analysis"))
              .font(.headline)
              .fontWeight(.semibold)
            
            Text(String(localized: "ai_analysis_description"))
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
            
            Button(String(localized: "analyze_now"), action: generateAIFeedback)
              .buttonStyle(.borderedProminent)
              .fontWeight(.semibold)
              .padding(.top, 8)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 60)
        }
        
        Spacer(minLength: 50)
      }
    }
  }

}

struct StudyFeedbackModel: Identifiable, Hashable {
  let id: String
  let title: String
  let content: String
  let icon: String
  let primaryColor: String
  let createdTime: Date
  let updatedTime: Date
}

struct AIFeedbackCard: View {
  let title: String
  let icon: String
  let content: String
  let color: Color
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Image(systemName: icon)
          .font(.title3)
          .foregroundColor(color)
        
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
      }
      
      Text(content)
        .font(.body)
        .lineSpacing(4)
        .foregroundColor(.primary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(0.05))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(color.opacity(0.2), lineWidth: 1)
        )
    )
  }
}

#Preview {
  NavigationStack {
    StudyRecordDetailView(
      record: StudyRecordModel(
        id: "sample",
        title: "Swift Basic Syntax Summary",
        content: "Summarized the differences between variables and constants. `var` is a variable, `let` is a constant...",
        createdTime: Date(),
        updatedTime: Date(),
        studyDuration: 1800, // 30분
        attachments: [],
        feedbacks: []
      ),
      entry: .studyRecordList
    )
  }
}
