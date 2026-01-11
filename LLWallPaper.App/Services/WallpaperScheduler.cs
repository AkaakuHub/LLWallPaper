using System.Windows.Threading;
using LLWallPaper.App.Models;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.Services;

public sealed class WallpaperScheduler
{
    private readonly DispatcherTimer _timer;
    private readonly WallpaperUseCase _useCase;
    private readonly Func<Settings> _settingsProvider;
    private readonly AppLogger _logger;

    public WallpaperScheduler(
        WallpaperUseCase useCase,
        Func<Settings> settingsProvider,
        AppLogger logger
    )
    {
        _useCase = useCase;
        _settingsProvider = settingsProvider;
        _logger = logger;
        _timer = new DispatcherTimer();
        _timer.Tick += OnTick;
    }

    public bool IsRunning => _timer.IsEnabled;

    public void Start()
    {
        var settings = _settingsProvider();
        var interval = Math.Max(1, settings.RotateIntervalMinutes);
        _timer.Interval = TimeSpan.FromMinutes(interval);
        _timer.Start();
    }

    public void Stop()
    {
        _timer.Stop();
    }

    public void UpdateInterval()
    {
        if (!_timer.IsEnabled)
        {
            return;
        }

        Start();
    }

    private async void OnTick(object? sender, EventArgs e)
    {
        try
        {
            var settings = _settingsProvider();
            if (!settings.AutoRotateEnabled)
            {
                return;
            }

            await _useCase.ApplyNextAsync(settings, CancellationToken.None);
        }
        catch (Exception ex)
        {
            _logger.Error("Scheduler tick failed.", ex);
        }
    }
}
