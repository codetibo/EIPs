(function () {
  'use strict';

  var searchIndex = [];
  var searchInput = document.getElementById('eip-search-input');
  var searchResults = document.getElementById('eip-search-results');
  var searchContainer = document.getElementById('eip-search-container');

  if (!searchInput) return;

  // Fetch the search index
  fetch('/search-index.json')
    .then(function (response) { return response.json(); })
    .then(function (data) {
      searchIndex = data;
    })
    .catch(function () {
      // Index unavailable — silently degrade
    });

  // Debounce utility
  function debounce(fn, delay) {
    var timer;
    return function () {
      var context = this;
      var args = arguments;
      clearTimeout(timer);
      timer = setTimeout(function () { fn.apply(context, args); }, delay);
    };
  }

  // Tokenize and normalize a string
  function tokenize(text) {
    return (text || '')
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, ' ')
      .split(/\s+/)
      .filter(Boolean);
  }

  // Score a document against query tokens (full-content aware)
  function scoreDocument(doc, queryTokens) {
    var score = 0;
    var titleStr = (doc.title || '').toLowerCase();
    var descStr = (doc.description || '').toLowerCase();
    var contentStr = (doc.content || '').toLowerCase();
    var statusStr = (doc.status || '').toLowerCase();
    var typeStr = (doc.type || '').toLowerCase();
    var categoryStr = (doc.category || '').toLowerCase();
    var authorStr = (doc.author || '').toLowerCase();
    var eipStr = String(doc.eip || '');

    var allText = [titleStr, descStr, contentStr, statusStr, typeStr, categoryStr, authorStr, eipStr].join(' ');

    for (var t = 0; t < queryTokens.length; t++) {
      var qt = queryTokens[t];

      // EIP number match (e.g., "721", "eip-721")
      if (eipStr === qt || eipStr.indexOf(qt) !== -1) {
        score += 50;
      }

      if (titleStr.indexOf(qt) !== -1) {
        score += 20;
        if (titleStr.split(/\s+/).indexOf(qt) !== -1) score += 10;
      }

      if (descStr.indexOf(qt) !== -1) {
        score += 8;
      }

      // Full body content match — weight depends on frequency
      if (contentStr.indexOf(qt) !== -1) {
        // Count occurrences for frequency bonus (up to +10)
        var count = 0;
        var pos = -1;
        while ((pos = contentStr.indexOf(qt, pos + 1)) !== -1) { count++; }
        score += 4 + Math.min(count, 6);
      }

      if (statusStr.indexOf(qt) !== -1) score += 6;
      if (typeStr.indexOf(qt) !== -1 || categoryStr.indexOf(qt) !== -1) score += 5;
      if (authorStr.indexOf(qt) !== -1) score += 4;

      // Phrase bonus
      if (queryTokens.length > 1 && allText.indexOf(queryTokens.join(' ')) !== -1) {
        score += 15;
      }
    }
    return score;
  }

  function performSearch(query) {
    query = query.trim();
    if (!query || query.length < 2 || searchIndex.length === 0) {
      return [];
    }

    var queryTokens = tokenize(query);
    if (queryTokens.length === 0) return [];

    var results = [];
    for (var i = 0; i < searchIndex.length; i++) {
      var doc = searchIndex[i];
      var score = scoreDocument(doc, queryTokens);
      if (score > 0) {
        results.push({ doc: doc, score: score });
      }
    }

    results.sort(function (a, b) { return b.score - a.score; });
    return results.slice(0, 20);
  }

  // Highlight matching terms in text
  function highlightText(text, tokens) {
    if (!text || tokens.length === 0) return text || '';
    var escaped = (text || '');
    for (var t = 0; t < tokens.length; t++) {
      var regex = new RegExp('(' + tokens[t].replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ')', 'gi');
      escaped = escaped.replace(regex, '<mark>$1</mark>');
    }
    return escaped;
  }

  // Extract a contextual snippet from the content around the first match
  function extractContextSnippet(content, queryTokens) {
    if (!content || queryTokens.length === 0) return '';

    var lower = content.toLowerCase();
    var firstMatchPos = -1;
    var matchLen = 0;

    // Find the earliest match position across all tokens
    for (var t = 0; t < queryTokens.length; t++) {
      var pos = lower.indexOf(queryTokens[t]);
      if (pos !== -1 && (firstMatchPos === -1 || pos < firstMatchPos)) {
        firstMatchPos = pos;
        matchLen = queryTokens[t].length;
      }
    }

    if (firstMatchPos === -1) return '';

    var contextChars = 120;
    var snippetStart = Math.max(0, firstMatchPos - contextChars);
    // Align to a word boundary if possible (but don't sweat it)
    if (snippetStart > 0) {
      var spaceBefore = content.indexOf(' ', snippetStart);
      if (spaceBefore !== -1 && spaceBefore < firstMatchPos) {
        snippetStart = spaceBefore + 1;
      }
    }

    var snippetEnd = Math.min(content.length, firstMatchPos + matchLen + contextChars);
    // Extend to end of last word if possible
    if (snippetEnd < content.length) {
      var spaceAfter = content.indexOf(' ', snippetEnd);
      if (spaceAfter !== -1 && spaceAfter - snippetEnd < 40) {
        snippetEnd = spaceAfter;
      }
    }

    var snippet = content.substring(snippetStart, snippetEnd).trim();

    // Signal truncation
    if (snippetStart > 0) snippet = '…' + snippet;
    if (snippetEnd < content.length) snippet = snippet + '…';

    return snippet;
  }

  function renderResults(results, query) {
    if (!searchResults) return;

    var tokens = tokenize(query);

    if (results.length === 0) {
      searchResults.innerHTML = '<div class="eip-search__empty">No EIPs found matching "' + escapeHtml(query) + '"</div>';
      searchResults.classList.add('eip-search__results--visible');
      return;
    }

    var html = '<div class="eip-search__results-count">' + results.length + ' result' + (results.length !== 1 ? 's' : '') + ' for "' + escapeHtml(query) + '"</div>';

    for (var r = 0; r < results.length; r++) {
      var doc = results[r].doc;
      var statusBadge = getStatusBadge(doc.status);
      var typeLabel = doc.type || '';
      if (doc.category) typeLabel += ' · ' + doc.category;

      // Try to show a contextual snippet; fall back to description
      var snippet = extractContextSnippet(doc.content, tokens);
      var snippetHtml;
      if (snippet) {
        snippetHtml = highlightText(snippet, tokens);
      } else {
        snippetHtml = highlightText(doc.description, tokens);
      }

      html += '<a href="' + doc.url + '" class="eip-search__result">' +
        '<div class="eip-search__result-header">' +
          '<span class="eip-search__result-number">EIP-' + doc.eip + '</span>' +
          statusBadge +
        '</div>' +
        '<div class="eip-search__result-title">' + highlightText(doc.title, tokens) + '</div>' +
        '<div class="eip-search__result-desc">' + snippetHtml + '</div>' +
        '<div class="eip-search__result-meta">' + escapeHtml(typeLabel) + '</div>' +
      '</a>';
    }

    searchResults.innerHTML = html;
    searchResults.classList.add('eip-search__results--visible');
  }

  function escapeHtml(str) {
    if (!str) return '';
    var div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  function getStatusBadge(status) {
    if (!status) return '';
    var colors = {
      'Final': 'var(--eip-search-badge-final, #198754)',
      'Living': 'var(--eip-search-badge-living, #198754)',
      'Last Call': 'var(--eip-search-badge-last-call, #0d6efd)',
      'Review': 'var(--eip-search-badge-review, #ffc107)',
      'Draft': 'var(--eip-search-badge-draft, #6c757d)',
      'Stagnant': 'var(--eip-search-badge-stagnant, #dc3545)',
      'Withdrawn': 'var(--eip-search-badge-withdrawn, #dc3545)'
    };
    var color = colors[status] || '#6c757d';
    return '<span class="eip-search__badge" style="background-color:' + color + '">' + escapeHtml(status) + '</span>';
  }

  var debouncedSearch = debounce(function () {
    var query = searchInput.value;
    var results = performSearch(query);
    renderResults(results, query);
  }, 200);

  searchInput.addEventListener('input', debouncedSearch);

  // Keyboard navigation within results
  searchInput.addEventListener('keydown', function (e) {
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      e.preventDefault();
      var items = searchResults.querySelectorAll('.eip-search__result');
      if (items.length === 0) return;
      var currentIndex = Array.prototype.indexOf.call(items, document.activeElement);
      var nextIndex;
      if (e.key === 'ArrowDown') {
        nextIndex = currentIndex < items.length - 1 ? currentIndex + 1 : 0;
      } else {
        nextIndex = currentIndex > 0 ? currentIndex - 1 : items.length - 1;
      }
      items[nextIndex].focus();
    }
    if (e.key === 'Escape') {
      searchResults.classList.remove('eip-search__results--visible');
      searchInput.blur();
    }
  });

  // Close results on click outside
  document.addEventListener('click', function (e) {
    if (searchContainer && !searchContainer.contains(e.target)) {
      searchResults.classList.remove('eip-search__results--visible');
    }
  });

  // Re-open results when refocusing input (if it has a value)
  searchInput.addEventListener('focus', function () {
    if (this.value.trim().length >= 2 && searchIndex.length > 0) {
      var results = performSearch(this.value);
      renderResults(results, this.value);
    }
  });
})();
