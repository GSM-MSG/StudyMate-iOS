import CoreData
import Foundation

extension PartialKeyPath where Root: NSManagedObject {
  public var stringValue: String {
    guard let value = _kvcKeyPathString else {
      fatalError("Keypath property must be @NSManaged or @objc")
    }
    return value
  }
}

public func || (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
  NSCompoundPredicate(orPredicateWithSubpredicates: [lhs, rhs])
}

public func && (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
  NSCompoundPredicate(andPredicateWithSubpredicates: [lhs, rhs])
}

public prefix func ! (predicate: NSPredicate) -> NSPredicate {
  NSCompoundPredicate(notPredicateWithSubpredicate: predicate)
}

// MARK: Equatable

public func == <T: NSManagedObject, V: Equatable>(
  _ lhs: KeyPath<T, V>,
  _ rhs: V
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .equalTo
  )
}

public func == <T: NSManagedObject, V: Equatable>(
  _ lhs: KeyPath<T, V>,
  _ rhs: KeyPath<T, V>
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forKeyPath: rhs.stringValue),
    modifier: .direct,
    type: .equalTo
  )
}

public func != <T: NSManagedObject, V: Equatable>(
  _ lhs: KeyPath<T, V>,
  _ rhs: V
) -> NSPredicate {
  !(lhs == rhs)
}

public func != <T: NSManagedObject, V: Equatable>(
  _ lhs: KeyPath<T, V>,
  _ rhs: KeyPath<T, V>
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forKeyPath: rhs.stringValue),
    modifier: .direct,
    type: .notEqualTo
  )
}

// MARK: Comparable

public func > <T: NSManagedObject, V: Comparable>(
  _ lhs: KeyPath<T, V>,
  _ rhs: V
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .greaterThan
  )
}

public func >= <T: NSManagedObject, V: Comparable>(
  _ lhs: KeyPath<T, V>,
  _ rhs: V
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .greaterThanOrEqualTo
  )
}

public func >= <T: NSManagedObject>(
  _ lhs: KeyPath<T, Date?>,
  _ rhs: Date
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .greaterThanOrEqualTo
  )
}

public func >= <T: NSManagedObject>(
  _ lhs: KeyPath<T, Date>,
  _ rhs: Date
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .greaterThanOrEqualTo
  )
}

public func > <T: NSManagedObject>(
  _ lhs: KeyPath<T, Date?>,
  _ rhs: Date
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .greaterThan
  )
}

public func > <T: NSManagedObject>(
  _ lhs: KeyPath<T, Date>,
  _ rhs: Date
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .greaterThan
  )
}

public func < <T: NSManagedObject, V: Comparable>(
  _ lhs: KeyPath<T, V>,
  _ rhs: V
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .lessThan
  )
}

public func <= <T: NSManagedObject, V: Comparable>(
  _ lhs: KeyPath<T, V>,
  _ rhs: V
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .lessThanOrEqualTo
  )
}

public func <= <T: NSManagedObject>(
  _ lhs: KeyPath<T, Date?>,
  _ rhs: Date
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .lessThanOrEqualTo
  )
}

public func <= <T: NSManagedObject>(
  _ lhs: KeyPath<T, Date>,
  _ rhs: Date
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .lessThanOrEqualTo
  )
}

public func < <T: NSManagedObject>(
  _ lhs: KeyPath<T, Date?>,
  _ rhs: Date
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .lessThan
  )
}

public func < <T: NSManagedObject>(
  _ lhs: KeyPath<T, Date>,
  _ rhs: Date
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs),
    modifier: .direct,
    type: .lessThan
  )
}

extension KeyPath where Root: NSManagedObject, Value: Comparable {
  public func between(
    _ range: ClosedRange<Value>
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(
        forKeyPath: stringValue
      ),
      rightExpression: NSExpression(
        forConstantValue: [
          NSExpression(forConstantValue: range.lowerBound),
          NSExpression(forConstantValue: range.upperBound),
        ]
      ),
      modifier: .direct,
      type: .between
    )
  }
}

// MARK: String

extension KeyPath where Root: NSManagedObject, Value == String {

  public func notEqual<Y: StringProtocol>(
    to rhs: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: rhs),
      modifier: .direct,
      type: .notEqualTo,
      options: options
    )
  }

  public func equal<Y: StringProtocol>(
    to rhs: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: rhs),
      modifier: .direct,
      type: .equalTo,
      options: options
    )
  }

  public func like<Y: StringProtocol>(
    _ comparator: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: comparator),
      modifier: .direct,
      type: .like,
      options: options
    )
  }

  public func contains<Y: StringProtocol>(
    _ substring: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: substring),
      modifier: .direct,
      type: .contains,
      options: options
    )
  }

  public func beginsWith<Y: StringProtocol>(
    _ prefix: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: prefix),
      modifier: .direct,
      type: .beginsWith,
      options: options
    )
  }

  public func endsWith<Y: StringProtocol>(
    _ suffix: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: suffix),
      modifier: .direct,
      type: .endsWith,
      options: options
    )
  }
}

extension KeyPath where Root: NSManagedObject, Value == String? {

  public func notEqual<Y: StringProtocol>(
    to rhs: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: rhs),
      modifier: .direct,
      type: .notEqualTo,
      options: options
    )
  }

  public func equal<Y: StringProtocol>(
    to rhs: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: rhs),
      modifier: .direct,
      type: .equalTo,
      options: options
    )
  }

  public func like<Y: StringProtocol>(
    _ comparator: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: comparator),
      modifier: .direct,
      type: .like,
      options: options
    )
  }

  public func contains<Y: StringProtocol>(
    _ substring: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: substring),
      modifier: .direct,
      type: .contains,
      options: options
    )
  }

  public func beginsWith<Y: StringProtocol>(
    _ prefix: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: prefix),
      modifier: .direct,
      type: .beginsWith,
      options: options
    )
  }

  public func endsWith<Y: StringProtocol>(
    _ suffix: Y,
    options: NSComparisonPredicate.Options = []
  ) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: suffix),
      modifier: .direct,
      type: .endsWith,
      options: options
    )
  }
}

extension KeyPath where Root: NSManagedObject, Value: Equatable {
  public func `in`<C: Collection>(
    _ collection: C
  ) -> NSPredicate
  where C.Element == Value {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: collection),
      modifier: .direct,
      type: .in
    )
  }
}

public func == <T: NSManagedObject, V: NSManagedObject>(
  _ lhs: KeyPath<T, V>,
  _ rhs: V
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs.objectID),
    modifier: .direct,
    type: .equalTo
  )
}

public func == <T: NSManagedObject, V: NSManagedObject>(
  _ lhs: KeyPath<T, V?>,
  _ rhs: V
) -> NSPredicate {
  NSComparisonPredicate(
    leftExpression: NSExpression(forKeyPath: lhs.stringValue),
    rightExpression: NSExpression(forConstantValue: rhs.objectID),
    modifier: .direct,
    type: .equalTo
  )
}

extension KeyPath
where
  Root: NSManagedObject,
  Value: Collection,
  Value.Element: NSManagedObject
{
  public func contains(_ value: Value.Element) -> NSPredicate {
    NSComparisonPredicate(
      leftExpression: NSExpression(forKeyPath: stringValue),
      rightExpression: NSExpression(forConstantValue: value.objectID),
      modifier: .direct,
      type: .contains
    )
  }
}
