using System.Collections.ObjectModel;
using LLWallPaper.App.Models;
using LLWallPaper.App.Services;
using LLWallPaper.App.Stores;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.ViewModels;

public sealed class CardListViewModel : ViewModelBase
{
    private const int RetryDelaySeconds = 30;
    private const int StartupMaxAttempts = 5;

    private readonly CardCatalogService _catalogService;
    private readonly FavoritesStore _favoritesStore;
    private readonly WallpaperUseCase _wallpaperUseCase;
    private readonly Func<Settings> _settingsProvider;

    private CardItemViewModel? _selectedItem;
    private string _searchText = string.Empty;
    private string _statusMessage = string.Empty;
    private bool _isBusy;

    public CardListViewModel(
        CardCatalogService catalogService,
        FavoritesStore favoritesStore,
        WallpaperUseCase wallpaperUseCase,
        Func<Settings> settingsProvider)
    {
        _catalogService = catalogService;
        _favoritesStore = favoritesStore;
        _wallpaperUseCase = wallpaperUseCase;
        _settingsProvider = settingsProvider;

        Items = new ObservableCollection<CardItemViewModel>();
        FetchCommand = new AsyncRelayCommand(_ => FetchWithRetryAsync(0));
        ApplyCommand = new AsyncRelayCommand(_ => ApplySelectedAsync(), _ => SelectedItem is not null);
        ToggleFavoriteCommand = new RelayCommand(_ => ToggleFavorite(), _ => SelectedItem is not null);
        ToggleBlockedCommand = new RelayCommand(_ => ToggleBlocked(), _ => SelectedItem is not null);

        _catalogService.CatalogUpdated += (_, _) => ReloadItems();
    }

    public ObservableCollection<CardItemViewModel> Items { get; }

    public CardItemViewModel? SelectedItem
    {
        get => _selectedItem;
        set
        {
            SetProperty(ref _selectedItem, value);
            ApplyCommand.RaiseCanExecuteChanged();
            ToggleFavoriteCommand.RaiseCanExecuteChanged();
            ToggleBlockedCommand.RaiseCanExecuteChanged();
        }
    }

    public string SearchText
    {
        get => _searchText;
        set
        {
            SetProperty(ref _searchText, value);
            ReloadItems();
        }
    }

    public string StatusMessage
    {
        get => _statusMessage;
        set => SetProperty(ref _statusMessage, value);
    }

    public bool IsBusy
    {
        get => _isBusy;
        set => SetProperty(ref _isBusy, value);
    }

    public AsyncRelayCommand FetchCommand { get; }
    public AsyncRelayCommand ApplyCommand { get; }
    public RelayCommand ToggleFavoriteCommand { get; }
    public RelayCommand ToggleBlockedCommand { get; }

    public async Task FetchWithRetryAsync(int initialDelaySeconds = 0)
    {
        if (initialDelaySeconds > 0)
        {
            StatusMessage = "Waiting for backend...";
            await Task.Delay(TimeSpan.FromSeconds(initialDelaySeconds));
        }

        var attempts = 0;
        while (true)
        {
            attempts++;
            if (await FetchOnceAsync())
            {
                return;
            }

            if (attempts >= StartupMaxAttempts)
            {
                StatusMessage = $"Failed to connect after {StartupMaxAttempts} attempts.";
                return;
            }

            StatusMessage = $"Fetch failed. Retrying ({attempts}/{StartupMaxAttempts})...";
            await Task.Delay(TimeSpan.FromSeconds(RetryDelaySeconds));
        }
    }

    private async Task<bool> FetchOnceAsync()
    {
        IsBusy = true;
        try
        {
            await _catalogService.RefreshAsync(CancellationToken.None);
            ReloadItems();
            StatusMessage = $"Loaded {Items.Count} cards.";
            return true;
        }
        catch (Exception ex)
        {
            StatusMessage = $"Fetch failed: {ex.Message}";
            return false;
        }
        finally
        {
            IsBusy = false;
        }
    }

    private async Task ApplySelectedAsync()
    {
        if (SelectedItem is null)
        {
            return;
        }

        var settings = _settingsProvider();
        var result = await _wallpaperUseCase.ApplyCardAsync(SelectedItem.Card, settings, CancellationToken.None, "manual");
        StatusMessage = result.Message;
    }

    private void ToggleFavorite()
    {
        if (SelectedItem is null)
        {
            return;
        }

        _favoritesStore.ToggleFavorite(SelectedItem.Id);
        SelectedItem.RefreshFlags();
    }

    private void ToggleBlocked()
    {
        if (SelectedItem is null)
        {
            return;
        }

        _favoritesStore.ToggleBlocked(SelectedItem.Id);
        SelectedItem.RefreshFlags();
    }

    private void ReloadItems()
    {
        var cards = _catalogService.Search(SearchText);
        var settings = _settingsProvider();
        if (settings.ExcludeThirdEvolution)
        {
            cards = cards.Where(card => !card.Id.EndsWith("2", StringComparison.Ordinal)).ToList();
        }
        Items.Clear();
        foreach (var card in cards)
        {
            Items.Add(new CardItemViewModel(card, _favoritesStore));
        }
    }
}

