(function () {
  "use strict";

  const api = window.NawafethApi;
  const ui = window.NawafethUi;
  if (!api || !ui) return;

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

  function iconForCategory(name) {
    const n = String(name || "").toLowerCase();
    if (n.includes("قانون") || n.includes("محام")) return "⚖️";
    if (n.includes("هندس")) return "🧰";
    if (n.includes("تصميم")) return "🎨";
    if (n.includes("توصيل")) return "🚚";
    if (n.includes("صح") || n.includes("طب")) return "🩺";
    if (n.includes("ترجم")) return "🌐";
    if (n.includes("برمج") || n.includes("تقن")) return "💻";
    if (n.includes("صيان")) return "🛠️";
    return "📌";
  }

  function renderCategories(items) {
    const root = document.getElementById("categories-list");
    if (!root) return;
    const fallback = [
      { name: "استشارات قانونية" },
      { name: "خدمات هندسية" },
      { name: "تصميم جرافيك" },
      { name: "توصيل سريع" },
      { name: "برمجة مواقع" },
    ];
    const list = items.length ? items : fallback;
    root.innerHTML = list
      .map(function (cat) {
        return '<div class="nw-chip">' + iconForCategory(cat.name) + " " + ui.safeText(cat.name) + "</div>";
      })
      .join("");
  }

  function renderProviders(items) {
    const root = document.getElementById("providers-list");
    if (!root) return;
    if (!items.length) {
      root.innerHTML = '<div class="nw-list-item">لا توجد بيانات مزودين حالياً.</div>';
      return;
    }
    root.innerHTML = items
      .map(function (provider) {
        const cover = mediaUrl(provider.cover_image || "");
        const avatar = mediaUrl(provider.profile_image || "");
        return (
          '<article class="nw-provider-card">' +
          '<div class="nw-provider-cover" style="background-image:url(\'' + ui.safeText(cover) + '\')"></div>' +
          '<div class="nw-provider-body">' +
          '<div class="nw-provider-top">' +
          '<div class="nw-provider-avatar" style="background-image:url(\'' + ui.safeText(avatar) + '\')"></div>' +
          "<div>" +
          '<p class="nw-provider-name">' + ui.safeText(provider.display_name || "مزود خدمة") + "</p>" +
          '<p class="nw-provider-city">' + ui.safeText(provider.city || "—") + "</p>" +
          "</div>" +
          "</div>" +
          '<div class="nw-provider-stats">' +
          "<span>⭐ " + ui.safeText(provider.rating_avg || "0") + "</span>" +
          "<span>👥 " + ui.safeText(provider.followers_count || 0) + "</span>" +
          "<span>❤ " + ui.safeText(provider.likes_count || 0) + "</span>" +
          "</div>" +
          "</div>" +
          "</article>"
        );
      })
      .join("");
  }

  function renderBanners(items) {
    const root = document.getElementById("banners-list");
    if (!root) return;
    if (!items.length) {
      root.innerHTML = '<div class="nw-list-item">لا توجد حملات ترويجية مفعلة الآن.</div>';
      return;
    }
    root.innerHTML = items
      .map(function (banner) {
        const imageUrl = mediaUrl(banner.file_url || "");
        return (
          '<article class="nw-banner-card">' +
          '<div class="nw-banner-image" style="background-image:url(\'' + ui.safeText(imageUrl) + '\')"></div>' +
          '<div class="nw-banner-meta">' +
          "<strong>" + ui.safeText(banner.caption || "عرض ترويجي") + "</strong>" +
          "<span>" + ui.safeText(banner.provider_display_name || "") + "</span>" +
          "</div>" +
          "</article>"
        );
      })
      .join("");
  }

  async function loadHomeData() {
    try {
      const [categoriesPayload, providersPayload, bannersPayload] = await Promise.all([
        api.get("/api/providers/categories/", { auth: false }),
        api.get("/api/providers/list/?page_size=10", { auth: false }),
        api.get("/api/promo/banners/home/?limit=6", { auth: false }),
      ]);

      renderCategories(asList(categoriesPayload));
      renderProviders(asList(providersPayload));
      renderBanners(asList(bannersPayload));
    } catch (_error) {
      renderCategories([]);
      renderProviders([]);
      renderBanners([]);
    }
  }

  document.addEventListener("DOMContentLoaded", function () {
    loadHomeData();
  });
})();

