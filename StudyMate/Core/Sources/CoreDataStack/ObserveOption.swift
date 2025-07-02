import Foundation

public struct ObserveOption: OptionSet, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let inserted = ObserveOption(rawValue: 1 << 0)
  public static let updated = ObserveOption(rawValue: 1 << 1)
  public static let deleted = ObserveOption(rawValue: 1 << 2)
}
