function getItems(hibernateAvailable, suspendAvailable) {
  var items = [
    {
      id: "lock",
      icon: "",
      label: "Lock",
      detail: "Lock screen session",
      action: "omarchy-system-lock",
      hotkey: "L",
      key: "l"
    },
    {
      id: "screensaver",
      icon: "󱄄",
      label: "Screensaver",
      detail: "Launch screensaver",
      action: "omarchy-launch-screensaver force",
      hotkey: "S",
      key: "s"
    }
  ]

  if (suspendAvailable !== false) {
    items.push({
      id: "suspend",
      icon: "󰒲",
      label: "Suspend",
      detail: "Sleep to RAM",
      action: "systemctl suspend",
      hotkey: "U",
      key: "u"
    })
  }

  if (hibernateAvailable !== false) {
    items.push({
      id: "hibernate",
      icon: "󰤁",
      label: "Hibernate",
      detail: "Save session & power off",
      action: "systemctl hibernate",
      hotkey: "H",
      key: "h"
    })
  }

  items.push({
    id: "logout",
    icon: "󰍃",
    label: "Logout",
    detail: "Exit desktop session",
    action: "omarchy-system-logout",
    hotkey: "X",
    key: "x"
  })

  items.push({
    id: "reboot",
    icon: "󰜉",
    label: "Reboot",
    detail: "Restart computer",
    action: "omarchy-system-reboot",
    hotkey: "R",
    key: "r",
    accent: true
  })

  items.push({
    id: "shutdown",
    icon: "󰐥",
    label: "Shutdown",
    detail: "Power off computer",
    action: "omarchy-system-shutdown",
    hotkey: "P",
    key: "p",
    urgent: true
  })

  return items
}

if (typeof module !== "undefined") {
  module.exports = {
    getItems: getItems
  }
}
