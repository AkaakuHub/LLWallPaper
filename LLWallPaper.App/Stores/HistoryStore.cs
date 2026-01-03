using System.IO;
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

    public void Append(HistoryEntry entry)
    {
        var state = LoadState();
        state.BasePath = ResolveBasePath(state.BasePath);
        state.Entries.Add(entry);
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

    public IReadOnlyList<string> GetRecentKeys(int count)
    {
        return GetRecentEntries(count)
            .Select(entry => entry.Key)
            .ToList();
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

        var state = LoadState();
        var basePath = ResolveBasePath(state.BasePath);
        if (string.IsNullOrWhiteSpace(basePath))
        {
            return Array.Empty<string>();
        }

        var entries = state.Entries;
        if (entries.Count == 0)
        {
            return Array.Empty<string>();
        }

        var skip = Math.Max(0, entries.Count - count);
        return entries
            .Skip(skip)
            .Select(entry => string.IsNullOrWhiteSpace(entry.FileName) ? string.Empty : Path.Combine(basePath, entry.FileName))
            .Where(path => !string.IsNullOrWhiteSpace(path))
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
                var state = JsonSerializer.Deserialize<HistoryState>(json, JsonOptions.Default) ?? new HistoryState();
                state.BasePath = ResolveBasePath(state.BasePath);
                state.Entries = state.Entries ?? new List<HistoryEntry>();
                return state;
            }
            catch (Exception ex)
            {
                _logger.Error("Failed to read history entries.", ex);
                return new HistoryState { BasePath = ResolveBasePath(string.Empty) };
            }
        }

        if (File.Exists(AppPaths.LegacyHistoryPath))
        {
            return MigrateLegacyHistory();
        }

        var empty = new HistoryState { BasePath = ResolveBasePath(string.Empty) };
        SaveState(empty);
        return empty;
    }

    private void SaveState(HistoryState state)
    {
        AppPaths.EnsureDirectories();
        var json = JsonSerializer.Serialize(state, JsonOptions.Default);
        File.WriteAllText(AppPaths.HistoryPath, json);
    }

    private HistoryState MigrateLegacyHistory()
    {
        try
        {
            var legacy = ReadLegacyEntries();
            var state = new HistoryState
            {
                BasePath = ResolveBasePath(legacy.BasePath),
                Entries = legacy.Entries
            };
            SaveState(state);

            var backupPath = AppPaths.LegacyHistoryPath + ".bak";
            File.Move(AppPaths.LegacyHistoryPath, backupPath, true);

            return state;
        }
        catch (Exception ex)
        {
            _logger.Error("Failed to migrate legacy history.", ex);
            return new HistoryState { BasePath = ResolveBasePath(string.Empty) };
        }
    }

    private LegacyReadResult ReadLegacyEntries()
    {
        var entries = new List<HistoryEntry>();
        string? basePath = null;
        var bytes = File.ReadAllBytes(AppPaths.LegacyHistoryPath);
        if (bytes.Length == 0)
        {
            return new LegacyReadResult(entries, basePath ?? string.Empty);
        }

        var options = new JsonReaderOptions
        {
            AllowTrailingCommas = true,
            CommentHandling = JsonCommentHandling.Skip,
            AllowMultipleValues = true
        };
        var reader = new Utf8JsonReader(bytes, isFinalBlock: true, state: new JsonReaderState(options));

        while (reader.Read())
        {
            if (reader.TokenType != JsonTokenType.StartObject)
            {
                continue;
            }

            using var doc = JsonDocument.ParseValue(ref reader);
            var entry = ParseLegacyEntry(doc.RootElement, ref basePath);
            if (entry is not null)
            {
                entries.Add(entry);
            }
        }

        return new LegacyReadResult(entries, basePath ?? string.Empty);
    }

    private static HistoryEntry? ParseLegacyEntry(JsonElement element, ref string? basePath)
    {
        var entry = element.Deserialize<HistoryEntry>(JsonOptions.Default);
        if (entry is null)
        {
            return null;
        }

        if (!string.IsNullOrWhiteSpace(entry.FileName))
        {
            return entry;
        }

        if (element.TryGetProperty("localPath", out var localPathProp))
        {
            var localPath = localPathProp.GetString();
            if (!string.IsNullOrWhiteSpace(localPath))
            {
                basePath ??= Path.GetDirectoryName(localPath);
                return new HistoryEntry
                {
                    At = entry.At,
                    Key = entry.Key,
                    FileName = Path.GetFileName(localPath),
                    Result = entry.Result
                };
            }
        }

        return entry;
    }

    private readonly record struct LegacyReadResult(List<HistoryEntry> Entries, string BasePath);

    private static string ResolveBasePath(string basePath)
    {
        if (!string.IsNullOrWhiteSpace(basePath))
        {
            return basePath;
        }

        return AppPaths.CacheRoot;
    }
}

