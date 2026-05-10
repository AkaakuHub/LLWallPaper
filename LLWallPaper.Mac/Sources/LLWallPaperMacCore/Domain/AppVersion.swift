import Foundation

public struct AppVersion: Comparable, Equatable, Sendable {
  private let components: [Int]

  public init?(_ value: String) {
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingPrefix("v")
    let components = normalized.split(separator: ".").map(String.init)
    guard !components.isEmpty else {
      return nil
    }

    var parsedComponents: [Int] = []
    for component in components {
      guard let number = Int(component), number >= 0 else {
        return nil
      }
      parsedComponents.append(number)
    }

    self.components = parsedComponents
  }

  public static func < (left: AppVersion, right: AppVersion) -> Bool {
    let count = max(left.components.count, right.components.count)
    for index in 0..<count {
      let leftValue = index < left.components.count ? left.components[index] : 0
      let rightValue = index < right.components.count ? right.components[index] : 0
      if leftValue != rightValue {
        return leftValue < rightValue
      }
    }
    return false
  }

  public static func == (left: AppVersion, right: AppVersion) -> Bool {
    !(left < right) && !(right < left)
  }
}
