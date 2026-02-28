(function () {
  "use strict";

  const api = window.NawafethApi;
  const ui = window.NawafethUi;
  if (!api || !ui) return;

  const dom = {
    loginRequired: document.getElementById("interactive-login-required"),
    content: document.getElementById("interactive-content"),
    tabs: document.getElementById("interactive-tabs"),
    panels: document.getElementById("interactive-panels"),
    error: document.getElementById("interactive-error"),
  };

  const state = {
    me: null,
    providerMode: false,
    activeTab: "following",
    following: [],
    followers: [],
    favorites: [],
    loading: {
      following: false,
      followers: false,
      favorites: false,
    },
    errors: {
      following: "",
      followers: "",
      favorites: "",
    },
  };

  function asList(payload) {
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.results)) return payload.results;
    return [];
  }

  function mediaUrl(path) {
    if (!path) return "";
    const p = String(path);
    if (/^https?:\/\//i.test(p)) return p;
    return window.location.origin.replace(/\/+$/, "") + (p.startsWith("/") ? p : "/" + p);
  }

  function setError(message) {
    if (!dom.error) return;
    dom.error.textContent = message || "";
    dom.error.hidden = !message;
  }

  function safe(value, fallback) {
    if (value === undefined || value === null || value === "") return fallback || "-";
    return String(value);
  }

  function availableTabs() {
    const tabs = [
      { key: "following", label: "من أتابع" },
      { key: "favorites", label: "مفضلتي" },
    ];
    if (state.providerMode) {
      tabs.splice(1, 0, { key: "followers", label: "متابعيني" });
    }
    return tabs;
  }

  function showLoginRequired() {
    if (dom.loginRequired) dom.loginRequired.hidden = false;
    if (dom.content) dom.content.hidden = true;
  }

  function showMainContent() {
    if (dom.loginRequired) dom.loginRequired.hidden = true;
    if (dom.content) dom.content.hidden = false;
  }

  function renderTabs() {
    if (!dom.tabs) return;
    const tabs = availableTabs();
    if (!tabs.some(function (tab) { return tab.key === state.activeTab; })) {
      state.activeTab = tabs[0].key;
    }
    dom.tabs.innerHTML = tabs
      .map(function (tab) {
        return (
          '<button type="button" class="nw-interactive-tab' +
          (tab.key === state.activeTab ? " is-active" : "") +
          '" data-tab="' +
          ui.safeText(tab.key) +
          '">' +
          ui.safeText(tab.label) +
          "</button>"
        );
      })
      .join("");
  }

  function emptyCard(message) {
    return '<div class="nw-interactive-empty">' + ui.safeText(message) + "</div>";
  }

  function loadingCard() {
    return emptyCard("جاري التحميل...");
  }

  function errorCard(message, retryAction) {
    return (
      '<div class="nw-interactive-empty">' +
      ui.safeText(message || "تعذر تحميل البيانات.") +
      '<div class="nw-interactive-actions"><button type="button" data-action="' +
      ui.safeText(retryAction) +
      '">إعادة المحاولة</button></div></div>'
    );
  }

  function renderFollowingPanel() {
    if (state.loading.following) return loadingCard();
    if (state.errors.following) return errorCard(state.errors.following, "reload-following");
    if (!state.following.length) return emptyCard("لا تتابع أي مزود خدمة حتى الآن.");

    return (
      '<div class="nw-interactive-grid">' +
      state.following
        .map(function (provider) {
          const cover = mediaUrl(provider.cover_image || "");
          return (
            '<article class="nw-interactive-card">' +
            '<div class="nw-interactive-cover" style="background-image:url(\'' +
            ui.safeText(cover) +
            '\')"></div>' +
            '<div class="nw-interactive-body">' +
            '<h3 class="nw-interactive-title">' +
            ui.safeText(safe(provider.display_name, "مزود خدمة")) +
            "</h3>" +
            '<p class="nw-interactive-meta">المدينة: ' +
            ui.safeText(safe(provider.city)) +
            "</p>" +
            '<p class="nw-interactive-meta">متابعون ' +
            ui.safeText(safe(provider.followers_count, 0)) +
            " • إعجابات " +
            ui.safeText(safe(provider.likes_count, 0)) +
            "</p>" +
            '<div class="nw-interactive-actions">' +
            '<button type="button" class="danger" data-action="unfollow" data-provider-id="' +
            ui.safeText(provider.id) +
            '">إلغاء المتابعة</button>' +
            "</div></div></article>"
          );
        })
        .join("") +
      "</div>"
    );
  }

  function renderFollowersPanel() {
    if (!state.providerMode) return "";
    if (state.loading.followers) return loadingCard();
    if (state.errors.followers) return errorCard(state.errors.followers, "reload-followers");
    if (!state.followers.length) return emptyCard("لا يوجد متابعون بعد.");

    return (
      '<div class="nw-interactive-grid">' +
      state.followers
        .map(function (user) {
          return (
            '<article class="nw-interactive-card"><div class="nw-interactive-cover"></div>' +
            '<div class="nw-interactive-body">' +
            '<h3 class="nw-interactive-title">' +
            ui.safeText(safe(user.display_name, "مستخدم")) +
            "</h3>" +
            '<p class="nw-interactive-meta">@' +
            ui.safeText(safe(user.username, "---")) +
            "</p>" +
            '<p class="nw-interactive-meta">' +
            (user.provider_id ? "لديه ملف مزود خدمة" : "مستخدم عميل") +
            "</p>" +
            "</div></article>"
          );
        })
        .join("") +
      "</div>"
    );
  }

  function renderFavoritesPanel() {
    if (state.loading.favorites) return loadingCard();
    if (state.errors.favorites) return errorCard(state.errors.favorites, "reload-favorites");
    if (!state.favorites.length) return emptyCard("لا توجد عناصر محفوظة في المفضلة.");

    return (
      '<div class="nw-interactive-grid">' +
      state.favorites
        .map(function (item) {
          const image = mediaUrl(item.thumbnail_url || item.file_url || "");
          const sourceLabel = item.__source === "spotlight" ? "أضواء" : "معرض";
          return (
            '<article class="nw-interactive-card">' +
            '<div class="nw-interactive-cover" style="background-image:url(\'' +
            ui.safeText(image) +
            '\')"></div>' +
            '<div class="nw-interactive-body">' +
            '<h3 class="nw-interactive-title">' +
            ui.safeText(safe(item.provider_display_name, "مزود خدمة")) +
            "</h3>" +
            '<p class="nw-interactive-meta">' +
            ui.safeText(sourceLabel) +
            " • إعجابات " +
            ui.safeText(safe(item.likes_count, 0)) +
            "</p>" +
            '<div class="nw-interactive-actions">' +
            '<button type="button" class="danger" data-action="unsave" data-item-id="' +
            ui.safeText(item.id) +
            '" data-source="' +
            ui.safeText(item.__source) +
            '">إزالة من المفضلة</button>' +
            "</div></div></article>"
          );
        })
        .join("") +
      "</div>"
    );
  }

  function renderPanels() {
    if (!dom.panels) return;
    const tabs = availableTabs();
    dom.panels.innerHTML = tabs
      .map(function (tab) {
        let content = "";
        if (tab.key === "following") content = renderFollowingPanel();
        if (tab.key === "followers") content = renderFollowersPanel();
        if (tab.key === "favorites") content = renderFavoritesPanel();
        return (
          '<section class="nw-interactive-panel' +
          (tab.key === state.activeTab ? " is-active" : "") +
          '" data-panel="' +
          ui.safeText(tab.key) +
          '">' +
          content +
          "</section>"
        );
      })
      .join("");
  }

  async function loadFollowing() {
    state.loading.following = true;
    state.errors.following = "";
    try {
      const payload = await api.get("/api/providers/me/following/");
      state.following = asList(payload);
    } catch (error) {
      state.following = [];
      state.errors.following = api.getErrorMessage(error && error.payload, error.message || "تعذر تحميل المتابَعين");
    } finally {
      state.loading.following = false;
    }
  }

  async function loadFollowers() {
    if (!state.providerMode) {
      state.followers = [];
      state.errors.followers = "";
      state.loading.followers = false;
      return;
    }
    state.loading.followers = true;
    state.errors.followers = "";
    try {
      const payload = await api.get("/api/providers/me/followers/");
      state.followers = asList(payload);
    } catch (error) {
      state.followers = [];
      state.errors.followers = api.getErrorMessage(error && error.payload, error.message || "تعذر تحميل المتابعين");
    } finally {
      state.loading.followers = false;
    }
  }

  async function loadFavorites() {
    state.loading.favorites = true;
    state.errors.favorites = "";
    try {
      const results = await Promise.all([
        api.get("/api/providers/me/favorites/"),
        api.get("/api/providers/me/favorites/spotlights/"),
      ]);
      const portfolio = asList(results[0]).map(function (item) {
        return { ...item, __source: "portfolio" };
      });
      const spotlights = asList(results[1]).map(function (item) {
        return { ...item, __source: "spotlight" };
      });
      state.favorites = portfolio.concat(spotlights);
      state.favorites.sort(function (a, b) {
        const ad = new Date(safe(a.created_at, "1970-01-01T00:00:00Z")).getTime();
        const bd = new Date(safe(b.created_at, "1970-01-01T00:00:00Z")).getTime();
        return bd - ad;
      });
    } catch (error) {
      state.favorites = [];
      state.errors.favorites = api.getErrorMessage(error && error.payload, error.message || "تعذر تحميل المفضلة");
    } finally {
      state.loading.favorites = false;
    }
  }

  async function reloadAllData() {
    setError("");
    await Promise.all([loadFollowing(), loadFollowers(), loadFavorites()]);
    renderTabs();
    renderPanels();
  }

  async function handleActionClick(event) {
    const button = event.target.closest("button[data-action]");
    if (!button) return;
    const action = button.getAttribute("data-action");
    if (!action) return;
    button.disabled = true;
    setError("");
    try {
      if (action === "reload-following") {
        await loadFollowing();
      } else if (action === "reload-followers") {
        await loadFollowers();
      } else if (action === "reload-favorites") {
        await loadFavorites();
      } else if (action === "unfollow") {
        const providerId = Number(button.getAttribute("data-provider-id"));
        if (Number.isFinite(providerId) && providerId > 0) {
          await api.post("/api/providers/" + String(providerId) + "/unfollow/", {});
          state.following = state.following.filter(function (item) {
            return Number(item.id) !== providerId;
          });
        }
      } else if (action === "unsave") {
        const itemId = Number(button.getAttribute("data-item-id"));
        const source = String(button.getAttribute("data-source") || "portfolio");
        if (Number.isFinite(itemId) && itemId > 0) {
          const path =
            source === "spotlight"
              ? "/api/providers/spotlights/" + String(itemId) + "/unsave/"
              : "/api/providers/portfolio/" + String(itemId) + "/unsave/";
          await api.post(path, {});
          state.favorites = state.favorites.filter(function (item) {
            return Number(item.id) !== itemId || String(item.__source) !== source;
          });
        }
      }
      renderTabs();
      renderPanels();
    } catch (error) {
      setError(api.getErrorMessage(error && error.payload, error.message || "تعذر تنفيذ الإجراء"));
    } finally {
      button.disabled = false;
    }
  }

  function handleTabClick(event) {
    const tab = event.target.closest(".nw-interactive-tab[data-tab]");
    if (!tab) return;
    state.activeTab = tab.getAttribute("data-tab") || "following";
    renderTabs();
    renderPanels();
  }

  async function init() {
    if (!api.isAuthenticated()) {
      showLoginRequired();
      return;
    }

    showMainContent();
    if (dom.tabs) dom.tabs.addEventListener("click", handleTabClick);
    if (dom.panels) dom.panels.addEventListener("click", handleActionClick);

    try {
      state.me = await api.get("/api/accounts/me/");
      state.providerMode = api.ensureProviderModeFromProfile(state.me || {});
      await reloadAllData();
    } catch (error) {
      const status = Number(error && error.status ? error.status : 0);
      if (status === 401) {
        api.clearSession();
        showLoginRequired();
        return;
      }
      setError(api.getErrorMessage(error && error.payload, error.message || "تعذر تحميل الصفحة"));
      renderTabs();
      renderPanels();
    }
  }

  document.addEventListener("DOMContentLoaded", init);
})();
