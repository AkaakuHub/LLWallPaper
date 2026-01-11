using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Media.Imaging;
using LLWallPaper.App.Models;
using LLWallPaper.App.Services;
using LLWallPaper.App.Stores;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.ViewModels;

public sealed class HistoryViewModel : ViewModelBase
{
    private readonly HistoryStore _historyStore;
    private readonly CardDetailLinkService _cardDetailLinkService;
    private readonly CardCatalogService _catalogService;
    private readonly FavoritesStore _favoritesStore;
    private readonly WallpaperUseCase _wallpaperUseCase;
    private readonly Func<Settings> _settingsProvider;
    private string _basePath = string.Empty;
    private HistoryEntry? _selectedEntry;
    private string _selectedImagePath = string.Empty;
    private bool _hasSelectedImage;
    private string _statusMessage = "Ready";
    private bool _isBusy;

    public HistoryViewModel(
        HistoryStore historyStore,
        CardDetailLinkService cardDetailLinkService,
        CardCatalogService catalogService,
        FavoritesStore favoritesStore,
        WallpaperUseCase wallpaperUseCase,
        Func<Settings> settingsProvider
    )
    {
        _historyStore = historyStore;
        _cardDetailLinkService = cardDetailLinkService;
        _catalogService = catalogService;
        _favoritesStore = favoritesStore;
        _wallpaperUseCase = wallpaperUseCase;
        _settingsProvider = settingsProvider;
        Items = new ObservableCollection<HistoryEntry>();
        Items.CollectionChanged += (_, _) => RaisePropertyChanged(nameof(TotalCount));
        RefreshCommand = new RelayCommand(_ => Refresh(), _ => !IsBusy);
        CopyImageCommand = new RelayCommand(_ => CopySelectedImage(), _ => HasSelectedImage);
        OpenDetailCommand = new RelayCommand(
            _ => OpenSelectedDetail(),
            _ => CanOpenSelectedDetail()
        );
        ApplyCommand = new AsyncRelayCommand(_ => ApplySelectedAsync(), _ => CanOperateSelected());
        ToggleFavoriteCommand = new RelayCommand(_ => ToggleFavorite(), _ => CanOperateSelected());
        ToggleBlockedCommand = new RelayCommand(_ => ToggleBlocked(), _ => CanOperateSelected());
    }

    public ObservableCollection<HistoryEntry> Items { get; }

    public int TotalCount => Items.Count;

    public string BasePath
    {
        get => _basePath;
        set
        {
            SetProperty(ref _basePath, value);
            UpdateSelectedImage();
        }
    }

    public HistoryEntry? SelectedEntry
    {
        get => _selectedEntry;
        set
        {
            SetProperty(ref _selectedEntry, value);
            UpdateSelectedImage();
            OpenDetailCommand.RaiseCanExecuteChanged();
            ApplyCommand.RaiseCanExecuteChanged();
            ToggleFavoriteCommand.RaiseCanExecuteChanged();
            ToggleBlockedCommand.RaiseCanExecuteChanged();
        }
    }

    public string SelectedImagePath
    {
        get => _selectedImagePath;
        private set => SetProperty(ref _selectedImagePath, value);
    }

    public bool HasSelectedImage
    {
        get => _hasSelectedImage;
        private set => SetProperty(ref _hasSelectedImage, value);
    }

    public string StatusMessage
    {
        get => _statusMessage;
        set => SetProperty(ref _statusMessage, value);
    }

    public bool IsBusy
    {
        get => _isBusy;
        set
        {
            if (_isBusy == value)
            {
                return;
            }

            _isBusy = value;
            RaisePropertyChanged();
            RefreshCommand.RaiseCanExecuteChanged();
        }
    }

    public RelayCommand RefreshCommand { get; }
    public RelayCommand CopyImageCommand { get; }
    public RelayCommand OpenDetailCommand { get; }
    public AsyncRelayCommand ApplyCommand { get; }
    public RelayCommand ToggleFavoriteCommand { get; }
    public RelayCommand ToggleBlockedCommand { get; }

    public void Refresh()
    {
        IsBusy = true;
        try
        {
            Items.Clear();
            var state = _historyStore.GetState();
            BasePath = state.BasePath;
            var entries = state.Entries.OrderByDescending(entry => entry.At).ToList();

            var previous = SelectedEntry;
            foreach (var entry in entries)
            {
                Items.Add(entry);
            }

            if (Items.Count > 0)
            {
                SelectedEntry = previous is null
                    ? Items[0]
                    : Items.FirstOrDefault(item =>
                        item.At == previous.At
                        && item.Key == previous.Key
                        && item.CardName == previous.CardName
                    ) ?? Items[0];
            }
            else
            {
                SelectedEntry = null;
            }

            StatusMessage = $"Loaded {Items.Count} entries.";
        }
        catch (Exception ex)
        {
            StatusMessage = $"Failed to load history: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
        }
    }

    private void CopySelectedImage()
    {
        if (!HasSelectedImage || string.IsNullOrWhiteSpace(SelectedImagePath))
        {
            StatusMessage = "No image to copy.";
            return;
        }

        try
        {
            var image = new BitmapImage();
            image.BeginInit();
            image.CacheOption = BitmapCacheOption.OnLoad;
            image.UriSource = new Uri(SelectedImagePath, UriKind.Absolute);
            image.EndInit();
            image.Freeze();
            System.Windows.Clipboard.SetImage(image);
            StatusMessage = "Image copied to clipboard.";
        }
        catch (Exception ex)
        {
            StatusMessage = $"Failed to copy image: {ex.Message}";
        }
    }

    private bool CanOperateSelected()
    {
        return _selectedEntry is not null && !string.IsNullOrWhiteSpace(_selectedEntry.Key);
    }

    private async Task ApplySelectedAsync()
    {
        if (_selectedEntry is null || string.IsNullOrWhiteSpace(_selectedEntry.Key))
        {
            StatusMessage = "No card selected.";
            return;
        }

        var card = _catalogService.Current.FirstOrDefault(item =>
            string.Equals(item.Id, _selectedEntry.Key, StringComparison.Ordinal)
        );
        if (card is null)
        {
            StatusMessage = "Card not found in catalog. Please fetch cards first.";
            return;
        }

        var settings = _settingsProvider();
        var result = await _wallpaperUseCase.ApplyCardAsync(
            card,
            settings,
            CancellationToken.None,
            "history"
        );
        StatusMessage = result.Message;
    }

    private void ToggleFavorite()
    {
        if (_selectedEntry is null || string.IsNullOrWhiteSpace(_selectedEntry.Key))
        {
            StatusMessage = "No card selected.";
            return;
        }

        _favoritesStore.ToggleFavorite(_selectedEntry.Key);
        var isFavorite = _favoritesStore.IsFavorite(_selectedEntry.Key);
        StatusMessage = isFavorite ? "Marked as favorite." : "Removed from favorites.";
    }

    private void ToggleBlocked()
    {
        if (_selectedEntry is null || string.IsNullOrWhiteSpace(_selectedEntry.Key))
        {
            StatusMessage = "No card selected.";
            return;
        }

        _favoritesStore.ToggleBlocked(_selectedEntry.Key);
        var isBlocked = _favoritesStore.IsBlocked(_selectedEntry.Key);
        StatusMessage = isBlocked ? "Marked as blocked." : "Removed from blocked.";
    }

    private void UpdateSelectedImage()
    {
        if (_selectedEntry is null || string.IsNullOrWhiteSpace(_selectedEntry.Key))
        {
            SelectedImagePath = string.Empty;
            HasSelectedImage = false;
            return;
        }

        var path = AppPaths.GetCachePathForKey(_selectedEntry.Key);
        SelectedImagePath = path;
        HasSelectedImage = File.Exists(path);
        CopyImageCommand.RaiseCanExecuteChanged();
        OpenDetailCommand.RaiseCanExecuteChanged();
    }

    private bool CanOpenSelectedDetail()
    {
        return _selectedEntry is not null && !string.IsNullOrWhiteSpace(_selectedEntry.Key);
    }

    private void OpenSelectedDetail()
    {
        if (_selectedEntry is null || string.IsNullOrWhiteSpace(_selectedEntry.Key))
        {
            StatusMessage = "No card selected.";
            return;
        }

        if (_cardDetailLinkService.TryOpen(_selectedEntry.Key, out var error))
        {
            StatusMessage = "Opened card detail.";
            return;
        }

        StatusMessage = error;
    }
}
