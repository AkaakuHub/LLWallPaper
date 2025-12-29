using System.Net.Http;
using System.Reflection;
using System.Threading.Tasks;
using System.Windows;
using LLWallPaper.App.Models;
using LLWallPaper.App.Services;
using LLWallPaper.App.Stores;
using LLWallPaper.App.Utils;
using LLWallPaper.App.ViewModels;
using WinForms = System.Windows.Forms;

namespace LLWallPaper.App;

public partial class App : System.Windows.Application
{
    private WinForms.NotifyIcon? _notifyIcon;
    private MainWindow? _mainWindow;
    private MainViewModel? _mainViewModel;
    private bool _isExitRequested;

    protected override async void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        AppPaths.EnsureDirectories();

        var logger = new AppLogger();
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
            var backendClient = new BackendApiClient(httpClient, () => settings.BackendBaseUrl, logger);
            var catalogService = new CardCatalogService(backendClient);
            var cacheStore = new CacheStore(httpClient, logger);
            var rotationService = new RotationService();
            var desktopAdapter = DesktopWallpaperAdapter.TryCreate(logger);
            var wallpaperUseCase = new WallpaperUseCase(catalogService, rotationService, cacheStore, desktopAdapter, favoritesStore, historyStore, logger);
            var scheduler = new WallpaperScheduler(wallpaperUseCase, () => settings, logger);
            var startupRegistryService = new StartupRegistryService();

            var settingsViewModel = new SettingsViewModel(settings, settingsStore, scheduler, startupRegistryService);
            var cardListViewModel = new CardListViewModel(catalogService, favoritesStore, wallpaperUseCase, () => settings);
            var mainViewModel = new MainViewModel(settings, settingsStore, favoritesStore, wallpaperUseCase, scheduler, cardListViewModel, settingsViewModel, logger);

            _mainViewModel = mainViewModel;

            if (settings.StartWithWindows)
            {
                var exePath = System.Reflection.Assembly.GetExecutingAssembly().Location;
                startupRegistryService.Enable(exePath);
            }
            else
            {
                startupRegistryService.Disable();
            }

            _mainWindow = new MainWindow
            {
                DataContext = mainViewModel
            };
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

        var menu = new WinForms.ContextMenuStrip();
        var nextItem = new WinForms.ToolStripMenuItem("Next");
        nextItem.Click += (_, _) => _mainViewModel.NextCommand.Execute(null);

        var toggleItem = new WinForms.ToolStripMenuItem("Pause/Resume");
        toggleItem.Click += (_, _) => _mainViewModel.ToggleAutoCommand.Execute(null);

        var openItem = new WinForms.ToolStripMenuItem("Open");
        openItem.Click += (_, _) => ShowMainWindow();

        var exitItem = new WinForms.ToolStripMenuItem("Exit");
        exitItem.Click += (_, _) => ExitApp();

        menu.Items.Add(openItem);
        menu.Items.Add(nextItem);
        menu.Items.Add(toggleItem);
        menu.Items.Add(new WinForms.ToolStripSeparator());
        menu.Items.Add(exitItem);

        var exePath = Assembly.GetExecutingAssembly().Location;
        var appIcon = System.Drawing.Icon.ExtractAssociatedIcon(exePath);

        _notifyIcon = new WinForms.NotifyIcon
        {
            Icon = appIcon ?? System.Drawing.SystemIcons.Application,
            Visible = true,
            Text = "LLWallPaper"
        };
        _notifyIcon.ContextMenuStrip = menu;
        _notifyIcon.DoubleClick += (_, _) => ShowMainWindow();
    }

    private void ShowMainWindow()
    {
        if (_mainWindow is null)
        {
            return;
        }

        _mainWindow.Show();
        _mainWindow.Activate();
    }

    private void ExitApp()
    {
        _isExitRequested = true;
        _notifyIcon?.Dispose();
        _mainWindow?.Close();
        Shutdown();
    }
}

