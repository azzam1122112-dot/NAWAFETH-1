/* ===================================================================
   interactivePage.js — Social interactions (following / favorites)
   GET /api/providers/me/following/
   GET /api/providers/me/favorites/
   GET /api/providers/me/favorites/spotlights/
   =================================================================== */
'use strict';

const InteractivePage = (() => {
  let _activeTab = 'following';

  function init() {
    if (!Auth.isLoggedIn()) { _showGate(); return; }
    _hideGate();

    // Tab clicks
    document.getElementById('interact-tabs').addEventListener('click', e => {
      const btn = e.target.closest('.tab-btn');
      if (!btn) return;
      document.querySelectorAll('#interact-tabs .tab-btn').forEach(t => t.classList.remove('active'));
      btn.classList.add('active');
      _activeTab = btn.dataset.tab;
      _switchTab();
    });

    _fetchFollowing();
    _fetchFavorites();
  }

  function _showGate() {
    const g = document.getElementById('auth-gate');
    const c = document.getElementById('interactive-content');
    if (g) g.classList.remove('hidden');
    if (c) c.classList.add('hidden');
  }

  function _hideGate() {
    const g = document.getElementById('auth-gate');
    const c = document.getElementById('interactive-content');
    if (g) g.classList.add('hidden');
    if (c) c.classList.remove('hidden');
  }

  function _switchTab() {
    document.getElementById('tab-following').classList.toggle('hidden', _activeTab !== 'following');
    document.getElementById('tab-favorites').classList.toggle('hidden', _activeTab !== 'favorites');
  }

  /* ---- Following ---- */
  async function _fetchFollowing() {
    const container = document.getElementById('following-list');
    const res = await ApiClient.get('/api/providers/me/following/');
    if (res.ok && res.data) {
      const list = Array.isArray(res.data) ? res.data : (res.data.results || []);
      _renderFollowing(container, list);
    } else if (res.status === 401) { _showGate(); }
  }

  function _renderFollowing(container, list) {
    const empty = container.querySelector('.empty-hint') || container.parentElement.querySelector('.empty-hint');
    container.innerHTML = '';
    if (!list.length) {
      container.innerHTML = '<div class="empty-hint"><div class="empty-icon">👥</div><p>لا توجد متابعات بعد</p></div>';
      return;
    }

    const frag = document.createDocumentFragment();
    list.forEach(item => {
      const p = item.provider || item;
      frag.appendChild(_providerCard(p));
    });
    container.appendChild(frag);
  }

  function _providerCard(p) {
    const card = UI.el('a', { className: 'provider-card', href: '/provider/' + p.id + '/' });

    const cover = UI.el('div', { className: 'provider-cover' });
    if (p.cover_image) cover.appendChild(UI.lazyImg(ApiClient.mediaUrl(p.cover_image), ''));
    card.appendChild(cover);

    const info = UI.el('div', { className: 'provider-info' });
    const avatar = UI.el('div', { className: 'provider-avatar' });
    const initial = (p.display_name || '').charAt(0) || '؟';
    if (p.profile_image) avatar.appendChild(UI.lazyImg(ApiClient.mediaUrl(p.profile_image), initial));
    else avatar.appendChild(UI.text(initial));
    info.appendChild(avatar);

    const meta = UI.el('div', { className: 'provider-meta' });
    const nameRow = UI.el('div', { className: 'provider-name-row' });
    nameRow.appendChild(UI.el('span', { className: 'provider-name', textContent: p.display_name || '' }));
    if (p.is_verified_blue) nameRow.appendChild(UI.icon('verified_blue', 13, '#2196F3'));
    meta.appendChild(nameRow);
    if (p.city) meta.appendChild(UI.el('div', { className: 'provider-city', textContent: p.city }));
    info.appendChild(meta);
    card.appendChild(info);

    return card;
  }

  /* ---- Favorites ---- */
  async function _fetchFavorites() {
    const container = document.getElementById('favorites-list');

    // Load both favorites and spotlights in parallel
    const [favRes, spotRes] = await Promise.all([
      ApiClient.get('/api/providers/me/favorites/'),
      ApiClient.get('/api/providers/me/favorites/spotlights/')
    ]);

    let providers = [];
    let spotlights = [];

    if (favRes.ok && favRes.data) {
      providers = Array.isArray(favRes.data) ? favRes.data : (favRes.data.results || []);
    }
    if (spotRes.ok && spotRes.data) {
      spotlights = Array.isArray(spotRes.data) ? spotRes.data : (spotRes.data.results || []);
    }

    _renderFavorites(container, providers, spotlights);
  }

  function _renderFavorites(container, providers, spotlights) {
    container.innerHTML = '';
    if (!providers.length && !spotlights.length) {
      container.innerHTML = '<div class="empty-hint"><div class="empty-icon">💜</div><p>لا توجد مفضلات بعد</p></div>';
      return;
    }

    // Spotlights (media grid)
    if (spotlights.length) {
      const section = UI.el('div', { className: 'fav-section' });
      section.appendChild(UI.el('h3', { className: 'section-title', textContent: 'أعمال مميزة' }));
      const grid = UI.el('div', { className: 'media-grid' });
      spotlights.forEach(s => {
        const item = UI.el('div', { className: 'media-item' });
        if (s.image || s.media_url) {
          item.appendChild(UI.lazyImg(ApiClient.mediaUrl(s.image || s.media_url), ''));
        }
        if (s.provider_name) {
          item.appendChild(UI.el('div', { className: 'media-caption', textContent: s.provider_name || '' }));
        }
        grid.appendChild(item);
      });
      section.appendChild(grid);
      container.appendChild(section);
    }

    // Favorite providers
    if (providers.length) {
      const section = UI.el('div', { className: 'fav-section' });
      section.appendChild(UI.el('h3', { className: 'section-title', textContent: 'مقدمي خدمات مفضلين' }));
      const grid = UI.el('div', { className: 'providers-grid' });
      providers.forEach(item => {
        const p = item.provider || item;
        grid.appendChild(_providerCard(p));
      });
      section.appendChild(grid);
      container.appendChild(section);
    }
  }

  // Boot
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else { init(); }

  return {};
})();
