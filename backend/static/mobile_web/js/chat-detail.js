(function () {
  "use strict";
  const api = window.NawafethApi;
  const ui = window.NawafethUi;

  // Extract thread ID from URL: /web/chats/<id>/
  const pathParts = window.location.pathname.split("/").filter(Boolean);
  const threadId = pathParts[pathParts.length - 1];

  const $area = document.getElementById("messages-area");
  const $input = document.getElementById("msg-input");
  const $send = document.getElementById("btn-send");
  const $back = document.getElementById("btn-back");
  const $attach = document.getElementById("btn-attach");
  const $fileInput = document.getElementById("file-input");
  const $peerName = document.getElementById("peer-name");
  const $peerAvatar = document.getElementById("peer-avatar");

  let state = { messages: [], myUserId: "", sending: false, pollTimer: null };

  function mediaUrl(path) {
    if (!path) return "";
    if (/^https?:\/\//i.test(path)) return path;
    return (window.location.origin || "") + (path.startsWith("/") ? path : "/" + path);
  }

  function formatTime(d) {
    if (!d) return "";
    const dt = new Date(d);
    return dt.toLocaleTimeString("ar-SA", { hour: "2-digit", minute: "2-digit" });
  }

  function formatDate(d) {
    if (!d) return "";
    return new Date(d).toLocaleDateString("ar-SA");
  }

  function renderMessage(m) {
    const isMine = String(m.sender_id || m.sender) === state.myUserId;
    const cls = isMine ? "is-mine" : "is-theirs";
    let attachHtml = "";
    if (m.attachment || m.file) {
      const url = mediaUrl(m.attachment || m.file);
      attachHtml = `<a class="nw-msg-attachment" href="${url}" target="_blank"><span class="material-icons-round" style="font-size:14px">attachment</span>مرفق</a>`;
    }
    return `
      <div class="nw-msg-row ${cls}">
        <div class="nw-msg-bubble">
          ${ui.safeText(m.text || m.content || m.body || "")}
          ${attachHtml}
          <span class="nw-msg-time">${formatTime(m.created_at || m.timestamp)}</span>
        </div>
      </div>
    `;
  }

  function renderMessages(messages) {
    if (messages.length === 0) {
      $area.innerHTML = '<div class="nw-chat-empty-msg"><span class="material-icons-round">chat</span><p>ابدأ المحادثة الآن</p></div>';
      return;
    }

    let html = "";
    let lastDate = "";
    messages.forEach(function (m) {
      const d = formatDate(m.created_at || m.timestamp);
      if (d !== lastDate) {
        html += '<div class="nw-msg-date-sep">' + d + "</div>";
        lastDate = d;
      }
      html += renderMessage(m);
    });
    $area.innerHTML = html;
    $area.scrollTop = $area.scrollHeight;
  }

  async function loadMessages() {
    if (!api.isAuthenticated() || !threadId) return;

    try {
      const data = await api.get(`/api/messaging/direct/thread/${threadId}/messages/`);
      const messages = data.results || data || [];
      state.messages = messages;
      renderMessages(messages);

      // Mark as read
      try { await api.post(`/api/messaging/direct/thread/${threadId}/messages/read/`); } catch (_) {}
    } catch (err) {
      $area.innerHTML = '<div class="nw-chat-empty-msg"><span class="material-icons-round">error_outline</span><p>' + ui.safeText(api.getErrorMessage(err.payload)) + "</p></div>";
    }
  }

  async function loadThreadInfo() {
    try {
      const threads = await api.get("/api/messaging/direct/threads/");
      const list = threads.results || threads || [];
      const thread = list.find(function (t) { return String(t.id || t.thread_id) === String(threadId); });
      if (thread) {
        const name = thread.peer_name || thread.other_user_name || "محادثة";
        $peerName.textContent = name;
        const initial = name.charAt(0).toUpperCase();
        if (thread.peer_avatar || thread.other_user_avatar) {
          $peerAvatar.innerHTML = '<img src="' + mediaUrl(thread.peer_avatar || thread.other_user_avatar) + '" alt="">';
        } else {
          $peerAvatar.textContent = initial;
        }
      }
    } catch (_) {}
  }

  async function sendMessage() {
    const text = $input.value.trim();
    if (!text || state.sending) return;

    state.sending = true;
    $send.disabled = true;

    try {
      await api.post(`/api/messaging/direct/thread/${threadId}/messages/send/`, { text: text });
      $input.value = "";
      autoResize();
      await loadMessages();
    } catch (err) {
      alert(api.getErrorMessage(err.payload, "فشل إرسال الرسالة"));
    } finally {
      state.sending = false;
      updateSendBtn();
    }
  }

  async function sendAttachment(file) {
    if (!file) return;
    const fd = new FormData();
    fd.append("file", file);
    fd.append("text", $input.value.trim() || "");

    state.sending = true;
    $send.disabled = true;

    try {
      await api.request("POST", `/api/messaging/direct/thread/${threadId}/messages/send/`, { body: fd, auth: true });
      $input.value = "";
      await loadMessages();
    } catch (err) {
      alert(api.getErrorMessage(err.payload, "فشل إرسال المرفق"));
    } finally {
      state.sending = false;
      updateSendBtn();
    }
  }

  function updateSendBtn() {
    $send.disabled = state.sending || !$input.value.trim();
  }

  function autoResize() {
    $input.style.height = "auto";
    $input.style.height = Math.min($input.scrollHeight, 120) + "px";
  }

  // Events
  $input.addEventListener("input", function () { updateSendBtn(); autoResize(); });
  $input.addEventListener("keydown", function (e) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  });
  $send.addEventListener("click", sendMessage);
  $back.addEventListener("click", function () {
    window.location.href = "/web/chats/";
  });
  $attach.addEventListener("click", function () { $fileInput.click(); });
  $fileInput.addEventListener("change", function () {
    if ($fileInput.files[0]) {
      sendAttachment($fileInput.files[0]);
      $fileInput.value = "";
    }
  });

  document.addEventListener("DOMContentLoaded", function () {
    state.myUserId = String(localStorage.getItem("nawafeth_user_id") || "");
    loadThreadInfo();
    loadMessages();

    // Poll for new messages every 8 seconds
    state.pollTimer = setInterval(loadMessages, 8000);
  });

  // Cleanup
  window.addEventListener("beforeunload", function () {
    if (state.pollTimer) clearInterval(state.pollTimer);
  });
})();
