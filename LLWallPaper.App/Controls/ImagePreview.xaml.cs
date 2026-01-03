using System.Windows;

namespace LLWallPaper.App.Controls;

public partial class ImagePreview : System.Windows.Controls.UserControl
{
    public static readonly DependencyProperty ImagePathProperty = DependencyProperty.Register(
        nameof(ImagePath),
        typeof(string),
        typeof(ImagePreview),
        new PropertyMetadata(string.Empty));

    public ImagePreview()
    {
        InitializeComponent();
    }

    public string ImagePath
    {
        get => (string)GetValue(ImagePathProperty);
        set => SetValue(ImagePathProperty, value);
    }
}
