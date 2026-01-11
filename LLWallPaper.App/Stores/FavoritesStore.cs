using System.IO;
using System.Text.Json;
using LLWallPaper.App.Models;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.Stores;

public sealed class FavoritesStore
{
    private readonly AppLogger _logger;
    private Favorites _state = new();

    public FavoritesStore(AppLogger logger)
    {
        _logger = logger;
    }

    public void Load()
    {
        AppPaths.EnsureDirectories();
        if (!File.Exists(AppPaths.FavoritesPath))
        {
            Save();
            return;
        }

        try
        {
            var json = File.ReadAllText(AppPaths.FavoritesPath);
            _state =
                JsonSerializer.Deserialize<Favorites>(json, JsonOptions.Default) ?? new Favorites();
        }
        catch (Exception ex)
        {
            _logger.Error("Failed to load favorites, resetting.", ex);
            _state = new Favorites();
        }
    }

    public bool IsFavorite(string key) => _state.FavoriteKeys.Contains(key);

    public bool IsBlocked(string key) => _state.BlockedKeys.Contains(key);

    public IReadOnlyCollection<string> FavoriteKeys => _state.FavoriteKeys;

    public IReadOnlyCollection<string> BlockedKeys => _state.BlockedKeys;

    public void ToggleFavorite(string key)
    {
        if (_state.FavoriteKeys.Contains(key))
        {
            _state.FavoriteKeys.Remove(key);
        }
        else
        {
            _state.FavoriteKeys.Add(key);
        }

        Save();
    }

    public void ToggleBlocked(string key)
    {
        if (_state.BlockedKeys.Contains(key))
        {
            _state.BlockedKeys.Remove(key);
        }
        else
        {
            _state.BlockedKeys.Add(key);
        }

        Save();
    }

    private void Save()
    {
        AppPaths.EnsureDirectories();
        var json = JsonSerializer.Serialize(_state, JsonOptions.Default);
        File.WriteAllText(AppPaths.FavoritesPath, json);
    }
}
