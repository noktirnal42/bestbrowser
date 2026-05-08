import Foundation
import WebKit

@MainActor
final class MediaPlaybackControlService {
    static let shared = MediaPlaybackControlService()

    private init() {}

    private func escapedString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }

    private var bootstrapScript: String {
        """
        (() => {
          if (window.__bestbrowserMediaController) { return true; }

          const state = {
            volume: 1,
            muted: false,
            siteURL: location.href
          };

          const collectRoots = () => {
            const roots = [];
            const queue = [document];
            const seen = new Set();

            while (queue.length) {
              const root = queue.shift();
              if (!root || seen.has(root)) { continue; }
              seen.add(root);
              roots.push(root);

              let descendants = [];
              try {
                descendants = Array.from(root.querySelectorAll('*'));
              } catch (_) {}

              for (const node of descendants) {
                if (node && node.shadowRoot) {
                  queue.push(node.shadowRoot);
                }
              }
            }

            return roots;
          };

          const queryAllDeep = (selector) => {
            const matches = [];
            for (const root of collectRoots()) {
              try {
                matches.push(...root.querySelectorAll(selector));
              } catch (_) {}
            }
            return matches;
          };

          const mediaNodes = () => {
            const nodes = [];
            for (const root of collectRoots()) {
              try {
                nodes.push(...root.querySelectorAll('audio,video'));
              } catch (_) {}
            }
            return nodes;
          };

          const applyToYouTubePlayers = () => {
            const candidates = [
              document.getElementById('movie_player'),
              ...queryAllDeep('.html5-video-player'),
              ...queryAllDeep('ytd-player')
            ].filter(Boolean);

            for (const candidate of candidates) {
              try {
                if (typeof candidate.setVolume === 'function') {
                  candidate.setVolume(Math.round(state.volume * 100));
                }
              } catch (_) {}

              try {
                if (state.muted && typeof candidate.mute === 'function') {
                  candidate.mute();
                } else if (!state.muted && typeof candidate.unMute === 'function') {
                  candidate.unMute();
                }
              } catch (_) {}
            }
          };

          const siteSelectors = () => {
            const url = state.siteURL || location.href;

            if (/di\\.fm/i.test(url)) {
              return {
                play: [
                  '[data-testid*="play" i]',
                  '[aria-label*="Play" i]',
                  '[title*="Play" i]',
                  'button[class*="play" i]',
                  'button[class*="listen" i]',
                  '.play-button',
                  '.btn-play',
                  '.player-play',
                  '.channel-play'
                ],
                volume: [
                  'input[type="range"][aria-label*="volume" i]',
                  'input[type="range"][name*="volume" i]',
                  '[data-testid*="volume" i] input[type="range"]',
                  'input[type="range"]'
                ],
                mute: [
                  '[aria-label*="Mute" i]',
                  '[title*="Mute" i]',
                  'button[class*="mute" i]',
                  '[data-testid*="mute" i]'
                ]
              };
            }

            if (/spotify\\.com/i.test(url)) {
              return {
                play: [
                  '[data-testid="control-button-playpause"]',
                  '[aria-label*="Play" i]',
                  '[title*="Play" i]'
                ],
                volume: [
                  '[data-testid="volume-bar"] input[type="range"]',
                  'input[type="range"][aria-label*="volume" i]',
                  'input[type="range"]'
                ],
                mute: [
                  '[data-testid="control-button-volume"]',
                  '[aria-label*="Mute" i]'
                ]
              };
            }

            if (/music\\.apple\\.com/i.test(url)) {
              return {
                play: [
                  '[data-testid*="play" i]',
                  '[aria-label*="Play" i]',
                  '[title*="Play" i]'
                ],
                volume: [
                  'input[type="range"][aria-label*="volume" i]',
                  'input[type="range"]'
                ],
                mute: [
                  '[aria-label*="Mute" i]',
                  '[title*="Mute" i]'
                ]
              };
            }

            return {
              play: [
                '[aria-label*="Play"]',
                '[title*="Play"]',
                'button[aria-label*="play" i]',
                'button[title*="play" i]',
                '.play-button',
                '.player-play',
                '.btn-play',
                '[data-testid*="play" i]'
              ],
              volume: [],
              mute: []
            };
          };

          const syncVolumeWidgets = () => {
            const selectors = siteSelectors().volume || [];
            for (const selector of selectors) {
              const nodes = queryAllDeep(selector);
              for (const node of nodes) {
                try {
                  const tag = node.tagName?.toLowerCase?.();
                  if (tag === 'input') {
                    node.value = String(state.volume);
                    node.dispatchEvent(new Event('input', { bubbles: true }));
                    node.dispatchEvent(new Event('change', { bubbles: true }));
                  } else {
                    node.value = String(state.volume);
                  }
                } catch (_) {}
              }
            }
          };

          const syncMuteWidgets = () => {
            const selectors = siteSelectors().mute || [];
            for (const selector of selectors) {
              const button = queryAllDeep(selector).find(Boolean);
              if (!button) { continue; }
              try {
                const pressed = button.getAttribute?.('aria-pressed');
                const label = (button.getAttribute?.('aria-label') || button.getAttribute?.('title') || '').toLowerCase();
                const looksMuted = pressed === 'true' || label.includes('unmute');
                if (looksMuted !== state.muted) {
                  button.click();
                }
              } catch (_) {}
            }
          };

          const apply = () => {
            for (const node of mediaNodes()) {
              try { node.volume = state.volume; } catch (_) {}
              try { node.muted = state.muted; } catch (_) {}
              try { node.defaultMuted = state.muted; } catch (_) {}
              try {
                if (state.muted) {
                  node.setAttribute('muted', '');
                } else {
                  node.removeAttribute('muted');
                }
              } catch (_) {}
            }

            if (/youtube\\.com/i.test(state.siteURL || location.href)) {
              applyToYouTubePlayers();
            }

            syncVolumeWidgets();
            syncMuteWidgets();
            try {
              if (window.Howler && typeof window.Howler.volume === 'function') {
                window.Howler.volume(state.volume);
                if (typeof window.Howler.mute === 'function') {
                  window.Howler.mute(state.muted);
                }
              }
            } catch (_) {}
          };

          const attemptPlayback = () => {
            for (const node of mediaNodes()) {
              try {
                const result = node.play?.();
                if (result && typeof result.catch === 'function') { result.catch(() => {}); }
              } catch (_) {}
            }
          };

          const kickButtons = () => {
            const selectors = siteSelectors().play;
            for (const selector of selectors) {
              const button = queryAllDeep(selector).find(Boolean);
              if (button && !button.disabled) {
                try { button.click(); } catch (_) {}
              }
            }
          };

          const refresh = () => {
            const media = mediaNodes();
            if (!media.length) {
              return { volume: state.volume, muted: state.muted, hasMedia: false };
            }
            const active = media.find((node) => !node.paused) || media[0];
            return {
              volume: typeof active.volume === 'number' ? active.volume : state.volume,
              muted: !!active.muted,
              hasMedia: true
            };
          };

          const scheduleApply = () => {
            apply();
            requestAnimationFrame(apply);
            setTimeout(apply, 150);
            setTimeout(apply, 500);
            setTimeout(apply, 1200);
            setTimeout(apply, 2200);
          };

          const observer = new MutationObserver(() => {
            scheduleApply();
          });

          setInterval(() => {
            scheduleApply();
          }, 1800);

          try {
            observer.observe(document.documentElement || document.body, {
              childList: true,
              subtree: true
            });
          } catch (_) {}

          window.__bestbrowserMediaController = {
            setState(volume, muted, shouldPlay, siteURL) {
              state.volume = Math.max(0, Math.min(1, Number(volume)));
              state.muted = !!muted;
              if (siteURL) {
                state.siteURL = String(siteURL);
              }
              scheduleApply();
              if (shouldPlay) {
                attemptPlayback();
                setTimeout(attemptPlayback, 250);
                setTimeout(kickButtons, 500);
                setTimeout(attemptPlayback, 1200);
                setTimeout(kickButtons, 1400);
              }
              return refresh();
            },
            refresh
          };

          scheduleApply();
          return true;
        })();
        """
    }

    private func escapedBool(_ value: Bool) -> String {
        value ? "true" : "false"
    }

    func installController(on webView: WKWebView) {
        webView.evaluateJavaScript(bootstrapScript, completionHandler: nil)
    }

    func applyState(
        volume: Double,
        muted: Bool,
        to webView: WKWebView,
        siteURL: String? = nil,
        attemptPlayback: Bool = false
    ) {
        let clampedVolume = min(max(volume, 0), 1)
        let siteURLValue = escapedString(siteURL ?? webView.url?.absoluteString ?? "")
        let script = """
        (() => {
          if (!window.__bestbrowserMediaController) {
            return null;
          }
          return window.__bestbrowserMediaController.setState(
            \(clampedVolume),
            \(escapedBool(muted)),
            \(escapedBool(attemptPlayback)),
            \(siteURLValue)
          );
        })();
        """

        installController(on: webView)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func refreshState(
        from webView: WKWebView,
        siteURL: String? = nil,
        completion: @escaping (_ volume: Double, _ muted: Bool, _ hasMedia: Bool) -> Void
    ) {
        let siteURLValue = escapedString(siteURL ?? webView.url?.absoluteString ?? "")
        let script = """
        (() => {
          if (!window.__bestbrowserMediaController) {
            return { volume: 1, muted: false, hasMedia: false };
          }
          const snapshot = window.__bestbrowserMediaController.refresh();
          window.__bestbrowserMediaController.setState(
            snapshot.volume,
            snapshot.muted,
            false,
            \(siteURLValue)
          );
          return window.__bestbrowserMediaController.refresh();
        })();
        """

        installController(on: webView)
        webView.evaluateJavaScript(script) { value, _ in
            let dictionary = value as? [String: Any]
            let volume = dictionary?["volume"] as? Double ?? 1
            let muted = dictionary?["muted"] as? Bool ?? false
            let hasMedia = dictionary?["hasMedia"] as? Bool ?? false
            completion(volume, muted, hasMedia)
        }
    }
}
