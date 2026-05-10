import Foundation
import XCTest

@testable import LLWallPaperMacCore

struct FeatureParityFixture: Decodable {
  let defaultSettings: SettingsFixture
  let cards: [CardFixture]
  let searchCases: [SearchCaseFixture]
  let rotationCases: [RotationCaseFixture]
  let backendCase: BackendCaseFixture
  let characterCases: [CharacterCaseFixture]
  let srCases: [SrCaseFixture]

  static func load(file: StaticString = #filePath, line: UInt = #line) throws
    -> FeatureParityFixture
  {
    let data = try Data(contentsOf: try fixtureUrl(file: file, line: line))
    return try JSONDecoder().decode(FeatureParityFixture.self, from: data)
  }

  static func backendJsonData(file: StaticString = #filePath, line: UInt = #line) throws -> Data {
    let data = try Data(contentsOf: try fixtureUrl(file: file, line: line))
    let root = try JSONSerialization.jsonObject(with: data)
    guard
      let dictionary = root as? [String: Any],
      let backendCase = dictionary["backendCase"] as? [String: Any],
      let json = backendCase["json"]
    else {
      XCTFail("backendCase.json was not found.", file: file, line: line)
      return Data()
    }

    return try JSONSerialization.data(withJSONObject: json)
  }

  private static func fixtureUrl(file: StaticString, line: UInt) throws -> URL {
    var directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    while true {
      let fixtureUrl =
        directory
        .appending(path: "tests")
        .appending(path: "feature-parity")
        .appending(path: "feature-parity.json")
      if FileManager.default.fileExists(atPath: fixtureUrl.path) {
        return fixtureUrl
      }

      let parent = directory.deletingLastPathComponent()
      if parent.path == directory.path {
        XCTFail("Feature parity fixture was not found.", file: file, line: line)
        throw FixtureError.notFound
      }
      directory = parent
    }
  }
}

enum FixtureError: Error {
  case notFound
}

struct SettingsFixture: Decodable {
  let backendBaseUrl: String
  let autoRotateEnabled: Bool
  let rotateIntervalMinutes: Int
  let rotateOnAppStart: Bool
  let recentExcludeCount: Int
  let preferFavorites: Bool
  let excludeBlocked: Bool
  let excludeThirdEvolution: Bool
  let excludeSrCards: Bool
  let startWithOs: Bool
  let startMinimized: Bool
  let cacheMaxMb: Int
  let historyMaxEntries: Int
}

struct CardFixture: Decodable {
  let id: String
  let name: String
  let imageUrl: URL
  let thumbnailUrl: URL?

  var cardItem: CardItem {
    CardItem(id: id, name: name, imageUrl: imageUrl, thumbnailUrl: thumbnailUrl)
  }
}

struct SearchCaseFixture: Decodable {
  let name: String
  let query: String
  let settings: SearchSettingsFixture
  let expectedIds: [String]
}

struct SearchSettingsFixture: Decodable {
  let excludeThirdEvolution: Bool
  let excludeSrCards: Bool
}

struct RotationCaseFixture: Decodable {
  let name: String
  let settings: RotationSettingsFixture
  let favoriteKeys: Set<String>
  let blockedKeys: Set<String>
  let recentKeys: Set<String>
  let expectedId: String?
}

struct RotationSettingsFixture: Decodable {
  let preferFavorites: Bool
  let excludeBlocked: Bool
  let excludeThirdEvolution: Bool
  let excludeSrCards: Bool
}

struct BackendCaseFixture: Decodable {
  let baseUrl: URL
  let expectedCards: [CardFixture]
}

struct CharacterCaseFixture: Decodable {
  let cardId: String
  let expectedName: String
}

struct SrCaseFixture: Decodable {
  let cardId: String
  let expected: Bool
}
