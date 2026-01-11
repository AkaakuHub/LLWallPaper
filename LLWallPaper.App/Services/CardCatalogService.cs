using LLWallPaper.App.Models;

namespace LLWallPaper.App.Services;

public sealed class CardCatalogService
{
    private readonly IBackendApiClient _backendApiClient;
    private readonly List<CardItem> _cards = new();

    public CardCatalogService(IBackendApiClient backendApiClient)
    {
        _backendApiClient = backendApiClient;
    }

    public event EventHandler? CatalogUpdated;

    public IReadOnlyList<CardItem> Current => _cards;

    public async Task RefreshAsync(CancellationToken cancellationToken)
    {
        var cards = await _backendApiClient.GetCardsAsync(cancellationToken);
        _cards.Clear();
        _cards.AddRange(cards);
        CatalogUpdated?.Invoke(this, EventArgs.Empty);
    }

    public IReadOnlyList<CardItem> Search(string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return _cards.ToList();
        }

        var term = query.Trim();
        return _cards
            .Where(card =>
                card.Id.Contains(term, StringComparison.OrdinalIgnoreCase)
                || card.Name.Contains(term, StringComparison.OrdinalIgnoreCase)
            )
            .ToList();
    }
}
