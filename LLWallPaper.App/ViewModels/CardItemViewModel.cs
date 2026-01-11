using LLWallPaper.App.Models;
using LLWallPaper.App.Stores;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.ViewModels;

public sealed class CardItemViewModel : ViewModelBase
{
    private readonly FavoritesStore _favoritesStore;

    public CardItemViewModel(CardItem card, FavoritesStore favoritesStore)
    {
        Card = card;
        _favoritesStore = favoritesStore;
    }

    public CardItem Card { get; }

    public string Id => Card.Id;
    public string Name => Card.Name;
    public string ImageUrl => Card.ImageUrl;
    public string? ThumbnailUrl => Card.ThumbnailUrl;
    public string CharacterName => CharacterMap.GetNameForId(Card.Id);

    public bool IsFavorite => _favoritesStore.IsFavorite(Card.Id);
    public bool IsBlocked => _favoritesStore.IsBlocked(Card.Id);

    public void RefreshFlags()
    {
        RaisePropertyChanged(nameof(IsFavorite));
        RaisePropertyChanged(nameof(IsBlocked));
    }
}

