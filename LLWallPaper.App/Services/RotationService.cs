using LLWallPaper.App.Models;

namespace LLWallPaper.App.Services;

public sealed class RotationService
{
    private readonly Random _random = new();

    public CardItem? PickNext(IReadOnlyList<CardItem> candidates, IReadOnlyCollection<string> recentKeys,
        IReadOnlyCollection<string> favoriteKeys, IReadOnlyCollection<string> blockedKeys,
        bool preferFavorites, bool excludeBlocked)
    {
        IEnumerable<CardItem> pool = candidates;
        if (excludeBlocked && blockedKeys.Count > 0)
        {
            pool = pool.Where(card => !blockedKeys.Contains(card.Id));
        }

        if (recentKeys.Count > 0)
        {
            pool = pool.Where(card => !recentKeys.Contains(card.Id));
        }

        var filtered = pool.ToList();
        if (filtered.Count == 0)
        {
            return null;
        }

        if (preferFavorites)
        {
            var favorites = filtered.Where(card => favoriteKeys.Contains(card.Id)).ToList();
            if (favorites.Count > 0)
            {
                return favorites[_random.Next(favorites.Count)];
            }
        }

        return filtered[_random.Next(filtered.Count)];
    }
}

