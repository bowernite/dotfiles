// ==UserScript==
// @name         Amazon Hide Sponsored
// @namespace    https://amazon.com/
// @version      1.0
// @description  Hides sponsored/ad results and ad widgets from Amazon search results
// @match        https://*.amazon.com/*
// @match        https://*.amazon.co.uk/*
// @match        https://*.amazon.ca/*
// @match        https://*.amazon.de/*
// @match        https://*.amazon.fr/*
// @match        https://*.amazon.it/*
// @match        https://*.amazon.es/*
// @match        https://*.amazon.nl/*
// @match        https://*.amazon.se/*
// @match        https://*.amazon.pl/*
// @match        https://*.amazon.com.au/*
// @match        https://*.amazon.com.mx/*
// @match        https://*.amazon.com.br/*
// @match        https://*.amazon.co.jp/*
// @match        https://*.amazon.in/*
// @match        https://*.amazon.sg/*
// @match        https://*.amazon.ae/*
// @grant        none
// @run-at       document-start
// @license      MIT
// ==/UserScript==

(function () {
  'use strict';

  const SCRIPT_NAME = 'AMZN-AD-HIDE';
  const POLL_INTERVAL_MS = 1000;
  const TICK_DELAY_MS = 100;

  const HIDDEN_CLASS = 'ash-hidden';
  const REASON_ATTR = 'data-ash-reason';

  // A tile within a search results list. Widgets (banners, carousels) are
  // matched separately as direct children of the results slot.
  const TILE_SELECTOR = 'div[data-component-type="s-search-result"], .s-result-item[data-asin]';

  // Localized "Sponsored" label words. Matched as the *entire* short text of a
  // node — never as a substring of a product title.
  const SPONSORED_WORDS = new RegExp(
    '^(?:' +
      [
        'sponsored(?:\\s+ad)?',
        // Disclaimer on first-party merchandising widgets; the middle words
        // vary ("our brands", "Amazon brands", ...)
        'featured from .{1,24} brands',
        'gesponsert',
        'sponsoris[ée]e?',
        'patrocinado?s?',
        'patrocinada',
        'sponsorizzat[oa]',
        'gesponsord',
        'sponsrad',
        'sponsoreret',
        'sponsorowane',
        'sponsorlu',
        'спонсировано',
        'реклама',
        'إعلان',
        'スポンサー',
        '広告',
        '赞助',
        '贊助',
        '广告',
        '스폰서',
      ].join('|') +
      ')$',
    'i'
  );

  // Attribute values (aria-label, alt, title) that mark ad affordances, e.g.
  // "View Sponsored information or leave ad feedback". Future-proofs against
  // the label becoming an icon — accessible names have to stay.
  const SPONSORED_ATTR_PATTERN =
    /sponsored|ad feedback|leave feedback on ad|anzeige|publicit[eé]|patrocinado|sponsorizzato|広告|スポンサー|赞助|贊助/i;

  // SPONSORED_WORDS is anchored (^...$), so a text node longer than the
  // longest label can never match — skip those before running the regex
  const MAX_LABEL_TEXT_LENGTH = 32;

  // SPONSORED_ATTR_PATTERN is a substring match, so cap the value length to
  // avoid firing on e.g. a long product alt text that happens to contain
  // "sponsored"
  const MAX_ATTR_VALUE_LENGTH = 120;

  let tickScheduled = false;
  let hiddenCount = 0;
  let lastLoggedCount = -1;
  const logOnceKeys = new Set();

  // ──────────────────────────────────────────────
  // Detectors — each is an independent signal that a tile/widget is an ad.
  // Ordered strongest-first; the first match wins and becomes the reason.
  // ──────────────────────────────────────────────

  const DETECTORS = [
    {
      // Amazon's own component metadata for sponsored placements
      name: 'sponsored-component',
      test: (el) =>
        matchesOrContains(el, '[data-component-type="sp-sponsored-result"], [data-component-type*="sponsored" i]'),
    },
    {
      // Legacy but still-used class on ad tiles
      name: 'ad-holder-class',
      test: (el) => matchesOrContains(el, '.AdHolder'),
    },
    {
      // Sponsored clicks are routed through ad-tracking redirects. The URL
      // shape is load-bearing for Amazon's ad billing, so it rarely changes.
      name: 'sspa-link',
      test: (el) =>
        !!el.querySelector('a[href*="/sspa/click"], a[href*="/gp/slredirect/"], a[href^="https://aax-"]'),
    },
    {
      // Ad-feedback plumbing only exists on paid placements
      name: 'ad-feedback',
      test: (el) =>
        matchesOrContains(
          el,
          '[data-ad-details], [data-adfeedbackdetails], [data-ad-id], ' +
            '.s-sponsored-info-icon, .puis-sponsored-label-info-icon, .puis-sponsored-label-text'
        ),
    },
    {
      // Widget/creative IDs that self-identify as ads
      name: 'ad-widget-id',
      test: (el) =>
        matchesOrContains(
          el,
          '[cel_widget_id*="sponsored" i], [data-cel-widget*="sponsored" i], ' +
            '[cel_widget_id*="advertising" i], [data-cel-widget*="advertising" i]'
        ),
    },
    {
      // First-party merchandising creatives ("Featured from Amazon brands"
      // etc). "loom" slots exist solely to host injected promo widgets, and
      // "mars"/"featured-brand" identify the creative itself.
      name: 'merch-widget',
      test: (el) =>
        matchesOrContains(
          el,
          '[cel_widget_id^="loom-" i], [data-cel-widget^="loom-" i], ' +
            '[cel_widget_id*="featured-brands" i], [data-cel-widget*="featured-brands" i], ' +
            '[data-csa-c-painter*="featured-brand" i], [class*="featured-brand-"]'
        ),
    },
    {
      // A short text node that IS a localized "Sponsored" label
      name: 'label-text',
      soft: true,
      test: (el) => hasSponsoredLabelText(el),
    },
    {
      // Accessible names on icons/badges (aria-label, alt, title)
      name: 'attr-text',
      soft: true,
      test: (el) => hasSponsoredAttrText(el),
    },
  ];

  // "Soft" hides rely on visible/accessible text rather than structure
  const SOFT_REASONS = new Set([
    ...DETECTORS.filter((d) => d.soft).map((d) => d.name),
    // A section hidden only because its tiles matched on text signals
    'sponsored-section-text',
  ]);

  // ──────────────────────────────────────────────
  // Bootstrap
  // ──────────────────────────────────────────────

  injectStyle();

  if (document.body) {
    init();
  } else {
    document.addEventListener('DOMContentLoaded', init);
  }

  function init() {
    const observer = new MutationObserver(() => scheduleTick());
    observer.observe(document.body, { childList: true, subtree: true });
    setInterval(scheduleTick, POLL_INTERVAL_MS);
    scheduleTick();
    log(`Loaded (v1.0) on ${location.href}`);
  }

  /**
   * Anti-flash layer: pure-CSS rules for the highest-confidence structural
   * signals, active before first paint so known ads never appear at all.
   * The JS detectors below catch everything these can't express.
   */
  function injectStyle() {
    const style = document.createElement('style');
    style.textContent = `
      .${HIDDEN_CLASS},
      [data-component-type="sp-sponsored-result"],
      .s-result-item.AdHolder,
      .s-main-slot > div:has([data-component-type="sp-sponsored-result"]),
      .s-main-slot > div:has(a[href*="/sspa/click"]),
      .s-main-slot > div:has(.puis-sponsored-label-text),
      .s-main-slot > div:has([data-ad-details]),
      .s-main-slot > div:has([data-adfeedbackdetails]),
      .s-main-slot > div:has([cel_widget_id^="loom-" i]),
      .s-main-slot > div:has([class*="featured-brand-container"]) {
        display: none !important;
      }
    `;
    (document.head || document.documentElement).appendChild(style);
  }

  // ──────────────────────────────────────────────
  // Main loop
  // ──────────────────────────────────────────────

  function scheduleTick() {
    if (tickScheduled) return;
    tickScheduled = true;
    setTimeout(() => {
      tickScheduled = false;
      tick();
    }, TICK_DELAY_MS);
  }

  function tick() {
    if (!isSearchPage()) return;

    for (const candidate of getCandidates()) {
      if (candidate.classList.contains(HIDDEN_CLASS) || candidate.closest(`.${HIDDEN_CLASS}`)) continue;

      const innerTiles = candidate.querySelectorAll(TILE_SELECTOR);
      if (innerTiles.length > 1) {
        // A wrapper around multiple result tiles. Never hide it for a signal
        // on one tile (that would take organic results down too) — but a
        // section where EVERY tile is an ad (e.g. a "Customers frequently
        // viewed · Sponsored" row) goes as a whole, heading included.
        const tileReasons = Array.from(innerTiles).map((tile) => detect(tile));
        if (tileReasons.every(Boolean)) {
          // A section caught purely on text signals must stay revertible by
          // the empty-page safety valve, like any other soft hide
          const allSoft = tileReasons.every((reason) => SOFT_REASONS.has(reason));
          hide(candidate, allSoft ? 'sponsored-section-text' : 'sponsored-section');
        }
        continue;
      }

      const reason = detect(candidate);
      if (reason) hide(candidate, reason);
    }

    revertSoftHidesIfPageEmptied();

    if (hiddenCount !== lastLoggedCount) {
      lastLoggedCount = hiddenCount;
      log(`${hiddenCount} sponsored item(s) hidden`);
    }
  }

  function isSearchPage() {
    const path = location.pathname;
    return (
      path === '/s' ||
      path.startsWith('/s/') ||
      path.startsWith('/s?') ||
      path.includes('/gp/search') ||
      new URLSearchParams(location.search).has('k')
    );
  }

  /**
   * Candidates are (a) direct children of the results slot — each is either
   * one result tile or one full-width ad widget/banner/carousel — and (b) any
   * result tile found anywhere, as a fallback if the slot markup changes.
   * @returns {Set<Element>}
   */
  function getCandidates() {
    const candidates = new Set();
    for (const slot of document.querySelectorAll('.s-main-slot, .s-result-list, [data-component-type="s-search-results"]')) {
      for (const child of slot.children) {
        candidates.add(child);
      }
    }
    for (const tile of document.querySelectorAll(TILE_SELECTOR)) {
      candidates.add(tile);
    }
    return candidates;
  }

  /**
   * Run all detectors against an element.
   * @param {Element} el
   * @returns {string|null} the name of the first matching detector, or null
   */
  function detect(el) {
    for (const detector of DETECTORS) {
      if (detector.test(el)) return detector.name;
    }
    return null;
  }

  // ──────────────────────────────────────────────
  // Text-based detection
  // ──────────────────────────────────────────────

  /** @param {Element} el */
  function hasSponsoredLabelText(el) {
    const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      const text = (node.textContent || '').trim();
      if (!text || text.length > MAX_LABEL_TEXT_LENGTH) continue;
      if (SPONSORED_WORDS.test(text)) return true;
    }
    return false;
  }

  /** @param {Element} el */
  function hasSponsoredAttrText(el) {
    const labeled = el.querySelectorAll('[aria-label], [alt], [title]');
    for (const item of labeled) {
      for (const attr of ['aria-label', 'alt', 'title']) {
        const value = item.getAttribute(attr);
        if (value && value.length <= MAX_ATTR_VALUE_LENGTH && SPONSORED_ATTR_PATTERN.test(value)) return true;
      }
    }
    return false;
  }

  // ──────────────────────────────────────────────
  // Hide / revert
  // ──────────────────────────────────────────────

  /**
   * @param {Element} el
   * @param {string} reason
   */
  function hide(el, reason) {
    el.classList.add(HIDDEN_CLASS);
    el.setAttribute(REASON_ATTR, reason);
    hiddenCount++;
    const label = describe(el);
    log(`Hiding [${reason}] ${label}`);
  }

  /**
   * Safety valve for the text-based detectors: if the page ended up with zero
   * visible results while soft (text-matched) hides exist, a pattern has gone
   * rogue (e.g. a product line legitimately reading "Sponsored") — undo them.
   */
  function revertSoftHidesIfPageEmptied() {
    const tiles = document.querySelectorAll(TILE_SELECTOR);
    if (tiles.length === 0) return;

    const anyVisible = Array.from(tiles).some(
      (tile) => !tile.classList.contains(HIDDEN_CLASS) && !tile.closest(`.${HIDDEN_CLASS}`)
    );
    if (anyVisible) return;

    const softHidden = document.querySelectorAll(`.${HIDDEN_CLASS}[${REASON_ATTR}]`);
    let reverted = 0;
    for (const el of softHidden) {
      const reason = el.getAttribute(REASON_ATTR) || '';
      if (!SOFT_REASONS.has(reason)) continue;
      el.classList.remove(HIDDEN_CLASS);
      el.removeAttribute(REASON_ATTR);
      hiddenCount--;
      reverted++;
    }
    if (reverted > 0) {
      logOnce('soft-revert', `⚠️ All results were hidden — reverted ${reverted} text-based hide(s)`);
    }
  }

  // ──────────────────────────────────────────────
  // Shared utilities
  // ──────────────────────────────────────────────

  /**
   * @param {Element} el
   * @param {string} selector
   */
  function matchesOrContains(el, selector) {
    return el.matches(selector) || !!el.querySelector(selector);
  }

  /** Short human-readable identity for logging @param {Element} el */
  function describe(el) {
    const asin = el.getAttribute('data-asin');
    if (asin) return `asin=${asin}`;
    const widgetId = el.getAttribute('cel_widget_id') || el.getAttribute('data-cel-widget');
    if (widgetId) return `widget=${widgetId}`;
    const heading = el.querySelector('h2, h3, h4');
    const text = (heading && heading.textContent ? heading.textContent : el.textContent || '').trim();
    return `"${text.slice(0, 60)}"`;
  }

  /** @param {...unknown} args */
  function log(...args) {
    console.log(`[${SCRIPT_NAME}]`, ...args);
  }

  /**
   * @param {string} key
   * @param {...unknown} args
   */
  function logOnce(key, ...args) {
    if (logOnceKeys.has(key)) return;
    logOnceKeys.add(key);
    log(...args);
  }
})();
