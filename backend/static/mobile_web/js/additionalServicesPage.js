"use strict";
var AdditionalServicesPage = (function () {
  var STATUS_LABELS = {
    pending_payment: "بانتظار الدفع",
    active: "نشط",
    consumed: "مستهلك",
    expired: "منتهي",
    cancelled: "ملغي"
  };
  var STATUS_COLORS = {
    pending_payment: "#B45309",
    active: "#15803D",
    consumed: "#1D4ED8",
    expired: "#6B7280",
    cancelled: "#B91C1C"
  };

  var state = {
    loading: true,
    loadingSilent: false,
    catalogItems: [],
    myExtras: [],
    errorMessage: "",
    buyingSkus: {}
  };

  function asText(value) {
    if (value === null || value === undefined) return "";
    return String(value).trim();
  }

  function asInt(value) {
    var n = Number(value);
    if (Number.isFinite(n)) return Math.trunc(n);
    return 0;
  }

  function asList(payload) {
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.results)) return payload.results;
    return [];
  }

  function statusCode(value) {
    return asText(value).toLowerCase();
  }

  function statusLabel(value) {
    return STATUS_LABELS[statusCode(value)] || "غير معروف";
  }

  function statusColor(value) {
    return STATUS_COLORS[statusCode(value)] || "#374151";
  }

  function escapeHtml(value) {
    return asText(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function formatDate(raw) {
    var text = asText(raw);
    if (!text) return "—";
    var parsed = new Date(text);
    if (Number.isNaN(parsed.getTime())) return text;
    return parsed.toLocaleDateString("ar-SA");
  }

  function formatPrice(value, currency) {
    var amount = asText(value);
    if (!amount) amount = "0";
    var curr = asText(currency).toUpperCase();
    var suffix = curr && curr !== "SAR" ? curr : "ر.س";
    return amount + " " + suffix;
  }

  function extractErrorMessage(res, fallback) {
    if (!res) return fallback;
    var data = res.data || {};
    if (typeof data === "string" && data.trim()) return data.trim();
    if (asText(data.detail)) return asText(data.detail);
    if (asText(data.message)) return asText(data.message);
    if (data.errors && typeof data.errors === "object") {
      var firstKey = Object.keys(data.errors)[0];
      var firstValue = data.errors[firstKey];
      if (Array.isArray(firstValue) && firstValue.length) return asText(firstValue[0]);
      if (asText(firstValue)) return asText(firstValue);
    }
    return fallback;
  }

  function latestPurchaseBySku() {
    var sorted = state.myExtras.slice().sort(function (a, b) {
      return asInt(b.id) - asInt(a.id);
    });
    var map = {};
    for (var i = 0; i < sorted.length; i++) {
      var item = sorted[i];
      var sku = asText(item && item.sku);
      if (!sku) continue;
      if (!map[sku]) map[sku] = item;
    }
    return map;
  }

  function setLoading(value, silent) {
    state.loading = value;
    state.loadingSilent = !!silent;
    var loadingEl = document.getElementById("as-loading");
    var contentEl = document.getElementById("as-content");
    if (!loadingEl || !contentEl) return;

    if (value && !state.loadingSilent) {
      loadingEl.style.display = "";
      contentEl.style.display = "none";
      return;
    }
    loadingEl.style.display = "none";
    contentEl.style.display = "";
  }

  function setError(message) {
    var errorEl = document.getElementById("as-error");
    if (!errorEl) return;
    if (message) {
      errorEl.textContent = message;
      errorEl.style.display = "";
      return;
    }
    errorEl.style.display = "none";
    errorEl.textContent = "";
  }

  function renderCatalog() {
    var root = document.getElementById("as-catalog-items");
    var count = document.getElementById("as-catalog-count");
    if (!root) return;

    if (count) count.textContent = state.catalogItems.length + " عنصر";

    if (!state.catalogItems.length) {
      root.innerHTML = '<div class="as-empty">لا توجد خدمات إضافية متاحة حالياً.</div>';
      return;
    }

    var latestBySku = latestPurchaseBySku();
    root.innerHTML = state.catalogItems.map(function (item) {
      var sku = asText(item && item.sku);
      var title = asText(item && item.title) || sku || "خدمة إضافية";
      var price = formatPrice(item && item.price, item && item.currency);
      var purchase = latestBySku[sku] || null;
      var purchaseStatus = purchase ? statusCode(purchase.status) : "";
      var purchaseStatusLabel = purchase ? statusLabel(purchase.status) : "";
      var purchaseStatusColor = statusColor(purchaseStatus);
      var isLocked = purchaseStatus === "active" || purchaseStatus === "pending_payment";
      var isBuying = !!state.buyingSkus[sku];
      var disabled = !sku || isBuying || isLocked;
      var buttonLabel = "طلب الخدمة";

      if (isBuying) buttonLabel = "جاري الطلب...";
      else if (purchaseStatus === "pending_payment") buttonLabel = "قيد المعالجة";
      else if (purchaseStatus === "active") buttonLabel = "مفعلة حالياً";

      return [
        '<article class="as-card">',
          '<div class="as-card-head">',
            '<div class="as-title-wrap">',
              '<strong>', escapeHtml(title), '</strong>',
              '<div class="as-sub">SKU: ', escapeHtml(sku || "—"), '</div>',
            '</div>',
            '<div class="as-price">', escapeHtml(price), '</div>',
          '</div>',
          '<div class="as-card-footer">',
            purchaseStatusLabel ? '<span class="as-pill" style="color:' + purchaseStatusColor + ';background:' + purchaseStatusColor + '1F">' + escapeHtml(purchaseStatusLabel) + '</span>' : '<span class="as-pill muted">جديد</span>',
            '<button class="as-buy-btn" data-sku="', escapeHtml(sku), '" data-title="', escapeHtml(title), '"', disabled ? " disabled" : "", ">", escapeHtml(buttonLabel), "</button>",
          "</div>",
        "</article>"
      ].join("");
    }).join("");
  }

  function renderHistory() {
    var root = document.getElementById("as-my-items");
    var count = document.getElementById("as-history-count");
    if (!root) return;

    if (count) count.textContent = state.myExtras.length + " طلب";

    if (!state.myExtras.length) {
      root.innerHTML = '<div class="as-empty">لا توجد طلبات خدمات إضافية بعد.</div>';
      return;
    }

    root.innerHTML = state.myExtras.map(function (item) {
      var title = asText(item && item.title) || "خدمة إضافية";
      var sku = asText(item && item.sku) || "—";
      var createdAt = formatDate(item && item.created_at);
      var invoice = asText(item && item.invoice) || "—";
      var amount = formatPrice(item && item.subtotal, item && item.currency);
      var sCode = statusCode(item && item.status);
      var sLabel = statusLabel(item && item.status);
      var sColor = statusColor(sCode);

      return [
        '<article class="as-card as-card-history">',
          '<div class="as-card-head">',
            '<div class="as-title-wrap">',
              '<strong>', escapeHtml(title), '</strong>',
              '<div class="as-sub">SKU: ', escapeHtml(sku), "</div>",
            "</div>",
            '<span class="as-pill" style="color:', sColor, ";background:", sColor, '1F">', escapeHtml(sLabel), "</span>",
          "</div>",
          '<div class="as-meta-grid">',
            '<div class="as-meta-row"><span>التاريخ</span><b>', escapeHtml(createdAt), "</b></div>",
            '<div class="as-meta-row"><span>المبلغ</span><b>', escapeHtml(amount), "</b></div>",
            '<div class="as-meta-row"><span>رقم الفاتورة</span><b>', escapeHtml(invoice), "</b></div>",
          "</div>",
        "</article>"
      ].join("");
    }).join("");
  }

  function render() {
    renderCatalog();
    renderHistory();
  }

  async function loadData(opts) {
    var options = opts || {};
    var silent = !!options.silent;
    setLoading(true, silent);
    setError("");

    try {
      var responses = await Promise.all([
        ApiClient.get("/api/extras/catalog/"),
        ApiClient.get("/api/extras/my/")
      ]);

      var catalogRes = responses[0];
      var myRes = responses[1];

      state.catalogItems = catalogRes && catalogRes.ok ? asList(catalogRes.data) : [];
      state.myExtras = myRes && myRes.ok ? asList(myRes.data) : [];

      var errors = [];
      if (!catalogRes || !catalogRes.ok) {
        errors.push(extractErrorMessage(catalogRes, "تعذر تحميل كتالوج الخدمات الإضافية"));
      }
      if (!myRes || !myRes.ok) {
        errors.push(extractErrorMessage(myRes, "تعذر تحميل سجل الطلبات السابقة"));
      }

      setError(errors.join(" • "));
      render();
    } catch (err) {
      setError("تعذر تحميل البيانات حالياً");
      state.catalogItems = [];
      state.myExtras = [];
      render();
    } finally {
      setLoading(false, false);
    }
  }

  async function buyExtra(sku, title) {
    var cleanSku = asText(sku);
    if (!cleanSku || state.buyingSkus[cleanSku]) return;

    var confirmed = window.confirm('هل تريد طلب خدمة "' + (asText(title) || cleanSku) + '"؟');
    if (!confirmed) return;

    state.buyingSkus[cleanSku] = true;
    renderCatalog();

    try {
      var res = await ApiClient.request("/api/extras/buy/" + encodeURIComponent(cleanSku) + "/", {
        method: "POST"
      });

      if (!res.ok) {
        alert(extractErrorMessage(res, "فشل تنفيذ طلب الخدمة"));
        return;
      }

      var code = asText(res.data && res.data.unified_request_code);
      if (code) alert("تم إرسال طلب الخدمة بنجاح (" + code + ")");
      else alert("تم إرسال طلب الخدمة بنجاح");

      await loadData({ silent: true });
    } catch (err) {
      alert("فشل تنفيذ طلب الخدمة");
    } finally {
      delete state.buyingSkus[cleanSku];
      renderCatalog();
    }
  }

  function bindEvents() {
    var backBtn = document.getElementById("as-back");
    if (backBtn) {
      backBtn.addEventListener("click", function () {
        history.back();
      });
    }

    var refreshBtn = document.getElementById("as-refresh");
    if (refreshBtn) {
      refreshBtn.addEventListener("click", function () {
        loadData({ silent: true });
      });
    }

    var catalogRoot = document.getElementById("as-catalog-items");
    if (catalogRoot) {
      catalogRoot.addEventListener("click", function (e) {
        var btn = e.target.closest(".as-buy-btn");
        if (!btn) return;
        buyExtra(btn.getAttribute("data-sku"), btn.getAttribute("data-title"));
      });
    }
  }

  function init() {
    bindEvents();
    loadData();
  }

  document.addEventListener("DOMContentLoaded", init);
  return { init: init, loadData: loadData };
})();
