# 11. Lock Screen presence

Draft for Fawad, 2026-11-14. Project 1 of four (then Settings redesign, notifications,
breathing). Picks agreed so far: the Live Activity goes quiet 15 min past due and keeps
the Dynamic Island; "Log one" is one Swift action shared by Siri, Shortcuts, the Action
Button, Control Center, a Lock Screen control and the widget's +; logs made outside the
app wait in a queue and widgets read a snapshot the app leaves them.

| File | Screens |
| --- | --- |
| `LockScreen.html` | v1: Live Activity (counting, quiet), Dynamic Island (compact, minimal, expanded), Lock Screen widgets, Home Screen widgets, Log one from the Action Button and Control Center. Fawad kept the Island and the Lock Screen widgets |
| `Rings-v3.html` | Fawad kept widgets 1 to 5 from v2. Four ways to add something around the ring in widgets 1 and 4: A countdown ring, B one segment per use, C the day's logs around a clock face, D words and a glow |
| `Rings-v4.html` | Fawad chose D for widgets 1 and 4, with A's countdown ring and a small counter: counting, before the first log, past the time on schedule (the wait counts up), at the limit |
| `LockScreen-v2.html` | One smaller Live Activity (timer, green bar, a changing line) counting and 15 min past due; seven Home Screen widgets: Today, Countdown, Your why (small), Today and the month, This week, Your plan (medium), Everything (large) |

Layout and content only; widget chrome and type come from WidgetKit. Emoji are stand-ins
for SF Symbols.
