pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: icons

  function iconFromName(iconName, fallbackName) {
    const fallback = fallbackName || "application-x-executable"
    try {
      if (iconName && typeof Quickshell !== 'undefined' && Quickshell.iconPath) {
        const p = Quickshell.iconPath(iconName, fallback)
        if (p && p !== "")
          return p
      }
    } catch (e) {

      // ignore and fall back
    }
    try {
      return Quickshell.iconPath ? (Quickshell.iconPath(fallback, true) || "") : ""
    } catch (e2) {
      return ""
    }
  }

  // Resolve icon path for a DesktopEntries appId - safe on missing entries
  function iconForAppId(appId, fallbackName) {
    const fallback = fallbackName || "application-x-executable"
    if (!appId)
      return iconFromName(fallback, fallback)
    try {
      if (typeof DesktopEntries === 'undefined' || !DesktopEntries.byId)
        return iconFromName(fallback, fallback)
      const entry = (DesktopEntries.heuristicLookup) ?
        DesktopEntries.heuristicLookup(appId) :
        DesktopEntries.byId(appId)
      const name = entry && entry.icon ? entry.icon : ""
      return iconFromName(name || fallback, fallback)
    } catch (e) {
      return iconFromName(fallback, fallback)
    }
  }
}
