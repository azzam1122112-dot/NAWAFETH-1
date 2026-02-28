(function () {
  "use strict";

  const api = window.NawafethApi;
  if (!api) return;

  function setError(message) {
    const el = document.getElementById("otp-error");
    if (!el) return;
    el.textContent = message || "";
    el.hidden = !message;
  }

  function setInfo(message) {
    const el = document.getElementById("otp-info");
    if (!el) return;
    el.textContent = message || "";
    el.hidden = !message;
  }

  function readPhone() {
    const params = new URLSearchParams(window.location.search);
    return String(params.get("phone") || "").trim();
  }

  function readDevCode() {
    const params = new URLSearchParams(window.location.search);
    return String(params.get("dev_code") || sessionStorage.getItem("nawafeth_dev_code") || "").trim();
  }

  function redirectAfterAuth(payload) {
    if (payload && payload.needs_completion) {
      window.location.href = api.urls.signup;
      return;
    }
    if (payload && payload.role_state === "provider") {
      window.location.href = api.urls.providerDashboard;
      return;
    }
    window.location.href = api.urls.home;
  }

  document.addEventListener("DOMContentLoaded", function () {
    const phone = readPhone();
    if (!phone) {
      window.location.href = api.urls.login;
      return;
    }

    const phoneEl = document.getElementById("otp-phone");
    if (phoneEl) {
      phoneEl.textContent = phone;
    }

    const digits = Array.from(document.querySelectorAll(".otp-digit"));
    const verifyBtn = document.getElementById("verify-btn");
    const resendBtn = document.getElementById("resend-btn");
    const timerEl = document.getElementById("resend-timer");
    if (!digits.length || !verifyBtn || !resendBtn || !timerEl) return;

    const devCode = readDevCode();
    if (devCode) {
      setInfo("رمز التطوير: " + devCode);
    }

    digits.forEach(function (input, index) {
      input.addEventListener("input", function (event) {
        const value = String(event.target.value || "").replace(/[^\d]/g, "");
        event.target.value = value.slice(0, 1);
        if (event.target.value && index < digits.length - 1) {
          digits[index + 1].focus();
        }
      });

      input.addEventListener("keydown", function (event) {
        if (event.key === "Backspace" && !input.value && index > 0) {
          digits[index - 1].focus();
        }
      });
    });

    function getCode() {
      return digits.map(function (x) { return x.value; }).join("");
    }

    function resetCountdown(seconds) {
      let left = seconds;
      resendBtn.disabled = true;
      timerEl.textContent = "يمكنك إعادة الإرسال بعد " + String(left) + " ثانية";
      const timer = window.setInterval(function () {
        left -= 1;
        if (left <= 0) {
          clearInterval(timer);
          resendBtn.disabled = false;
          timerEl.textContent = "";
          return;
        }
        timerEl.textContent = "يمكنك إعادة الإرسال بعد " + String(left) + " ثانية";
      }, 1000);
    }

    resetCountdown(60);

    verifyBtn.addEventListener("click", async function () {
      setError("");
      setInfo("");
      const code = getCode();
      if (!/^\d{4}$/.test(code)) {
        setError("أدخل رمز التحقق المكوّن من 4 أرقام.");
        return;
      }

      verifyBtn.disabled = true;
      verifyBtn.textContent = "جارٍ التحقق...";
      try {
        const payload = await api.post(
          "/api/accounts/otp/verify/",
          { phone: phone, code: code },
          { auth: false }
        );

        api.setSession({
          access: payload.access || "",
          refresh: payload.refresh || "",
          userId: payload.user_id || "",
          roleState: payload.role_state || "",
        });
        sessionStorage.removeItem("nawafeth_dev_code");
        redirectAfterAuth(payload);
      } catch (error) {
        setError(api.getErrorMessage(error && error.payload, error.message || "فشل التحقق من الرمز"));
      } finally {
        verifyBtn.disabled = false;
        verifyBtn.textContent = "تأكيد الرمز";
      }
    });

    resendBtn.addEventListener("click", async function () {
      setError("");
      setInfo("");
      resendBtn.disabled = true;
      try {
        const payload = await api.post("/api/accounts/otp/send/", { phone: phone }, { auth: false });
        if (payload && payload.dev_code) {
          setInfo("رمز التطوير الجديد: " + String(payload.dev_code));
          sessionStorage.setItem("nawafeth_dev_code", String(payload.dev_code));
        } else {
          setInfo("تم إرسال رمز جديد.");
        }
        resetCountdown(60);
      } catch (error) {
        resendBtn.disabled = false;
        setError(api.getErrorMessage(error && error.payload, error.message || "تعذر إعادة إرسال الرمز"));
      }
    });
  });
})();

