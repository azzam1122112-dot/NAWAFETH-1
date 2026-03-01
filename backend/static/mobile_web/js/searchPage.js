/* ===================================================================
   searchPage.js — Search/browse providers page controller
   GET /api/providers/list/?page_size=30&q=X&category_id=Y
   GET /api/providers/categories/
   =================================================================== */
'use strict';

const SearchPage = (() => {
  let _providers = [];
  let _categories = [];
  let _activeCat = '';
  let _query = '';
  let _debounce = null;

  function init() {
    const input = document.getElementById('search-input');
    const clearBtn = document.getElementById('search-clear');
    const sortSel = document.getElementById('sort-select');

    input.addEventListener('input', () => {
      clearBtn.classList.toggle('hidden', !input.value);
      clearTimeout(_debounce);
      _debounce = setTimeout(() => { _query = input.value.trim(); _fetchProviders(); }, 400);
    });

    clearBtn.addEventListener('click', () => {
      input.value = ''; clearBtn.classList.add('hidden');
      _query = ''; _fetchProviders();
      input.focus();
    });

    sortSel.addEventListener('change', () => _renderProviders());

    // Category filter delegation
    document.getElementById('filter-row').addEventListener('click', e => {
      const chip = e.target.closest('.filter-chip');
      if (!chip) return;
      document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      _activeCat = chip.dataset.catId || '';
      _fetchProviders();
    });

    // Load categories + providers
    _fetchCategories();
    _fetchProviders();

    // Focus search if query param
    const urlQ = new URLSearchParams(window.location.search).get('q');
    if (urlQ) { input.value = urlQ; _query = urlQ; _fetchProviders(); }

    const urlCat = new URLSearchParams(window.location.search).get('category');
    if (urlCat) _activeCat = urlCat;
  }

  async function _fetchCategories() {
    const cached = NwCache.get('search_categories');
    if (cached && cached.data) _renderCategoryChips(cached.data);

    const res = await ApiClient.get('/api/providers/categories/');
    if (res.ok && res.data) {
      const list = Array.isArray(res.data) ? res.data : (res.data.results || []);
      NwCache.set('search_categories', list, 300);
      _categories = list;
      _renderCategoryChips(list);
    }
  }

  function _renderCategoryChips(cats) {
    const row = document.getElementById('filter-row');
    // Keep "all" chip
    row.innerHTML = '<button class="filter-chip ' + (!_activeCat ? 'active' : '') + '" data-cat-id="">الكل</button>';
    cats.forEach(cat => {
      const btn = document.createElement('button');
      btn.className = 'filter-chip' + (_activeCat == cat.id ? ' active' : '');
      btn.dataset.catId = cat.id;
      btn.textContent = cat.name;
      row.appendChild(btn);
    });
  }

  async function _fetchProviders() {
    let url = '/api/providers/list/?page_size=30';
    if (_query) url += '&q=' + encodeURIComponent(_query);
    if (_activeCat) url += '&category_id=' + _activeCat;

    const res = await ApiClient.get(url);
    if (res.ok && res.data) {
      _providers = Array.isArray(res.data) ? res.data : (res.data.results || []);
      _renderProviders();
    }
  }

  function _renderProviders() {
    const container = document.getElementById('providers-list');
    const emptyEl = document.getElementById('empty-state');
    const countEl = document.getElementById('results-count');

    let list = [..._providers];

    // Sort
    const sort = document.getElementById('sort-select').value;
    if (sort === 'rating') list.sort((a, b) => (b.rating_avg || 0) - (a.rating_avg || 0));
    else if (sort === 'followers') list.sort((a, b) => (b.followers_count || 0) - (a.followers_count || 0));

    if (countEl) countEl.textContent = list.length + ' نتيجة';

    container.innerHTML = '';
    if (!list.length) {
      emptyEl.classList.remove('hidden');
      return;
    }
    emptyEl.classList.add('hidden');

    const frag = document.createDocumentFragment();
    list.forEach(p => {
      const card = _buildProviderCard(p);
      frag.appendChild(card);
    });
    container.appendChild(frag);
  }

  function _buildProviderCard(p) {
    const profileUrl = ApiClient.mediaUrl(p.profile_image);
    const coverUrl = ApiClient.mediaUrl(p.cover_image);
    const displayName = p.display_name || '';
    const initial = displayName.charAt(0) || '؟';

    const card = UI.el('a', { className: 'provider-card', href: '/provider/' + p.id + '/' });

    // Cover
    const cover = UI.el('div', { className: 'provider-cover' });
    if (coverUrl) cover.appendChild(UI.lazyImg(coverUrl, displayName));
    card.appendChild(cover);

    // Info
    const info = UI.el('div', { className: 'provider-info' });
    const avatar = UI.el('div', { className: 'provider-avatar' });
    if (profileUrl) avatar.appendChild(UI.lazyImg(profileUrl, initial));
    else avatar.appendChild(UI.text(initial));
    info.appendChild(avatar);

    const meta = UI.el('div', { className: 'provider-meta' });
    const nameRow = UI.el('div', { className: 'provider-name-row' });
    nameRow.appendChild(UI.el('span', { className: 'provider-name', textContent: displayName }));
    if (p.is_verified_blue) nameRow.appendChild(UI.icon('verified_blue', 13, '#2196F3'));
    else if (p.is_verified_green) nameRow.appendChild(UI.icon('verified_green', 13, '#4CAF50'));
    meta.appendChild(nameRow);
    if (p.city) meta.appendChild(UI.el('div', { className: 'provider-city', textContent: p.city }));
    info.appendChild(meta);
    card.appendChild(info);

    // Stats
    const stats = UI.el('div', { className: 'provider-stats' });
    const rating = p.rating_avg > 0 ? parseFloat(p.rating_avg).toFixed(1) : '-';
    stats.appendChild(_stat('star', rating, '#FFC107'));
    stats.appendChild(_stat('people', String(p.followers_count || 0), '#999'));
    stats.appendChild(_stat('heart', String(p.likes_count || 0), '#999'));
    card.appendChild(stats);

    return card;
  }

  function _stat(iconName, value, color) {
    const cls = iconName === 'star' ? 'provider-stat rating' : 'provider-stat';
    return UI.el('span', { className: cls }, [UI.icon(iconName, 13, color), UI.text(' ' + value)]);
  }

  // Boot
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else { init(); }

  return {};
})();
