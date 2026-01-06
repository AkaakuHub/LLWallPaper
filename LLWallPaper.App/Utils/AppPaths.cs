using System.IO;
using System.Linq;

namespace LLWallPaper.App.Utils;

public static class AppPaths
{
    public static string Root
    {
        get
        {
            var basePath = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            return Path.Combine(basePath, "AkaakuHub", "LLWallPaper");
        }
    }

    public static string SettingsPath => Path.Combine(Root, "settings.json");
    public static string FavoritesPath => Path.Combine(Root, "favorites.json");
    public static string HistoryPath => Path.Combine(Root, "history.json");
    public static string LegacyHistoryPath => Path.Combine(Root, "history.jsonl");
    public static string LogPath => Path.Combine(Root, "logs", "app.log");
    public static string CacheRoot => Path.Combine(Root, "cache", "images");

    public static string GetCachePathForKey(string key)
    {
        if (string.IsNullOrWhiteSpace(key))
        {
            return string.Empty;
        }

        var safeId = string.Concat(key.Select(ch => char.IsLetterOrDigit(ch) ? ch : '_'));
        var fileName = $"card_{safeId}_full.webp";
        return Path.Combine(CacheRoot, fileName);
    }

    public static void EnsureDirectories()
    {
        Directory.CreateDirectory(Root);
        Directory.CreateDirectory(Path.GetDirectoryName(LogPath)!);
        Directory.CreateDirectory(CacheRoot);
    }
}

