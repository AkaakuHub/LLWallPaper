using System.IO;
using System.Linq;
using System.Text.Json;
using LLWallPaper.App.Models;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.Stores;

public sealed class HistoryStore
{
    private readonly AppLogger _logger;

    public HistoryStore(AppLogger logger)
    {
        _logger = logger;
    }

    public void Append(HistoryEntry entry, int maxEntries)
    {
        var state = LoadState();
        state.BasePath = ResolveBasePath(state.BasePath);
        state.Entries.Add(entry);
        if (maxEntries > 0 && state.Entries.Count > maxEntries)
        {
            var excess = state.Entries.Count - maxEntries;
            state.Entries.RemoveRange(0, excess);
        }
        SaveState(state);
    }

    public HistoryState GetState()
    {
        return LoadState();
    }

    public IReadOnlyList<HistoryEntry> GetAllEntries()
    {
        return LoadState().Entries;
    }

    public void TrimToMax(int maxEntries)
    {
        if (maxEntries <= 0)
        {
            return;
        }

        var state = LoadState();
        if (state.Entries.Count <= maxEntries)
        {
            return;
        }

        var excess = state.Entries.Count - maxEntries;
        state.Entries.RemoveRange(0, excess);
        SaveState(state);
    }

    public IReadOnlyList<string> GetRecentKeys(int count)
    {
        return GetRecentEntries(count).Select(entry => entry.Key).ToList();
    }

    public IReadOnlyList<HistoryEntry> GetRecentEntries(int count)
    {
        if (count <= 0)
        {
            return Array.Empty<HistoryEntry>();
        }

        var entries = LoadState().Entries;
        if (entries.Count == 0)
        {
            return Array.Empty<HistoryEntry>();
        }

        var skip = Math.Max(0, entries.Count - count);
        return entries.Skip(skip).ToList();
    }

    public IReadOnlyList<string> GetRecentLocalPaths(int count)
    {
        if (count <= 0)
        {
            return Array.Empty<string>();
        }

        var entries = LoadState().Entries;
        if (entries.Count == 0)
        {
            return Array.Empty<string>();
        }

        var skip = Math.Max(0, entries.Count - count);
        return entries
            .Skip(skip)
            .Select(entry => AppPaths.GetCachePathForKey(entry.Key))
            .Where(path => !string.IsNullOrWhiteSpace(path) && File.Exists(path))
            .ToList();
    }

    private HistoryState LoadState()
    {
        AppPaths.EnsureDirectories();
        if (File.Exists(AppPaths.HistoryPath))
        {
            try
            {
                var json = File.ReadAllText(AppPaths.HistoryPath);
                var state =
                    JsonSerializer.Deserialize<HistoryState>(json, JsonOptions.Default)
                    ?? new HistoryState();
                state.BasePath = ResolveBasePath(state.BasePath);
                state.Entries ??= new List<HistoryEntry>();
                return state;
            }
            catch (Exception ex)
            {
                _logger.Error("Failed to read history entries.", ex);
                return new HistoryState { BasePath = ResolveBasePath(string.Empty) };
            }
        }

        var empty = new HistoryState { BasePath = ResolveBasePath(string.Empty) };
        SaveState(empty);
        return empty;
    }

    private void SaveState(HistoryState state)
    {
        AppPaths.EnsureDirectories();
        state.BasePath = ResolveBasePath(state.BasePath);
        var json = JsonSerializer.Serialize(state, JsonOptions.Default);
        File.WriteAllText(AppPaths.HistoryPath, json);
    }

    private static string ResolveBasePath(string basePath)
    {
        if (!string.IsNullOrWhiteSpace(basePath))
        {
            return basePath;
        }

        return AppPaths.CacheRoot;
    }
}
