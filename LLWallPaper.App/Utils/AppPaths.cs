using System.IO;

namespace LLWallPaper.App.Utils;

public static class AppPaths
{
    public static string Root
    {
        get
        {
            var basePath = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            return Path.Combine(basePath, "MoshiMoshi", "WallpaperApp");
        }
    }

    public static string SettingsPath => Path.Combine(Root, "settings.json");
    public static string FavoritesPath => Path.Combine(Root, "favorites.json");
    public static string HistoryPath => Path.Combine(Root, "history.jsonl");
    public static string LogPath => Path.Combine(Root, "logs", "app.log");
    public static string CacheRoot => Path.Combine(Root, "cache", "images");

    public static void EnsureDirectories()
    {
        Directory.CreateDirectory(Root);
        Directory.CreateDirectory(Path.GetDirectoryName(LogPath)!);
        Directory.CreateDirectory(CacheRoot);
    }
}

