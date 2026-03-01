(function () {
  "use strict";
  const api = window.NawafethApi;
  const ui = window.NawafethUi;

  let state = { threads: [], filter: "all", search: "", loading: false };

  const $list = document.getElementById("chat-list");
  const $search = document.getElementById("chat-search");
  const $filters = document.getElementById("chat-filters");

  function mediaUrl(path) {
    if (!path) return "";
    if (/^https?:\/\//i.test(path)) return path;
    return (window.location.origin || "") + (path.startsWith("/") ? path : "/" + path);
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
    if (days < 7) return days + " ي";
    return ui.formatDateTime(dateStr);
  }

  function getInitial(name) {
    return (name || "?").charAt(0).toUpperCase();
  }

  function renderTile(t) {
    const name = t.peer_name || t.other_user_name || "محادثة";
    const last = t.last_message || t.last_message_text || "";
    const unread = (t.unread_count || 0) > 0;
    const fav = t.is_favorite;
    const avatar = t.peer_avatar || t.other_user_avatar || "";
    const threadId = t.id || t.thread_id;
    const label = t.client_label || "";

    const avatarHtml = avatar
      ? `<img src="${mediaUrl(avatar)}" alt="">`
      : getInitial(name);

    return `
      <a href="/web/chats/${threadId}/" class="nw-chat-tile ${unread ? "is-unread" : ""}" data-id="${threadId}">
        <div class="nw-chat-avatar">${avatarHtml}</div>
        <div class="nw-chat-content">
          <p class="nw-chat-name">
            ${ui.safeText(name)}
            ${fav ? '<span class="material-icons-round fav-star">star</span>' : ""}
            ${label ? '<span class="nw-client-label">' + ui.safeText(label) + "</span>" : ""}
          </p>
          <p class="nw-chat-last-msg">${ui.safeText(last)}</p>
        </div>
        <div class="nw-chat-meta">
          <span class="nw-chat-time">${relativeTime(t.last_message_at || t.updated_at)}</span>
          ${unread ? '<span class="nw-chat-unread-badge">' + t.unread_count + "</span>" : ""}
        </div>
      </a>
    `;
  }

  function applyFilterAndRender() {
    let filtered = state.threads;

    // Search
    if (state.search) {
      const q = state.search.toLowerCase();
      filtered = filtered.filter(function (t) {
        const name = (t.peer_name || t.other_user_name || "").toLowerCase();
        const msg = (t.last_message || t.last_message_text || "").toLowerCase();
        return name.includes(q) || msg.includes(q);
      });
    }

    // Filter
    switch (state.filter) {
      case "unread":
        filtered = filtered.filter(function (t) { return (t.unread_count || 0) > 0; });
        break;
      case "favorite":
        filtered = filtered.filter(function (t) { return t.is_favorite; });
        break;
      case "clients":
        filtered = filtered.filter(function (t) { return t.client_label; });
        break;
      case "recent":
        filtered = filtered.slice().sort(function (a, b) {
          return new Date(b.last_message_at || b.updated_at || 0) - new Date(a.last_message_at || a.updated_at || 0);
        });
        break;
    }

    if (filtered.length === 0) {
      $list.innerHTML = '<div class="nw-chats-empty"><span class="material-icons-round">chat_bubble_outline</span><p>لا توجد محادثات</p></div>';
    } else {
      $list.innerHTML = filtered.map(renderTile).join("");
    }

    // Update unread badge on chip
    const uc = state.threads.reduce(function (sum, t) { return sum + (t.unread_count || 0); }, 0);
    const unreadChip = $filters.querySelector('[data-filter="unread"]');
    if (unreadChip) {
      const badge = unreadChip.querySelector(".chip-badge");
      if (uc > 0) {
        if (badge) {
          badge.textContent = uc;
        } else {
          unreadChip.insertAdjacentHTML("beforeend", ' <span class="chip-badge">' + uc + "</span>");
        }
      } else if (badge) {
        badge.remove();
      }
    }
  }

  async function loadThreads() {
    if (state.loading) return;
    if (!api.isAuthenticated()) {
      $list.innerHTML = '<div class="nw-chats-empty"><span class="material-icons-round">lock</span><p>سجل دخولك لعرض المحادثات</p></div>';
      return;
    }
    state.loading = true;
    $list.innerHTML = '<div class="nw-chats-loading"></div>';

    try {
      const data = await api.get("/api/messaging/direct/threads/");
      state.threads = data.results || data || [];
      applyFilterAndRender();
    } catch (err) {
      $list.innerHTML = '<div class="nw-chats-empty"><span class="material-icons-round">error_outline</span><p>' + ui.safeText(api.getErrorMessage(err.payload)) + "</p></div>";
    } finally {
      state.loading = false;
    }
  }

  // Filter chips
  $filters.addEventListener("click", function (e) {
    const chip = e.target.closest(".nw-chat-chip");
    if (!chip) return;
    $filters.querySelectorAll(".nw-chat-chip").forEach(function (c) { c.classList.remove("is-active"); });
    chip.classList.add("is-active");
    state.filter = chip.dataset.filter;
    applyFilterAndRender();
  });

  // Search
  let searchTimer;
  $search.addEventListener("input", function () {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(function () {
      state.search = $search.value.trim();
      applyFilterAndRender();
    }, 250);
  });

  document.addEventListener("DOMContentLoaded", function () {
    loadThreads();
  });
})();
