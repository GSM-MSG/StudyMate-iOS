import SwiftUI
import UIKit

struct TimePicker: UIViewRepresentable {
  @Binding var duration: TimeInterval
  
  func makeUIView(context: Context) -> UIDatePicker {
    let picker = UIDatePicker()
    picker.datePickerMode = .countDownTimer
    picker.preferredDatePickerStyle = .wheels
    picker.minuteInterval = 1
    picker.countDownDuration = duration
    
    picker.addTarget(
      context.coordinator,
      action: #selector(Coordinator.durationChanged(_:)),
      for: .valueChanged
    )
    
    return picker
  }
  
  func updateUIView(_ uiView: UIDatePicker, context: Context) {
    uiView.countDownDuration = duration
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  @MainActor
  final class Coordinator: NSObject {
    let parent: TimePicker
    
    init(_ parent: TimePicker) {
      self.parent = parent
    }
    
    @objc func durationChanged(_ sender: UIDatePicker) {
      parent.duration = sender.countDownDuration
    }
  }
} 
