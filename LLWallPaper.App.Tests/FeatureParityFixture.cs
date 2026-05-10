using System.Text.Json;
using LLWallPaper.App.Models;

namespace LLWallPaper.App.Tests;

internal sealed class FeatureParityFixture
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    public SettingsFixture DefaultSettings { get; init; } = new();
    public CardFixture[] Cards { get; init; } = [];
    public SearchCaseFixture[] SearchCases { get; init; } = [];
    public RotationCaseFixture[] RotationCases { get; init; } = [];
    public BackendCaseFixture BackendCase { get; init; } = new();
    public CharacterCaseFixture[] CharacterCases { get; init; } = [];
    public SrCaseFixture[] SrCases { get; init; } = [];

    public static FeatureParityFixture Load()
    {
        var path = FindFixturePath(AppContext.BaseDirectory);
        var json = File.ReadAllText(path);
        return JsonSerializer.Deserialize<FeatureParityFixture>(json, JsonOptions)
            ?? throw new InvalidOperationException("Feature parity fixture is empty.");
    }

    private static string FindFixturePath(string startDirectory)
    {
        var directory = new DirectoryInfo(startDirectory);
        while (directory is not null)
        {
            var path = Path.Combine(
                directory.FullName,
                "tests",
                "feature-parity",
                "feature-parity.json"
            );
            if (File.Exists(path))
            {
                return path;
            }

            directory = directory.Parent;
        }

        throw new FileNotFoundException("Feature parity fixture was not found.");
    }
}

internal sealed class SettingsFixture
{
    public string BackendBaseUrl { get; init; } = "";
    public bool AutoRotateEnabled { get; init; }
    public int RotateIntervalMinutes { get; init; }
    public bool RotateOnAppStart { get; init; }
    public int RecentExcludeCount { get; init; }
    public bool PreferFavorites { get; init; }
    public bool ExcludeBlocked { get; init; }
    public bool ExcludeThirdEvolution { get; init; }
    public bool ExcludeSrCards { get; init; }
    public bool StartWithOs { get; init; }
    public bool StartMinimized { get; init; }
    public int CacheMaxMb { get; init; }
    public int HistoryMaxEntries { get; init; }
}

internal sealed class CardFixture
{
    public string Id { get; init; } = "";
    public string Name { get; init; } = "";
    public string ImageUrl { get; init; } = "";
    public string? ThumbnailUrl { get; init; }

    public CardItem ToCardItem() =>
        new()
        {
            Id = Id,
            Name = Name,
            ImageUrl = ImageUrl,
            ThumbnailUrl = ThumbnailUrl,
        };
}

internal sealed class SearchCaseFixture
{
    public string Name { get; init; } = "";
    public string Query { get; init; } = "";
    public SearchSettingsFixture Settings { get; init; } = new();
    public string[] ExpectedIds { get; init; } = [];
}

internal sealed class SearchSettingsFixture
{
    public bool ExcludeThirdEvolution { get; init; }
    public bool ExcludeSrCards { get; init; }
}

internal sealed class RotationCaseFixture
{
    public string Name { get; init; } = "";
    public RotationSettingsFixture Settings { get; init; } = new();
    public string[] FavoriteKeys { get; init; } = [];
    public string[] BlockedKeys { get; init; } = [];
    public string[] RecentKeys { get; init; } = [];
    public string? ExpectedId { get; init; }
}

internal sealed class RotationSettingsFixture
{
    public bool PreferFavorites { get; init; }
    public bool ExcludeBlocked { get; init; }
    public bool ExcludeThirdEvolution { get; init; }
    public bool ExcludeSrCards { get; init; }
}

internal sealed class BackendCaseFixture
{
    public string BaseUrl { get; init; } = "";
    public JsonElement Json { get; init; }
    public CardFixture[] ExpectedCards { get; init; } = [];
}

internal sealed class CharacterCaseFixture
{
    public string CardId { get; init; } = "";
    public string ExpectedName { get; init; } = "";
}

internal sealed class SrCaseFixture
{
    public string CardId { get; init; } = "";
    public bool Expected { get; init; }
}
