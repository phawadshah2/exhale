import SwiftUI
import WidgetKit

/// Exhale's widgets, Live Activity and controls (Lock Screen presence plan,
/// Tasks 11 to 13).
@main
struct ExhaleWidgetsBundle: WidgetBundle {
  var body: some Widget {
    LockScreenWidget()
    TodayWidget()
    CountdownWidget()
    WhyWidget()
    MonthWidget()
    WeekWidget()
    CountdownActivity()
    if #available(iOS 18, *) {
      LogOneControl()
    }
  }
}
