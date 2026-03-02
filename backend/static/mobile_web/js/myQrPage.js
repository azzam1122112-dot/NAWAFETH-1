/* ===================================================================
   myQrPage.js — Build user's Nawafeth profile QR from API data.
   =================================================================== */
'use strict';

const MyQrPage = (() => {
  function init() {
    const authGate = document.getElementById('qr-auth-gate');
    const content = document.getElementById('qr-content');

    if (!Auth.isLoggedIn()) {
      if (authGate) authGate.classList.remove('hidden');
      if (content) content.classList.add('hidden');
      return;
    }

    if (authGate) authGate.classList.add('hidden');
    if (content) content.classList.remove('hidden');

    _loadQrData();
  }

  async function _loadQrData() {
    const meRes = await ApiClient.get('/api/accounts/me/');
    if (!meRes.ok || !meRes.data) {
      _showError('تعذر تحميل بيانات الحساب');
      return;
    }

    const me = meRes.data;
    const profileRes = await ApiClient.get('/api/providers/me/profile/');
    let targetUrl = `${window.location.origin}/profile/`;
    let title = 'رابط نافذتي';

    if (profileRes.ok && profileRes.data && profileRes.data.id) {
      targetUrl = `${window.location.origin}/provider/${profileRes.data.id}/`;
      title = 'QR ملف مقدم الخدمة';
    } else if (me.id) {
      targetUrl = `${window.location.origin}/profile/?user=${me.id}`;
    }

    const qrApi = 'https://api.qrserver.com/v1/create-qr-code/?size=420x420&data=' + encodeURIComponent(targetUrl);

    const titleEl = document.getElementById('qr-title');
    const textEl = document.getElementById('qr-link-text');
    const imgEl = document.getElementById('my-qr-image');
    const openEl = document.getElementById('open-qr-link');
    const copyBtn = document.getElementById('copy-qr-link');

    if (titleEl) titleEl.textContent = title;
    if (textEl) textEl.textContent = targetUrl;
    if (imgEl) imgEl.src = qrApi;
    if (openEl) openEl.href = targetUrl;

    if (copyBtn) {
      copyBtn.addEventListener('click', async () => {
        try {
          await navigator.clipboard.writeText(targetUrl);
          _showSuccess('تم نسخ الرابط');
        } catch (_) {
          _showError('تعذر نسخ الرابط');
        }
      });
    }
  }

  function _showSuccess(msg) {
    const success = document.getElementById('qr-success');
    const error = document.getElementById('qr-error');
    if (error) error.classList.add('hidden');
    if (!success) return;
    success.textContent = msg;
    success.classList.remove('hidden');
  }

  function _showError(msg) {
    const success = document.getElementById('qr-success');
    const error = document.getElementById('qr-error');
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
