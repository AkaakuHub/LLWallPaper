import Foundation

@MainActor
public final class CardCatalogService: ObservableObject, CardCatalogProviding {
  @Published public private(set) var current: [CardItem] = []

  private let backendApiClient: BackendApiClient

  public init(backendApiClient: BackendApiClient) {
    self.backendApiClient = backendApiClient
  }

  public func refresh(baseUrl: String) async throws {
    current = try await backendApiClient.getCards(baseUrl: baseUrl)
  }

  public func search(_ query: String, settings: AppSettings) -> [CardItem] {
    CardSearch.filter(cards: current, query: query, settings: settings)
  }
}
