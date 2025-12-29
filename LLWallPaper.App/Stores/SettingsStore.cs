using System.IO;
using System.Text.Json;
using LLWallPaper.App.Models;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.Stores;

public sealed class SettingsStore
{
    private readonly AppLogger _logger;

    public SettingsStore(AppLogger logger)
    {
        _logger = logger;
    }

    public Settings Load()
    {
        AppPaths.EnsureDirectories();
        if (!File.Exists(AppPaths.SettingsPath))
        {
            var settings = new Settings();
            Save(settings);
            return settings;
        }

        try
        {
            var json = File.ReadAllText(AppPaths.SettingsPath);
            return JsonSerializer.Deserialize<Settings>(json, JsonOptions.Default) ?? new Settings();
        }
        catch (Exception ex)
        {
            _logger.Error("Failed to load settings, using defaults.", ex);
            return new Settings();
        }
    }

    public void Save(Settings settings)
    {
        AppPaths.EnsureDirectories();
        var json = JsonSerializer.Serialize(settings, JsonOptions.Default);
        File.WriteAllText(AppPaths.SettingsPath, json);
    }
}

