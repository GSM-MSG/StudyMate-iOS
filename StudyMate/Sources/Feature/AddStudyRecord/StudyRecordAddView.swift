//
//  StudyRecordAddView.swift
//  StudyMate
//
//  Created by 최형우 on 6/2/25.
//

import AnalyticsClient
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import VisionKit

struct StudyRecordAddView: View {
  private enum FocusField {
    case title
    case content
  }

  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = StudyRecordAddViewModel()
  @State private var showingImagePicker = false
  @State private var showingCameraPicker = false
  @State private var showingDocumentPicker = false
  @State private var showingAudioPicker = false
  @State private var showingActionSheet = false
  @State private var showingScannerSheet = false
  @State private var selectedPhoto: PhotosPickerItem?
  @FocusState private var focusedField: FocusField?

  @State private var onAppeared = false
  @State private var showAudioLimitAlert = false

  let onSave: (StudyRecordModel) -> Void

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        LazyVStack(spacing: 24) {
          VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "title"))
              .font(.headline)
              .fontWeight(.semibold)

            TextField(
              String(localized: "title_placeholder"), text: $viewModel.title
            )
            .focused($focusedField, equals: .title)
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
                .focused($focusedField, equals: .content)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background {
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemGray6))
                }
                .frame(minHeight: 200)

              if viewModel.content.isEmpty {
                Text(String(localized: "content_placeholder"))
                  .foregroundColor(.secondary)
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
                .foregroundStyle(.primary)

              TimePicker(duration: $viewModel.studyDuration)
            }
            .frame(maxWidth: .infinity)
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

              LazyVGrid(
                columns: [
                  GridItem(.flexible()),
                  GridItem(.flexible()),
                ], spacing: 12
              ) {
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
            ViewThatFits(in: .horizontal) {
              // Horizontal layout
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
                .confirmationDialog(
                  String(localized: "photo_selection"),
                  isPresented: $showingActionSheet
                ) {
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

                Button {
                  if viewModel.attachments.contains(where: { $0.type == .audio }) {
                    showAudioLimitAlert = true
                  } else {
                    showingAudioPicker = true
                  }
                } label: {
                  HStack {
                    Image(systemName: "waveform")

                    Text("Audio")
                      .minimumScaleFactor(0.8)
                  }
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background {
                    RoundedRectangle(cornerRadius: 8)
                      .fill(Color.purple.opacity(0.1))
                  }
                  .foregroundStyle(.purple)
                }
              }

              // Vertical fallback
              VStack(spacing: 12) {
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
                .confirmationDialog(
                  String(localized: "photo_selection"),
                  isPresented: $showingActionSheet
                ) {
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

                Button {
                  if viewModel.attachments.contains(where: { $0.type == .audio }) {
                    showAudioLimitAlert = true
                  } else {
                    showingAudioPicker = true
                  }
                } label: {
                  HStack {
                    Image(systemName: "waveform")

                    Text("Audio")
                      .minimumScaleFactor(0.8)
                  }
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background {
                    RoundedRectangle(cornerRadius: 8)
                      .fill(Color.purple.opacity(0.1))
                  }
                  .foregroundStyle(.purple)
                }
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
    .onAppear {
      guard onAppeared == false else { return }
      onAppeared = true
      focusedField = .title
      AnalyticsClient.shared.track(event: .viewAddStudyRecord)
    }
    .analyticsScreen(name: "add_study_record")
    .navigationTitle(String(localized: "add_study_record_title"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .keyboard) {
        Button {
          showingScannerSheet = true
        } label: {
          Image(systemName: "doc.text.viewfinder")
        }

        Spacer()
        
        Button(String(localized: "done")) {
          focusedField = nil
        }
      }
    }
    .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhoto, matching: .images)
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
      DocumentPicker(onDocumentsPicked: { urls in
        for url in urls {
          let attachment = AttachmentItem(
            type: .pdf,
            url: url,
            name: url.lastPathComponent
          )
          viewModel.addAttachment(attachment)
        }
      }, contentTypes: [.pdf], allowsMultipleSelection: true)
      .ignoresSafeArea()
    }
    .sheet(isPresented: $showingAudioPicker) {
      DocumentPicker(onDocumentsPicked: { urls in
        if let url = urls.first {
          let attachment = AttachmentItem(
            type: .audio,
            url: url,
            name: url.lastPathComponent
          )
          viewModel.addAttachment(attachment)
        }
      }, contentTypes: [.audio], allowsMultipleSelection: false)
      .ignoresSafeArea()
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
    .alert(
      "Only one audio file per entry",
      isPresented: $showAudioLimitAlert
    ) {
      Button("Okay") { showAudioLimitAlert = false }
    } message: {
      Text("You can add one audio recording to each learning record. Remove the current audio to add a new one.")
    }
    .onChange(of: selectedPhoto) { _, newPhoto in
      if let newPhoto = newPhoto {
        Task {
          if let data = try? await newPhoto.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
          {
            let attachment = AttachmentItem(
              type: .image,
              image: image,
              name:
                "Photo_\(Date().formatted(.dateTime.hour().minute().second()))"
            )
            viewModel.addAttachment(attachment)
          }
        }
      }
    }
    .alert(
      String(localized: "error"),
      isPresented: .constant(viewModel.errorMessage != nil)
    ) {
      Button(String(localized: "confirm")) {
        viewModel.clearError()
      }
    } message: {
      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
      }
    }
  }

  @ViewBuilder
  private func saveButton() -> some View {
    if #available(iOS 26.0, *) {
      Button {
        Task {
          if let newRecord = await viewModel.saveStudyRecord() {
            onSave(newRecord)
            dismiss()
          }
        }
      } label: {
        if viewModel.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .frame(maxWidth: .infinity)
            .padding()
        } else {
          Text(String(localized: "save"))
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
        }
      }
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(viewModel.isValidInput ? Color.accentColor : Color.gray)
      )
      .disabled(!viewModel.isValidInput || viewModel.isLoading)
      .padding(.horizontal, 20)
      .padding(.bottom, 34)
    } else {
      Button {
        Task {
          if let newRecord = await viewModel.saveStudyRecord() {
            onSave(newRecord)
            dismiss()
          }
        }
      } label: {
        if viewModel.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .frame(maxWidth: .infinity)
            .padding()
        } else {
          Text(String(localized: "save"))
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
        }
      }
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(viewModel.isValidInput ? Color.accentColor : Color.gray)
      )
      .disabled(!viewModel.isValidInput || viewModel.isLoading)
      .padding(.horizontal, 20)
      .padding(.bottom, 34)
    }
  }
}

// MARK: - Supporting Views

struct AttachmentRowView: View {
  let attachment: AttachmentItem
  let onRemove: () -> Void

  var body: some View {
    HStack {
      if attachment.type == .image {
        if let image = attachment.image {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 50, height: 50)
            .clipped()
            .cornerRadius(8)
        } else {
          Image(systemName: "photo")
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
      } else if attachment.type == .pdf {
        Image(systemName: "doc")
          .font(.title2)
          .foregroundColor(.blue)
          .frame(width: 50, height: 50)
          .background(Color.blue.opacity(0.1))
          .cornerRadius(8)
      } else {
        Image(systemName: "waveform")
          .font(.title2)
          .foregroundColor(.purple)
          .frame(width: 50, height: 50)
          .background(Color.purple.opacity(0.1))
          .cornerRadius(8)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(attachment.name)
          .font(.subheadline)
          .fontWeight(.medium)
          .lineLimit(1)

        Text(
          attachment.type == .image
            ? String(localized: "image")
            : (attachment.type == .pdf ? String(localized: "document") : "Audio")
        )
        .font(.caption)
        .foregroundColor(.secondary)

        if attachment.type == .audio, let url = attachment.url {
          AudioPlayerView(url: url)
            .padding(.top, 4)
        }
      }

      Spacer()

      Button(action: onRemove) {
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(.red)
      }
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(UIColor.secondarySystemBackground))
    )
  }
}

#Preview {
  StudyRecordAddView { _ in }
}
