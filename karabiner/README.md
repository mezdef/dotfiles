# Karabiner (kept for DriverKit virtual HID driver)

Karabiner-Elements is no longer used for key remapping — that's handled by [kanata](../kanata/).
However, Karabiner must remain installed because kanata depends on the
**Karabiner-DriverKit-VirtualHIDDevice** driver to create its virtual keyboard on macOS.

This stow package preserves the Karabiner config so it doesn't prompt for setup on launch.

If Karabiner is ever uninstalled, kanata will stop working.
