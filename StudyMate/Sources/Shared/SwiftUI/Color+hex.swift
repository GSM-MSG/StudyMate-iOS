import SwiftUI

extension Color {
  /// HEX 문자열로부터 Color 객체를 생성합니다.
  /// - Parameters:
  ///   - hex: "#RRGGBB" 또는 "#RRGGBBAA" 형식의 HEX 문자열
  ///   - opacity: 투명도. HEX 문자열에 알파값이 포함된 경우 이 값은 무시됩니다.
  /// - Returns: 생성된 Color 객체. 변환에 실패할 경우 .gray를 반환합니다.
  public init(hex: String, opacity: Double = 1.0) {
    let hexSanitized = hex
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0

    Scanner(string: hexSanitized)
      .scanHexInt64(&rgb)

    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    switch hexSanitized.count {
    case 6:
      red = Double((rgb & 0xFF0000) >> 16) / 255.0
      green = Double((rgb & 0x00FF00) >> 8) / 255.0
      blue = Double(rgb & 0x0000FF) / 255.0
      alpha = opacity
    case 8:
      red = Double((rgb & 0xFF00_0000) >> 24) / 255.0
      green = Double((rgb & 0x00FF_0000) >> 16) / 255.0
      blue = Double((rgb & 0x0000_FF00) >> 8) / 255.0
      alpha = Double(rgb & 0x0000_00FF) / 255.0
    default:
      self.init(.gray)
      return
    }

    self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
  }

  /// RGB 값으로부터 Color 객체를 생성합니다.
  /// - Parameters:
  ///   - r: Red 값 (0-255)
  ///   - g: Green 값 (0-255)
  ///   - b: Blue 값 (0-255)
  ///   - a: Alpha 값 (0.0-1.0)
  /// - Returns: 생성된 Color 객체
  public init(r: Int, g: Int, b: Int, a: Double = 1.0) {
    self.init(
      .sRGB,
      red: Double(r) / 255.0,
      green: Double(g) / 255.0,
      blue: Double(b) / 255.0,
      opacity: a
    )
  }

  /// Color 객체를 HEX 문자열로 변환합니다.
  /// - Parameter includeAlpha: 알파값 포함 여부
  /// - Returns: "#RRGGBB" 또는 "#RRGGBBAA" 형식의 HEX 문자열
  public func toHexString(includeAlpha: Bool = false) -> String {
    #if os(iOS) || os(watchOS) || os(visionOS)
    typealias PlatformColor = UIColor
    #else
    typealias PlatformColor = NSColor
    #endif
    guard let components = PlatformColor(self).cgColor.components else {
      return "#000000"
    }

    let r = components[0]
    let g = components[1]
    let b = components[2]
    let a = components[3]

    if includeAlpha {
      return String(
        format: "#%02lX%02lX%02lX%02lX",
        lroundf(Float(r) * 255),
        lroundf(Float(g) * 255),
        lroundf(Float(b) * 255),
        lroundf(Float(a) * 255)
      )
    } else {
      return String(
        format: "#%02lX%02lX%02lX",
        lroundf(Float(r) * 255),
        lroundf(Float(g) * 255),
        lroundf(Float(b) * 255)
      )
    }
  }
}
