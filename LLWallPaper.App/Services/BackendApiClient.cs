using System.Net.Http;
using System.Text.Json;
using LLWallPaper.App.Models;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.Services;

public sealed class BackendApiClient : IBackendApiClient
{
    private readonly HttpClient _httpClient;
    private readonly Func<string> _baseUrlProvider;
    private readonly AppLogger _logger;

    public BackendApiClient(HttpClient httpClient, Func<string> baseUrlProvider, AppLogger logger)
    {
        _httpClient = httpClient;
        _baseUrlProvider = baseUrlProvider;
        _logger = logger;
    }

    public async Task<IReadOnlyList<CardItem>> GetCardsAsync(CancellationToken cancellationToken)
    {
        var baseUrl = _baseUrlProvider()?.TrimEnd('/') ?? string.Empty;
        if (string.IsNullOrWhiteSpace(baseUrl))
        {
            throw new InvalidOperationException("Backend base URL is empty.");
        }

        try
        {
            var requestUrl = $"{baseUrl}/api/card-illustrations";
            using var response = await _httpClient.GetAsync(requestUrl, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException(
                    $"Backend returned {response.StatusCode} for {requestUrl}."
                );
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var doc = await JsonDocument.ParseAsync(
                stream,
                cancellationToken: cancellationToken
            );
            if (doc.RootElement.ValueKind == JsonValueKind.Array)
            {
                return ParseArray(doc.RootElement, baseUrl);
            }

            if (
                doc.RootElement.TryGetProperty("cards", out var cards)
                && cards.ValueKind == JsonValueKind.Array
            )
            {
                return ParseArray(cards, baseUrl);
            }
        }
        catch (Exception ex)
        {
            _logger.Error("Failed to fetch cards from backend.", ex);
            throw;
        }
        return Array.Empty<CardItem>();
    }

    private static IReadOnlyList<CardItem> ParseArray(JsonElement array, string baseUrl)
    {
        var list = new List<CardItem>();
        foreach (var element in array.EnumerateArray())
        {
            if (!element.TryGetProperty("id", out var idProp))
            {
                continue;
            }

            var id = idProp.ValueKind switch
            {
                JsonValueKind.String => idProp.GetString() ?? string.Empty,
                JsonValueKind.Number => idProp.GetRawText(),
                _ => idProp.GetRawText(),
            };
            if (string.IsNullOrWhiteSpace(id))
            {
                continue;
            }

            var name = element.TryGetProperty("name", out var nameProp)
                ? nameProp.GetString() ?? id
                : id;
            var hasFull = HasAssetFlag(element, "full");
            if (!hasFull)
            {
                continue;
            }

            var imageUrl = $"{baseUrl}/api/card-illustrations/image/{id}?type=full";
            var thumbUrl = $"{baseUrl}/api/card-illustrations/image/{id}?type=half";

            list.Add(
                new CardItem
                {
                    Id = id,
                    Name = name,
                    ImageUrl = imageUrl,
                    ThumbnailUrl = thumbUrl,
                }
            );
        }

        return list;
    }

    private static bool HasAssetFlag(JsonElement element, string key)
    {
        if (!element.TryGetProperty("assets", out var assets))
        {
            return false;
        }

        if (!assets.TryGetProperty("images", out var images))
        {
            return false;
        }

        if (!images.TryGetProperty(key, out var flag))
        {
            return false;
        }

        return flag.ValueKind switch
        {
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.String => bool.TryParse(flag.GetString(), out var parsed) && parsed,
            _ => false,
        };
    }
}
