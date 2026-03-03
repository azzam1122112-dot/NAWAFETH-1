"use strict";
var ProfileCompletionPage = (function () {
  var RAW_API = window.ApiClient;
  var API = window.NwApiClient;
  var BASE_WEIGHT = 0.30;
  var OPTIONAL_SECTION_WEIGHT = 0.70 / 6;

  function init() { loadProfile(); }

  function hasText(value) {
    return typeof value === "string" && value.trim().length > 0;
  }

  function hasNonEmptyList(value) {
    if (!Array.isArray(value) || !value.length) return false;
    return value.some(function (item) {
      if (item == null) return false;
      if (typeof item === "string") return item.trim().length > 0;
      if (Array.isArray(item)) return item.length > 0;
      if (typeof item === "object") return Object.keys(item).length > 0;
      return true;
    });
  }

  function toPercent(completion) {
    return Math.max(0, Math.min(100, Math.round(completion * 100)));
  }

  function resolveChecks(profile) {
    // Match Flutter mobile logic in ProviderProfileModel exactly.
    return {
      basic: true,
      service_details: hasText(profile.display_name) && hasText(profile.bio),
      additional: hasText(profile.about_details) || hasNonEmptyList(profile.qualifications) || hasNonEmptyList(profile.experiences),
      contact_full: hasText(profile.whatsapp) || hasText(profile.website) || hasNonEmptyList(profile.social_links),
      lang_loc: hasNonEmptyList(profile.languages) && Number(profile.coverage_radius_km || 0) > 0,
      content: hasText(profile.profile_image) || hasText(profile.cover_image) || hasNonEmptyList(profile.content_sections),
      seo: hasText(profile.seo_keywords) || hasText(profile.seo_meta_description) || hasText(profile.seo_slug)
    };
  }

  function completionPercentFromChecks(checks) {
    var doneOptional = [
      checks.service_details,
      checks.additional,
      checks.contact_full,
      checks.lang_loc,
      checks.content,
      checks.seo
    ].filter(Boolean).length;
    return toPercent(BASE_WEIGHT + (doneOptional * OPTIONAL_SECTION_WEIGHT));
  }

  function checkSvg(done) {
    if (done) {
      return '<svg width="22" height="22" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="#4CAF50"/><path d="M9.1 12.3l2 2 4-4" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
    }
    return '<svg width="22" height="22" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="none" stroke="#c7c7cd" stroke-width="2"/></svg>';
  }

  function renderCompletion(percent) {
    var pct = document.getElementById("pc-percent");
    var fill = document.getElementById("pc-bar-fill");
    if (pct) pct.textContent = percent + "%";
    if (fill) fill.style.width = percent + "%";
  }

  function renderChecks(checks) {
    Object.keys(checks).forEach(function (sectionKey) {
      var done = !!checks[sectionKey];
      var tile = document.querySelector('.pc-section-tile[data-section="' + sectionKey + '"]');
      var el = document.getElementById("pc-check-" + sectionKey);
      if (el) el.innerHTML = checkSvg(done);
      if (!tile) return;
      tile.classList.toggle("is-complete", done);
      tile.classList.toggle("is-incomplete", !done);
      tile.setAttribute("data-complete", done ? "1" : "0");
    });
  }

  function setLoadingMessage(html) {
    var loading = document.getElementById("pc-loading");
    if (loading) loading.innerHTML = html;
  }

  function showContent() {
    var loading = document.getElementById("pc-loading");
    var content = document.getElementById("pc-content");
    if (loading) loading.style.display = "none";
    if (content) content.style.display = "";
  }

  function fetchProfile() {
    if (RAW_API && typeof RAW_API.get === "function") {
      return RAW_API.get("/api/providers/me/profile/");
    }
    return API.get("/api/providers/me/profile/").then(function (data) {
      return { ok: !!data, status: data ? 200 : 0, data: data };
    });
  }

  function loadProfile() {
    fetchProfile().then(function (resp) {
      if (!resp || !resp.ok) {
        if (resp && resp.status === 401) {
          setLoadingMessage('<p class="text-muted">يرجى تسجيل الدخول كـمقدم خدمة لعرض الملف.</p>');
          return;
        }
        if (resp && resp.status === 404) {
          setLoadingMessage('<p class="text-muted">لا يوجد ملف مزود بعد.</p>');
          return;
        }
        setLoadingMessage('<p class="text-muted">تعذر تحميل بيانات الملف. حاول مرة أخرى.</p>');
        return;
      }

      var profile = resp.data || {};
      var checks = resolveChecks(profile);
      var percent = completionPercentFromChecks(checks);
      renderCompletion(percent);
      renderChecks(checks);
      showContent();
    }).catch(function () {
      setLoadingMessage('<p class="text-muted">تعذر تحميل بيانات الملف.</p>');
    });
  }

  document.addEventListener("DOMContentLoaded", init);
  return { init: init };
})();
