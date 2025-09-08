import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
  let onDocumentsPicked: ([URL]) -> Void
  var contentTypes: [UTType] = [.pdf]
  var allowsMultipleSelection: Bool = true
  
  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
    picker.delegate = context.coordinator
    picker.allowsMultipleSelection = allowsMultipleSelection
    return picker
  }
  
  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UIDocumentPickerDelegate {
    let parent: DocumentPicker
    
    init(_ parent: DocumentPicker) {
      self.parent = parent
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      parent.onDocumentsPicked(urls)
    }
  }
}
