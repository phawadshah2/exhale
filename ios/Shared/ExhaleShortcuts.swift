import AppIntents

#if !WIDGET_EXTENSION
  /// Log one for Siri, Shortcuts, Spotlight and the Action Button.
  struct ExhaleShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
      AppShortcut(
        intent: LogOneIntent(),
        phrases: ["Log one in \(.applicationName)"],
        shortTitle: "Log one",
        systemImageName: "plus")
    }
  }
#endif
