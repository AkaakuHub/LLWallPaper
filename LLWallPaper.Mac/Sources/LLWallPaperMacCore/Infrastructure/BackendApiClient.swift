import Foundation

@MainActor
public final class BackendApiClient {
  private let session: URLSession
  private let logger: AppLogger

  public init(session: URLSession = .shared, logger: AppLogger) {
    self.session = session
    self.logger = logger
  }

  public func getCards(baseUrl: String) async throws -> [CardItem] {
    guard let baseUrl = URL(string: baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)) else {
      throw BackendApiError.emptyBaseUrl
    }

    let requestUrl = baseUrl.appending(path: "api/card-illustrations")
    do {
      let (data, response) = try await session.data(from: requestUrl)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw BackendApiError.invalidResponse
      }
      guard (200..<300).contains(httpResponse.statusCode) else {
        throw BackendApiError.httpStatus(httpResponse.statusCode)
      }

      return try Self.parseCards(data: data, baseUrl: baseUrl)
    } catch {
      logger.error("Failed to fetch cards from backend.", error)
      throw error
    }
  }

  public static func parseCards(data: Data, baseUrl: URL) throws -> [CardItem] {
    let json = try JSONSerialization.jsonObject(with: data)
    let array: [Any]

    if let rootArray = json as? [Any] {
      array = rootArray
    } else if let dictionary = json as? [String: Any], let cards = dictionary["cards"] as? [Any] {
      array = cards
    } else {
      return []
    }

    return array.compactMap { item in
      guard
        let dictionary = item as? [String: Any],
        let id = parseId(dictionary["id"]),
        hasImageAsset(dictionary, key: "full")
      else {
        return nil
      }

      let name = dictionary["name"] as? String ?? id
      let imageUrl = baseUrl.appending(path: "api/card-illustrations/image/\(id)")
        .appending(queryItems: [URLQueryItem(name: "type", value: "full")])
      let thumbnailUrl = baseUrl.appending(path: "api/card-illustrations/image/\(id)")
        .appending(queryItems: [URLQueryItem(name: "type", value: "half")])

      return CardItem(id: id, name: name, imageUrl: imageUrl, thumbnailUrl: thumbnailUrl)
    }
  }

  private static func parseId(_ value: Any?) -> String? {
    switch value {
    case let string as String:
      return string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : string
    case let number as NSNumber:
      return number.stringValue
    default:
      return nil
    }
  }

  private static func hasImageAsset(_ dictionary: [String: Any], key: String) -> Bool {
    guard
      let assets = dictionary["assets"] as? [String: Any],
      let images = assets["images"] as? [String: Any],
      let value = images[key]
    else {
      return false
    }

    if let bool = value as? Bool {
      return bool
    }

    if let string = value as? String {
      return Bool(string) ?? false
    }

    return false
  }
}

public enum BackendApiError: LocalizedError, Equatable {
  case emptyBaseUrl
  case invalidResponse
  case httpStatus(Int)

  public var errorDescription: String? {
    switch self {
    case .emptyBaseUrl:
      return "Backend base URL is empty."
    case .invalidResponse:
      return "Backend returned an invalid response."
    case let .httpStatus(statusCode):
      return "Backend returned HTTP \(statusCode)."
    }
  }
}
