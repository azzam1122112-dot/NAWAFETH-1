/* ===================================================================
   loginPage.js — Login/OTP page controller
   POST /api/accounts/otp/send/  → send OTP
   POST /api/accounts/otp/verify/ → verify & get JWT tokens
   =================================================================== */
'use strict';

const LoginPage = (() => {
  let _phone = '';
  let _resendTimer = null;

  function init() {
    // If already logged in, redirect to next or home
    if (Auth.isLoggedIn()) {
      const next = new URLSearchParams(window.location.search).get('next') || '/';
      window.location.href = next;
      return;
    }

    // Elements
    const phoneInput  = document.getElementById('phone-input');
    const otpInput    = document.getElementById('otp-input');
    const btnSend     = document.getElementById('btn-send-otp');
    const btnVerify   = document.getElementById('btn-verify-otp');
    const btnResend   = document.getElementById('btn-resend-otp');
    const btnBack     = document.getElementById('btn-back-phone');
    const btnGuest    = document.getElementById('btn-guest');

    // Send OTP
    btnSend.addEventListener('click', () => _sendOTP(phoneInput));
    phoneInput.addEventListener('keydown', e => { if (e.key === 'Enter') _sendOTP(phoneInput); });

    // Verify OTP
    btnVerify.addEventListener('click', () => _verifyOTP(otpInput));
    otpInput.addEventListener('keydown', e => { if (e.key === 'Enter') _verifyOTP(otpInput); });

    // Resend
    btnResend.addEventListener('click', () => _sendOTP(phoneInput, true));

    // Back to phone step
    btnBack.addEventListener('click', () => {
      document.getElementById('step-otp').classList.add('hidden');
      document.getElementById('step-phone').classList.remove('hidden');
    });

    // Guest
    btnGuest.addEventListener('click', () => {
      Auth.logout();
      window.location.href = '/';
    });
  }

  async function _sendOTP(phoneInput, isResend) {
    const phone = phoneInput.value.trim();
    const errEl = document.getElementById('phone-error');

    // Validate: Saudi number starting with 05
    if (!/^05\d{8}$/.test(phone)) {
      _showError(errEl, 'أدخل رقم جوال صحيح يبدأ بـ 05');
      return;
    }
    _hideError(errEl);
    _phone = phone;

    // Loading
    _setLoading('send-otp', true);

    const res = await ApiClient.request('/api/accounts/otp/send/', {
      method: 'POST',
      body: { phone: phone },
    });

    _setLoading('send-otp', false);

    if (res.ok) {
      // Switch to OTP step
      document.getElementById('step-phone').classList.add('hidden');
      document.getElementById('step-otp').classList.remove('hidden');
      document.getElementById('otp-phone-display').textContent = phone;
      document.getElementById('otp-input').value = '';
      document.getElementById('otp-input').focus();

      // Show dev code if available
      if (res.data && res.data.dev_code) {
        document.getElementById('otp-input').value = String(res.data.dev_code);
      }

      // Start resend timer
      _startResendTimer();
    } else {
      const msg = res.data && (res.data.detail || res.data.error) || 'حدث خطأ، حاول مرة أخرى';
      _showError(errEl, msg);
    }
  }

  async function _verifyOTP(otpInput) {
    const code = otpInput.value.trim();
    const errEl = document.getElementById('otp-error');

    if (!/^\d{4}$/.test(code)) {
      _showError(errEl, 'أدخل رمز التحقق المكون من 4 أرقام');
      return;
    }
    _hideError(errEl);

    _setLoading('verify-otp', true);

    const res = await ApiClient.request('/api/accounts/otp/verify/', {
      method: 'POST',
      body: { phone: _phone, code: code },
    });

    _setLoading('verify-otp', false);

    if (res.ok && res.data) {
      // Save tokens
      Auth.saveTokens({
        access: res.data.access,
        refresh: res.data.refresh,
        user_id: res.data.user_id,
        role_state: res.data.role_state,
      });

      // Redirect
      const next = new URLSearchParams(window.location.search).get('next') || '/';
      window.location.href = next;
    } else {
      const msg = res.data && (res.data.detail || res.data.error) || 'رمز التحقق غير صحيح';
      _showError(errEl, msg);
    }
  }

  function _startResendTimer() {
    const btn = document.getElementById('btn-resend-otp');
    const span = document.getElementById('resend-timer');
    let sec = 60;
    btn.disabled = true;

    if (_resendTimer) clearInterval(_resendTimer);
    _resendTimer = setInterval(() => {
      sec--;
      span.textContent = sec;
      if (sec <= 0) {
        clearInterval(_resendTimer);
        btn.disabled = false;
        span.textContent = '';
      }
    }, 1000);
  }

  function _setLoading(prefix, loading) {
    const txt = document.getElementById(prefix + '-text');
    const spin = document.getElementById(prefix + '-spinner');
    if (txt) txt.classList.toggle('hidden', loading);
    if (spin) spin.classList.toggle('hidden', !loading);
  }

  function _showError(el, msg) { if (el) { el.textContent = msg; el.classList.remove('hidden'); } }
  function _hideError(el) { if (el) { el.textContent = ''; el.classList.add('hidden'); } }

  // Boot
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else { init(); }

  return {};
})();
