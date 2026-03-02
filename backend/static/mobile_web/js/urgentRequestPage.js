/* ===================================================================
   urgentRequestPage.js — Urgent Request form controller
   POST /api/marketplace/requests/create/  (request_type='urgent')
   =================================================================== */
'use strict';

const UrgentRequestPage = (() => {
  let _selectedFiles = [];
  const _cities = [
    'الرياض','جدة','مكة المكرمة','المدينة المنورة','الدمام','الخبر','الظهران','الطائف','تبوك','بريدة',
    'عنيزة','حائل','أبها','خميس مشيط','نجران','جازان','ينبع','الباحة','الجبيل','حفر الباطن',
    'القطيف','الأحساء','سكاكا','عرعر','بيشة','الخرج','الدوادمي','المجمعة','القويعية','وادي الدواسر'
  ];

  function init() {
    const isLoggedIn = !!Auth.isLoggedIn();
    _setAuthState(isLoggedIn);
    if (!isLoggedIn) return;

    _loadCities();
    _loadCategories();
    _bindDispatchMode();
    _bindDescriptionCounter();

    const catSel = document.getElementById('ur-category');
    if (catSel) catSel.addEventListener('change', _onCategoryChange);

    const fileInput = document.getElementById('ur-files');
    if (fileInput) fileInput.addEventListener('change', _onFilesChanged);

    const form = document.getElementById('ur-form');
    if (form) form.addEventListener('submit', _onSubmit);
  }

  function _setAuthState(isLoggedIn) {
    const gate = document.getElementById('auth-gate');
    const formContent = document.getElementById('form-content');
    if (gate) gate.classList.toggle('hidden', isLoggedIn);
    if (formContent) formContent.classList.toggle('hidden', !isLoggedIn);
  }

  function _loadCities() {
    const citySel = document.getElementById('ur-city');
    if (!citySel) return;
    _cities.forEach((city) => {
      const option = document.createElement('option');
      option.value = city;
      option.textContent = city;
      citySel.appendChild(option);
    });
  }

  function _bindDispatchMode() {
    const labels = document.querySelectorAll('.radio-chip-label');
    labels.forEach((label) => {
      const input = label.querySelector('input[type="radio"]');
      const chip = label.querySelector('.radio-chip');
      if (!input || !chip) return;
      input.addEventListener('change', () => {
        document.querySelectorAll('.radio-chip-label .radio-chip').forEach((node) => {
          node.classList.remove('active');
        });
        chip.classList.add('active');
      });
    });
  }

  function _bindDescriptionCounter() {
    const textarea = document.getElementById('ur-description');
    const counter = document.getElementById('ur-desc-count');
    if (!textarea || !counter) return;
    const update = () => { counter.textContent = String((textarea.value || '').length); };
    textarea.addEventListener('input', update);
    update();
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
    const city = document.getElementById('ur-city')?.value;
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
    if (city) fd.append('city', city);
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
    if (!btn) return;
    btn.disabled = false;
    btn.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" style="vertical-align:middle;margin-inline-end:4px"><path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/></svg>إرسال الطلب';
  }

  // Boot
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
  return {};
})();
