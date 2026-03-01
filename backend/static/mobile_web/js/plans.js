(function () {
  "use strict";
  const api = window.NawafethApi;
  const ui = window.NawafethUi;

  const PLAN_ICONS = ["diamond", "workspace_premium", "star", "auto_awesome"];

  const $list = document.getElementById("plans-list");
  const $currentPlan = document.getElementById("current-plan");

  function renderPlan(plan, index) {
    const icon = plan.icon || PLAN_ICONS[index % PLAN_ICONS.length];
    const features = plan.features || plan.feature_list || [];
    const popular = plan.is_popular || plan.recommended;

    let featHtml = "";
    if (Array.isArray(features)) {
      featHtml = features.map(function (f) {
        const text = typeof f === "string" ? f : (f.text || f.name || f.title || "");
        return '<li class="nw-plan-feature"><span class="material-icons-round">check_circle</span>' + ui.safeText(text) + "</li>";
      }).join("");
    }

    return `
      <div class="nw-plan-card">
        <div class="nw-plan-card-header">
          ${popular ? '<div class="nw-plan-popular">الأكثر شيوعاً</div>' : ""}
          <div class="nw-plan-icon material-icons-round">${ui.safeText(icon)}</div>
          <h2 class="nw-plan-name">${ui.safeText(plan.title || plan.name)}</h2>
          <p class="nw-plan-desc">${ui.safeText(plan.description || "")}</p>
          <p class="nw-plan-price">${plan.price || "0"} <small>ر.س</small></p>
          <p class="nw-plan-period">${ui.safeText(plan.period_display || plan.period || "شهرياً")}</p>
        </div>
        <div class="nw-plan-card-body">
          <ul class="nw-plan-features">${featHtml}</ul>
          <button class="nw-plan-subscribe-btn" data-plan-id="${plan.id}">اشترك الآن</button>
        </div>
      </div>
    `;
  }

  async function loadPlans() {
    try {
      const data = await api.get("/api/subscriptions/plans/");
      const plans = data.results || data || [];

      if (plans.length === 0) {
        $list.innerHTML = '<div class="nw-plans-empty"><span class="material-icons-round">credit_card_off</span><p>لا توجد باقات متاحة حالياً</p></div>';
        return;
      }

      $list.innerHTML = plans.map(renderPlan).join("");
    } catch (err) {
      $list.innerHTML = '<div class="nw-plans-empty"><span class="material-icons-round">error_outline</span><p>' + ui.safeText(api.getErrorMessage(err.payload)) + "</p></div>";
    }
  }

  async function loadCurrentSubscription() {
    if (!api.isAuthenticated()) return;
    try {
      const data = await api.get("/api/subscriptions/my/");
      const sub = data.results ? data.results[0] : (Array.isArray(data) ? data[0] : data);
      if (sub && sub.plan_name) {
        document.getElementById("current-plan-name").textContent = "باقتك الحالية: " + (sub.plan_name || sub.plan_title || "");
        document.getElementById("current-plan-expiry").textContent = sub.expires_at ? "تنتهي: " + ui.formatDateTime(sub.expires_at) : "اشتراك نشط";
        $currentPlan.hidden = false;
      }
    } catch (_) {}
  }

  async function subscribe(planId) {
    if (!api.isAuthenticated()) {
      window.location.href = "/web/auth/login/";
      return;
    }
    if (!confirm("هل تريد الاشتراك في هذه الباقة؟")) return;

    try {
      await api.post(`/api/subscriptions/subscribe/${planId}/`);
      alert("تم الاشتراك بنجاح!");
      loadCurrentSubscription();
    } catch (err) {
      alert(api.getErrorMessage(err.payload, "فشل الاشتراك"));
    }
  }

  $list.addEventListener("click", function (e) {
    const btn = e.target.closest(".nw-plan-subscribe-btn");
    if (btn) subscribe(btn.dataset.planId);
  });

  document.addEventListener("DOMContentLoaded", function () {
    loadPlans();
    loadCurrentSubscription();
  });
})();
