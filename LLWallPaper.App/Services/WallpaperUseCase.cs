using System.IO;
using LLWallPaper.App.Models;
using LLWallPaper.App.Stores;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.Services;

public sealed class WallpaperUseCase
{
    private readonly CardCatalogService _catalogService;
    private readonly RotationService _rotationService;
    private readonly CacheStore _cacheStore;
    private readonly DesktopWallpaperAdapter? _desktopWallpaperAdapter;
    private readonly FavoritesStore _favoritesStore;
    private readonly HistoryStore _historyStore;
    private readonly AppLogger _logger;

    public WallpaperUseCase(
        CardCatalogService catalogService,
        RotationService rotationService,
        CacheStore cacheStore,
        DesktopWallpaperAdapter? desktopWallpaperAdapter,
        FavoritesStore favoritesStore,
        HistoryStore historyStore,
        AppLogger logger)
    {
        _catalogService = catalogService;
        _rotationService = rotationService;
        _cacheStore = cacheStore;
        _desktopWallpaperAdapter = desktopWallpaperAdapter;
        _favoritesStore = favoritesStore;
        _historyStore = historyStore;
        _logger = logger;
    }

    public event EventHandler<WallpaperChangedEventArgs>? WallpaperChanged;

    public async Task<WallpaperResult> ApplyNextAsync(Settings settings, CancellationToken cancellationToken)
    {
        var candidates = _catalogService.Current;
        if (candidates.Count == 0)
        {
            return new WallpaperResult(false, "No cards available.");
        }

        var recentKeys = _historyStore.GetRecentKeys(settings.RecentExcludeCount);
        var card = _rotationService.PickNext(
            candidates,
            recentKeys,
            _favoritesStore.FavoriteKeys,
            _favoritesStore.BlockedKeys,
            settings.PreferFavorites,
            settings.ExcludeBlocked,
            settings.ExcludeThirdEvolution);

        if (card is null)
        {
            return new WallpaperResult(false, "No eligible cards.");
        }

        return await ApplyCardAsync(card, settings, cancellationToken, "auto");
    }

    public async Task<WallpaperResult> ApplyCardAsync(CardItem card, Settings settings, CancellationToken cancellationToken, string reason)
    {
        var protectedPaths = _historyStore.GetRecentLocalPaths(settings.RecentExcludeCount)
            .Where(path => !string.IsNullOrWhiteSpace(path))
            .ToList();

        var localPath = await _cacheStore.EnsureLocalAsync(card, settings.CacheMaxMb, protectedPaths);
        if (string.IsNullOrWhiteSpace(localPath))
        {
            _historyStore.Append(new HistoryEntry
            {
                At = DateTimeOffset.Now,
                Key = card.Id,
                FileName = string.Empty,
                Result = "download_failed"
            });

            return new WallpaperResult(false, "Download failed.");
        }

        if (_desktopWallpaperAdapter is null)
        {
            _historyStore.Append(new HistoryEntry
            {
                At = DateTimeOffset.Now,
                Key = card.Id,
                FileName = Path.GetFileName(localPath),
                Result = "wallpaper_not_supported"
            });

            return new WallpaperResult(false, "IDesktopWallpaper not available on this OS.");
        }

        if (!_desktopWallpaperAdapter.TrySetWallpaper(localPath, out var error))
        {
            _logger.Error("SetWallpaper failed.", error is null ? null : new InvalidOperationException(error));
            _historyStore.Append(new HistoryEntry
            {
                At = DateTimeOffset.Now,
                Key = card.Id,
                FileName = Path.GetFileName(localPath),
                Result = "setwallpaper_failed"
            });

            return new WallpaperResult(false, "SetWallpaper failed.");
        }

        try
        {
            _historyStore.Append(new HistoryEntry
            {
                At = DateTimeOffset.Now,
                Key = card.Id,
                FileName = Path.GetFileName(localPath),
                Result = "ok"
            });

            WallpaperChanged?.Invoke(this, new WallpaperChangedEventArgs(card, localPath, reason));
            return new WallpaperResult(true, "Wallpaper updated.");
        }
        catch (Exception ex)
        {
            _logger.Error("Wallpaper change handler failed.", ex);
            return new WallpaperResult(true, "Wallpaper updated (with notification error).");
        }
    }

}

public sealed class WallpaperChangedEventArgs : EventArgs
{
    public WallpaperChangedEventArgs(CardItem card, string localPath, string reason)
    {
        Card = card;
        LocalPath = localPath;
        Reason = reason;
    }

    public CardItem Card { get; }
    public string LocalPath { get; }
    public string Reason { get; }
}

public readonly record struct WallpaperResult(bool Success, string Message);

