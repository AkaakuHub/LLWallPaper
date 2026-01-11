using System.IO;
using System.Text;

namespace LLWallPaper.App.Utils;

public sealed class AppLogger
{
    private readonly object _lock = new();

    public void Info(string message) => Write("INFO", message);

    public void Error(string message, Exception? exception = null)
    {
        var extra = exception is null
            ? string.Empty
            : $" | {exception.GetType().Name}: {exception.Message}";
        Write("ERROR", message + extra);
    }

    private void Write(string level, string message)
    {
        var line = $"[{DateTimeOffset.Now:O}] {level} {message}{Environment.NewLine}";
        lock (_lock)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(AppPaths.LogPath)!);
            File.AppendAllText(AppPaths.LogPath, line, Encoding.UTF8);
        }
    }
}
