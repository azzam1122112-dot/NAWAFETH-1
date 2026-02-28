(function () {
  "use strict";

  const api = window.NawafethApi;
  if (!api) return;

  const dom = {
    loginRequired: document.getElementById("profile-login-required"),
    content: document.getElementById("profile-content"),
    avatar: document.getElementById("profile-avatar"),
    displayName: document.getElementById("profile-display-name"),
    username: document.getElementById("profile-username"),
    contact: document.getElementById("profile-contact"),
    following: document.getElementById("stat-following"),
    likes: document.getElementById("stat-likes"),
    favorites: document.getElementById("stat-favorites"),
    modeHint: document.getElementById("profile-mode-hint"),
    modeBtn: document.getElementById("profile-mode-btn"),
    error: document.getElementById("profile-error"),
    logoutBtn: document.getElementById("profile-logout-btn"),
  };

  const state = {
    me: null,
    providerProfile: null,
    canSwitch: false,
    providerMode: false,
  };

  function safe(value, fallback) {
    if (value === undefined || value === null || value === "") return fallback || "-";
    return String(value);
  }

  function setError(message) {
    if (!dom.error) return;
    dom.error.textContent = message || "";
    dom.error.hidden = !message;
  }

  function setText(node, value, fallback) {
    if (!node) return;
    node.textContent = safe(value, fallback || "-");
  }

  function showLoginRequired() {
    if (dom.loginRequired) dom.loginRequired.hidden = false;
    if (dom.content) dom.content.hidden = true;
  }

  function showContent() {
    if (dom.loginRequired) dom.loginRequired.hidden = true;
    if (dom.content) dom.content.hidden = false;
  }

  function resolveDisplayName(me) {
    const first = String(me && me.first_name ? me.first_name : "").trim();
    const last = String(me && me.last_name ? me.last_name : "").trim();
    if (first || last) return (first + " " + last).trim();
    if (me && me.username) return String(me.username);
    if (me && me.phone) return String(me.phone);
    return "مستخدم";
  }

  function resolveUsernameDisplay(me) {
    const username = String(me && me.username ? me.username : "").trim();
    if (!username) return "@---";
    return username.startsWith("@") ? username : "@" + username;
  }

  function firstLetter(text) {
    const value = String(text || "").trim();
    if (!value) return "ن";
    return value.slice(0, 1).toUpperCase();
  }

  async function loadProviderProfileIfAny() {
    state.providerProfile = null;
    if (!state.canSwitch) return;
    try {
      state.providerProfile = await api.get("/api/providers/me/profile/");
    } catch (_error) {
      state.providerProfile = null;
    }
  }

  function renderAvatar(displayName) {
    if (!dom.avatar) return;
    const image = state.providerProfile && state.providerProfile.profile_image
      ? String(state.providerProfile.profile_image)
      : "";
    if (image) {
      const absolute = /^https?:\/\//i.test(image)
        ? image
        : window.location.origin.replace(/\/+$/, "") + (image.startsWith("/") ? image : "/" + image);
      dom.avatar.style.backgroundImage = "url('" + absolute + "')";
      dom.avatar.textContent = "";
    } else {
      dom.avatar.style.backgroundImage = "";
      dom.avatar.textContent = firstLetter(displayName);
      dom.avatar.style.display = "flex";
      dom.avatar.style.alignItems = "center";
      dom.avatar.style.justifyContent = "center";
      dom.avatar.style.fontWeight = "800";
      dom.avatar.style.fontSize = "1.2rem";
      dom.avatar.style.color = "#fff";
    }
  }

  function renderModeState() {
    if (!dom.modeHint || !dom.modeBtn) return;
    if (!state.canSwitch) {
      dom.modeHint.textContent = "وضع عميل فقط (لا يوجد ملف مزود خدمة)";
      dom.modeBtn.textContent = "غير متاح";
      dom.modeBtn.disabled = true;
      return;
    }
    dom.modeBtn.disabled = false;
    if (state.providerMode) {
      dom.modeHint.textContent = "وضع مقدم الخدمة مفعل";
      dom.modeBtn.textContent = "التبديل إلى عميل";
    } else {
      dom.modeHint.textContent = "وضع العميل مفعل";
      dom.modeBtn.textContent = "التبديل إلى مزود";
    }
  }

  function renderProfile() {
    const me = state.me || {};
    const displayName = resolveDisplayName(me);

    showContent();
    setText(dom.displayName, displayName, "مستخدم");
    setText(dom.username, resolveUsernameDisplay(me), "@---");

    const email = String(me.email || "").trim();
    const phone = String(me.phone || "").trim();
    const contact = email && phone ? email + " - " + phone : (email || phone || "-");
    setText(dom.contact, contact, "-");

    setText(dom.following, me.following_count || 0, "0");
    setText(dom.likes, me.likes_count || 0, "0");
    setText(dom.favorites, me.favorites_media_count || 0, "0");

    renderAvatar(displayName);
    renderModeState();
  }

  async function toggleMode() {
    if (!state.canSwitch) return;
    const next = !state.providerMode;
    api.setProviderMode(next);
    state.providerMode = next;
    renderModeState();
    setError("");

    if (next) {
      window.location.href = api.urls.providerDashboard || "/web/provider/dashboard/";
    }
  }

  function bindEvents() {
    if (dom.modeBtn) {
      dom.modeBtn.addEventListener("click", function () {
        toggleMode();
      });
    }
    if (dom.logoutBtn) {
      dom.logoutBtn.addEventListener("click", function () {
        api.clearSession();
        window.location.href = api.urls.home || "/";
      });
    }
  }

  async function init() {
    bindEvents();
    if (!api.isAuthenticated()) {
      showLoginRequired();
      return;
    }

    try {
      setError("");
      state.me = await api.get("/api/accounts/me/");
      state.canSwitch = Boolean(
        state.me && (state.me.is_provider === true || state.me.has_provider_profile === true)
      );
      state.providerMode = api.ensureProviderModeFromProfile(state.me || {});
      await loadProviderProfileIfAny();
      renderProfile();
    } catch (error) {
      const status = Number(error && error.status ? error.status : 0);
      if (status === 401) {
        api.clearSession();
        showLoginRequired();
        return;
      }
      setError(api.getErrorMessage(error && error.payload, error.message || "تعذر تحميل بيانات الحساب"));
      showContent();
    }
  }

  document.addEventListener("DOMContentLoaded", init);
})();
