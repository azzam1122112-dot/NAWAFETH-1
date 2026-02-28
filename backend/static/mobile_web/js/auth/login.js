(function () {
  "use strict";

  const api = window.NawafethApi;
  if (!api) return;

  function normalizePhone(value) {
    return String(value || "").trim();
  }

  function isPhoneValid(phone) {
    const digits = phone.replace(/[^\d]/g, "");
    return digits.length >= 9 && digits.length <= 14;
  }

  function setError(message) {
    const el = document.getElementById("login-error");
    if (!el) return;
    el.textContent = message || "";
    el.hidden = !message;
  }

  function setInfo(message) {
    const el = document.getElementById("login-info");
    if (!el) return;
    el.textContent = message || "";
    el.hidden = !message;
  }

  document.addEventListener("DOMContentLoaded", function () {
    const form = document.getElementById("login-form");
    const phoneInput = document.getElementById("phone-input");
    const sendBtn = document.getElementById("send-otp-btn");
    const guestBtn = document.getElementById("guest-btn");
    if (!form || !phoneInput || !sendBtn || !guestBtn) return;

    form.addEventListener("submit", async function (event) {
      event.preventDefault();
      setError("");
      setInfo("");

      const phone = normalizePhone(phoneInput.value);
      if (!isPhoneValid(phone)) {
        setError("أدخل رقم جوال صحيح.");
        return;
      }

      sendBtn.disabled = true;
      sendBtn.textContent = "جارٍ الإرسال...";
      try {
        const payload = await api.post("/api/accounts/otp/send/", { phone: phone }, { auth: false });
        const params = new URLSearchParams();
        params.set("phone", phone);
        if (payload && payload.dev_code) {
          params.set("dev_code", String(payload.dev_code));
          sessionStorage.setItem("nawafeth_dev_code", String(payload.dev_code));
          setInfo("رمز التطوير: " + String(payload.dev_code));
        }
        window.location.href = api.urls.otp + "?" + params.toString();
      } catch (error) {
        setError(api.getErrorMessage(error && error.payload, error.message || "تعذر إرسال رمز التحقق"));
      } finally {
        sendBtn.disabled = false;
        sendBtn.textContent = "إرسال رمز التحقق";
      }
    });

    guestBtn.addEventListener("click", function () {
      api.clearSession();
      window.location.href = api.urls.home;
    });
  });
})();

