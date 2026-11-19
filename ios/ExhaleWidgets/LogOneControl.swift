import AppIntents
import SwiftUI
import WidgetKit

/// Log one in Control Center, on the Lock Screen and on the Action Button.
@available(iOS 18, *)
struct LogOneControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "LogOne") {
      ControlWidgetButton(action: LogOneIntent()) {
        Label("Log one", systemImage: "plus")
      }
    }
    .displayName("Log one")
    .description("Logs one now, without opening Exhale.")
  }
}
