import AVFoundation
import SwiftUI

final class AudioPlayerController: NSObject, ObservableObject, AVAudioPlayerDelegate {
  @Published var isPlaying = false
  private var player: AVAudioPlayer?
  private var hasSecurityAccess = false
  private var currentURL: URL?

  func togglePlay(url: URL) {
    if currentURL != url || player == nil {
      prepare(url: url)
    }
    guard let player else { return }
    if isPlaying {
      player.pause()
      isPlaying = false
    } else {
      player.play()
      isPlaying = true
    }
  }

  private func prepare(url: URL) {
    cleanup()
    currentURL = url
    hasSecurityAccess = url.startAccessingSecurityScopedResource()
    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.delegate = self
      player.prepareToPlay()
      self.player = player
    } catch {
      self.player = nil
      if hasSecurityAccess {
        url.stopAccessingSecurityScopedResource()
        hasSecurityAccess = false
      }
      print("Audio prepare error: \(error)")
    }
  }

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    isPlaying = false
  }

  private func cleanup() {
    if let url = currentURL, hasSecurityAccess {
      url.stopAccessingSecurityScopedResource()
      hasSecurityAccess = false
    }
    player?.stop()
    player = nil
    isPlaying = false
  }

  deinit {
    cleanup()
  }
}

struct AudioPlayerView: View {
  let url: URL
  @StateObject private var controller = AudioPlayerController()

  var body: some View {
    Button {
      controller.togglePlay(url: url)
    } label: {
      Image(systemName: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill")
        .font(.system(size: 22, weight: .semibold))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(controller.isPlaying ? "Pause audio" : "Play audio")
  }
}

