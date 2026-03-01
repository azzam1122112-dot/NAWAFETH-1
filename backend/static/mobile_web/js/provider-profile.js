(function () {
  "use strict";
  const api = window.NawafethApi;
  const ui = window.NawafethUi;

  // Extract provider ID from URL: /web/providers/<id>/
  const pathParts = window.location.pathname.split("/").filter(Boolean);
  const providerId = pathParts[pathParts.length - 1];

  let state = { provider: null, isFollowing: false, activeTab: "services" };

  const $cover = document.getElementById("pp-cover");
  const $avatar = document.getElementById("pp-avatar");
  const $name = document.getElementById("pp-name");
  const $category = document.getElementById("pp-category");
  const $bio = document.getElementById("pp-bio");
  const $tabContent = document.getElementById("tab-content");
  const $btnFollow = document.getElementById("btn-follow");
  const $btnMessage = document.getElementById("btn-message");
  const $btnRequest = document.getElementById("btn-request");

  function mediaUrl(path) {
    if (!path) return "";
    if (/^https?:\/\//i.test(path)) return path;
    return (window.location.origin || "") + (path.startsWith("/") ? path : "/" + path);
  }

  async function loadProfile() {
    try {
      const p = await api.get(`/api/providers/${providerId}/`);
      state.provider = p;

      // Cover
      if (p.cover_image || p.cover) {
        $cover.innerHTML = '<img src="' + mediaUrl(p.cover_image || p.cover) + '" alt="">' + $cover.innerHTML;
      }

      // Avatar
      const logo = p.logo || p.avatar || p.profile_picture;
      if (logo) {
        $avatar.innerHTML = '<img src="' + mediaUrl(logo) + '" alt="">';
      } else {
        $avatar.textContent = (p.business_name || p.name || "?").charAt(0);
      }

      $name.textContent = p.business_name || p.name || "";
      $category.textContent = p.category_name || p.category || "";
      $bio.textContent = p.bio || p.description || "";

      // Stats
      await loadStats();

      // Check follow status
      state.isFollowing = p.is_following || false;
      updateFollowBtn();

      // Load default tab
      loadTab("services");
    } catch (err) {
      $tabContent.innerHTML = '<div class="nw-pp-empty"><span class="material-icons-round">error_outline</span><p>' + ui.safeText(api.getErrorMessage(err.payload)) + "</p></div>";
    }
  }

  async function loadStats() {
    try {
      const stats = await api.get(`/api/providers/${providerId}/stats/`);
      document.getElementById("stat-followers").textContent = stats.followers_count || stats.followers || 0;
      document.getElementById("stat-following").textContent = stats.following_count || stats.following || 0;
      document.getElementById("stat-likes").textContent = stats.likes_count || stats.likes || 0;
      document.getElementById("stat-completed").textContent = stats.completed_requests || stats.completed || 0;
    } catch (_) {}
  }

  function updateFollowBtn() {
    if (state.isFollowing) {
      $btnFollow.classList.add("is-following");
      $btnFollow.innerHTML = '<span class="material-icons-round">check</span>متابَع';
    } else {
      $btnFollow.classList.remove("is-following");
      $btnFollow.innerHTML = '<span class="material-icons-round">person_add</span>متابعة';
    }
  }

  // ── Tab Content Loaders ──
  async function loadTab(tab) {
    state.activeTab = tab;
    $tabContent.innerHTML = '<div class="nw-pp-loading"></div>';

    switch (tab) {
      case "services": return loadServices();
      case "portfolio": return loadPortfolio();
      case "reviews": return loadReviews();
    }
  }

  async function loadServices() {
    try {
      const data = await api.get(`/api/providers/${providerId}/services/`);
      const list = data.results || data || [];
      if (list.length === 0) {
        $tabContent.innerHTML = '<div class="nw-pp-empty"><span class="material-icons-round">build</span><p>لا توجد خدمات</p></div>';
        return;
      }
      $tabContent.innerHTML = list.map(function (s) {
        return `
          <div class="nw-pp-service">
            <div class="nw-pp-service-icon"><span class="material-icons-round">build_circle</span></div>
            <div class="nw-pp-service-info">
              <p class="nw-pp-service-name">${ui.safeText(s.title || s.name)}</p>
              <p class="nw-pp-service-price">${s.price ? s.price + " ر.س" : "حسب الطلب"}</p>
            </div>
          </div>
        `;
      }).join("");
    } catch (err) {
      $tabContent.innerHTML = '<div class="nw-pp-empty"><span class="material-icons-round">error_outline</span><p>تعذر تحميل الخدمات</p></div>';
    }
  }

  async function loadPortfolio() {
    try {
      const data = await api.get(`/api/providers/${providerId}/portfolio/`);
      const list = data.results || data || [];
      if (list.length === 0) {
        $tabContent.innerHTML = '<div class="nw-pp-empty"><span class="material-icons-round">photo_library</span><p>لا توجد أعمال</p></div>';
        return;
      }
      $tabContent.innerHTML = '<div class="nw-pp-portfolio">' + list.map(function (item) {
        const img = item.image || item.thumbnail || item.file;
        return `<div class="nw-pp-portfolio-item">${img ? '<img src="' + mediaUrl(img) + '" alt="">' : ""}</div>`;
      }).join("") + "</div>";
    } catch (err) {
      $tabContent.innerHTML = '<div class="nw-pp-empty"><span class="material-icons-round">error_outline</span><p>تعذر تحميل المعرض</p></div>';
    }
  }

  async function loadReviews() {
    try {
      // Try reviews endpoint - fall back to provider detail
      let reviews = [];
      try {
        const data = await api.get(`/api/reviews/?provider_id=${providerId}`);
        reviews = data.results || data || [];
      } catch (_) {
        if (state.provider && state.provider.reviews) reviews = state.provider.reviews;
      }

      if (reviews.length === 0) {
        $tabContent.innerHTML = '<div class="nw-pp-empty"><span class="material-icons-round">rate_review</span><p>لا توجد مراجعات بعد</p></div>';
        return;
      }

      $tabContent.innerHTML = reviews.map(function (r) {
        const stars = "★".repeat(r.rating || 0) + "☆".repeat(5 - (r.rating || 0));
        return `
          <div class="nw-pp-review">
            <div class="nw-pp-review-header">
              <div class="nw-pp-review-avatar">${(r.reviewer_name || r.user_name || "?").charAt(0)}</div>
              <div>
                <div class="nw-pp-review-name">${ui.safeText(r.reviewer_name || r.user_name || "مستخدم")}</div>
                <div class="nw-pp-review-stars">${stars}</div>
              </div>
            </div>
            <p class="nw-pp-review-text">${ui.safeText(r.comment || r.text || "")}</p>
            <p class="nw-pp-review-date">${ui.formatDateTime(r.created_at)}</p>
          </div>
        `;
      }).join("");
    } catch (err) {
      $tabContent.innerHTML = '<div class="nw-pp-empty"><span class="material-icons-round">error_outline</span><p>تعذر تحميل المراجعات</p></div>';
    }
  }

  // ── Events ──
  document.querySelectorAll(".nw-pp-tab").forEach(function (tab) {
    tab.addEventListener("click", function () {
      document.querySelectorAll(".nw-pp-tab").forEach(function (t) { t.classList.remove("is-active"); });
      tab.classList.add("is-active");
      loadTab(tab.dataset.tab);
    });
  });

  $btnFollow.addEventListener("click", async function () {
    if (!api.isAuthenticated()) { window.location.href = "/web/auth/login/"; return; }
    try {
      if (state.isFollowing) {
        await api.post(`/api/providers/${providerId}/unfollow/`);
        state.isFollowing = false;
      } else {
        await api.post(`/api/providers/${providerId}/follow/`);
        state.isFollowing = true;
      }
      updateFollowBtn();
      loadStats();
    } catch (_) {}
  });

  $btnMessage.addEventListener("click", async function () {
    if (!api.isAuthenticated()) { window.location.href = "/web/auth/login/"; return; }
    try {
      const res = await api.post("/api/messaging/direct/thread/", { provider_id: parseInt(providerId) });
      const threadId = res.id || res.thread_id;
      window.location.href = "/web/chats/" + threadId + "/";
    } catch (_) {
      alert("تعذر بدء المحادثة");
    }
  });

  $btnRequest.addEventListener("click", function () {
    window.location.href = "/web/search/";
  });

  document.getElementById("btn-back").addEventListener("click", function () {
    window.history.back();
  });

  document.addEventListener("DOMContentLoaded", function () {
    if (!providerId || providerId === "providers") {
      $tabContent.innerHTML = '<div class="nw-pp-empty"><span class="material-icons-round">error</span><p>معرّف المزود غير صالح</p></div>';
      return;
    }
    loadProfile();
  });
})();
