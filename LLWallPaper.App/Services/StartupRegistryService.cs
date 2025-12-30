using System.IO;
using System.Reflection;
using Microsoft.Win32;

namespace LLWallPaper.App.Services;

public sealed class StartupRegistryService
{
    private const string RunKeyPath = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
    private const string ValueName = "LLWallPaper";

    public bool IsEnabled()
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, false);
        return key?.GetValue(ValueName) is string;
    }

    public void Enable(string executablePath)
    {
        using var key = Registry.CurrentUser.CreateSubKey(RunKeyPath);
        key.SetValue(ValueName, Quote(executablePath));
    }

    public void Disable()
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, true);
        key?.DeleteValue(ValueName, false);
    }

    public string ResolveExecutablePath()
    {
        var processPath = Environment.ProcessPath;
        if (!string.IsNullOrWhiteSpace(processPath) &&
            processPath.EndsWith(".exe", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(Path.GetFileName(processPath), "dotnet.exe", StringComparison.OrdinalIgnoreCase))
        {
            return processPath;
        }

        var entryName = Assembly.GetEntryAssembly()?.GetName().Name ?? "LLWallPaper.App";
        var baseDir = AppContext.BaseDirectory;
        var candidate = Path.Combine(baseDir, $"{entryName}.exe");
        if (File.Exists(candidate))
        {
            return candidate;
        }

        var asmLocation = Assembly.GetExecutingAssembly().Location;
        if (!string.IsNullOrWhiteSpace(asmLocation) &&
            asmLocation.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
        {
            return asmLocation;
        }

        return candidate;
    }

    private static string Quote(string path) => $"\"{path}\"";
}
