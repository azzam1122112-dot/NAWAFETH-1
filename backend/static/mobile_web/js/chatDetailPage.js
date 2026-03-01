/* ===================================================================
   chatDetailPage.js — Single chat thread detail
   GET  /api/messaging/direct/thread/<id>/messages/
   POST /api/messaging/direct/thread/<id>/messages/send/
   POST /api/messaging/direct/thread/<id>/messages/read/
   =================================================================== */
'use strict';

const ChatDetailPage = (() => {
  let _threadId = null;
  let _messages = [];
  let _myUserId = null;
  let _pollTimer = null;

  function init() {
    if (!Auth.isLoggedIn()) { window.location.href = '/login/?next=' + encodeURIComponent(window.location.pathname); return; }

    const match = window.location.pathname.match(/\/chat\/(\d+)/);
    if (!match) { window.location.href = '/chats/'; return; }
    _threadId = match[1];
    _myUserId = parseInt(sessionStorage.getItem('nw_user_id')) || 0;

    // Send message
    document.getElementById('btn-send').addEventListener('click', _sendMessage);
    document.getElementById('msg-input').addEventListener('keydown', e => {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); _sendMessage(); }
    });

    _loadMessages();
    _markRead();

    // Poll for new messages every 5s
    _pollTimer = setInterval(_loadMessages, 5000);
  }

  async function _loadMessages() {
    const res = await ApiClient.get('/api/messaging/direct/thread/' + _threadId + '/messages/');
    if (!res.ok) return;

    const list = Array.isArray(res.data) ? res.data : (res.data.results || []);

    // Update peer info from first message if available
    if (list.length && !document.getElementById('peer-name').dataset.loaded) {
      const sample = list[0];
      const peerId = sample.sender_id === _myUserId ? sample.receiver_id : sample.sender_id;
      const peerName = sample.sender_id === _myUserId
        ? (sample.receiver_name || 'مستخدم')
        : (sample.sender_name || 'مستخدم');
      document.getElementById('peer-name').textContent = peerName;
      document.getElementById('peer-name').dataset.loaded = '1';
    }

    // Only re-render if count changed
    if (list.length !== _messages.length) {
      _messages = list;
      _renderMessages();
    }
  }

  function _renderMessages() {
    const container = document.getElementById('chat-messages');
    container.innerHTML = '';

    if (!_messages.length) {
      container.innerHTML = '<div class="empty-hint" style="padding:40px"><div class="empty-icon">💬</div><p>ابدأ المحادثة الآن</p></div>';
      return;
    }

    const frag = document.createDocumentFragment();

    // Messages in chronological order
    const sorted = [..._messages].sort((a, b) => new Date(a.created_at || a.timestamp) - new Date(b.created_at || b.timestamp));

    sorted.forEach(msg => {
      const isMine = msg.sender_id === _myUserId || msg.sender === _myUserId;
      const bubble = UI.el('div', { className: 'msg-bubble ' + (isMine ? 'mine' : 'theirs') });

      bubble.appendChild(UI.el('div', { className: 'msg-text', textContent: msg.text || msg.content || msg.body || '' }));

      if (msg.created_at || msg.timestamp) {
        const dt = new Date(msg.created_at || msg.timestamp);
        bubble.appendChild(UI.el('div', {
          className: 'msg-time',
          textContent: dt.toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' })
        }));
      }

      frag.appendChild(bubble);
    });

    container.appendChild(frag);

    // Scroll to bottom
    container.scrollTop = container.scrollHeight;
  }

  async function _sendMessage() {
    const input = document.getElementById('msg-input');
    const text = input.value.trim();
    if (!text) return;

    input.value = '';
    input.focus();

    // Optimistic add
    const tempMsg = {
      sender_id: _myUserId,
      text: text,
      created_at: new Date().toISOString(),
    };
    _messages.push(tempMsg);
    _renderMessages();

    const res = await ApiClient.request('/api/messaging/direct/thread/' + _threadId + '/messages/send/', {
      method: 'POST',
      body: { text },
    });

    if (!res.ok) {
      // Remove temp message on failure
      _messages.pop();
      _renderMessages();
    }
  }

  async function _markRead() {
    await ApiClient.request('/api/messaging/direct/thread/' + _threadId + '/messages/read/', { method: 'POST' });
  }

  // Cleanup on page leave
  window.addEventListener('beforeunload', () => {
    if (_pollTimer) clearInterval(_pollTimer);
  });

  // Boot
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
  return {};
})();
