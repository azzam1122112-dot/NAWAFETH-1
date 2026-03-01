/* ===================================================================
   addServicePage.js — Add Service hub page controller
   GET /api/providers/categories/
   =================================================================== */
'use strict';

const AddServicePage = (() => {
  function init() {
    _fetchCategories();
  }

  async function _fetchCategories() {
    const grid = document.getElementById('cats-grid');
    const res = await ApiClient.get('/api/providers/categories/');
    if (!res.ok || !res.data) return;

    const cats = Array.isArray(res.data) ? res.data : (res.data.results || []);
    grid.innerHTML = '';
    if (!cats.length) return;

    const frag = document.createDocumentFragment();
    cats.forEach(cat => {
      const item = UI.el('a', { className: 'cat-item', href: '/search/?category=' + cat.id });
      const iconWrap = UI.el('div', { className: 'cat-icon' });
      iconWrap.appendChild(UI.icon(UI.categoryIconKey(cat.name), 24, '#673AB7'));
      item.appendChild(iconWrap);
      item.appendChild(UI.el('div', { className: 'cat-name', textContent: cat.name }));
      frag.appendChild(item);
    });
    grid.appendChild(frag);
  }

  // Boot
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
  return {};
})();
