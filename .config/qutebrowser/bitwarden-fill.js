function (login) {
    "use strict";
    if (location.href !== new URL(login.url).href) {
        return {ok: false, error: "changed-page"};
    }

    // Include accessible frames and open shadow roots. Cross-origin frames
    // remain inaccessible; never guess a text field as a password fallback.
    function inputs(root, found = []) {
        found.push(...root.querySelectorAll("input"));
        for (const element of root.querySelectorAll("*")) {
            if (element.shadowRoot) inputs(element.shadowRoot, found);
            if (element.tagName === "IFRAME") {
                try {
                    if (element.contentDocument) inputs(element.contentDocument, found);
                } catch (_) { /* Cross-origin frame. */ }
            }
        }
        return found;
    }

    function activeInput(root = document) {
        let active = root.activeElement;
        while (active && active.shadowRoot && active.shadowRoot.activeElement) {
            active = active.shadowRoot.activeElement;
        }
        if (active && active.tagName === "IFRAME") {
            try { return activeInput(active.contentDocument); } catch (_) { return null; }
        }
        return active;
    }

    function visible(input) {
        const style = input.ownerDocument.defaultView.getComputedStyle(input);
        return !input.disabled && !input.readOnly && input.type !== "hidden"
            && input.getClientRects().length > 0
            && style.visibility === "visible" && style.display !== "none" && style.opacity !== "0";
    }

    function passwordInput(input) {
        const autocomplete = input.autocomplete.toLowerCase().split(/\s+/);
        return !autocomplete.includes("new-password")
            && (input.type === "password" || autocomplete.includes("current-password"));
    }

    function usernameInput(input) {
        return ["text", "email", "tel"].includes(input.type) && !passwordInput(input)
            && !input.autocomplete.toLowerCase().split(/\s+/).includes("one-time-code");
    }

    function passwordField(all, active) {
        const passwords = all.filter(passwordInput);
        if (passwords.includes(active)) return active;
        if (active && active.form) {
            const sameForm = passwords.filter(input => input.form === active.form);
            if (sameForm.length === 1) return sameForm[0];
        }
        return passwords.length === 1 ? passwords[0] : null;
    }

    function usernameField(all, password, active) {
        const candidates = all.filter(usernameInput).filter(input => !password
            || (input.ownerDocument === password.ownerDocument
                && (!password.form || input.form === password.form)));
        const ranked = candidates.map(input => {
            const autocomplete = input.autocomplete.toLowerCase().split(/\s+/);
            let score = autocomplete.includes("username") ? 100 : 0;
            if (autocomplete.includes("email") || input.type === "email") score += 60;
            if (/user|email|login|identifier|phone/i.test(input.name + " " + input.id)) score += 40;
            if (input === active) score += 10;
            return {input, score};
        }).sort((a, b) => b.score - a.score);
        if (ranked.length === 1) return ranked[0].input;
        if (ranked.length > 1 && ranked[0].score > ranked[1].score) return ranked[0].input;
        return null;
    }

    function assign(input, value) {
        // Native setters and bubbling events also update controlled inputs
        // used by frameworks such as React. Replace existing content in full.
        const view = input.ownerDocument.defaultView;
        const setter = Object.getOwnPropertyDescriptor(view.HTMLInputElement.prototype, "value").set;
        input.focus();
        setter.call(input, value);
        input.dispatchEvent(new view.Event("input", {bubbles: true, composed: true}));
        input.dispatchEvent(new view.Event("change", {bubbles: true, composed: true}));
    }

    let all = inputs(document).filter(visible);
    const active = activeInput();
    let password = passwordField(all, active);
    const username = usernameField(all, password, active);
    if (!password && all.some(passwordInput)) return {ok: false, error: "ambiguous"};
    if (login.mode === "password" && !password) return {ok: false, error: "no-password"};
    if (login.mode === "username" || !password) {
        if (!username) return {ok: false, error: "no-fields"};
        assign(username, login.username);
        return {ok: true, filled: "username"};
    }
    if (login.mode === "login" && username && login.username) {
        assign(username, login.username);
        // Input events may synchronously replace fields in a reactive form.
        all = inputs(document).filter(visible);
        password = passwordField(all, activeInput());
        if (!password) return {ok: true, filled: "username"};
    }
    if (!passwordInput(password)) return {ok: false, error: "no-password"};
    assign(password, login.password);
    return {ok: true, filled: login.mode === "login" && username ? "login" : "password"};
}
