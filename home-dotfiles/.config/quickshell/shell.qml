import Quickshell

ShellRoot {
    VolumeOsd {}
    ScreenshotOsd {}
    Notifications { id: notifs }
    PowerMenu {}
    Bar { todoCount: todo.remaining; notifCount: notifs.count; onOpenTodo: todo.openMenu() }
    Todo { id: todo }
    SettingsCornerTrigger {}
}