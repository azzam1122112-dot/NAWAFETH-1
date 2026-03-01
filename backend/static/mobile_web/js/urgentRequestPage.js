/* ===================================================================
   urgentRequestPage.js — Urgent Request form controller
   POST /api/marketplace/requests/create/  (request_type='urgent')
   =================================================================== */
'use strict';

const UrgentRequestPage = (() => {
  let _selectedFiles = [];

  function init() {
    if (!Auth.isLoggedIn()) return;

    _loadCategories();

    const catSel = document.getElementById('ur-category');
    if (catSel) catSel.addEventListener('change', _onCategoryChange);

    const fileInput = document.getElementById('ur-files');
    if (fileInput) fileInput.addEventListener('change', _onFilesChanged);

    const form = document.getElementById('ur-form');
    if (form) form.addEventListener('submit', _onSubmit);
  }

  /* ---- Categories cascade ---- */
  async function _loadCategories() {
    const res = await ApiClient.get('/api/providers/categories/');
    if (!res.ok || !res.data) return;
    const cats = Array.isArray(res.data) ? res.data : (res.data.results || []);
    const sel = document.getElementById('ur-category');
    if (!sel) return;
    cats.forEach(c => {
      const opt = document.createElement('option');
      opt.value = c.id;
      opt.textContent = c.name;
      opt.dataset.subs = JSON.stringify(c.subcategories || []);
      sel.appendChild(opt);
    });
  }

  function _onCategoryChange() {
    const sel = document.getElementById('ur-category');
    const subSel = document.getElementById('ur-subcategory');
    if (!sel || !subSel) return;
    subSel.innerHTML = '<option value="">-- اختر التخصص --</option>';
    const opt = sel.options[sel.selectedIndex];
    if (!opt || !opt.dataset.subs) return;
    try {
      const subs = JSON.parse(opt.dataset.subs);
      subs.forEach(s => {
        const o = document.createElement('option');
        o.value = s.id;
        o.textContent = s.name;
        subSel.appendChild(o);
      });
    } catch (e) { /* ignore */ }
  }

  /* ---- File handling ---- */
  function _onFilesChanged(e) {
    _selectedFiles = Array.from(e.target.files || []);
    const list = document.getElementById('ur-file-list');
    if (!list) return;
    list.innerHTML = '';
    _selectedFiles.forEach(f => {
      const item = UI.el('div', { className: 'file-item' });
      item.appendChild(UI.icon('attachment', 16, '#666'));
      item.appendChild(UI.el('span', { textContent: f.name }));
      list.appendChild(item);
    });
  }

  /* ---- Submit ---- */
  async function _onSubmit(e) {
    e.preventDefault();
    const btn = document.getElementById('ur-submit');
    if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner-inline"></span> جاري الإرسال...'; }

    const desc = document.getElementById('ur-description')?.value?.trim();
    const subcat = document.getElementById('ur-subcategory')?.value;
    const dispatch = document.querySelector('input[name="dispatch_mode"]:checked')?.value || 'nearest';

    if (!desc) {
      _showError('يرجى كتابة وصف الطلب');
      _resetBtn(btn);
      return;
    }

    const fd = new FormData();
    fd.append('request_type', 'urgent');
    fd.append('description', desc);
    if (subcat) fd.append('subcategory', subcat);
    fd.append('dispatch_mode', dispatch);
    _selectedFiles.forEach(f => fd.append('images', f));

    const res = await ApiClient.request('/api/marketplace/requests/create/', { method: 'POST', body: fd, formData: true });
    if (res.ok) {
      document.getElementById('ur-success')?.classList.add('visible');
      setTimeout(() => { window.location.href = '/orders/'; }, 2000);
    } else {
      _showError(res.data?.detail || 'حدث خطأ، حاول مرة أخرى');
    }
    _resetBtn(btn);
  }

  function _showError(msg) {
    let errEl = document.getElementById('ur-error');
    if (!errEl) {
      errEl = UI.el('div', { id: 'ur-error', className: 'form-error' });
      document.getElementById('ur-form')?.prepend(errEl);
    }
    errEl.textContent = msg;
    errEl.style.display = 'block';
    setTimeout(() => { errEl.style.display = 'none'; }, 4000);
  }

  function _resetBtn(btn) {
    if (btn) { btn.disabled = false; btn.textContent = 'إرسال الطلب العاجل'; }
  }

  // Boot
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
  return {};
})();
