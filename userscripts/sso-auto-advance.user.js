// ==UserScript==
// @name         SSO Auto-Advance
// @namespace    https://github.com/
// @version      2.0
// @description  Auto-advances GitHub SSO banners/pages and Okta passkey auth flows
// @match        https://github.com/*
// @match        https://*.okta.com/*
// @match        https://*.oktapreview.com/*
// @grant        none
// @run-at       document-end
// @license      MIT
// ==/UserScript==

(function () {
  'use strict';

  const SCRIPT_NAME = 'SSO-AUTO';
  const POLL_INTERVAL_MS = 400;
  const TICK_DELAY_MS = 100;
  const MAX_RETRIES_PER_STATE = 3;
  const WEBAUTHN_RETRY_COOLDOWN_MS = 2000;

  // The SSO org to auto-select on GitHub
  const SSO_ORG = 'Solace Health';

  const clickLog = new Map();
  let tickScheduled = false;
  let lastState = 'unknown';
  let lastRetriedAt = 0;
  let triedWebAuthn = false;

  // ──────────────────────────────────────────────
  // Bootstrap
  // ──────────────────────────────────────────────

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
    log('Loaded (v2.0)');
  }

  // ──────────────────────────────────────────────
  // Main loop — dispatch by hostname
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
    const host = location.hostname;
    if (host === 'github.com') return tickGitHub();
    if (host.endsWith('.okta.com') || host.endsWith('.oktapreview.com')) return tickOkta();
  }

  // ══════════════════════════════════════════════
  // GitHub SSO
  // ══════════════════════════════════════════════

  function tickGitHub() {
    const state = detectGitHubState();

    if (state !== lastState) {
      clickLog.clear();
      log(`State: ${lastState} → ${state}`);
      lastState = state;
    }

    switch (state) {
      case 'gh-sso-banner': {
        const btn = findSSOBannerButton();
        clickOnce(btn, 'gh-sso-banner-button');
        break;
      }

      case 'gh-sso-menu-open': {
        const item = findSSSOrgMenuItem();
        clickOnce(item, 'gh-sso-org-select');
        break;
      }

      case 'gh-sso-continue': {
        const btn = findSSOContinueButton();
        clickOnce(btn, 'gh-sso-continue');
        break;
      }

      default:
        break;
    }
  }

  // ── GitHub page detection ─────────────────────

  function detectGitHubState() {
    // SSO org page (github.com/orgs/*/sso) — click Continue
    if (findSSOContinueButton()) return 'gh-sso-continue';

    // SSO dropdown menu is open — pick the org
    if (findSSSOrgMenuItem()) return 'gh-sso-menu-open';

    // SSO banner visible — open the dropdown
    if (findSSOBannerButton()) return 'gh-sso-banner';

    return 'unknown';
  }

  // ── GitHub selectors ──────────────────────────

  function findSSOBannerButton() {
    // Best: test ID on the banner, then find the SSO button inside it
    const banner = document.querySelector('[data-testid="global-sso-banner"]');
    if (banner && isVisible(banner)) {
      // The dropdown trigger button inside the banner actions
      const buttons = banner.querySelectorAll('button[aria-haspopup="true"]');
      for (const btn of buttons) {
        if (isVisible(btn)) return btn;
      }
    }

    // Fallback: any banner-like container with an SSO button
    const allButtons = document.querySelectorAll('button[aria-haspopup="true"]');
    for (const btn of allButtons) {
      if (!isVisible(btn)) continue;
      const text = (btn.textContent || '').trim().toLowerCase();
      if (text.includes('single sign-on')) return btn;
    }

    return null;
  }

  function findSSSOrgMenuItem() {
    // Look in the open menu for a menuitem linking to the target org's SSO
    const items = document.querySelectorAll('a[role="menuitem"]');
    for (const item of items) {
      if (!isVisible(item)) continue;
      // Check href for the org SSO path
      const href = item.getAttribute('href') || '';
      if (/\/orgs\/Solace-Health\/sso/i.test(href)) return item;
      // Fallback: check the label text
      const text = (item.textContent || '').trim();
      if (text === SSO_ORG) return item;
    }
    return null;
  }

  function findSSOContinueButton() {
    // Only on SSO pages (github.com/orgs/*/sso*)
    if (!/\/orgs\/[^/]+\/sso/.test(location.pathname)) return null;

    // Best: submit button inside a form whose action contains /saml/initiate
    const forms = document.querySelectorAll('form[action*="/saml/initiate"]');
    for (const form of forms) {
      if (!isVisible(form)) continue;
      const btn = form.querySelector('button[type="submit"], button, input[type="submit"]');
      if (btn && isVisible(btn)) return btn;
    }

    // Fallback: any primary button on an .org-sso page
    const container = document.querySelector('.org-sso, .org-sso-panel');
    if (container) {
      const btn = container.querySelector('.btn-primary');
      if (btn && isVisible(btn)) return btn;
    }

    return null;
  }

  // ══════════════════════════════════════════════
  // Okta
  // ══════════════════════════════════════════════

  function tickOkta() {
    const state = detectOktaState();

    if (state !== lastState) {
      clickLog.clear();
      lastRetriedAt = 0;
      log(`State: ${lastState} → ${state}`);
      lastState = state;
    }

    switch (state) {
      case 'has-passkey-button': {
        const btn = findSignInWithPasskeyButton();
        clickOnce(btn, 'sign-in-with-passkey');
        break;
      }

      case 'identifier-filled': {
        const btn = findOktaSubmitButton();
        clickOnce(btn, 'identifier-submit');
        break;
      }

      case 'authenticator-select': {
        const btn = findPasskeyAuthenticatorOption();
        clickOnce(btn, 'passkey-authenticator-select');
        break;
      }

      case 'wrong-authenticator': {
        if (triedWebAuthn) {
          log('Passkey already attempted, staying on password page');
          break;
        }
        const btn = findSwitchAuthenticatorLink();
        clickOnce(btn, 'switch-authenticator');
        break;
      }

      case 'webauthn-challenge': {
        triedWebAuthn = true;
        if (!isWebAuthnPromptActive() && Date.now() - lastRetriedAt > WEBAUTHN_RETRY_COOLDOWN_MS) {
          const btn = findWebAuthnRetryButton();
          if (clickOnce(btn, 'webauthn-retry')) {
            lastRetriedAt = Date.now();
          }
        }
        break;
      }

      default:
        break;
    }
  }

  // ── Okta page detection ───────────────────────

  function detectOktaState() {
    if (findSignInWithPasskeyButton()) return 'has-passkey-button';

    if (isOnWebAuthnChallengePage()) return 'webauthn-challenge';

    if (isOnNonWebAuthnChallengePage() && findSwitchAuthenticatorLink()) return 'wrong-authenticator';

    if (findPasskeyAuthenticatorOption()) return 'authenticator-select';

    const identifierInput = document.querySelector('input[name="identifier"]');
    if (identifierInput && identifierInput.value && findOktaSubmitButton()) {
      return 'identifier-filled';
    }

    return 'unknown';
  }

  function isOnWebAuthnChallengePage() {
    if (document.querySelector('.mfa-verify-webauthn, .challenge-authenticator--webauthn')) return true;
    if (document.querySelector('form.oie-verify-webauthn')) return true;
    if (document.querySelector('a.retry-webauthn, [data-se="webauthn-waiting"]')) return true;
    return false;
  }

  function isOnNonWebAuthnChallengePage() {
    if (document.querySelector('.mfa-verify-password, .challenge-authenticator--okta_password')) return true;
    const challenge = document.querySelector('[class*="challenge-authenticator--"]');
    if (challenge && !challenge.classList.contains('challenge-authenticator--webauthn')) return true;
    return false;
  }

  function isWebAuthnPromptActive() {
    const spinner = document.querySelector('[data-se="webauthn-waiting"]');
    if (!spinner) return false;
    return isVisible(spinner);
  }

  // ── Okta selectors ────────────────────────────

  function findOktaSubmitButton() {
    const forms = document.querySelectorAll('form[data-se="o-form"], form');
    for (const form of forms) {
      if (!isVisible(form)) continue;
      const candidates = form.querySelectorAll(
        'input[type="submit"], button[type="submit"], [data-type="save"]'
      );
      for (const btn of candidates) {
        if (isVisible(btn) && !btn.disabled) return btn;
      }
    }
    return null;
  }

  function findPasskeyAuthenticatorOption() {
    const passkeyPatterns = [
      /passkey/i,
      /fido/i,
      /webauthn/i,
      /biometric/i,
      /security key/i,
    ];

    const webauthnContainer = document.querySelector('[data-se="webauthn"]');
    if (webauthnContainer) {
      const btn = webauthnContainer.querySelector('a, button, [role="button"]');
      if (btn && isVisible(btn)) return btn;
    }

    const rows = document.querySelectorAll('.authenticator-row, [data-se*="authenticator"]');
    for (const row of rows) {
      if (!isVisible(row)) continue;
      const rowText = row.textContent || '';
      if (!passkeyPatterns.some(p => p.test(rowText))) continue;
      const btn = row.querySelector('a, button, [role="button"], [data-type="save"]');
      if (btn && isVisible(btn)) return btn;
      if (row.tagName === 'A' || row.tagName === 'BUTTON' || row.getAttribute('role') === 'button') {
        return row;
      }
    }

    const clickables = document.querySelectorAll('a, button, [role="button"], [role="link"]');
    for (const el of clickables) {
      if (!isVisible(el) || el.disabled) continue;
      const text = (el.textContent || '').trim();
      if (passkeyPatterns.some(p => p.test(text))) return el;
    }

    return null;
  }

  function findSignInWithPasskeyButton() {
    return findButtonByText(
      /sign in with.{0,5}passkey/i,
      /use.{0,5}passkey/i
    );
  }

  function findSwitchAuthenticatorLink() {
    const link = document.querySelector('a[data-se="switchAuthenticator"]');
    if (link && isVisible(link)) return link;
    return findButtonByText(/verify with something else/i);
  }

  function findWebAuthnRetryButton() {
    const retry = document.querySelector('a.retry-webauthn');
    if (retry && isVisible(retry)) return retry;
    return findButtonByText('verify', /^verify$/i, 'retry', /^retry$/i);
  }

  // ══════════════════════════════════════════════
  // Shared utilities
  // ══════════════════════════════════════════════

  function log(...args) {
    console.log(`[${SCRIPT_NAME}]`, ...args);
  }

  function isVisible(el) {
    if (!el) return false;
    const style = window.getComputedStyle(el);
    if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') return false;
    const rect = el.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0;
  }

  function findButtonByText(...patterns) {
    const clickables = document.querySelectorAll('a, button, input[type="submit"], [role="button"]');
    for (const el of clickables) {
      if (!isVisible(el) || el.disabled) continue;
      const text = (el.textContent || el.value || '').trim().toLowerCase();
      for (const pattern of patterns) {
        if (typeof pattern === 'string' && text === pattern.toLowerCase()) return el;
        if (pattern instanceof RegExp && pattern.test(text)) return el;
      }
    }
    return null;
  }

  function clickOnce(el, label) {
    if (!el || !isVisible(el)) return false;
    const key = label || el.textContent?.trim()?.slice(0, 40) || 'unknown';
    const count = clickLog.get(key) || 0;
    if (count >= MAX_RETRIES_PER_STATE) {
      log(`Skipping "${key}" — already clicked ${count} times`);
      return false;
    }
    clickLog.set(key, count + 1);
    log(`Clicking: "${key}"`);
    el.click();
    return true;
  }
})();
