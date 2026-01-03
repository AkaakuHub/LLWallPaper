using System.Text.Json.Serialization;

namespace LLWallPaper.App.Models;

public sealed class CardItem
{
    public string Id { get; init; } = "";
    public string Name { get; init; } = "";
    public string ImageUrl { get; init; } = "";
    public string? ThumbnailUrl { get; init; }
}

public sealed class Settings
{
    [JsonPropertyName("backendBaseUrl")]
    public string BackendBaseUrl { get; set; } = "http://127.0.0.1:3000";

    [JsonPropertyName("autoRotateEnabled")]
    public bool AutoRotateEnabled { get; set; } = true;

    [JsonPropertyName("rotateIntervalMinutes")]
    public int RotateIntervalMinutes { get; set; } = 15;

    [JsonPropertyName("rotateOnAppStart")]
    public bool RotateOnAppStart { get; set; } = true;

    [JsonPropertyName("recentExcludeCount")]
    public int RecentExcludeCount { get; set; } = 30;

    [JsonPropertyName("preferFavorites")]
    public bool PreferFavorites { get; set; } = true;

    [JsonPropertyName("excludeBlocked")]
    public bool ExcludeBlocked { get; set; } = true;

    [JsonPropertyName("excludeThirdEvolution")]
    public bool ExcludeThirdEvolution { get; set; } = false;

    [JsonPropertyName("startWithWindows")]
    public bool StartWithWindows { get; set; } = false;

    [JsonPropertyName("startMinimized")]
    public bool StartMinimized { get; set; } = false;

    [JsonPropertyName("cacheMaxMb")]
    public int CacheMaxMb { get; set; } = 2048;

    [JsonPropertyName("historyMaxEntries")]
    public int HistoryMaxEntries { get; set; } = 100;
}

public sealed class Favorites
{
    [JsonPropertyName("favorites")]
    public List<string> FavoriteKeys { get; set; } = new();

    [JsonPropertyName("blocked")]
    public List<string> BlockedKeys { get; set; } = new();
}

public sealed class HistoryEntry
{
    public DateTimeOffset At { get; init; } = DateTimeOffset.UtcNow;
    public string Key { get; init; } = "";
    public string FileName { get; init; } = "";
    public string Result { get; init; } = "ok";
}

public sealed class HistoryState
{
    [JsonPropertyName("basePath")]
    public string BasePath { get; set; } = "";

    [JsonPropertyName("entries")]
    public List<HistoryEntry> Entries { get; set; } = new();
}

