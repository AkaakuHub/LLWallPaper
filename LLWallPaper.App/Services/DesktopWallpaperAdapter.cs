using System.Runtime.InteropServices;
using LLWallPaper.App.Utils;

namespace LLWallPaper.App.Services;

public sealed class DesktopWallpaperAdapter
{
    private readonly IDesktopWallpaper _desktopWallpaper;

    private DesktopWallpaperAdapter(IDesktopWallpaper desktopWallpaper)
    {
        _desktopWallpaper = desktopWallpaper;
    }

    public static DesktopWallpaperAdapter? TryCreate(AppLogger logger)
    {
        try
        {
            var desktop = (IDesktopWallpaper)new DesktopWallpaper();
            return new DesktopWallpaperAdapter(desktop);
        }
        catch (COMException ex)
        {
            logger.Error("IDesktopWallpaper COM class not available.", ex);
            return null;
        }
        catch (Exception ex)
        {
            logger.Error("Failed to initialize IDesktopWallpaper.", ex);
            return null;
        }
    }

    public bool TrySetWallpaper(string fullPath, out string? error)
    {
        try
        {
            _desktopWallpaper.SetWallpaper(null, fullPath);
            error = null;
            return true;
        }
        catch (Exception ex)
        {
            error = ex.Message;
            return false;
        }
    }

    [ComImport]
    [Guid("C2CF3110-460E-4FC1-B9D0-8A1C0C9CC4BD")]
    private class DesktopWallpaper { }

    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B")]
    private interface IDesktopWallpaper
    {
        void SetWallpaper(
            [MarshalAs(UnmanagedType.LPWStr)] string? monitorID,
            [MarshalAs(UnmanagedType.LPWStr)] string wallpaper
        );

        [return: MarshalAs(UnmanagedType.LPWStr)]
        string GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID);
        void GetMonitorDevicePathAt(
            uint monitorIndex,
            [MarshalAs(UnmanagedType.LPWStr)] out string monitorID
        );
        uint GetMonitorDevicePathCount();
        void SetBackgroundColor(uint color);
        uint GetBackgroundColor();
        void SetPosition(DesktopWallpaperPosition position);
        DesktopWallpaperPosition GetPosition();
        void SetSlideshow([MarshalAs(UnmanagedType.Interface)] object items);

        [return: MarshalAs(UnmanagedType.Interface)]
        object GetSlideshow();
        void SetSlideshowOptions(DesktopSlideshowOptions options, uint slideshowTick);
        void GetSlideshowOptions(out DesktopSlideshowOptions options, out uint slideshowTick);
        void AdvanceSlideshow(
            [MarshalAs(UnmanagedType.LPWStr)] string monitorID,
            DesktopSlideshowDirection direction
        );
        DesktopSlideshowState GetStatus();
        void Enable(bool enable);
    }

    private enum DesktopWallpaperPosition
    {
        Center = 0,
        Tile = 1,
        Stretch = 2,
        Fit = 3,
        Fill = 4,
        Span = 5,
    }

    [Flags]
    private enum DesktopSlideshowOptions
    {
        None = 0,
        ShuffleImages = 0x1,
    }

    private enum DesktopSlideshowDirection
    {
        Forward = 0,
        Backward = 1,
    }

    [Flags]
    private enum DesktopSlideshowState
    {
        Enabled = 0x1,
        Slideshow = 0x2,
        DisabledByRemoteSession = 0x4,
    }
}
