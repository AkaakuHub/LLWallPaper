using System.Net;
using System.Text;
using LLWallPaper.App.Models;
using LLWallPaper.App.Services;
using LLWallPaper.App.Stores;
using LLWallPaper.App.Utils;
using LLWallPaper.App.ViewModels;

namespace LLWallPaper.App.Tests;

[TestClass]
public sealed class FeatureParityTests
{
    private static readonly HttpClient UnusedHttpClient = new();

    [TestMethod]
    public void DefaultSettingsMatchSharedFixture()
    {
        var fixture = FeatureParityFixture.Load();
        var settings = new Settings();

        Assert.AreEqual(fixture.DefaultSettings.BackendBaseUrl, settings.BackendBaseUrl);
        Assert.AreEqual(fixture.DefaultSettings.AutoRotateEnabled, settings.AutoRotateEnabled);
        Assert.AreEqual(
            fixture.DefaultSettings.RotateIntervalMinutes,
            settings.RotateIntervalMinutes
        );
        Assert.AreEqual(fixture.DefaultSettings.RotateOnAppStart, settings.RotateOnAppStart);
        Assert.AreEqual(fixture.DefaultSettings.RecentExcludeCount, settings.RecentExcludeCount);
        Assert.AreEqual(fixture.DefaultSettings.PreferFavorites, settings.PreferFavorites);
        Assert.AreEqual(fixture.DefaultSettings.ExcludeBlocked, settings.ExcludeBlocked);
        Assert.AreEqual(
            fixture.DefaultSettings.ExcludeThirdEvolution,
            settings.ExcludeThirdEvolution
        );
        Assert.AreEqual(fixture.DefaultSettings.ExcludeSrCards, settings.ExcludeSrCards);
        Assert.AreEqual(fixture.DefaultSettings.StartWithOs, settings.StartWithWindows);
        Assert.AreEqual(fixture.DefaultSettings.StartMinimized, settings.StartMinimized);
        Assert.AreEqual(fixture.DefaultSettings.CacheMaxMb, settings.CacheMaxMb);
        Assert.AreEqual(fixture.DefaultSettings.HistoryMaxEntries, settings.HistoryMaxEntries);
    }

    [TestMethod]
    public async Task CardSearchMatchesSharedFixture()
    {
        var fixture = FeatureParityFixture.Load();

        foreach (var testCase in fixture.SearchCases)
        {
            var settings = new Settings
            {
                ExcludeThirdEvolution = testCase.Settings.ExcludeThirdEvolution,
                ExcludeSrCards = testCase.Settings.ExcludeSrCards,
            };
            var catalogService = new CardCatalogService(new StubBackendApiClient(fixture.Cards));
            await catalogService.RefreshAsync(CancellationToken.None);
            var favoritesStore = new FavoritesStore(new AppLogger());
            var viewModel = new CardListViewModel(
                catalogService,
                favoritesStore,
                CreateUnusedWallpaperUseCase(catalogService, favoritesStore),
                () => settings
            )
            {
                SearchText = testCase.Query,
            };

            CollectionAssert.AreEqual(
                testCase.ExpectedIds,
                viewModel.Items.Select(item => item.Id).ToArray(),
                testCase.Name
            );
        }
    }

    [TestMethod]
    public void RotationMatchesSharedFixture()
    {
        var fixture = FeatureParityFixture.Load();
        var cards = fixture.Cards.Select(card => card.ToCardItem()).ToArray();
        var rotationService = new RotationService();

        foreach (var testCase in fixture.RotationCases)
        {
            var card = rotationService.PickNext(
                cards,
                testCase.RecentKeys,
                testCase.FavoriteKeys,
                testCase.BlockedKeys,
                testCase.Settings.PreferFavorites,
                testCase.Settings.ExcludeBlocked,
                testCase.Settings.ExcludeThirdEvolution,
                testCase.Settings.ExcludeSrCards
            );

            Assert.AreEqual(testCase.ExpectedId, card?.Id, testCase.Name);
        }
    }

    [TestMethod]
    public async Task BackendParserMatchesSharedFixture()
    {
        var fixture = FeatureParityFixture.Load();
        using var httpClient = new HttpClient(
            new StubHttpMessageHandler(
                $"{fixture.BackendCase.BaseUrl}/api/card-illustrations",
                fixture.BackendCase.Json.GetRawText()
            )
        );
        var client = new BackendApiClient(
            httpClient,
            () => fixture.BackendCase.BaseUrl,
            new AppLogger()
        );

        var cards = await client.GetCardsAsync(CancellationToken.None);

        Assert.AreEqual(fixture.BackendCase.ExpectedCards.Length, cards.Count);
        for (var i = 0; i < fixture.BackendCase.ExpectedCards.Length; i++)
        {
            var expected = fixture.BackendCase.ExpectedCards[i];
            var actual = cards[i];
            Assert.AreEqual(expected.Id, actual.Id);
            Assert.AreEqual(expected.Name, actual.Name);
            Assert.AreEqual(expected.ImageUrl, actual.ImageUrl);
            Assert.AreEqual(expected.ThumbnailUrl, actual.ThumbnailUrl);
        }
    }

    [TestMethod]
    public void CharacterMapMatchesSharedFixture()
    {
        var fixture = FeatureParityFixture.Load();

        foreach (var testCase in fixture.CharacterCases)
        {
            Assert.AreEqual(
                testCase.ExpectedName,
                CharacterMap.GetNameForId(testCase.CardId),
                testCase.CardId
            );
        }

        foreach (var testCase in fixture.SrCases)
        {
            Assert.AreEqual(
                testCase.Expected,
                CharacterMap.IsSrCard(testCase.CardId),
                testCase.CardId
            );
        }
    }

    private static WallpaperUseCase CreateUnusedWallpaperUseCase(
        CardCatalogService catalogService,
        FavoritesStore favoritesStore
    )
    {
        var logger = new AppLogger();
        return new WallpaperUseCase(
            catalogService,
            new RotationService(),
            new CacheStore(UnusedHttpClient, logger),
            null,
            favoritesStore,
            new HistoryStore(logger),
            logger
        );
    }

    private sealed class StubBackendApiClient : IBackendApiClient
    {
        private readonly IReadOnlyList<CardFixture> _cards;

        public StubBackendApiClient(IReadOnlyList<CardFixture> cards)
        {
            _cards = cards;
        }

        public Task<IReadOnlyList<CardItem>> GetCardsAsync(CancellationToken cancellationToken)
        {
            IReadOnlyList<CardItem> cards = _cards.Select(card => card.ToCardItem()).ToArray();
            return Task.FromResult(cards);
        }
    }

    private sealed class StubHttpMessageHandler : HttpMessageHandler
    {
        private readonly string _expectedRequestUrl;
        private readonly string _responseJson;

        public StubHttpMessageHandler(string expectedRequestUrl, string responseJson)
        {
            _expectedRequestUrl = expectedRequestUrl;
            _responseJson = responseJson;
        }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken
        )
        {
            Assert.AreEqual(_expectedRequestUrl, request.RequestUri?.AbsoluteUri);
            var response = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(_responseJson, Encoding.UTF8, "application/json"),
            };
            return Task.FromResult(response);
        }
    }
}
