(function () {
  "use strict";
  const api = window.NawafethApi;
  const ui = window.NawafethUi;

  const $avatar = document.getElementById("settings-avatar");
  const $nameDisplay = document.getElementById("settings-name");
  const $phoneDisplay = document.getElementById("settings-phone");
  const $firstName = document.getElementById("inp-first-name");
  const $lastName = document.getElementById("inp-last-name");
  const $email = document.getElementById("inp-email");
  const $phone = document.getElementById("inp-phone");
  const $error = document.getElementById("profile-error");
  const $success = document.getElementById("profile-success");
  const $avatarFile = document.getElementById("avatar-file");

  function mediaUrl(path) {
    if (!path) return "";
    if (/^https?:\/\//i.test(path)) return path;
    return (window.location.origin || "") + (path.startsWith("/") ? path : "/" + path);
  }

  async function loadProfile() {
    if (!api.isAuthenticated()) {
      window.location.href = "/web/auth/login/";
      return;
    }

    try {
      const me = await api.get("/api/accounts/me/");

      $firstName.value = me.first_name || "";
      $lastName.value = me.last_name || "";
      $email.value = me.email || "";
      $phone.value = me.phone || me.phone_number || "";

      const name = (me.first_name || "") + " " + (me.last_name || "");
      $nameDisplay.textContent = name.trim() || "مستخدم";
      $phoneDisplay.textContent = me.phone || me.phone_number || "";

      const pic = me.avatar || me.profile_picture;
      if (pic) {
        const img = document.createElement("img");
        img.src = mediaUrl(pic);
        img.alt = "";
        $avatar.prepend(img);
      } else {
        $avatar.prepend(document.createTextNode((me.first_name || "?").charAt(0)));
      }
    } catch (err) {
      $error.textContent = api.getErrorMessage(err.payload, "تعذر تحميل بيانات الحساب");
      $error.hidden = false;
    }
  }

  async function saveProfile() {
    $error.hidden = true;
    $success.hidden = true;

    try {
      const body = {
        first_name: $firstName.value.trim(),
        last_name: $lastName.value.trim(),
        email: $email.value.trim(),
      };
      await api.patch("/api/accounts/me/", body);
      $success.textContent = "تم حفظ التغييرات بنجاح";
      $success.hidden = false;
      $nameDisplay.textContent = (body.first_name + " " + body.last_name).trim();
    } catch (err) {
      $error.textContent = api.getErrorMessage(err.payload, "فشل حفظ التغييرات");
      $error.hidden = false;
    }
  }

  async function uploadAvatar(file) {
    if (!file) return;
    const fd = new FormData();
    fd.append("avatar", file);

    try {
      await api.request("PATCH", "/api/accounts/me/", { body: fd, auth: true });
      // Refresh
      const img = $avatar.querySelector("img");
      const url = URL.createObjectURL(file);
      if (img) {
        img.src = url;
      } else {
        const newImg = document.createElement("img");
        newImg.src = url;
        $avatar.prepend(newImg);
      }
    } catch (err) {
      alert(api.getErrorMessage(err.payload, "فشل رفع الصورة"));
    }
  }

  async function deleteAccount() {
    if (!confirm("هل أنت متأكد من حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.")) return;
    if (!confirm("تأكيد نهائي: سيتم حذف جميع بياناتك بشكل دائم.")) return;

    try {
      await api.delete("/api/accounts/delete/");
      api.clearSession();
      window.location.href = "/web/";
    } catch (err) {
      alert(api.getErrorMessage(err.payload, "فشل حذف الحساب"));
    }
  }

  // Events
  document.getElementById("btn-save").addEventListener("click", saveProfile);
  document.getElementById("btn-delete-account").addEventListener("click", deleteAccount);
  document.getElementById("btn-change-avatar").addEventListener("click", function () {
    $avatarFile.click();
  });
  $avatarFile.addEventListener("change", function () {
    if ($avatarFile.files[0]) {
      uploadAvatar($avatarFile.files[0]);
    }
  });

  document.addEventListener("DOMContentLoaded", loadProfile);
})();
