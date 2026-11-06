// ==UserScript==
// @name         YouTube ad skipping
// @namespace    local.qutebrowser
// @version      1.0.1
// @description  Click Skip and speed up marked ads without seeking the video.
// @match        https://www.youtube.com/*
// @match        https://m.youtube.com/*
// @run-at       document-end
// @noframes
// @grant        none
// @qute-js-world main
// ==/UserScript==

// Inspired by BreadOnPenguins' yt-ads.js (jso8910 and others):
// https://github.com/BreadOnPenguins/dots/blob/master/.config/qutebrowser/greasemonkey/yt-ads.js
// Unlike that script, never seek to a very large currentTime: a stale ad flag
// could otherwise skip the real video. Only modify the marked player's video.
(() => {
    "use strict";
    // Export the toggle outside qutebrowser's userscript window proxy so
    // the ,a binding in the main world can actually reach it.
    const window = globalThis;
    if (window.top !== window.self ||
        !["www.youtube.com", "m.youtube.com"].includes(location.hostname) ||
        window.__quteYoutubeAdSkip) {
        return;
    }

    const fastRate = 16;
    const skipButtons = [
        ".ytp-ad-skip-button",
        ".ytp-ad-skip-button-modern",
        ".ytp-skip-ad-button",
        ".videoAdUiSkipButton",
    ].join(",");
    const clicked = new WeakMap();
    let enabled = true;
    let navigating = false;
    let player = null;
    let changed = null;
    let pending = null;

    function restore() {
        if (!changed) return;
        const previous = changed;
        changed = null;
        // Preserve a manual change if the user changed a value in the meantime.
        try {
            if (previous.video.playbackRate === fastRate) {
                previous.video.playbackRate = previous.rate;
            }
            if (previous.video.muted) {
                previous.video.muted = previous.muted;
            }
        } catch (_) {
            // A removed or unloaded media element may no longer accept changes.
        }
    }

    function markedAd() {
        return player && (player.classList.contains("ad-showing") ||
                          player.classList.contains("ad-interrupting"));
    }

    function visible(element) {
        const style = getComputedStyle(element);
        return element.getClientRects().length > 0 && !element.hidden &&
            style.display !== "none" && style.visibility !== "hidden" &&
            Number(style.opacity) !== 0;
    }

    const observer = new MutationObserver(schedule);
    function check() {
        if (pending !== null) clearTimeout(pending);
        pending = null;
        const current = document.getElementById("movie_player");
        if (current !== player) {
            restore();
            observer.disconnect();
            player = current;
            if (player) {
                observer.observe(player, {
                    childList: true, subtree: true, attributes: true,
                    attributeFilter: ["class", "hidden", "disabled", "aria-disabled"],
                });
            }
        }
        if (!enabled || navigating || !markedAd()) {
            restore();
            return;
        }

        for (const button of player.querySelectorAll(skipButtons)) {
            if (!button.disabled && button.getAttribute("aria-disabled") !== "true" &&
                visible(button) && performance.now() - (clicked.get(button) ?? -Infinity) > 1000) {
                clicked.set(button, performance.now());
                button.click();
                break;
            }
        }
        // Clicking Skip may synchronously switch back to the real video.
        if (!markedAd()) {
            restore();
            return;
        }

        const videos = [...player.querySelectorAll("video")];
        const video = videos.find(item => item.classList.contains("html5-main-video")) ||
            (videos.length === 1 ? videos[0] : null);
        if (!video || video.readyState < 1 || !visible(video)) {
            restore();
            return;
        }
        if (!changed || changed.video !== video) {
            restore();
            changed = {video, rate: video.playbackRate, muted: video.muted};
        }
        try {
            if (video.playbackRate !== fastRate) video.playbackRate = fastRate;
            if (!video.muted) video.muted = true;
        } catch (_) {
            restore();
        }
    }

    function schedule() {
        if (pending === null) pending = setTimeout(check, 100);
    }

    document.addEventListener("yt-navigate-start", () => {
        navigating = true;
        restore();
    });
    document.addEventListener("yt-navigate-finish", () => {
        navigating = false;
        schedule();
    });
    window.addEventListener("pagehide", restore);
    window.__quteYoutubeAdSkip = {
        get enabled() { return enabled; },
        toggle() {
            enabled = !enabled;
            if (enabled) check();
            else restore();
            return "YouTube ad skipping: " + (enabled ? "on" : "off");
        },
    };
    // The player can appear late or be replaced during YouTube navigation.
    setInterval(check, 500);
    check();
})();
