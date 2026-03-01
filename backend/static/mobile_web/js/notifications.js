(function () {
  "use strict";
  const api = window.NawafethApi;
  const ui = window.NawafethUi;

  const ICON_MAP = {
    assignment: { icon: "assignment", cls: "kind-assignment" },
    local_offer: { icon: "local_offer", cls: "kind-offer" },
    offer: { icon: "local_offer", cls: "kind-offer" },
    chat: { icon: "chat_bubble", cls: "kind-chat" },
    chat_bubble: { icon: "chat_bubble", cls: "kind-chat" },
    message: { icon: "chat_bubble", cls: "kind-chat" },
    warning: { icon: "warning", cls: "kind-warning" },
    success: { icon: "check_circle", cls: "kind-success" },
    check: { icon: "check_circle", cls: "kind-success" },
    error: { icon: "error", cls: "kind-error" },
    info: { icon: "info", cls: "kind-info" },
  };

  const PAGE_SIZE = 20;
  let state = { items: [], offset: 0, hasMore: true, loading: false };

  const $list = document.getElementById("notif-list");
  const $loading = document.getElementById("notif-loading");
  const $loadMoreWrap = document.getElementById("load-more-wrap");

  function getIconInfo(kind) {
    return ICON_MAP[kind] || ICON_MAP[(kind || "").split("_")[0]] || { icon: "notifications", cls: "kind-default" };
  }

  function relativeTime(dateStr) {
    if (!dateStr) return "";
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return "الآن";
    if (mins < 60) return mins + " د";
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return hrs + " س";
    const days = Math.floor(hrs / 24);
    if (days < 30) return days + " ي";
    return ui.formatDateTime(dateStr);
  }

  function renderCard(n) {
    const info = getIconInfo(n.kind || n.notification_type);
    const unread = !n.is_read;
    const urgent = n.urgency === "urgent";
    const important = n.urgency === "important";
    const pinned = n.is_pinned;

    let cls = "nw-notif-card";
    if (unread) cls += " is-unread";
    if (urgent) cls += " is-urgent";
    if (important) cls += " is-important";
    if (pinned) cls += " is-pinned";

    let badges = "";
    if (pinned) badges += '<span class="nw-notif-badge badge-pin"><span class="material-icons-round" style="font-size:10px">push_pin</span>مثبت</span>';
    if (n.is_follow_up) badges += '<span class="nw-notif-badge badge-follow"><span class="material-icons-round" style="font-size:10px">flag</span>متابعة</span>';

    return `
      <div class="${cls}" data-id="${n.id}">
        <button class="nw-notif-menu-btn" data-action="menu" data-id="${n.id}" title="خيارات">
          <span class="material-icons-round">more_vert</span>
        </button>
        <div class="nw-notif-icon ${info.cls}">
          <span class="material-icons-round">${ui.safeText(info.icon)}</span>
        </div>
        <div class="nw-notif-body">
          <p class="nw-notif-title">${ui.safeText(n.title || n.message || "إشعار")}</p>
          <p class="nw-notif-desc">${ui.safeText(n.body || n.description || "")}</p>
          <span class="nw-notif-time">${relativeTime(n.created_at || n.timestamp)}</span>
          ${badges ? '<div class="nw-notif-badges">' + badges + "</div>" : ""}
        </div>
      </div>
    `;
  }

  async function loadNotifications(reset) {
    if (state.loading) return;
    if (!api.isAuthenticated()) {
      $list.innerHTML = '<div class="nw-notif-empty"><span class="material-icons-round">lock</span><p>سجل دخولك لعرض الإشعارات</p></div>';
      return;
    }

    state.loading = true;
    if (reset) {
      state.items = [];
      state.offset = 0;
      state.hasMore = true;
      $list.innerHTML = '<div class="nw-notif-loading" id="notif-loading"></div>';
    }

    try {
      const mode = api.isProviderMode() ? "provider" : "client";
      const data = await api.get(`/api/notifications/?mode=${mode}&limit=${PAGE_SIZE}&offset=${state.offset}`);
      const results = data.results || data || [];
      state.items = state.items.concat(results);
      state.offset += results.length;
      state.hasMore = results.length >= PAGE_SIZE;

      if (state.items.length === 0) {
        $list.innerHTML = '<div class="nw-notif-empty"><span class="material-icons-round">notifications_off</span><p>لا توجد إشعارات</p></div>';
      } else {
        if (reset) $list.innerHTML = "";
        results.forEach(function (n) {
          $list.insertAdjacentHTML("beforeend", renderCard(n));
        });
      }
      $loadMoreWrap.hidden = !state.hasMore;
    } catch (err) {
      if (reset) $list.innerHTML = "";
      $list.insertAdjacentHTML("beforeend",
        '<div class="nw-notif-empty"><span class="material-icons-round">error_outline</span><p>' + ui.safeText(api.getErrorMessage(err.payload)) + "</p></div>");
    } finally {
      state.loading = false;
      var ld = document.getElementById("notif-loading");
      if (ld) ld.remove();
    }
  }

  async function markRead(id) {
    try {
      await api.post(`/api/notifications/mark-read/${id}/`);
      const card = $list.querySelector(`[data-id="${id}"]`);
      if (card) card.classList.remove("is-unread");
    } catch (_) {}
  }

  async function markAllRead() {
    try {
      await api.post("/api/notifications/mark-all-read/");
      $list.querySelectorAll(".is-unread").forEach(function (el) {
        el.classList.remove("is-unread");
      });
    } catch (_) {}
  }

  async function deleteOld() {
    if (!confirm("حذف الإشعارات القديمة المقروءة؟")) return;
    try {
      await api.delete("/api/notifications/delete-old/");
      loadNotifications(true);
    } catch (_) {}
  }

  async function togglePin(id) {
    try {
      await api.post(`/api/notifications/actions/${id}/`, { action: "toggle_pin" });
      loadNotifications(true);
    } catch (_) {}
  }

  async function toggleFollowUp(id) {
    try {
      await api.post(`/api/notifications/actions/${id}/`, { action: "toggle_follow_up" });
      loadNotifications(true);
    } catch (_) {}
  }

  // Event handlers
  document.getElementById("btn-mark-all").addEventListener("click", markAllRead);
  document.getElementById("btn-delete-old").addEventListener("click", deleteOld);
  document.getElementById("btn-load-more").addEventListener("click", function () {
    loadNotifications(false);
  });

  $list.addEventListener("click", function (e) {
    const card = e.target.closest(".nw-notif-card");
    if (!card) return;

    // Menu button
    const menuBtn = e.target.closest("[data-action='menu']");
    if (menuBtn) {
      e.stopPropagation();
      const id = menuBtn.dataset.id;
      const items = [
        { label: "تعليم كمقروء", action: () => markRead(id) },
        { label: "تثبيت / إلغاء تثبيت", action: () => togglePin(id) },
        { label: "متابعة / إلغاء متابعة", action: () => toggleFollowUp(id) },
      ];
      showContextMenu(menuBtn, items);
      return;
    }

    // Click on card -> mark as read
    const id = card.dataset.id;
    if (card.classList.contains("is-unread")) {
      markRead(id);
    }
  });

  // Simple context menu
  function showContextMenu(anchor, items) {
    let existing = document.querySelector(".nw-ctx-menu");
    if (existing) existing.remove();

    const menu = document.createElement("div");
    menu.className = "nw-ctx-menu";
    menu.style.cssText = "position:fixed;z-index:9999;background:#fff;border-radius:12px;box-shadow:0 8px 24px rgba(0,0,0,0.12);padding:6px 0;min-width:160px;";

    items.forEach(function (item) {
      const btn = document.createElement("button");
      btn.style.cssText = "display:block;width:100%;border:none;background:none;padding:10px 16px;text-align:right;font-family:inherit;font-size:12.5px;font-weight:600;color:#374151;cursor:pointer;";
      btn.textContent = item.label;
      btn.addEventListener("click", function () {
        menu.remove();
        item.action();
      });
      btn.addEventListener("mouseenter", function () { btn.style.background = "#f7f2ff"; });
      btn.addEventListener("mouseleave", function () { btn.style.background = "none"; });
      menu.appendChild(btn);
    });

    document.body.appendChild(menu);
    const r = anchor.getBoundingClientRect();
    menu.style.top = r.bottom + 4 + "px";
    menu.style.right = (window.innerWidth - r.right) + "px";

    setTimeout(function () {
      document.addEventListener("click", function handler() {
        menu.remove();
        document.removeEventListener("click", handler);
      });
    }, 10);
  }

  document.addEventListener("DOMContentLoaded", function () {
    loadNotifications(true);
  });
})();
