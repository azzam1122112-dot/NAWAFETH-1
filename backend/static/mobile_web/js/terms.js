(function () {
  "use strict";
  const api = window.NawafethApi;
  const ui = window.NawafethUi;

  const $list = document.getElementById("terms-list");

  const ICON_MAP = {
    "اتفاقية الاستخدام": "handshake",
    "سياسة الخصوصية": "shield",
    "الأنظمة والتشريعات": "balance",
    "الخدمات الممنوعة": "block",
  };

  const FALLBACK_TERMS = [
    { title: "اتفاقية الاستخدام", icon: "handshake", content: "يرجى تحميل المحتوى من الخادم..." },
    { title: "سياسة الخصوصية", icon: "shield", content: "يرجى تحميل المحتوى من الخادم..." },
    { title: "الأنظمة والتشريعات", icon: "balance", content: "يرجى تحميل المحتوى من الخادم..." },
    { title: "الخدمات الممنوعة", icon: "block", content: "يرجى تحميل المحتوى من الخادم..." },
  ];

  function renderCard(item, open) {
    const icon = ICON_MAP[item.title] || item.icon || "article";
    const date = item.last_update || item.updated_at || "";
    return `
      <div class="nw-expand-card ${open ? "is-open" : ""}">
        <div class="nw-expand-header" onclick="this.parentElement.classList.toggle('is-open')">
          <div class="nw-expand-icon"><span class="material-icons-round">${ui.safeText(icon)}</span></div>
          <span class="nw-expand-title">${ui.safeText(item.title || item.name)}</span>
          <span class="material-icons-round nw-expand-arrow">expand_more</span>
        </div>
        <div class="nw-expand-body">
          ${date ? '<p class="nw-expand-date">آخر تحديث: ' + ui.formatDateTime(date) + "</p>" : ""}
          ${item.content || item.body || item.text || ""}
        </div>
      </div>
    `;
  }

  async function loadTerms() {
    try {
      const data = await api.get("/api/content/public/", { auth: false });
      const items = data.results || data.items || data.terms || (Array.isArray(data) ? data : []);

      if (items.length === 0) {
        $list.innerHTML = FALLBACK_TERMS.map(function (t, i) { return renderCard(t, i === 0); }).join("");
      } else {
        $list.innerHTML = items.map(function (t, i) { return renderCard(t, i === 0); }).join("");
      }
    } catch (_) {
      // Fallback
      $list.innerHTML = FALLBACK_TERMS.map(function (t, i) { return renderCard(t, i === 0); }).join("");
    }
  }

  document.addEventListener("DOMContentLoaded", loadTerms);
})();
