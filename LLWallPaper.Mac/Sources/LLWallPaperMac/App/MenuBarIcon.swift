import AppKit

enum MenuBarIcon {
  static let image: NSImage = {
    let imageUrl = Bundle.module.url(forResource: "LLWallPaperMenuBar", withExtension: "png")!
    let image = NSImage(contentsOf: imageUrl)!
    image.size = NSSize(width: 18, height: 18)
    return image
  }()
}
