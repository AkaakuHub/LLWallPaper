using System.Net.Http;
using System.Reflection;
using System.Threading.Tasks;
using System.Windows;
using LLWallPaper.App.Models;
using LLWallPaper.App.Services;
using LLWallPaper.App.Stores;
using LLWallPaper.App.Utils;
using LLWallPaper.App.ViewModels;
using Velopack;
using Velopack.Sources;
using WinForms = System.Windows.Forms;

namespace LLWallPaper.App;

public partial class App : System.Windows.Application
{
    private WinForms.NotifyIcon? _notifyIcon;
    private MainWindow? _mainWindow;
    private MainViewModel? _mainViewModel;
    private bool _isExitRequested;
    private WinForms.ToolStripMenuItem? _currentWallpaperItem;
    private AppLogger? _logger;

    [STAThread]
    public static void Main()
    {
        VelopackApp.Build().Run();
        var app = new App();
        app.InitializeComponent();
        app.Run();
    }

    protected override async void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        AppPaths.EnsureDirectories();

        var logger = new AppLogger();
        _logger = logger;
        logger.Info("Startup begin.");

        try
        {
            DispatcherUnhandledException += (_, args) =>
            {
                logger.Error("DispatcherUnhandledException", args.Exception);
                System.Windows.MessageBox.Show(args.Exception.Message, "LLWallPaper Error");
                args.Handled = true;
            };

            AppDomain.CurrentDomain.UnhandledException += (_, args) =>
            {
                if (args.ExceptionObject is Exception ex)
                {
                    logger.Error("UnhandledException", ex);
                }
            };

            TaskScheduler.UnobservedTaskException += (_, args) =>
            {
                logger.Error("UnobservedTaskException", args.Exception);
                args.SetObserved();
            };

            var settingsStore = new SettingsStore(logger);
            var settings = settingsStore.Load();
            var favoritesStore = new FavoritesStore(logger);
            var historyStore = new HistoryStore(logger);

            var handler = new HttpClientHandler();
            handler.ServerCertificateCustomValidationCallback = (_, _, _, _) => true;
            var httpClient = new HttpClient(handler);
            var backendClient = new BackendApiClient(
                httpClient,
                () => settings.BackendBaseUrl,
                logger
            );
            var catalogService = new CardCatalogService(backendClient);
            var cacheStore = new CacheStore(httpClient, logger);
            var rotationService = new RotationService();
            var desktopAdapter = DesktopWallpaperAdapter.TryCreate(logger);
            var wallpaperUseCase = new WallpaperUseCase(
                catalogService,
                rotationService,
                cacheStore,
                desktopAdapter,
                favoritesStore,
                historyStore,
                logger
            );
            var scheduler = new WallpaperScheduler(wallpaperUseCase, () => settings, logger);
            var startupRegistryService = new StartupRegistryService();
            var cardDetailLinkService = new CardDetailLinkService(
                () => settings.BackendBaseUrl,
                logger
            );

            var settingsViewModel = new SettingsViewModel(
                settings,
                settingsStore,
                scheduler,
                startupRegistryService,
                historyStore
            );
            var cardListViewModel = new CardListViewModel(
                catalogService,
                favoritesStore,
                wallpaperUseCase,
                () => settings
            );
            var historyViewModel = new HistoryViewModel(
                historyStore,
                cardDetailLinkService,
                catalogService,
                favoritesStore,
                wallpaperUseCase,
                () => settings
            );
            var mainViewModel = new MainViewModel(
                settings,
                settingsStore,
                favoritesStore,
                wallpaperUseCase,
                scheduler,
                cardListViewModel,
                settingsViewModel,
                historyViewModel,
                logger
            );

            _mainViewModel = mainViewModel;

            if (settings.StartWithWindows)
            {
                var exePath = startupRegistryService.ResolveExecutablePath();
                startupRegistryService.Enable(exePath);
            }
            else
            {
                startupRegistryService.Disable();
            }

            _mainWindow = new MainWindow { DataContext = mainViewModel };
            MainWindow = _mainWindow;
            _mainWindow.Closing += OnMainWindowClosing;
            if (settings.StartMinimized)
            {
                _mainWindow.WindowState = WindowState.Minimized;
                _mainWindow.Hide();
            }
            else
            {
                _mainWindow.Show();
            }

            InitializeTrayIcon();

            await mainViewModel.InitializeAsync();
            _ = CheckForUpdatesAsync();
            logger.Info("Startup completed.");
        }
        catch (Exception ex)
        {
            logger.Error("Startup failed.", ex);
            System.Windows.MessageBox.Show(ex.Message, "LLWallPaper Error");
            Shutdown();
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _notifyIcon?.Dispose();
        base.OnExit(e);
    }

    private void OnMainWindowClosing(object? sender, System.ComponentModel.CancelEventArgs e)
    {
        if (_isExitRequested)
        {
            return;
        }

        e.Cancel = true;
        _mainWindow?.Hide();
    }

    private void InitializeTrayIcon()
    {
        if (_mainViewModel is null)
        {
            return;
        }

        _mainViewModel.PropertyChanged += OnMainViewModelPropertyChanged;

        var menu = new WinForms.ContextMenuStrip();
        _currentWallpaperItem = new WinForms.ToolStripMenuItem();
        _currentWallpaperItem.Enabled = false;
        UpdateTrayCurrentWallpaper();

        var nextItem = new WinForms.ToolStripMenuItem("Next");
        nextItem.Click += (_, _) => _mainViewModel.NextCommand.Execute(null);

        var toggleItem = new WinForms.ToolStripMenuItem("Pause/Resume");
        toggleItem.Click += (_, _) => _mainViewModel.ToggleAutoCommand.Execute(null);

        var openItem = new WinForms.ToolStripMenuItem("Open");
        openItem.Click += (_, _) => ShowMainWindow(forceShow: true);

        var exitItem = new WinForms.ToolStripMenuItem("Exit");
        exitItem.Click += (_, _) => ExitApp();

        menu.Items.Add(_currentWallpaperItem);
        menu.Items.Add(new WinForms.ToolStripSeparator());
        menu.Items.Add(openItem);
        menu.Items.Add(nextItem);
        menu.Items.Add(toggleItem);
        menu.Items.Add(new WinForms.ToolStripSeparator());
        menu.Items.Add(exitItem);

        var exePath = new StartupRegistryService().ResolveExecutablePath();
        var appIcon = System.Drawing.Icon.ExtractAssociatedIcon(exePath);

        _notifyIcon = new WinForms.NotifyIcon
        {
            Icon = appIcon ?? System.Drawing.SystemIcons.Application,
            Visible = true,
            Text = "LLWallPaper",
        };
        _notifyIcon.ContextMenuStrip = menu;
        _notifyIcon.MouseClick += (_, args) =>
        {
            if (args.Button == WinForms.MouseButtons.Left)
            {
                ShowMainWindow(forceShow: true);
            }
        };
    }

    private void ShowMainWindow(bool forceShow)
    {
        if (_mainWindow is null)
        {
            return;
        }

        if (forceShow)
        {
            _mainWindow.WindowState = WindowState.Normal;
        }
        _mainWindow.Show();
        _mainWindow.Activate();
    }

    private void ExitApp()
    {
        _isExitRequested = true;
        _notifyIcon?.Dispose();
        if (_mainViewModel is not null)
        {
            _mainViewModel.PropertyChanged -= OnMainViewModelPropertyChanged;
        }
        _mainWindow?.Close();
        Shutdown();
    }

    private void OnMainViewModelPropertyChanged(
        object? sender,
        System.ComponentModel.PropertyChangedEventArgs e
    )
    {
        if (
            e.PropertyName == nameof(MainViewModel.CurrentCardName)
            || e.PropertyName == nameof(MainViewModel.CurrentCharacterName)
        )
        {
            UpdateTrayCurrentWallpaper();
        }
    }

    private void UpdateTrayCurrentWallpaper()
    {
        if (_currentWallpaperItem is null || _mainViewModel is null)
        {
            return;
        }

        var text =
            $"Current: {_mainViewModel.CurrentCardName} / {_mainViewModel.CurrentCharacterName}";
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.Invoke(() => _currentWallpaperItem.Text = text);
            return;
        }

        _currentWallpaperItem.Text = text;
    }

    private async Task CheckForUpdatesAsync()
    {
        try
        {
            var manager = new UpdateManager(
                new GithubSource("https://github.com/AkaakuHub/LLWallPaper", null, false, null)
            );
            if (!manager.IsInstalled)
            {
                return;
            }

            var update = await manager.CheckForUpdatesAsync();
            if (update is null)
            {
                return;
            }

            var result = System.Windows.MessageBox.Show(
                "Update available. Install now?",
                "LLWallPaper Update",
                MessageBoxButton.YesNo,
                MessageBoxImage.Question,
                MessageBoxResult.Yes
            );
            if (result != MessageBoxResult.Yes)
            {
                return;
            }

            await manager.DownloadUpdatesAsync(update);
            manager.ApplyUpdatesAndRestart(update);
        }
        catch (Exception ex)
        {
            _logger?.Error("Update check failed.", ex);
        }
    }
}
