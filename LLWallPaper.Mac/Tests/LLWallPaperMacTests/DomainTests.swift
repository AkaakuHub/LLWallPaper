import Foundation
import XCTest

@testable import LLWallPaperMacCore

final class DomainTests: XCTestCase {
  func testCharacterNameUsesSharedFixture() throws {
    let fixture = try FeatureParityFixture.load()

    for testCase in fixture.characterCases {
      XCTAssertEqual(CharacterMap.name(for: testCase.cardId), testCase.expectedName)
    }
  }

  func testSrCardDetectionUsesSharedFixture() throws {
    let fixture = try FeatureParityFixture.load()

    for testCase in fixture.srCases {
      XCTAssertEqual(CharacterMap.isSrCard(testCase.cardId), testCase.expected)
    }
  }

  func testCardSearchMatchesSharedFixture() throws {
    let fixture = try FeatureParityFixture.load()
    let cards = fixture.cards.map(\.cardItem)

    for testCase in fixture.searchCases {
      var settings = AppSettings()
      settings.excludeThirdEvolution = testCase.settings.excludeThirdEvolution
      settings.excludeSrCards = testCase.settings.excludeSrCards

      let result = CardSearch.filter(cards: cards, query: testCase.query, settings: settings)

      XCTAssertEqual(result.map(\.id), testCase.expectedIds, testCase.name)
    }
  }

  @MainActor
  func testBackendParserMatchesSharedFixture() throws {
    let fixture = try FeatureParityFixture.load()
    let cards = try BackendApiClient.parseCards(
      data: try FeatureParityFixture.backendJsonData(),
      baseUrl: fixture.backendCase.baseUrl
    )

    XCTAssertEqual(cards.count, fixture.backendCase.expectedCards.count)
    for (card, expected) in zip(cards, fixture.backendCase.expectedCards) {
      XCTAssertEqual(card.id, expected.id)
      XCTAssertEqual(card.name, expected.name)
      XCTAssertEqual(card.imageUrl, expected.imageUrl)
      XCTAssertEqual(card.thumbnailUrl, expected.thumbnailUrl)
    }
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
