/* ===================================================================
   settingsPage.js — Account settings / profile editing controller
   GET  /api/accounts/me/
   PATCH /api/accounts/me/
   DELETE /api/accounts/delete/
   =================================================================== */
'use strict';

const SettingsPage = (() => {

  function init() {
    if (!Auth.isLoggedIn()) return;

    _loadProfile();

    const form = document.getElementById('settings-form');
    if (form) form.addEventListener('submit', _onSave);

    const delBtn = document.getElementById('delete-account-btn');
    if (delBtn) delBtn.addEventListener('click', _onDeleteAccount);
  }

  /* ---- Load profile data into form ---- */
  async function _loadProfile() {
    const profile = Auth.getProfile ? await Auth.getProfile(true) : null;
    let data = profile;

    if (!data) {
      const res = await ApiClient.get('/api/accounts/me/');
      if (!res.ok) return;
      data = res.data;
    }

    _setVal('set-username', data.username || data.phone || '');
    _setVal('set-first-name', data.first_name || '');
    _setVal('set-last-name', data.last_name || '');
    _setVal('set-phone', data.phone || '');
    _setVal('set-email', data.email || '');

    // Header
    const nameEl = document.getElementById('settings-name');
    if (nameEl) nameEl.textContent = (data.first_name || '') + ' ' + (data.last_name || '') || data.username || '';

    const emailEl = document.getElementById('settings-email');
    if (emailEl) emailEl.textContent = data.email || '';

    const avatarEl = document.getElementById('settings-avatar');
    if (avatarEl && data.avatar) avatarEl.src = ApiClient.mediaUrl(data.avatar);
  }

  function _setVal(id, val) {
    const el = document.getElementById(id);
    if (el) el.value = val;
  }

  /* ---- Save ---- */
  async function _onSave(e) {
    e.preventDefault();
    const btn = document.getElementById('settings-save-btn');
    if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner-inline"></span> جاري الحفظ...'; }

    const body = {};
    const first = document.getElementById('set-first-name')?.value?.trim();
    const last = document.getElementById('set-last-name')?.value?.trim();
    const email = document.getElementById('set-email')?.value?.trim();

    if (first !== undefined) body.first_name = first;
    if (last !== undefined) body.last_name = last;
    if (email !== undefined) body.email = email;

    const res = await ApiClient.request('/api/accounts/me/', { method: 'PATCH', body: JSON.stringify(body) });
    if (res.ok) {
      _showSuccess('تم حفظ التغييرات بنجاح');
      // Update cached profile
      if (Auth.clearProfileCache) Auth.clearProfileCache();
    } else {
      _showError(res.data?.detail || 'حدث خطأ أثناء الحفظ');
    }

    if (btn) { btn.disabled = false; btn.textContent = 'حفظ التغييرات'; }
  }

  /* ---- Delete Account ---- */
  async function _onDeleteAccount() {
    const confirmed = confirm('هل أنت متأكد من حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.');
    if (!confirmed) return;

    const btn = document.getElementById('delete-account-btn');
    if (btn) { btn.disabled = true; btn.textContent = 'جاري الحذف...'; }

    const res = await ApiClient.request('/api/accounts/delete/', { method: 'DELETE' });
    if (res.ok) {
      Auth.logout();
      window.location.href = '/';
    } else {
      _showError(res.data?.detail || 'حدث خطأ أثناء حذف الحساب');
      if (btn) { btn.disabled = false; btn.textContent = 'حذف الحساب نهائياً'; }
    }
  }

  /* ---- Feedback ---- */
  function _showSuccess(msg) {
    let el = document.getElementById('settings-success');
    if (!el) {
      el = UI.el('div', { id: 'settings-success', className: 'form-success' });
      document.getElementById('settings-form')?.prepend(el);
    }
    el.textContent = msg;
    el.style.display = 'block';
    setTimeout(() => { el.style.display = 'none'; }, 3000);
  }

  function _showError(msg) {
    let el = document.getElementById('settings-error');
    if (!el) {
      el = UI.el('div', { id: 'settings-error', className: 'form-error' });
      document.getElementById('settings-form')?.prepend(el);
    }
    el.textContent = msg;
    el.style.display = 'block';
    setTimeout(() => { el.style.display = 'none'; }, 4000);
  }

  // Boot
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
  return {};
})();
