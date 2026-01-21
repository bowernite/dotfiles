// ==UserScript==
// @name         ChatGPT Model Switcher Menu Opener
// @namespace    https://chatgpt.com/
// @version      3.0
// @description  Open ChatGPT model switcher menu with Ctrl+Alt+. and restore focus on Enter
// @match        https://chatgpt.com/*
// @grant        none
// @run-at       document-end
// @license      MIT
// ==/UserScript==

(function () {
  'use strict';

  function log(...args) {
    console.log('[MODEL-SWITCHER]', ...args);
  }

  function isVisible(el) {
    if (!el) return false;
    const style = window.getComputedStyle(el);
    if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') return false;
    const rect = el.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0;
  }

  function simulateClick(element) {
    if (!element) return;
    log('Simulating POINTER click (focus, pointerdown, pointerup, click)');
    try {
      element.focus();

      const pointerdownEvent = new PointerEvent('pointerdown', {
        bubbles: true,
        cancelable: true,
        view: window,
        pointerType: 'mouse',
        isPrimary: true
      });
      element.dispatchEvent(pointerdownEvent);

      const pointerupEvent = new PointerEvent('pointerup', {
        bubbles: true,
        cancelable: true,
        view: window,
        pointerType: 'mouse',
        isPrimary: true
      });
      element.dispatchEvent(pointerupEvent);

      element.click();
    } catch (e) {
      log('Error during simulateClick, falling back', e);
      if (element.click) element.click();
    }
  }

  function getModelButton() {
    const buttons = document.querySelectorAll("button[data-testid='model-switcher-dropdown-button']");
    for (const btn of buttons) {
      if (isVisible(btn)) return btn;
    }
    return null;
  }

  function isMenuOpen() {
    const btn = getModelButton();
    return btn && btn.getAttribute('aria-expanded') === 'true';
  }

  let previouslyFocusedElement = null;
  let enterListener = null;

  function setupEnterListener() {
    if (enterListener) return;

    enterListener = (e) => {
      if (e.key !== 'Enter') return;
      if (!isMenuOpen()) return;

      const btn = getModelButton();
      if (!btn) return;

      const menu = document.querySelector('[data-radix-menu-content][data-state="open"]');
      if (!menu) return;

      const activeMenuItem = menu.querySelector('[role="menuitem"][aria-current="true"], [role="menuitem"]:focus');
      if (!activeMenuItem) return;

      e.preventDefault();
      e.stopPropagation();

      if (activeMenuItem instanceof HTMLElement) {
        activeMenuItem.click();
      }

      setTimeout(() => {
        if (previouslyFocusedElement && document.contains(previouslyFocusedElement)) {
          previouslyFocusedElement.focus();
          log('✅ Focus restored to previous element');
        }
        previouslyFocusedElement = null;

        if (enterListener) {
          document.removeEventListener('keydown', enterListener, true);
          enterListener = null;
        }
      }, 100);
    };

    document.addEventListener('keydown', enterListener, true);
    log('Enter listener set up');
  }

  function openModelMenu() {
    const btn = getModelButton();
    if (!btn) {
      log('❌ No visible model button found.');
      return;
    }

    previouslyFocusedElement = document.activeElement;
    log('Stored previously focused element:', previouslyFocusedElement);

    if (btn.getAttribute('aria-expanded') !== 'true') {
      simulateClick(btn);
      setupEnterListener();
    } else {
      log('Menu already open');
    }
  }

  window.addEventListener(
    'keydown',
    (e) => {
      // Cmd+/ (Command+/ on macOS)
      // event.metaKey = Command/Windows key; event.key/code: '/' or 'Slash'
      if (!e.metaKey || e.ctrlKey || e.altKey || e.shiftKey) return;
      if (e.key !== '/' && e.code !== 'Slash') return;

      e.preventDefault();
      openModelMenu();
    },
    true
  );

  function isEditableElement(element) {
    if (!element) return false;
    const tagName = element.tagName?.toLowerCase();
    if (tagName === 'input' || tagName === 'textarea') return true;
    if (element.isContentEditable) return true;
    return false;
  }

  function saveCursorPosition(element) {
    if (element.tagName?.toLowerCase() === 'input' || element.tagName?.toLowerCase() === 'textarea') {
      return {
        type: 'input',
        start: element.selectionStart,
        end: element.selectionEnd
      };
    } else if (element.isContentEditable) {
      const selection = window.getSelection();
      if (selection && selection.rangeCount > 0) {
        const range = selection.getRangeAt(0).cloneRange();
        return {
          type: 'contenteditable',
          range: range
        };
      }
    }
    return null;
  }

  function restoreCursorPosition(element, savedPosition) {
    if (!savedPosition) return;

    if (savedPosition.type === 'input') {
      element.setSelectionRange(savedPosition.start, savedPosition.end);
    } else if (savedPosition.type === 'contenteditable' && savedPosition.range) {
      const selection = window.getSelection();
      if (selection) {
        selection.removeAllRanges();
        selection.addRange(savedPosition.range);
      }
    }
  }

  function moveCursorToStart(element) {
    if (element.tagName?.toLowerCase() === 'input' || element.tagName?.toLowerCase() === 'textarea') {
      element.setSelectionRange(0, 0);
    } else if (element.isContentEditable) {
      const selection = window.getSelection();
      if (selection) {
        const range = document.createRange();
        range.selectNodeContents(element);
        range.collapse(true);
        selection.removeAllRanges();
        selection.addRange(range);
      }
    }
  }

  function insertTextAtCursor(element, text) {
    if (element.tagName?.toLowerCase() === 'input' || element.tagName?.toLowerCase() === 'textarea') {
      const start = element.selectionStart;
      const end = element.selectionEnd;
      const value = element.value;
      element.value = value.slice(0, start) + text + value.slice(end);
      element.setSelectionRange(start + text.length, start + text.length);
      
      const inputEvent = new Event('input', {
        bubbles: true,
        cancelable: true
      });
      element.dispatchEvent(inputEvent);
    } else if (element.isContentEditable) {
      const selection = window.getSelection();
      if (selection && selection.rangeCount > 0) {
        const range = selection.getRangeAt(0);
        range.deleteContents();
        const textNode = document.createTextNode(text);
        range.insertNode(textNode);
        range.setStartAfter(textNode);
        range.collapse(true);
        selection.removeAllRanges();
        selection.addRange(range);
        
        const inputEvent = new Event('input', {
          bubbles: true,
          cancelable: true
        });
        element.dispatchEvent(inputEvent);
      }
    }
  }

  function dispatchEnterKey(element) {
    const enterEvent = new KeyboardEvent('keydown', {
      key: 'Enter',
      code: 'Enter',
      keyCode: 13,
      which: 13,
      bubbles: true,
      cancelable: true,
      view: window
    });
    element.dispatchEvent(enterEvent);

    const enterPressEvent = new KeyboardEvent('keypress', {
      key: 'Enter',
      code: 'Enter',
      keyCode: 13,
      which: 13,
      bubbles: true,
      cancelable: true,
      view: window
    });
    element.dispatchEvent(enterPressEvent);

    const enterUpEvent = new KeyboardEvent('keyup', {
      key: 'Enter',
      code: 'Enter',
      keyCode: 13,
      which: 13,
      bubbles: true,
      cancelable: true,
      view: window
    });
    element.dispatchEvent(enterUpEvent);
  }

  function getSearchPillButton() {
    const buttons = document.querySelectorAll('button[aria-label="Search, click to remove"]');
    for (const btn of buttons) {
      if (isVisible(btn)) return btn;
    }
    return null;
  }

  window.addEventListener(
    'keydown',
    (e) => {
      // Cmd+S (Command+S on macOS)
      if (!e.metaKey || e.ctrlKey || e.altKey || e.shiftKey) return;
      if (e.key !== 's' && e.code !== 'KeyS') return;

      const searchPillButton = getSearchPillButton();
      if (searchPillButton && searchPillButton instanceof HTMLElement) {
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();
        searchPillButton.click();
        return;
      }

      const activeElement = document.activeElement;
      if (!activeElement || !isEditableElement(activeElement)) return;

      e.preventDefault();
      e.stopPropagation();
      e.stopImmediatePropagation();

      if (activeElement instanceof HTMLElement) {
        activeElement.focus();
      }

      const savedPosition = saveCursorPosition(activeElement);
      moveCursorToStart(activeElement);
      insertTextAtCursor(activeElement, '/search');
      
      setTimeout(() => {
        if (activeElement instanceof HTMLElement) {
          activeElement.focus();
        }
        dispatchEnterKey(activeElement);
        
        setTimeout(() => {
          const currentActive = document.activeElement;
          if (currentActive === activeElement || (activeElement instanceof HTMLElement && activeElement.contains(currentActive))) {
            restoreCursorPosition(activeElement, savedPosition);
          }
        }, 0);
      }, 100);
    },
    true
  );

  log('Userscript loaded (v3.0): Ctrl+Alt+. to open model menu, Enter to select and restore focus.');
})();
