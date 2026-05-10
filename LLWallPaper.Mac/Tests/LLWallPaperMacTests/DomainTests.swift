import Foundation
import XCTest

@testable import LLWallPaperMacCore

final class DomainTests: XCTestCase {
  func testCharacterNameUsesFirstFourDigits() {
    XCTAssertEqual(CharacterMap.name(for: "102199"), "乙宗梢")
    XCTAssertEqual(CharacterMap.name(for: "999999"), "その他")
  }

  func testSrCardDetectionUsesFifthAndSixthDigits() {
    XCTAssertTrue(CharacterMap.isSrCard("102130"))
    XCTAssertFalse(CharacterMap.isSrCard("102131"))
    XCTAssertFalse(CharacterMap.isSrCard("1021"))
  }

  func testCardSearchFiltersByQueryAndRules() throws {
    let settings = {
      var settings = AppSettings()
      settings.excludeThirdEvolution = true
      settings.excludeSrCards = true
      return settings
    }()
    let cards = [
      try makeCard(id: "102111", name: "First"),
      try makeCard(id: "102112", name: "Third Evolution"),
      try makeCard(id: "102130", name: "SR"),
    ]

    let result = CardSearch.filter(cards: cards, query: "1021", settings: settings)

    XCTAssertEqual(result.map(\.id), ["102111"])
  }

  @MainActor
  func testBackendParserAcceptsRootCardsObject() throws {
    let json = """
      {
        "cards": [
          {
            "id": 102111,
            "name": "Card Name",
            "assets": { "images": { "full": true, "half": true } }
          },
          {
            "id": "102112",
            "name": "No Full",
            "assets": { "images": { "full": false } }
          }
        ]
      }
      """
    let cards = try BackendApiClient.parseCards(
      data: Data(json.utf8),
      baseUrl: URL(string: "http://127.0.0.1:3000")!
    )

    XCTAssertEqual(cards.count, 1)
    XCTAssertEqual(cards[0].id, "102111")
    XCTAssertEqual(cards[0].name, "Card Name")
    XCTAssertEqual(
      cards[0].imageUrl.absoluteString,
      "http://127.0.0.1:3000/api/card-illustrations/image/102111?type=full")
  }

  func testRotationReturnsNilWhenAllCandidatesAreBlocked() throws {
    var settings = AppSettings()
    settings.excludeBlocked = true
    settings.excludeSrCards = false
    let card = try makeCard(id: "102111", name: "Blocked")

    let result = RotationService().pickNext(
      candidates: [card],
      recentKeys: [],
      favoriteKeys: [],
      blockedKeys: ["102111"],
      settings: settings
    )

    XCTAssertNil(result)
  }

  private func makeCard(id: String, name: String) throws -> CardItem {
    let imageUrl = try XCTUnwrap(URL(string: "http://127.0.0.1:3000/image/\(id).webp"))
    return CardItem(id: id, name: name, imageUrl: imageUrl, thumbnailUrl: nil)
  }
}
