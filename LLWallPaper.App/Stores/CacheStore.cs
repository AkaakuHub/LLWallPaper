using System.IO;
using System.Net.Http;
using LLWallPaper.App.Models;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.Stores;

public sealed class CacheStore
{
    private readonly HttpClient _httpClient;
    private readonly AppLogger _logger;

    public CacheStore(HttpClient httpClient, AppLogger logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<string?> EnsureLocalAsync(CardItem card, int cacheMaxMb, IReadOnlyCollection<string> protectedPaths)
    {
        AppPaths.EnsureDirectories();
        var extension = ".webp";
        var safeId = string.Concat(card.Id.Select(ch => char.IsLetterOrDigit(ch) ? ch : '_'));
        var fileName = $"card_{safeId}_full{extension}";
        var path = Path.Combine(AppPaths.CacheRoot, fileName);

        if (File.Exists(path))
        {
            return path;
        }

        try
        {
            using var response = await _httpClient.GetAsync(card.ImageUrl);
            if (!response.IsSuccessStatusCode)
            {
                _logger.Error($"Download failed for {card.Id} with status {response.StatusCode}.");
                return null;
            }

            await using var stream = await response.Content.ReadAsStreamAsync();
            await using var fileStream = File.Create(path);
            await stream.CopyToAsync(fileStream);

            TrimCache(cacheMaxMb, protectedPaths.Append(path).ToList());
            return path;
        }
        catch (Exception ex)
        {
            _logger.Error($"Download failed for {card.Id}.", ex);
            return null;
        }
    }

    private void TrimCache(int maxMb, IReadOnlyCollection<string> protectedPaths)
    {
        var maxBytes = (long)maxMb * 1024L * 1024L;
        if (maxBytes <= 0)
        {
            return;
        }

        var dir = new DirectoryInfo(AppPaths.CacheRoot);
        if (!dir.Exists)
        {
            return;
        }

        var files = dir.GetFiles()
            .Where(file => !protectedPaths.Contains(file.FullName, StringComparer.OrdinalIgnoreCase))
            .OrderBy(file => file.LastWriteTimeUtc)
            .ToList();

        var totalBytes = dir.GetFiles().Sum(file => file.Length);
        foreach (var file in files)
        {
            if (totalBytes <= maxBytes)
            {
                break;
            }

            try
            {
                totalBytes -= file.Length;
                file.Delete();
            }
            catch (Exception ex)
            {
                _logger.Error($"Failed to delete cache file {file.FullName}.", ex);
            }
        }
    }
}
