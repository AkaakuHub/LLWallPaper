import Foundation
import ServiceManagement

@MainActor
public final class StartupService {
  public init() {}

  public func isEnabled() -> Bool {
    SMAppService.mainApp.status == .enabled
  }

  public func setEnabled(_ enabled: Bool) throws {
    if enabled {
      if SMAppService.mainApp.status != .enabled {
        try SMAppService.mainApp.register()
      }
    } else if SMAppService.mainApp.status == .enabled {
      try SMAppService.mainApp.unregister()
    }
  }
}
