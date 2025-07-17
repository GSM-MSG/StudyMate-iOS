import SwiftUI
import UIKit
import Vision
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
  let onTextRecognized: (String) -> Void
  let dismiss: () -> Void
  
  func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
    let scanner = VNDocumentCameraViewController()
    scanner.delegate = context.coordinator
    return scanner
  }
  
  func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  @MainActor
  final class Coordinator: NSObject, @preconcurrency VNDocumentCameraViewControllerDelegate {
    let parent: DocumentScannerView
    
    init(_ parent: DocumentScannerView) {
      self.parent = parent
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
      var recognizedTexts: [String] = []
      
      for pageIndex in 0..<scan.pageCount {
        let image = scan.imageOfPage(at: pageIndex)
        recognizeText(from: image) { text in
          if !text.isEmpty {
            recognizedTexts.append(text)
          }
        }
      }
      
      let combinedText = recognizedTexts.joined(separator: " ")
      if !combinedText.isEmpty {
        parent.onTextRecognized(combinedText)
      }
      parent.dismiss()
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
      parent.dismiss()
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
      parent.dismiss()
    }
    
    private func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
      guard let cgImage = image.cgImage else {
        completion("")
        return
      }
      
      let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
          completion("")
          return
        }
        
        let recognizedText = observations.compactMap { observation in
          observation.topCandidates(1).first?.string
        }.joined(separator: " ")
        
        completion(recognizedText)
      }
      
      request.recognitionLevel = .accurate
      
      let handler = VNImageRequestHandler(cgImage: cgImage)
      try? handler.perform([request])
    }
  }
}
