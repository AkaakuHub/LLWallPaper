using System;
using System.Diagnostics;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.Services;

public sealed class CardDetailLinkService
{
    private readonly Func<string> _baseUrlProvider;
    private readonly AppLogger _logger;

    public CardDetailLinkService(Func<string> baseUrlProvider, AppLogger logger)
    {
        _baseUrlProvider = baseUrlProvider;
        _logger = logger;
    }

    public bool TryOpen(string key, out string errorMessage)
    {
        errorMessage = string.Empty;
        if (string.IsNullOrWhiteSpace(key))
        {
            errorMessage = "No card selected.";
            return false;
        }

        var baseUrl = _baseUrlProvider?.Invoke() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(baseUrl))
        {
            errorMessage = "Base URL is empty.";
            return false;
        }

        if (!Uri.TryCreate(baseUrl.Trim(), UriKind.Absolute, out var baseUri))
        {
            errorMessage = "Base URL is invalid.";
            return false;
        }

        var safeKey = Uri.EscapeDataString(key);
        var detailUri = new Uri(baseUri, $"card/{safeKey}");

        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = detailUri.ToString(),
                UseShellExecute = true
            });
            return true;
        }
        catch (Exception ex)
        {
            _logger.Error("Failed to open card detail URL.", ex);
            errorMessage = "Failed to open browser.";
            return false;
        }
    }
}
