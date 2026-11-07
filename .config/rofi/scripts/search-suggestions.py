#!/usr/bin/env python3
"""Fetch public search completions; stdout is a bounded, plain-text list."""
import json
import sys
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def suggestions(query, provider="duckduckgo"):
    if provider == "youtube":
        url = "https://suggestqueries.google.com/complete/search?" + urlencode(
            {"client": "firefox", "ds": "yt", "q": query}
        )
    elif provider == "duckduckgo":
        url = "https://duckduckgo.com/ac/?" + urlencode({"q": query, "type": "list"})
    else:
        return []
    request = Request(url, headers={"User-Agent": "rofi-search/1.0"})
    with urlopen(request, timeout=2) as response:
        payload = json.loads(response.read(65537))
    # Both endpoints return [query, [completion, ...], ...].
    if not isinstance(payload, list) or len(payload) < 2 or not isinstance(payload[1], list):
        return []
    results = []
    for item in payload[1]:
        if not isinstance(item, str):
            continue
        item = " ".join(item.split())
        if item and len(item) <= 512 and item != query and item not in results:
            results.append(item)
        if len(results) == 6:
            break
    return results


if __name__ == "__main__":
    try:
        query = sys.argv[1].strip()
        if 2 <= len(query) <= 512:
            for value in suggestions(query, sys.argv[2] if len(sys.argv) > 2 else "duckduckgo"):
                print(value)
    except (OSError, ValueError, IndexError):
        pass  # Suggestions are optional; the query remains searchable.
