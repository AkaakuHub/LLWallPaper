using LLWallPaper.App.Models;
using LLWallPaper.App.Services;
using LLWallPaper.App.Stores;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.ViewModels;

public sealed class MainViewModel : ViewModelBase
{
    private readonly Settings _settings;
    private readonly SettingsStore _settingsStore;
    private readonly FavoritesStore _favoritesStore;
    private readonly WallpaperUseCase _wallpaperUseCase;
    private readonly WallpaperScheduler _scheduler;
    private readonly AppLogger _logger;

    private string _statusText = "Ready";
    private string _currentCardName = "-";
    private string _currentCharacterName = "その他";
    private string _currentCardId = "-";
    private string _currentSource = "-";
    private CardItem? _currentCard;
    private bool _currentIsFavorite;
    private bool _currentIsBlocked;

    public MainViewModel(
        Settings settings,
        SettingsStore settingsStore,
        FavoritesStore favoritesStore,
        WallpaperUseCase wallpaperUseCase,
        WallpaperScheduler scheduler,
        CardListViewModel cardListViewModel,
        SettingsViewModel settingsViewModel,
        HistoryViewModel historyViewModel,
        AppLogger logger)
    {
        _settings = settings;
        _settingsStore = settingsStore;
        _favoritesStore = favoritesStore;
        _wallpaperUseCase = wallpaperUseCase;
        _scheduler = scheduler;
        _logger = logger;

        CardList = cardListViewModel;
        Settings = settingsViewModel;
        History = historyViewModel;

        NextCommand = new AsyncRelayCommand(_ => ApplyNextAsync());
        ToggleAutoCommand = new RelayCommand(_ => ToggleAuto());
        ToggleCurrentFavoriteCommand = new RelayCommand(_ => ToggleCurrentFavorite(), _ => _currentCard is not null);
        ToggleCurrentBlockedCommand = new RelayCommand(_ => ToggleCurrentBlocked(), _ => _currentCard is not null);
        ExitCommand = new RelayCommand(_ => ExitRequested?.Invoke(this, EventArgs.Empty));

        _wallpaperUseCase.WallpaperChanged += OnWallpaperChanged;
    }

    public event EventHandler? ExitRequested;

    public CardListViewModel CardList { get; }
    public SettingsViewModel Settings { get; }
    public HistoryViewModel History { get; }

    public string StatusText
    {
        get => _statusText;
        set => SetProperty(ref _statusText, value);
    }

    public string CurrentCardName
    {
        get => _currentCardName;
        set => SetProperty(ref _currentCardName, value);
    }

    public string CurrentCardId
    {
        get => _currentCardId;
        set => SetProperty(ref _currentCardId, value);
    }

    public string CurrentCharacterName
    {
        get => _currentCharacterName;
        set => SetProperty(ref _currentCharacterName, value);
    }

    public string CurrentSource
    {
        get => _currentSource;
        set => SetProperty(ref _currentSource, value);
    }

    public bool CurrentIsFavorite
    {
        get => _currentIsFavorite;
        set => SetProperty(ref _currentIsFavorite, value);
    }

    public bool CurrentIsBlocked
    {
        get => _currentIsBlocked;
        set => SetProperty(ref _currentIsBlocked, value);
    }

    public bool IsAutoEnabled => _settings.AutoRotateEnabled;

    public AsyncRelayCommand NextCommand { get; }
    public RelayCommand ToggleAutoCommand { get; }
    public RelayCommand ToggleCurrentFavoriteCommand { get; }
    public RelayCommand ToggleCurrentBlockedCommand { get; }
    public RelayCommand ExitCommand { get; }

    public async Task InitializeAsync()
    {
        _favoritesStore.Load();
        await CardList.FetchWithRetryAsync(0);
        History.Refresh();

        if (_settings.RotateOnAppStart)
        {
            await ApplyNextAsync();
        }

        if (_settings.AutoRotateEnabled)
        {
            _scheduler.Start();
        }
    }

    private async Task ApplyNextAsync()
    {
        StatusText = "Applying next wallpaper...";
        var result = await _wallpaperUseCase.ApplyNextAsync(_settings, CancellationToken.None);
        StatusText = result.Message;
    }

    private void ToggleAuto()
    {
        _settings.AutoRotateEnabled = !_settings.AutoRotateEnabled;
        _settingsStore.Save(_settings);
        RaisePropertyChanged(nameof(IsAutoEnabled));
        if (_settings.AutoRotateEnabled)
        {
            _scheduler.Start();
            StatusText = "Auto-rotate enabled.";
        }
        else
        {
            _scheduler.Stop();
            StatusText = "Auto-rotate paused.";
        }
    }

    private void ToggleCurrentFavorite()
    {
        if (_currentCard is null)
        {
            return;
        }

        _favoritesStore.ToggleFavorite(_currentCard.Id);
        CurrentIsFavorite = _favoritesStore.IsFavorite(_currentCard.Id);
        StatusText = CurrentIsFavorite ? "Marked as favorite." : "Removed from favorites.";
    }

    private void ToggleCurrentBlocked()
    {
        if (_currentCard is null)
        {
            return;
        }

        _favoritesStore.ToggleBlocked(_currentCard.Id);
        CurrentIsBlocked = _favoritesStore.IsBlocked(_currentCard.Id);
        StatusText = CurrentIsBlocked ? "Marked as blocked." : "Removed from blocked.";
    }

    private void OnWallpaperChanged(object? sender, WallpaperChangedEventArgs e)
    {
        _currentCard = e.Card;
        CurrentCardName = e.Card.Name;
        CurrentCharacterName = CharacterMap.GetNameForId(e.Card.Id);
        CurrentCardId = e.Card.Id;
        CurrentSource = e.Reason;
        CurrentIsFavorite = _favoritesStore.IsFavorite(e.Card.Id);
        CurrentIsBlocked = _favoritesStore.IsBlocked(e.Card.Id);
        StatusText = "Wallpaper updated.";
        ToggleCurrentFavoriteCommand.RaiseCanExecuteChanged();
        ToggleCurrentBlockedCommand.RaiseCanExecuteChanged();
        History.Refresh();
    }
}

