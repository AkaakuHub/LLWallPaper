using LLWallPaper.App.Models;
using LLWallPaper.App.Services;
using LLWallPaper.App.Stores;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.ViewModels;

public sealed class SettingsViewModel : ViewModelBase
{
    private readonly SettingsStore _settingsStore;
    private readonly WallpaperScheduler _scheduler;
    private readonly StartupRegistryService _startupRegistryService;
    private readonly HistoryStore _historyStore;
    private readonly Settings _settings;

    public SettingsViewModel(
        Settings settings,
        SettingsStore settingsStore,
        WallpaperScheduler scheduler,
        StartupRegistryService startupRegistryService,
        HistoryStore historyStore
    )
    {
        _settings = settings;
        _settingsStore = settingsStore;
        _scheduler = scheduler;
        _startupRegistryService = startupRegistryService;
        _historyStore = historyStore;
        SaveCommand = new RelayCommand(_ => Save());
    }

    public string BackendBaseUrl
    {
        get => _settings.BackendBaseUrl;
        set
        {
            if (_settings.BackendBaseUrl != value)
            {
                _settings.BackendBaseUrl = value;
                RaisePropertyChanged();
            }
        }
    }

    public bool AutoRotateEnabled
    {
        get => _settings.AutoRotateEnabled;
        set
        {
            if (_settings.AutoRotateEnabled != value)
            {
                _settings.AutoRotateEnabled = value;
                RaisePropertyChanged();
            }
        }
    }

    public int RotateIntervalMinutes
    {
        get => _settings.RotateIntervalMinutes;
        set
        {
            if (_settings.RotateIntervalMinutes != value)
            {
                _settings.RotateIntervalMinutes = value;
                RaisePropertyChanged();
            }
        }
    }

    public bool RotateOnAppStart
    {
        get => _settings.RotateOnAppStart;
        set
        {
            if (_settings.RotateOnAppStart != value)
            {
                _settings.RotateOnAppStart = value;
                RaisePropertyChanged();
            }
        }
    }

    public int RecentExcludeCount
    {
        get => _settings.RecentExcludeCount;
        set
        {
            if (_settings.RecentExcludeCount != value)
            {
                _settings.RecentExcludeCount = value;
                RaisePropertyChanged();
            }
        }
    }

    public bool PreferFavorites
    {
        get => _settings.PreferFavorites;
        set
        {
            if (_settings.PreferFavorites != value)
            {
                _settings.PreferFavorites = value;
                RaisePropertyChanged();
            }
        }
    }

    public bool ExcludeBlocked
    {
        get => _settings.ExcludeBlocked;
        set
        {
            if (_settings.ExcludeBlocked != value)
            {
                _settings.ExcludeBlocked = value;
                RaisePropertyChanged();
            }
        }
    }

    public bool ExcludeThirdEvolution
    {
        get => _settings.ExcludeThirdEvolution;
        set
        {
            if (_settings.ExcludeThirdEvolution != value)
            {
                _settings.ExcludeThirdEvolution = value;
                RaisePropertyChanged();
            }
        }
    }

    public bool StartWithWindows
    {
        get => _settings.StartWithWindows;
        set
        {
            if (_settings.StartWithWindows != value)
            {
                _settings.StartWithWindows = value;
                RaisePropertyChanged();
            }
        }
    }

    public bool StartMinimized
    {
        get => _settings.StartMinimized;
        set
        {
            if (_settings.StartMinimized != value)
            {
                _settings.StartMinimized = value;
                RaisePropertyChanged();
            }
        }
    }

    public int CacheMaxMb
    {
        get => _settings.CacheMaxMb;
        set
        {
            if (_settings.CacheMaxMb != value)
            {
                _settings.CacheMaxMb = value;
                RaisePropertyChanged();
            }
        }
    }

    public int HistoryMaxEntries
    {
        get => _settings.HistoryMaxEntries;
        set
        {
            if (_settings.HistoryMaxEntries != value)
            {
                _settings.HistoryMaxEntries = value;
                RaisePropertyChanged();
            }
        }
    }

    public RelayCommand SaveCommand { get; }

    private void Save()
    {
        _settingsStore.Save(_settings);
        _historyStore.TrimToMax(_settings.HistoryMaxEntries);
        System.Windows.MessageBox.Show("Settings saved.", "LLWallPaper");
        var exePath = _startupRegistryService.ResolveExecutablePath();
        if (_settings.StartWithWindows)
        {
            _startupRegistryService.Enable(exePath);
        }
        else
        {
            _startupRegistryService.Disable();
        }
        if (_settings.AutoRotateEnabled)
        {
            if (!_scheduler.IsRunning)
            {
                _scheduler.Start();
            }
            else
            {
                _scheduler.UpdateInterval();
            }
        }
        else
        {
            _scheduler.Stop();
        }
    }
}
