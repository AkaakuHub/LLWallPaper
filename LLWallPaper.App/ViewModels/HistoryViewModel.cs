using System.Collections.ObjectModel;
using System.Linq;
using LLWallPaper.App.Models;
using LLWallPaper.App.Stores;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.ViewModels;

public sealed class HistoryViewModel : ViewModelBase
{
    private readonly HistoryStore _historyStore;
    private string _basePath = string.Empty;
    private string _statusMessage = "Ready";
    private bool _isBusy;

    public HistoryViewModel(HistoryStore historyStore)
    {
        _historyStore = historyStore;
        Items = new ObservableCollection<HistoryEntry>();
        Items.CollectionChanged += (_, _) => RaisePropertyChanged(nameof(TotalCount));
        RefreshCommand = new RelayCommand(_ => Refresh(), _ => !IsBusy);
    }

    public ObservableCollection<HistoryEntry> Items { get; }

    public int TotalCount => Items.Count;

    public string BasePath
    {
        get => _basePath;
        set => SetProperty(ref _basePath, value);
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

    public void Refresh()
    {
        IsBusy = true;
        try
        {
            Items.Clear();
            var state = _historyStore.GetState();
            BasePath = state.BasePath;
            var entries = state.Entries
                .OrderByDescending(entry => entry.At)
                .ToList();

            foreach (var entry in entries)
            {
                Items.Add(entry);
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
}
