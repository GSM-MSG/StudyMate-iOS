//
//  StudyRecordEditView.swift
//  StudyMate
//
//  Created by 최형우 on 6/2/25.
//

import SwiftUI
import PhotosUI
import VisionKit
import UniformTypeIdentifiers

struct StudyRecordEditView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: StudyRecordEditViewModel
  @State private var showingImagePicker = false
  @State private var showingCameraPicker = false
  @State private var showingDocumentPicker = false
  @State private var showingActionSheet = false
  @State private var showingScannerSheet = false
  @State private var selectedPhoto: PhotosPickerItem?
  @FocusState private var isContentFieldFocused: Bool
  
  let onSave: (StudyRecordModel) -> Void
  
  init(record: StudyRecordModel, onSave: @escaping (StudyRecordModel) -> Void) {
    self._viewModel = State(initialValue: StudyRecordEditViewModel(record: record))
    self.onSave = onSave
  }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ScrollView {
          LazyVStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
              Text(String(localized: "title"))
                .font(.headline)
                .fontWeight(.semibold)
              
              TextField(String(localized: "title_placeholder"), text: $viewModel.title)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .padding()
                .background {
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemGray6))
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
              Text(String(localized: "study_content"))
                .font(.headline)
                .fontWeight(.semibold)
              
              ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.content)
                  .focused($isContentFieldFocused)
                  .font(.body)
                  .scrollContentBackground(.hidden)
                  .background(
                    RoundedRectangle(cornerRadius: 8)
                      .fill(Color(UIColor.systemGray6))
                  )
                  .frame(minHeight: 200)
                
                if viewModel.content.isEmpty {
                  Text(String(localized: "content_placeholder"))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
                }
              }
            }
            
            VStack(alignment: .leading, spacing: 12) {
              Text(String(localized: "study_duration"))
                .font(.headline)
                .fontWeight(.semibold)
              
              VStack(spacing: 8) {
                Text(viewModel.formattedDuration)
                  .font(.title3)
                  .fontWeight(.medium)
                  .foregroundColor(.primary)
                
                TimePicker(duration: $viewModel.studyDuration)
              }
              .padding()
              .background {
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color(UIColor.systemGray6))
              }
            }
            
            if !viewModel.attachments.isEmpty {
              VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "attachments"))
                  .font(.headline)
                  .fontWeight(.semibold)
                
                LazyVGrid(columns: [
                  GridItem(.flexible()),
                  GridItem(.flexible())
                ], spacing: 12) {
                  ForEach(viewModel.attachments) { attachment in
                    AttachmentRowView(
                      attachment: attachment,
                      onRemove: {
                        viewModel.removeAttachment(attachment)
                      }
                    )
                  }
                }
              }
            }
            
            VStack(alignment: .leading, spacing: 12) {
              Text(String(localized: "add_attachments"))
                .font(.headline)
                .fontWeight(.semibold)
              
              HStack(spacing: 12) {
                Button {
                  showingActionSheet = true
                } label: {
                  HStack {
                    Image(systemName: "camera")
                    Text(String(localized: "photo"))
                      .minimumScaleFactor(0.8)
                  }
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background(Color.blue.opacity(0.1))
                  .foregroundColor(.blue)
                  .cornerRadius(8)
                }
                .confirmationDialog(String(localized: "photo_selection"), isPresented: $showingActionSheet) {
                  Button(String(localized: "camera")) {
                    showingCameraPicker = true
                  }
                  Button(String(localized: "photo_library")) {
                    showingImagePicker = true
                  }
                }
                
                Button {
                  showingDocumentPicker = true
                } label: {
                  HStack {
                    Image(systemName: "doc")
                    Text("PDF")
                      .minimumScaleFactor(0.8)
                  }
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background(Color.green.opacity(0.1))
                  .foregroundColor(.green)
                  .cornerRadius(8)
                }
              }
            }
            
            Spacer(minLength: 100)
          }
          .padding(20)
        }
        
        VStack(spacing: 16) {
          saveButton()
        }
        .background(.ultraThinMaterial)
      }
      .navigationTitle(String(localized: "edit_study_record_title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(String(localized: "cancel")) {
            dismiss()
          }
        }

        ToolbarItemGroup(placement: .keyboard) {
          Button {
            showingScannerSheet = true
          } label: {
            Image(systemName: "doc.text.viewfinder")
          }

          Spacer()
        }
      }
      .sheet(isPresented: $showingImagePicker) {
        PhotosPicker("", selection: $selectedPhoto, matching: .images)
      }
      .sheet(isPresented: $showingCameraPicker) {
        CameraView { image in
          let attachment = AttachmentItem(
            type: .image,
            image: image,
            name: "Camera_\(Date().formatted(.dateTime.hour().minute().second()))"
          )
          viewModel.addAttachment(attachment)
        }
      }
      .sheet(isPresented: $showingDocumentPicker) {
        DocumentPicker { urls in
          for url in urls {
            let attachment = AttachmentItem(
              type: .pdf,
              url: url,
              name: url.lastPathComponent
            )
            viewModel.addAttachment(attachment)
          }
        }
      }
      .fullScreenCover(isPresented: $showingScannerSheet) {
        DocumentScannerView(
          onTextRecognized: { text in
            viewModel.appendTextFromScanner(text)
          },
          dismiss: {
            showingScannerSheet = false
          }
        )
      }
      .onChange(of: selectedPhoto) { _, newPhoto in
        if let newPhoto = newPhoto {
          Task {
            if let data = try? await newPhoto.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
              let attachment = AttachmentItem(
                type: .image,
                image: image,
                name: "Photo_\(Date().formatted(.dateTime.hour().minute().second()))"
              )
              await MainActor.run {
                viewModel.addAttachment(attachment)
              }
            }
          }
        }
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
    }
  }
  
  @ViewBuilder
  private func saveButton() -> some View {
    Button {
      Task {
        if let updatedRecord = await viewModel.updateStudyRecord() {
          onSave(updatedRecord)
          dismiss()
        }
      }
    } label: {
      Group {
        if viewModel.isLoading {
          ProgressView()
            .tint(.white)
        } else {
          Text(String(localized: "save"))
            .fontWeight(.semibold)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .background(
        viewModel.isValidInput ? Color.accentColor : Color.gray
      )
      .foregroundColor(.white)
      .cornerRadius(12)
      .disabled(!viewModel.isValidInput || viewModel.isLoading)
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 20)
    .animation(.easeInOut(duration: 0.2), value: viewModel.isValidInput)
  }
}

#Preview {
  StudyRecordEditView(record: StudyRecordModel(
    id: "sample",
    title: "Swift Basic Syntax Summary",
   content: "Summarized the differences between variables and constants. `var` is a variable, `let` is a constant...",
    createdTime: Date(),
    updatedTime: Date(),
    attachments: [],
    feedbacks: []
  )) { _ in }
} 
