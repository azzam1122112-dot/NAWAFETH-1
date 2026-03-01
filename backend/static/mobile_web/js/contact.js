(function () {
  "use strict";
  const api = window.NawafethApi;
  const ui = window.NawafethUi;

  const $form = document.getElementById("ticket-form");
  const $team = document.getElementById("ticket-team");
  const $subject = document.getElementById("ticket-subject");
  const $desc = document.getElementById("ticket-desc");
  const $file = document.getElementById("ticket-file");
  const $error = document.getElementById("ticket-error");
  const $success = document.getElementById("ticket-success");
  const $ticketsList = document.getElementById("tickets-list");

  const STATUS_LABELS = {
    new: "جديدة",
    in_progress: "قيد المعالجة",
    returned: "مرتجعة",
    closed: "مغلقة",
  };

  async function loadTeams() {
    try {
      const data = await api.get("/api/support/teams/", { auth: false });
      const teams = data.results || data || [];
      teams.forEach(function (t) {
        const opt = document.createElement("option");
        opt.value = t.id;
        opt.textContent = t.name || t.title;
        $team.appendChild(opt);
      });
    } catch (_) {}
  }

  async function loadTickets() {
    if (!api.isAuthenticated()) {
      $ticketsList.innerHTML = '<p style="font-size:12px;color:#9ca3af;text-align:center;padding:20px">سجل دخولك لعرض التذاكر</p>';
      return;
    }

    try {
      const data = await api.get("/api/support/tickets/my/");
      const tickets = data.results || data || [];

      if (tickets.length === 0) {
        $ticketsList.innerHTML = '<p style="font-size:12px;color:#9ca3af;text-align:center;padding:20px">لا توجد تذاكر سابقة</p>';
        return;
      }

      $ticketsList.innerHTML = tickets.map(function (t) {
        const status = t.status || "new";
        const label = STATUS_LABELS[status] || status;
        return `
          <div class="nw-ticket-card" data-id="${t.id}">
            <div class="nw-ticket-status-dot status-${status}"></div>
            <div class="nw-ticket-info">
              <p class="nw-ticket-subject">${ui.safeText(t.subject || t.title || "تذكرة #" + t.id)}</p>
              <p class="nw-ticket-meta">${ui.formatDateTime(t.created_at)} — ${ui.safeText(t.team_name || "")}</p>
            </div>
            <span class="nw-ticket-status-pill status-${status}">${ui.safeText(label)}</span>
          </div>
        `;
      }).join("");
    } catch (err) {
      $ticketsList.innerHTML = '<p style="font-size:12px;color:#dc2626;text-align:center;padding:20px">' + ui.safeText(api.getErrorMessage(err.payload)) + "</p>";
    }
  }

  $form.addEventListener("submit", async function (e) {
    e.preventDefault();
    $error.hidden = true;
    $success.hidden = true;

    if (!api.isAuthenticated()) {
      $error.textContent = "يجب تسجيل الدخول أولاً";
      $error.hidden = false;
      return;
    }

    const fd = new FormData();
    fd.append("team", $team.value);
    fd.append("subject", $subject.value.trim());
    fd.append("description", $desc.value.trim());
    if ($file.files[0]) {
      fd.append("attachment", $file.files[0]);
    }

    try {
      await api.request("POST", "/api/support/tickets/create/", { body: fd, auth: true });
      $success.textContent = "تم إرسال التذكرة بنجاح! سيتم الرد عليك قريباً.";
      $success.hidden = false;
      $form.reset();
      loadTickets();
    } catch (err) {
      $error.textContent = api.getErrorMessage(err.payload, "فشل إرسال التذكرة");
      $error.hidden = false;
    }
  });

  // Click ticket to show detail
  $ticketsList.addEventListener("click", function (e) {
    const card = e.target.closest(".nw-ticket-card");
    if (!card) return;
    const id = card.dataset.id;
    // Could open a detail modal — for now we just expand inline
    loadTicketDetail(id, card);
  });

  async function loadTicketDetail(id, card) {
    if (card.querySelector(".nw-ticket-detail")) {
      card.querySelector(".nw-ticket-detail").remove();
      return;
    }

    try {
      const data = await api.get(`/api/support/tickets/${id}/`);
      const detail = document.createElement("div");
      detail.className = "nw-ticket-detail";
      detail.style.cssText = "padding:10px 0 0;font-size:12px;color:#374151;line-height:1.7;border-top:1px solid #e5e7eb;margin-top:8px;";
      detail.innerHTML = '<p style="margin:0">' + ui.safeText(data.description || data.body || "") + "</p>";

      // Comments
      if (data.comments && data.comments.length > 0) {
        detail.innerHTML += data.comments.map(function (c) {
          return '<div style="padding:6px 0;border-top:1px dashed #e5e7eb;margin-top:6px"><strong style="font-size:11px;color:#6b7280">' + ui.safeText(c.author_name || "فريق الدعم") + " — " + ui.formatDateTime(c.created_at) + '</strong><p style="margin:2px 0 0">' + ui.safeText(c.text || c.body) + "</p></div>";
        }).join("");
      }

      card.appendChild(detail);
    } catch (_) {}
  }

  document.addEventListener("DOMContentLoaded", function () {
    loadTeams();
    loadTickets();
  });
})();
