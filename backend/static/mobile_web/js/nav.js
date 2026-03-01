/* ===================================================================
   nav.js — Shared navigation controller
   Sidebar toggle, auth-aware UI, bottom nav active state.
   =================================================================== */
'use strict';

const Nav = (() => {
  function init() {
    _initSidebar();
    _initAuthUI();
    _initLogout();
  }

  /* ---------- Sidebar ---------- */
  function _initSidebar() {
    const btn = document.getElementById('btn-menu');
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebar-overlay');
    const close = document.getElementById('sidebar-close');
    if (!btn || !sidebar) return;

    const open = () => { sidebar.classList.add('open'); overlay.classList.remove('hidden'); };
    const shut = () => { sidebar.classList.remove('open'); overlay.classList.add('hidden'); };

    btn.addEventListener('click', open);
    if (overlay) overlay.addEventListener('click', shut);
    if (close) close.addEventListener('click', shut);
  }

  /* ---------- Auth-aware UI ---------- */
  async function _initAuthUI() {
    const loginLink = document.getElementById('sidebar-login-link');
    const logoutBtn = document.getElementById('sidebar-logout');
    const nameEl = document.getElementById('sidebar-name');
    const roleEl = document.getElementById('sidebar-role');
    const avatarEl = document.getElementById('sidebar-avatar');
    const navAvatar = document.getElementById('user-avatar-nav');

    if (!Auth.isLoggedIn()) return; // guest mode — defaults are fine

    // Hide login, show logout
    if (loginLink) loginLink.classList.add('hidden');
    if (logoutBtn) logoutBtn.classList.remove('hidden');

    // Load profile
    const profile = await Auth.getProfile();
    if (profile) {
      const display = profile.display_name || profile.first_name || 'مستخدم';
      if (nameEl) nameEl.textContent = display;
      if (roleEl) roleEl.textContent = profile.role_state === 'provider' ? 'مقدم خدمة' :
                                       profile.role_state === 'client' ? 'عميل' : 'مستخدم';
      const initial = display.charAt(0);
      if (avatarEl) {
        if (profile.profile_image) {
          avatarEl.innerHTML = '';
          const img = document.createElement('img');
          img.src = ApiClient.mediaUrl(profile.profile_image);
          img.alt = display;
          avatarEl.appendChild(img);
        } else {
          avatarEl.textContent = initial;
        }
      }
      if (navAvatar) {
        navAvatar.classList.remove('hidden');
        if (profile.profile_image) {
          navAvatar.innerHTML = '';
          const img = document.createElement('img');
          img.src = ApiClient.mediaUrl(profile.profile_image);
          img.alt = display;
          navAvatar.appendChild(img);
        } else {
          navAvatar.textContent = initial;
        }
      }
    }
  }

  /* ---------- Logout ---------- */
  function _initLogout() {
    const btn = document.getElementById('sidebar-logout');
    if (!btn) return;
    btn.addEventListener('click', async () => {
      const refresh = Auth.getRefreshToken();
      if (refresh) {
        await ApiClient.request('/api/accounts/logout/', {
          method: 'POST', body: { refresh },
        });
      }
      Auth.logout();
      window.location.href = '/';
    });
  }

  // Boot
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  return { init };
})();
