/* Live search suggestions for Rofi 2.x. Network work runs in a cancellable helper. */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <gio/gio.h>
#include <rofi/mode-private.h>

/* Rofi exports these view functions, but does not install view.h. */
typedef struct RofiViewState RofiViewState;
extern RofiViewState *rofi_view_get_active(void);
extern const char *rofi_view_get_user_input(const RofiViewState *state);
extern void rofi_view_reload(void);
extern void rofi_view_set_selected_line(RofiViewState *state, unsigned int line);

typedef struct {
    char *query;
    GPtrArray *rows;
    GSubprocess *process;
    guint timer;
    guint generation;
    gint64 changed;
    gint64 started;
    gboolean pending;
} State;

typedef struct {
    Mode *mode;
    guint generation;
    char *query;
} Request;

static void cancel_request(State *s) {
    s->generation++;
    if (s->process) {
        g_subprocess_force_exit(s->process);
        g_clear_object(&s->process);
    }
}

static void received(GObject *object, GAsyncResult *result, gpointer data) {
    Request *request = data;
    State *s = mode_get_private_data(request->mode);
    char *output = NULL;
    gboolean ok = g_subprocess_communicate_utf8_finish(
        G_SUBPROCESS(object), result, &output, NULL, NULL);
    RofiViewState *view = rofi_view_get_active();
    if (s && s->generation == request->generation) {
        g_clear_object(&s->process);
        /* Compare actual input as well: the user may have typed since our tick. */
        if (ok && view && g_subprocess_get_successful(G_SUBPROCESS(object)) &&
            g_strcmp0(rofi_view_get_user_input(view), request->query) == 0) {
            g_ptr_array_set_size(s->rows, 0);
            char **lines = g_strsplit(output ? output : "", "\n", -1);
            for (guint i = 0; lines[i] && s->rows->len < 6; i++) {
                if (*lines[i] && g_utf8_validate(lines[i], -1, NULL))
                    g_ptr_array_add(s->rows, g_strdup(lines[i]));
            }
            g_strfreev(lines);
            rofi_view_reload();
        }
    }
    g_free(output);
    g_free(request->query);
    g_free(request);
}

static gboolean tick(gpointer data) {
    Mode *mode = data;
    State *s = mode_get_private_data(mode);
    RofiViewState *view = rofi_view_get_active();
    if (!view) return G_SOURCE_CONTINUE;
    const char *input = rofi_view_get_user_input(view);
    if (!input) input = "";
    if (s->process && g_get_monotonic_time() - s->started > 2500000)
        cancel_request(s); /* Includes DNS stalls beyond the helper's socket timeout. */
    if (g_strcmp0(input, s->query) != 0) {
        cancel_request(s);
        g_free(s->query);
        s->query = g_strdup(input);
        g_ptr_array_set_size(s->rows, 0);
        s->changed = g_get_monotonic_time();
        s->pending = g_utf8_strlen(input, -1) >= 2 && strlen(input) <= 2048;
        rofi_view_reload();
        rofi_view_set_selected_line(view, 0);
    }
    if (s->pending && g_get_monotonic_time() - s->changed >= 300000) {
        s->pending = FALSE;
        const char *helper = g_getenv("ROFI_SEARCH_HELPER");
        if (!helper) return G_SOURCE_CONTINUE;
        const char *provider = g_getenv("ROFI_SEARCH_PROVIDER");
        s->process = g_subprocess_new(G_SUBPROCESS_FLAGS_STDOUT_PIPE |
                                     G_SUBPROCESS_FLAGS_STDERR_SILENCE,
                                     NULL, "python3", helper, s->query,
                                     provider ? provider : "duckduckgo", NULL);
        if (s->process) {
            s->started = g_get_monotonic_time();
            Request *request = g_new0(Request, 1);
            request->mode = mode;
            request->generation = s->generation;
            request->query = g_strdup(s->query);
            g_subprocess_communicate_utf8_async(s->process, NULL, NULL, received, request);
        }
    }
    return G_SOURCE_CONTINUE;
}

static int init(Mode *mode) {
    State *s = g_new0(State, 1);
    s->query = g_strdup("");
    s->rows = g_ptr_array_new_with_free_func(g_free);
    mode_set_private_data(mode, s);
    s->timer = g_timeout_add(40, tick, mode);
    return TRUE;
}

static void destroy(Mode *mode) {
    State *s = mode_get_private_data(mode);
    if (!s) return;
    g_source_remove(s->timer);
    cancel_request(s);
    mode_set_private_data(mode, NULL);
    g_ptr_array_free(s->rows, TRUE);
    g_free(s->query);
    g_free(s);
}

static unsigned int count(const Mode *mode) {
    State *s = mode_get_private_data(mode);
    return s->rows->len;
}

static int match(const Mode *mode, rofi_int_matcher **tokens, unsigned int index) {
    (void)mode; (void)tokens; (void)index;
    return TRUE; /* The provider supplies ranking; don't fuzzy-filter it again. */
}

static char *display(const Mode *mode, unsigned int index, int *state,
                     GList **attributes, int get_entry) {
    (void)state; (void)attributes;
    if (!get_entry) return NULL;
    State *s = mode_get_private_data(mode);
    return index < s->rows->len ? g_strdup(g_ptr_array_index(s->rows, index)) : NULL;
}

static char *completion(const Mode *mode, unsigned int index) {
    State *s = mode_get_private_data(mode);
    return g_strdup(index < s->rows->len
                    ? g_ptr_array_index(s->rows, index) : s->query);
}

static ModeMode result(Mode *mode, int flags, char **input, unsigned int index) {
    State *s = mode_get_private_data(mode);
    if (flags & (MENU_OK | MENU_CUSTOM_INPUT)) {
        const char *query = input && *input ? *input : "";
        /* Never accept an old suggestion during the interval before a tick. */
        if ((flags & MENU_OK) && !(flags & MENU_CUSTOM_INPUT) &&
            index < s->rows->len && g_strcmp0(query, s->query) == 0)
            query = g_ptr_array_index(s->rows, index);
        if (*query) {
            puts(query);
            fflush(stdout);
        }
    }
    return MODE_EXIT;
}

G_MODULE_EXPORT Mode mode = {
    .abi_version = ABI_VERSION,
    .name = "search-suggestions",
    ._init = init,
    ._destroy = destroy,
    ._get_num_entries = count,
    ._result = result,
    ._token_match = match,
    ._get_display_value = display,
    ._get_completion = completion,
    .type = MODE_TYPE_SWITCHER,
};
