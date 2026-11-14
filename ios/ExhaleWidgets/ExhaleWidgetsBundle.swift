import SwiftUI
import WidgetKit

/// Exhale's widgets, Live Activity and controls. Filled in by the Lock Screen
/// presence plan (Tasks 11 to 13).
@main
struct ExhaleWidgetsBundle: WidgetBundle {
  var body: some Widget {
    PlaceholderWidget()
  }
}

/// Keeps the bundle valid until the first real widget lands; shows nothing.
struct PlaceholderWidget: Widget {
  var body: some WidgetConfiguration {
    EmptyWidgetConfiguration()
  }
}
