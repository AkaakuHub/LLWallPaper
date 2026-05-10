import Foundation

public enum CardSearch {
  public static func filter(cards: [CardItem], query: String, settings: AppSettings) -> [CardItem] {
    var result = cards
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

    if !trimmedQuery.isEmpty {
      result = result.filter {
        $0.id.localizedCaseInsensitiveContains(trimmedQuery)
          || $0.name.localizedCaseInsensitiveContains(trimmedQuery)
      }
    }

    if settings.excludeThirdEvolution {
      result = result.filter { !$0.id.hasSuffix("2") }
    }

    if settings.excludeSrCards {
      result = result.filter { !CharacterMap.isSrCard($0.id) }
    }

    return result
  }
}
