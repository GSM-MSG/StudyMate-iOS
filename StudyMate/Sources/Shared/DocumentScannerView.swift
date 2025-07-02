import SwiftUI
import UIKit
import Vision
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
  let onTextRecognized: (String) -> Void
  let dismiss: () -> Void
  
  func makeUIViewController(context: Context) -> DataScannerViewController {
    let scanner = DataScannerViewController(
      recognizedDataTypes: [.text()],
      qualityLevel: .balanced,
      recognizesMultipleItems: true,
      isHighFrameRateTrackingEnabled: false,
      isPinchToZoomEnabled: true,
      isGuidanceEnabled: true,
      isHighlightingEnabled: true
    )
    
    scanner.delegate = context.coordinator
    
    scanner.navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: String(localized: "cancel"),
      style: .plain,
      target: context.coordinator,
      action: #selector(context.coordinator.cancelScanning)
    )
    
    scanner.navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: String(localized: "done"),
      style: .done,
      target: context.coordinator,
      action: #selector(context.coordinator.finishScanning)
    )
    
    return scanner
  }
  
  func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, DataScannerViewControllerDelegate {
    let parent: DocumentScannerView
    private var recognizedTexts: [String] = []
    
    init(_ parent: DocumentScannerView) {
      self.parent = parent
    }
    
    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
      switch item {
      case .text(let text):
        if !recognizedTexts.contains(text.transcript) {
          recognizedTexts.append(text.transcript)
        }
      default:
        break
      }
    }
    
    func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
      for item in addedItems {
        switch item {
        case .text(let text):
          if !recognizedTexts.contains(text.transcript) {
            recognizedTexts.append(text.transcript)
          }
        default:
          break
        }
      }
    }
    
    @objc func cancelScanning() {
      parent.dismiss()
    }
    
    @objc func finishScanning() {
      let combinedText = recognizedTexts.joined(separator: " ")
      if !combinedText.isEmpty {
        parent.onTextRecognized(combinedText)
      }
      parent.dismiss()
    }
  }
}
