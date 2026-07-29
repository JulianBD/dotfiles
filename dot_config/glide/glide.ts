// Config docs:
//
//   https://glide-browser.app/config
//
// API reference:
//
//   https://glide-browser.app/api
//
// Default config files can be found here:
//
//   https://github.com/glide-browser/glide/tree/main/src/glide/browser/base/content/plugins
//
// Most default keymappings are defined here:
//
//   https://github.com/glide-browser/glide/blob/main/src/glide/browser/base/content/plugins/keymaps.mts
//
// Try typing `glide.` and see what you can do!

glide.o.hint_size = "15px";

// Disable HTTP/3 (QUIC over UDP/443). The corporate Zscaler proxy doesn't pass
// QUIC through, so every request stalls waiting for a QUIC timeout before
// falling back to TCP -- pages load slowly, if at all. Forcing TCP avoids the
// stall. Requires a browser restart to take effect.
glide.prefs.set("network.http.http3.enable", false);
glide.prefs.set("network.http.altsvc.enabled", false);