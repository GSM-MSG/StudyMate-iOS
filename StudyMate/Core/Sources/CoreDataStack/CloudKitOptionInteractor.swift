import Foundation

public struct CloudKitOptionInteractor: Sendable {
  public let fetchEnablediCloud: @Sendable () -> Bool
  public let setEnablediCloud: @Sendable (Bool) -> Void

  public init(
    fetchEnablediCloud: @escaping @Sendable () -> Bool,
    setEnablediCloud: @escaping @Sendable (Bool) -> Void
  ) {
    self.fetchEnablediCloud = fetchEnablediCloud
    self.setEnablediCloud = setEnablediCloud
  }
}

extension CloudKitOptionInteractor {
  public static let live: CloudKitOptionInteractor = {
    CloudKitOptionInteractor(
      fetchEnablediCloud: { UserDefaults.standard.bool(forKey: "enableiCloud") },
      setEnablediCloud: { UserDefaults.standard.set($0, forKey: "enableiCloud") }
    )
  }()
}
