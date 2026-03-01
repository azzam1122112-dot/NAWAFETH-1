(function () {
  "use strict";
  const api = window.NawafethApi;
  const ui = window.NawafethUi;

  // Tab switching
  const tabs = document.querySelectorAll(".nw-search-tab");
  const tabProviders = document.getElementById("tab-providers");
  const tabRequest = document.getElementById("tab-request");

  tabs.forEach(function (tab) {
    tab.addEventListener("click", function () {
      tabs.forEach(function (t) { t.classList.remove("is-active"); });
      tab.classList.add("is-active");
      if (tab.dataset.tab === "providers") {
        tabProviders.hidden = false;
        tabRequest.hidden = true;
      } else {
        tabProviders.hidden = true;
        tabRequest.hidden = false;
      }
    });
  });

  // ── Provider Search ──
  const $provResults = document.getElementById("provider-results");
  const $provSearch = document.getElementById("provider-search");

  function mediaUrl(path) {
    if (!path) return "";
    if (/^https?:\/\//i.test(path)) return path;
    return (window.location.origin || "") + (path.startsWith("/") ? path : "/" + path);
  }

  function renderProvider(p) {
    const name = p.business_name || p.name || p.user_name || "مزود";
    const cat = p.category_name || p.category || "";
    const avatar = p.logo || p.avatar || p.profile_picture || "";
    const cover = p.cover_image || p.cover || "";
    const id = p.id || p.provider_id;

    const avatarHtml = avatar
      ? `<img src="${mediaUrl(avatar)}" alt="">`
      : (name.charAt(0) || "?");

    return `
      <a href="/web/providers/${id}/" class="nw-provider-card-mini">
        <div class="cover">${cover ? '<img src="' + mediaUrl(cover) + '" alt="">' : ""}</div>
        <div class="info">
          <div class="avatar">${avatarHtml}</div>
          <p class="name">${ui.safeText(name)}</p>
          <p class="cat">${ui.safeText(cat)}</p>
        </div>
      </a>
    `;
  }

  async function loadProviders(search) {
    try {
      let url = "/api/providers/list/";
      if (search) url += "?search=" + encodeURIComponent(search);
      const data = await api.get(url);
      const list = data.results || data || [];
      if (list.length === 0) {
        $provResults.innerHTML = '<div class="nw-search-empty" style="grid-column:1/-1"><span class="material-icons-round">search_off</span><p>لا توجد نتائج</p></div>';
      } else {
        $provResults.innerHTML = list.map(renderProvider).join("");
      }
    } catch (err) {
      $provResults.innerHTML = '<div class="nw-search-empty" style="grid-column:1/-1"><span class="material-icons-round">error_outline</span><p>' + ui.safeText(api.getErrorMessage(err.payload)) + "</p></div>";
    }
  }

  let searchTimer;
  $provSearch.addEventListener("input", function () {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(function () {
      loadProviders($provSearch.value.trim());
    }, 350);
  });

  // ── Service Request Form ──
  const $form = document.getElementById("request-form");
  const $category = document.getElementById("req-category");
  const $subcategory = document.getElementById("req-subcategory");
  const $title = document.getElementById("req-title");
  const $details = document.getElementById("req-details");
  const $titleCount = document.getElementById("title-count");
  const $detailsCount = document.getElementById("details-count");
  const $error = document.getElementById("req-error");
  const $success = document.getElementById("req-success");

  let categories = [];

  async function loadCategories() {
    try {
      const data = await api.get("/api/providers/categories/");
      categories = data.results || data || [];
      categories.forEach(function (c) {
        const opt = document.createElement("option");
        opt.value = c.id;
        opt.textContent = c.name || c.title;
        $category.appendChild(opt);
      });
    } catch (_) {}
  }

  $category.addEventListener("change", function () {
    $subcategory.innerHTML = '<option value="">اختر التصنيف الفرعي</option>';
    const catId = parseInt($category.value);
    const cat = categories.find(function (c) { return c.id === catId; });
    if (cat && cat.subcategories) {
      cat.subcategories.forEach(function (s) {
        const opt = document.createElement("option");
        opt.value = s.id;
        opt.textContent = s.name || s.title;
        $subcategory.appendChild(opt);
      });
    }
  });

  // Char counts
  $title.addEventListener("input", function () {
    $titleCount.textContent = $title.value.length + "/50";
  });
  $details.addEventListener("input", function () {
    $detailsCount.textContent = $details.value.length + "/500";
  });

  // Radio pills
  document.getElementById("delivery-options").addEventListener("click", function (e) {
    const pill = e.target.closest(".nw-radio-pill");
    if (!pill) return;
    document.querySelectorAll(".nw-radio-pill").forEach(function (p) { p.classList.remove("is-selected"); });
    pill.classList.add("is-selected");
  });

  $form.addEventListener("submit", async function (e) {
    e.preventDefault();
    $error.hidden = true;
    $success.hidden = true;

    if (!api.isAuthenticated()) {
      $error.textContent = "يجب تسجيل الدخول أولاً";
      $error.hidden = false;
      return;
    }

    const deliveryVal = document.querySelector('input[name="delivery"]:checked');
    const deadline = document.getElementById("req-deadline").value;

    const body = {
      category_id: parseInt($category.value) || undefined,
      subcategory_id: parseInt($subcategory.value) || undefined,
      title: $title.value.trim(),
      description: $details.value.trim(),
      delivery_option: deliveryVal ? deliveryVal.value : "immediate",
    };
    if (deadline) body.deadline = ui.toIsoFromLocalInput(deadline);

    try {
      await api.post("/api/marketplace/requests/create/", body);
      $success.textContent = "تم إرسال طلبك بنجاح! سيتم إشعارك عند تلقي عروض.";
      $success.hidden = false;
      $form.reset();
      $titleCount.textContent = "0/50";
      $detailsCount.textContent = "0/500";
      document.querySelectorAll(".nw-radio-pill").forEach(function (p, i) {
        p.classList.toggle("is-selected", i === 0);
      });
    } catch (err) {
      $error.textContent = api.getErrorMessage(err.payload, "فشل إرسال الطلب");
      $error.hidden = false;
    }
  });

  document.addEventListener("DOMContentLoaded", function () {
    loadProviders("");
    loadCategories();
  });
})();
