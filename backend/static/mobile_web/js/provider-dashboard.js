(function () {
  "use strict";

  const api = window.NawafethApi;
  const ui = window.NawafethUi;
  if (!api || !ui) return;

  const state = {
    me: null,
    profile: null,
    subscriptions: [],
    categories: [],
    services: [],
    reviews: [],
    rating: null,
    promos: [],
    orders: [],
  };

  function asList(payload) {
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.results)) return payload.results;
    return [];
  }

  function setText(id, value) {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = value === undefined || value === null || value === "" ? "-" : String(value);
  }

  function setError(message) {
    const el = document.getElementById("provider-error");
    if (!el) return;
    el.textContent = message || "";
    el.hidden = !message;
  }

  function completionPercent(profile) {
    if (!profile || typeof profile !== "object") return 30;
    let score = 30;
    if (profile.display_name && profile.bio) score += 12;
    if (profile.about_details || (Array.isArray(profile.qualifications) && profile.qualifications.length)) score += 12;
    if (profile.whatsapp || profile.website || (Array.isArray(profile.social_links) && profile.social_links.length)) score += 12;
    if ((Array.isArray(profile.languages) && profile.languages.length) || Number(profile.coverage_radius_km || 0) > 0) score += 12;
    if (profile.profile_image || profile.cover_image || (Array.isArray(profile.content_sections) && profile.content_sections.length)) score += 12;
    if (profile.seo_keywords || profile.seo_meta_description || profile.seo_slug) score += 10;
    return Math.min(score, 100);
  }

  function setupTabs() {
    const tabs = Array.from(document.querySelectorAll(".nw-tab"));
    const panels = Array.from(document.querySelectorAll(".nw-tab-panel"));
    tabs.forEach(function (btn) {
      btn.addEventListener("click", function () {
        const target = btn.dataset.tab;
        tabs.forEach(function (b) {
          b.classList.toggle("is-active", b === btn);
        });
        panels.forEach(function (panel) {
          panel.classList.toggle("is-active", panel.dataset.panel === target);
        });
      });
    });
  }

  function renderSummary() {
    const me = state.me || {};
    const profile = state.profile || {};
    const rating = state.rating || {};
    const activeSub = asList(state.subscriptions).find(function (item) {
      return item && item.status === "active";
    }) || asList(state.subscriptions)[0] || null;

    setText("provider-name", profile.display_name || me.provider_display_name || "لوحة مزود الخدمة");
    setText("provider-meta", profile.city || me.provider_city || "—");
    setText("followers-count", me.provider_followers_count || 0);
    setText("likes-count", me.provider_likes_received_count || 0);
    setText("rating-avg", Number(rating.rating_avg || profile.rating_avg || 0).toFixed(2));
    setText("services-count", state.services.length);

    const planBadge = document.getElementById("plan-badge");
    if (planBadge) {
      const plan = activeSub && activeSub.plan ? activeSub.plan.title : (activeSub && activeSub.plan_title);
      planBadge.textContent = plan || "الباقة المجانية";
    }

    const completionBadge = document.getElementById("completion-badge");
    if (completionBadge) {
      completionBadge.textContent = "اكتمال الملف " + String(completionPercent(profile)) + "%";
    }
  }

  function populateSubcategories() {
    const select = document.getElementById("service-subcategory");
    if (!select) return;
    const options = ['<option value="">اختر التصنيف الفرعي</option>'];
    asList(state.categories).forEach(function (cat) {
      asList(cat.subcategories).forEach(function (sub) {
        options.push(
          '<option value="' +
            ui.safeText(sub.id) +
            '">' +
            ui.safeText(cat.name) +
            " - " +
            ui.safeText(sub.name) +
            "</option>"
        );
      });
    });
    select.innerHTML = options.join("");
  }

  function renderServices() {
    const root = document.getElementById("services-list");
    if (!root) return;
    if (!state.services.length) {
      root.innerHTML = '<div class="nw-list-item">لا توجد خدمات بعد.</div>';
      return;
    }
    root.innerHTML = state.services
      .map(function (svc) {
        const priceFrom = svc.price_from || "";
        const priceTo = svc.price_to || "";
        const priceLabel = priceFrom && priceTo ? priceFrom + " - " + priceTo : (priceFrom || priceTo || "—");
        return (
          '<article class="nw-list-item">' +
          "<h4>" + ui.safeText(svc.title || "خدمة بدون عنوان") + "</h4>" +
          "<p>التصنيف: " + ui.safeText(svc.subcategory && svc.subcategory.name ? svc.subcategory.name : "—") + "</p>" +
          "<p>السعر: " + ui.safeText(priceLabel) + "</p>" +
          '<button class="nw-link-btn js-delete-service" data-id="' + ui.safeText(svc.id) + '" type="button">حذف</button>' +
          "</article>"
        );
      })
      .join("");
  }

  function renderReviews() {
    const summaryRoot = document.getElementById("reviews-summary");
    const listRoot = document.getElementById("reviews-list");
    if (!summaryRoot || !listRoot) return;

    const rating = state.rating || {};
    summaryRoot.textContent =
      "متوسط التقييم: " +
      String(Number(rating.rating_avg || 0).toFixed(2)) +
      " من 5 (" +
      String(rating.rating_count || 0) +
      " مراجعة)";

    if (!state.reviews.length) {
      listRoot.innerHTML = '<div class="nw-list-item">لا توجد مراجعات منشورة.</div>';
      return;
    }

    listRoot.innerHTML = state.reviews
      .map(function (review) {
        return (
          '<article class="nw-list-item">' +
          "<h4>" + ui.safeText(review.client_name || "عميل") + " - ⭐ " + ui.safeText(review.rating || 0) + "</h4>" +
          "<p>" + ui.safeText(review.comment || "بدون تعليق") + "</p>" +
          "<p>الرد الحالي: " + ui.safeText(review.provider_reply || "لا يوجد رد") + "</p>" +
          '<form class="js-reply-form nw-inline-form" data-id="' + ui.safeText(review.id) + '">' +
          '<input name="reply" type="text" placeholder="أضف ردًا على المراجعة" required>' +
          '<button class="nw-primary-btn" type="submit">حفظ الرد</button>' +
          "</form>" +
          "</article>"
        );
      })
      .join("");
  }

  function renderPromos() {
    const root = document.getElementById("promo-list");
    if (!root) return;
    if (!state.promos.length) {
      root.innerHTML = '<div class="nw-list-item">لا توجد طلبات ترويج بعد.</div>';
      return;
    }
    root.innerHTML = state.promos
      .map(function (promo) {
        return (
          '<article class="nw-list-item">' +
          "<h4>" + ui.safeText(promo.title || "حملة") + "</h4>" +
          "<p>النوع: " + ui.safeText(promo.ad_type || "-") + "</p>" +
          "<p>الحالة: " + ui.safeText(promo.status || "-") + "</p>" +
          "<p>الفترة: " + ui.formatDateTime(promo.start_at) + " - " + ui.formatDateTime(promo.end_at) + "</p>" +
          "</article>"
        );
      })
      .join("");
  }

  function renderOrders() {
    const root = document.getElementById("orders-list");
    if (!root) return;
    if (!state.orders.length) {
      root.innerHTML = '<div class="nw-list-item">لا توجد طلبات حالياً.</div>';
      return;
    }
    root.innerHTML = state.orders
      .map(function (order) {
        return (
          '<article class="nw-list-item">' +
          "<h4>" + ui.safeText(order.title || "طلب") + "</h4>" +
          "<p>الحالة: " + ui.safeText(order.status_label || order.status || "-") + "</p>" +
          "<p>المدينة: " + ui.safeText(order.city || "-") + "</p>" +
          "<p>تاريخ الإنشاء: " + ui.formatDateTime(order.created_at) + "</p>" +
          "</article>"
        );
      })
      .join("");
  }

  async function loadCollections() {
    const [servicesPayload, categoriesPayload, promosPayload, ordersPayload] = await Promise.all([
      api.get("/api/providers/me/services/"),
      api.get("/api/providers/categories/", { auth: false }),
      api.get("/api/promo/requests/my/"),
      api.get("/api/marketplace/provider/requests/"),
    ]);
    state.services = asList(servicesPayload);
    state.categories = asList(categoriesPayload);
    state.promos = asList(promosPayload);
    state.orders = asList(ordersPayload);
  }

  async function loadReviewsIfPossible() {
    const providerId = state.profile && state.profile.id;
    if (!providerId) {
      state.reviews = [];
      state.rating = { rating_avg: 0, rating_count: 0 };
      return;
    }
    const [reviewsPayload, ratingPayload] = await Promise.all([
      api.get("/api/reviews/providers/" + String(providerId) + "/reviews/", { auth: false }),
      api.get("/api/reviews/providers/" + String(providerId) + "/rating/", { auth: false }),
    ]);
    state.reviews = asList(reviewsPayload);
    state.rating = ratingPayload || {};
  }

  async function reloadAll() {
    setError("");
    try {
      const [mePayload, profilePayload, subsPayload] = await Promise.all([
        api.get("/api/accounts/me/"),
        api.get("/api/providers/me/profile/"),
        api.get("/api/subscriptions/my/"),
      ]);
      state.me = mePayload || {};
      state.profile = profilePayload || {};
      state.subscriptions = asList(subsPayload);

      await loadCollections();
      await loadReviewsIfPossible();

      renderSummary();
      populateSubcategories();
      renderServices();
      renderReviews();
      renderPromos();
      renderOrders();
    } catch (error) {
      setError(api.getErrorMessage(error && error.payload, error.message || "تعذر تحميل لوحة المزود"));
    }
  }

  function setupServiceForm() {
    const form = document.getElementById("service-form");
    if (!form) return;

    form.addEventListener("submit", async function (event) {
      event.preventDefault();
      setError("");
      const title = String(document.getElementById("service-title").value || "").trim();
      const priceFrom = String(document.getElementById("service-price-from").value || "").trim();
      const priceTo = String(document.getElementById("service-price-to").value || "").trim();
      const subcategoryId = String(document.getElementById("service-subcategory").value || "").trim();

      if (!title || !subcategoryId) {
        setError("عنوان الخدمة والتصنيف الفرعي مطلوبان.");
        return;
      }

      try {
        await api.post("/api/providers/me/services/", {
          title: title,
          description: "",
          price_from: priceFrom || null,
          price_to: priceTo || null,
          price_unit: "fixed",
          subcategory_id: Number(subcategoryId),
        });
        form.reset();
        await reloadAll();
      } catch (error) {
        setError(api.getErrorMessage(error && error.payload, error.message || "فشل إنشاء الخدمة"));
      }
    });

    const servicesRoot = document.getElementById("services-list");
    if (servicesRoot) {
      servicesRoot.addEventListener("click", async function (event) {
        const target = event.target;
        if (!target || !target.classList.contains("js-delete-service")) return;
        const id = target.getAttribute("data-id");
        if (!id) return;
        try {
          await api.delete("/api/providers/me/services/" + String(id) + "/");
          await reloadAll();
        } catch (error) {
          setError(api.getErrorMessage(error && error.payload, error.message || "فشل حذف الخدمة"));
        }
      });
    }
  }

  function setupReviewReplies() {
    const root = document.getElementById("reviews-list");
    if (!root) return;
    root.addEventListener("submit", async function (event) {
      const form = event.target;
      if (!form || !form.classList.contains("js-reply-form")) return;
      event.preventDefault();
      const reviewId = form.getAttribute("data-id");
      const input = form.querySelector("input[name='reply']");
      const text = String(input && input.value ? input.value : "").trim();
      if (!reviewId || !text) {
        setError("اكتب نص الرد قبل الحفظ.");
        return;
      }
      try {
        await api.post("/api/reviews/reviews/" + String(reviewId) + "/provider-reply/", {
          provider_reply: text,
        });
        await reloadAll();
      } catch (error) {
        setError(api.getErrorMessage(error && error.payload, error.message || "تعذر حفظ الرد"));
      }
    });
  }

  function setupPromoForm() {
    const form = document.getElementById("promo-form");
    if (!form) return;
    form.addEventListener("submit", async function (event) {
      event.preventDefault();
      setError("");

      const title = String(document.getElementById("promo-title").value || "").trim();
      const adType = String(document.getElementById("promo-type").value || "").trim();
      const startAtLocal = String(document.getElementById("promo-start").value || "");
      const endAtLocal = String(document.getElementById("promo-end").value || "");
      const startAt = ui.toIsoFromLocalInput(startAtLocal);
      const endAt = ui.toIsoFromLocalInput(endAtLocal);

      if (!title || !adType || !startAt || !endAt) {
        setError("حقول الترويج الأساسية مطلوبة.");
        return;
      }

      try {
        await api.post("/api/promo/requests/create/", {
          title: title,
          ad_type: adType,
          start_at: startAt,
          end_at: endAt,
          frequency: "60s",
          position: "normal",
        });
        form.reset();
        await reloadAll();
      } catch (error) {
        setError(api.getErrorMessage(error && error.payload, error.message || "تعذر إرسال طلب الترويج"));
      }
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    if (!api.isAuthenticated()) {
      window.location.href = api.urls.login;
      return;
    }
    setupTabs();
    setupServiceForm();
    setupReviewReplies();
    setupPromoForm();
    reloadAll();
  });
})();

