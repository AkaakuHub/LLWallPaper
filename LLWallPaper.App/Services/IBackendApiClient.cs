using LLWallPaper.App.Models;

namespace LLWallPaper.App.Services;

public interface IBackendApiClient
{
    Task<IReadOnlyList<CardItem>> GetCardsAsync(CancellationToken cancellationToken);
}

