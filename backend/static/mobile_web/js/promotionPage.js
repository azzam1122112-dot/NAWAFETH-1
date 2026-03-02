"use strict";
var PromotionPage = (function () {
  var STATUS_LABELS = { "new": "جديد", "in_review": "قيد المراجعة", "quoted": "تم التسعير", "pending_payment": "بانتظار الدفع", "active": "مفعل", "rejected": "مرفوض", "expired": "منتهي", "cancelled": "ملغي" };
  var STATUS_COLORS = { "new": "#2196F3", "in_review": "#FF9800", "quoted": "#009688", "pending_payment": "#FFC107", "active": "#4CAF50", "rejected": "#F44336", "expired": "#9E9E9E", "cancelled": "#607D8B" };
  var AD_LABELS = { "banner_home": "بانر الصفحة الرئيسية", "banner_category": "بانر صفحة القسم", "banner_search": "بانر صفحة البحث", "popup_home": "نافذة منبثقة رئيسية", "popup_category": "نافذة منبثقة داخل قسم", "featured_top5": "تمييز ضمن أول 5", "featured_top10": "تمييز ضمن أول 10", "boost_profile": "تعزيز ملف مقدم الخدمة", "push_notification": "إشعار دفع (Push)" };

  function asText(value) {
    if (value === null || value === undefined) return "";
    return String(value).trim();
  }

  function extractList(payload) {
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.results)) return payload.results;
    return [];
  }

  function extractErrorMessage(res, fallback) {
    if (!res) return fallback;
    var data = res.data || {};
    if (typeof data === "string" && data.trim()) return data.trim();
    if (asText(data.detail)) return asText(data.detail);
    if (asText(data.message)) return asText(data.message);
    return fallback;
  }

  function dateToIso(dateStr, isEnd) {
    var clean = asText(dateStr);
    if (!clean) return "";
    var dt = new Date(clean + (isEnd ? "T23:59:59" : "T00:00:00"));
    if (Number.isNaN(dt.getTime())) return "";
    return dt.toISOString();
  }

  function init() {
    loadRequests();
    bindEvents();
  }

  async function loadRequests() {
    var loading = document.getElementById("promo-loading");
    var empty = document.getElementById("promo-empty");
    var listEl = document.getElementById("promo-list");
    loading.style.display = "";
    empty.style.display = "none";
    listEl.innerHTML = "";

    try {
      var res = await ApiClient.get("/api/promo/requests/my/");
      document.getElementById("promo-loading").style.display = "none";

      if (!res.ok) {
        loading.innerHTML = '<p class="text-muted">' + extractErrorMessage(res, "تعذر تحميل الطلبات") + "</p>";
        return;
      }

      var list = extractList(res.data);
      if (!list.length) { document.getElementById("promo-empty").style.display = ""; return; }
      document.getElementById("promo-empty").style.display = "none";
      document.getElementById("promo-list").innerHTML = list.map(function (r) {
        var status = r.status || "new";
        var color = STATUS_COLORS[status] || "#9E9E9E";
        var date = asText(r.created_at).substring(0, 10);
        return '<div class="promo-card">' +
          '<div class="promo-card-header"><div class="promo-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#663D90" stroke-width="2"><path d="M22 12h-9l-3 9L5.6 2.7 2 12h3"/></svg></div>' +
          '<div class="promo-info"><strong>' + (r.title || "طلب ترويج") + '</strong>' + (r.code ? '<span class="text-muted">' + r.code + '</span>' : '') + '</div>' +
          '<span class="badge" style="background:' + color + '20;color:' + color + '">' + (STATUS_LABELS[status] || status) + '</span></div>' +
          '<div class="promo-card-footer"><span>' + (AD_LABELS[r.ad_type] || r.ad_type || "") + '</span><span class="text-muted">' + date + '</span></div></div>';
      }).join("");
    } catch (err) {
      document.getElementById("promo-loading").innerHTML = '<p class="text-muted">تعذر تحميل الطلبات</p>';
    }
  }

  function bindEvents() {
    // Tabs
    document.getElementById("promo-tabs").addEventListener("click", function (e) {
      var tab = e.target.closest(".tab");
      if (!tab) return;
      var name = tab.dataset.tab;
      this.querySelectorAll(".tab").forEach(function (t) { t.classList.toggle("active", t === tab); });
      document.querySelectorAll(".tab-panel").forEach(function (p) { p.classList.toggle("active", p.dataset.panel === name); });
    });

    document.getElementById("btn-go-new") && document.getElementById("btn-go-new").addEventListener("click", function () {
      document.querySelector('[data-tab="new"]').click();
    });

    // Submit form
    document.getElementById("promo-form").addEventListener("submit", async function (e) {
      e.preventDefault();
      var btn = document.getElementById("promo-submit");
      btn.disabled = true; btn.textContent = "جاري الإرسال...";

      var title = document.getElementById("promo-title").value.trim();
      var adType = document.getElementById("promo-ad-type").value;
      var redirect = document.getElementById("promo-redirect").value.trim();
      var start = document.getElementById("promo-start").value;
      var end = document.getElementById("promo-end").value;
      var targetCity = document.getElementById("promo-cities").value.trim();
      var imageFile = document.getElementById("promo-image").files[0];

      var startIso = dateToIso(start, false);
      var endIso = dateToIso(end, true);
      if (!startIso || !endIso) {
        alert("يرجى تحديد تاريخ البداية والنهاية");
        btn.disabled = false; btn.textContent = "إرسال الطلب";
        return;
      }

      var payload = {
        title: title,
        ad_type: adType,
        start_at: startIso,
        end_at: endIso,
        frequency: "60s",
        position: "normal"
      };
      if (redirect) payload.redirect_url = redirect;
      if (targetCity) payload.target_city = targetCity;

      try {
        var createRes = await ApiClient.request("/api/promo/requests/create/", {
          method: "POST",
          body: payload
        });

        if (!createRes.ok) {
          alert(extractErrorMessage(createRes, "فشل إرسال الطلب"));
          return;
        }

        var requestId = createRes.data && createRes.data.id;
        if (requestId && imageFile) {
          var fd = new FormData();
          fd.append("file", imageFile);
          fd.append("asset_type", "image");
          var uploadRes = await ApiClient.request("/api/promo/requests/" + requestId + "/assets/", {
            method: "POST",
            body: fd,
            formData: true
          });
          if (!uploadRes.ok) {
            alert(extractErrorMessage(uploadRes, "تم إنشاء الطلب لكن فشل رفع الملف"));
          }
        }

        alert("تم إرسال طلب الترويج بنجاح");
        document.getElementById("promo-form").reset();
        document.querySelector('[data-tab="requests"]').click();
        loadRequests();
      } catch (err) {
        alert("فشل إرسال الطلب");
      } finally {
        btn.disabled = false; btn.textContent = "إرسال الطلب";
      }
    });
  }

  document.addEventListener("DOMContentLoaded", init);
  return { init: init };
})();
