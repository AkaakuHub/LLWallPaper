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
        AppPaths.EnsureDirectories();
        var line = JsonSerializer.Serialize(entry, JsonOptions.Default);
        File.AppendAllText(AppPaths.HistoryPath, line + Environment.NewLine);
    }

    public IReadOnlyList<string> GetRecentKeys(int count)
    {
        if (!File.Exists(AppPaths.HistoryPath) || count <= 0)
        {
            return Array.Empty<string>();
        }

        try
        {
            var lines = File.ReadLines(AppPaths.HistoryPath)
                .Reverse()
                .Take(count)
                .Select(line => JsonSerializer.Deserialize<HistoryEntry>(line, JsonOptions.Default))
                .Where(entry => entry is not null)
                .Select(entry => entry!.Key)
                .ToList();

            return lines;
        }
        catch (Exception ex)
        {
            _logger.Error("Failed to read history.", ex);
            return Array.Empty<string>();
        }
    }

    public IReadOnlyList<HistoryEntry> GetRecentEntries(int count)
    {
        if (!File.Exists(AppPaths.HistoryPath) || count <= 0)
        {
            return Array.Empty<HistoryEntry>();
        }

        try
        {
            return File.ReadLines(AppPaths.HistoryPath)
                .Reverse()
                .Take(count)
                .Select(line => JsonSerializer.Deserialize<HistoryEntry>(line, JsonOptions.Default))
                .Where(entry => entry is not null)
                .Select(entry => entry!)
                .ToList();
        }
        catch (Exception ex)
        {
            _logger.Error("Failed to read history entries.", ex);
            return Array.Empty<HistoryEntry>();
        }
    }
}

