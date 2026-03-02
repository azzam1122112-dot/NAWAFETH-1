/* ===================================================================
   languagePage.js — Language selection page (mobile parity)
   Keeps user choice locally and syncs against active account session.
   =================================================================== */
'use strict';

const LanguagePage = (() => {
  const KEY = 'nw_lang';

  function init() {
    const authGate = document.getElementById('language-auth-gate');
    const content = document.getElementById('language-content');

    if (!Auth.isLoggedIn()) {
      if (authGate) authGate.classList.remove('hidden');
      if (content) content.classList.add('hidden');
      return;
    }

    if (authGate) authGate.classList.add('hidden');
    if (content) content.classList.remove('hidden');

    _renderCurrent();
    _loadProfileForSync();

    const arBtn = document.getElementById('lang-ar');
    const enBtn = document.getElementById('lang-en');
    if (arBtn) arBtn.addEventListener('click', () => _setLanguage('ar'));
    if (enBtn) enBtn.addEventListener('click', () => _setLanguage('en'));
  }

  async function _loadProfileForSync() {
    try {
      await Auth.getProfile(true);
    } catch (_) {
      // Keep page functional even if profile fetch fails.
    }
  }

  function _setLanguage(lang) {
    try {
      localStorage.setItem(KEY, lang);
    } catch (_) {
      _showError('تعذر حفظ اللغة على هذا المتصفح');
      return;
    }

    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    _renderCurrent();
    _showSuccess(lang === 'ar' ? 'تم اختيار العربية' : 'English selected');
  }

  function _getLanguage() {
    try {
      return localStorage.getItem(KEY) || 'ar';
    } catch (_) {
      return 'ar';
    }
  }

  function _renderCurrent() {
    const lang = _getLanguage();
    const label = document.getElementById('language-current-label');
    if (!label) return;
    label.textContent = lang === 'en' ? 'English' : 'العربية';
  }

  function _showSuccess(msg) {
    const success = document.getElementById('language-success');
    const error = document.getElementById('language-error');
    if (error) error.classList.add('hidden');
    if (!success) return;
    success.textContent = msg;
    success.classList.remove('hidden');
  }

  function _showError(msg) {
    const success = document.getElementById('language-success');
    const error = document.getElementById('language-error');
    if (success) success.classList.add('hidden');
    if (!error) return;
    error.textContent = msg;
    error.classList.remove('hidden');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  return { init };
})();
