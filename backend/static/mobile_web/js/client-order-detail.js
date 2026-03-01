/* ── Client Order Detail JS ── */
(function(){
  const API = window.NawafethApi;
  const UI  = window.NawafethUi;
  const orderId = window.location.pathname.split('/').filter(Boolean).pop();

  const dom = {
    loading : document.getElementById('cod-loading'),
    error   : document.getElementById('cod-error'),
    errorMsg: document.getElementById('cod-error-msg'),
    body    : document.getElementById('cod-body'),
    retry   : document.getElementById('btn-retry'),
  };

  let order = null;
  let ratingValues = { response_speed:0, cost_value:0, quality:0, credibility:0, on_time:0 };

  async function load(){
    dom.loading.style.display=''; dom.error.style.display='none'; dom.body.style.display='none';
    try{
      const res = await API.get('/api/marketplace/requests/client/' + orderId + '/');
      if(!res.ok) throw new Error('fail');
      order = await res.json();
      render();
    }catch(e){
      dom.loading.style.display='none'; dom.error.style.display='';
      dom.errorMsg.textContent = 'تعذّر تحميل تفاصيل الطلب';
    }
  }

  function statusColor(sg){
    return { completed:'nw-status-completed', cancelled:'nw-status-cancelled', in_progress:'nw-status-in_progress', new:'nw-status-new' }[sg] || '';
  }

  function fmt(d){ if(!d) return '-'; const dt=new Date(d); return dt.toLocaleDateString('ar-SA');}
  function fmtMoney(v){ return v!=null ? Math.round(v)+' SR':'-';}

  function render(){
    dom.loading.style.display='none'; dom.body.style.display='';
    const o = order;
    const sg = o.status_group || 'new';

    // Header
    document.getElementById('cod-display-id').textContent = o.display_id || '#'+o.id;
    const typeBadge = document.getElementById('cod-type-badge');
    if(o.request_type && o.request_type!=='normal'){
      typeBadge.style.display='';
      typeBadge.textContent = o.request_type_label || o.request_type;
      typeBadge.className = 'nw-badge nw-badge-type '+ o.request_type;
    }
    const pill = document.getElementById('cod-status-pill');
    pill.textContent = o.status_label || sg;
    pill.className = 'nw-pill ' + statusColor(sg);

    document.getElementById('cod-title-text').textContent = o.title || '';
    document.getElementById('cod-category').textContent = [o.category_name,o.subcategory_name].filter(Boolean).join(' / ');
    document.getElementById('cod-created-at').textContent = fmt(o.created_at);

    if(o.provider_name){
      const row = document.getElementById('cod-provider-row'); row.style.display='';
      document.getElementById('cod-provider-name').textContent = o.provider_name;
      if(o.provider_phone){
        document.getElementById('cod-phone-icon').style.display='';
        document.getElementById('cod-provider-phone').textContent = o.provider_phone;
      }
    }

    // Status cards
    if(sg==='completed'){
      const card = document.getElementById('cod-completed-card'); card.style.display='';
      document.getElementById('cod-delivered-at').textContent = fmt(o.delivered_at);
      document.getElementById('cod-actual-amount').textContent = fmtMoney(o.actual_amount);
    }
    if(sg==='in_progress'){
      const card = document.getElementById('cod-inprogress-card'); card.style.display='';
      document.getElementById('cod-expected-delivery').textContent = fmt(o.expected_delivery_at);
      document.getElementById('cod-estimated-amount').textContent = fmtMoney(o.estimated_amount);
      document.getElementById('cod-received-amt').textContent = fmtMoney(o.received_amt);
      document.getElementById('cod-remaining-amt').textContent = fmtMoney(o.remaining_amt);
    }
    if(sg==='cancelled'){
      const card = document.getElementById('cod-cancelled-card'); card.style.display='';
      document.getElementById('cod-cancel-date').textContent = fmt(o.canceled_at);
      document.getElementById('cod-cancel-reason').textContent = o.cancel_reason || '-';
    }

    // Editable title & details
    const canEdit = o.status === 'new';
    const titleInput = document.getElementById('cod-edit-title');
    const detailsInput = document.getElementById('cod-edit-details');
    titleInput.value = o.title || '';
    detailsInput.value = o.description || '';

    if(canEdit){
      document.getElementById('btn-edit-title').style.display='';
      document.getElementById('btn-edit-details').style.display='';
      document.getElementById('cod-edit-note').style.display='';
      document.getElementById('btn-save').style.display='';
    }

    // Attachments
    const attBox = document.getElementById('cod-attachments');
    const atts = o.attachments || [];
    if(atts.length){
      attBox.innerHTML = atts.map(a=>{
        const icon = {image:'image',video:'videocam',audio:'audiotrack',document:'description'}[a.file_type]||'attach_file';
        const name = (a.file_url||'').split('/').pop();
        return `<div class="nw-att-item"><span class="material-icons-round">${icon}</span><span class="nw-att-name">${name}</span><span class="nw-att-type">${a.file_type}</span></div>`;
      }).join('');
    }

    // Status logs
    const logs = o.status_logs || [];
    if(logs.length){
      document.getElementById('cod-statuslog-card').style.display='';
      document.getElementById('cod-status-logs').innerHTML = logs.map(l=>
        `<div class="nw-tl-item"><div class="nw-tl-dot"></div><div class="nw-tl-text"><div class="nw-tl-transition">${l.from_status||'—'} → ${l.to_status}</div>${l.note?'<div class="nw-tl-note">'+l.note+'</div>':''}${l.created_at?'<div class="nw-tl-time">'+fmt(l.created_at)+'</div>':''}</div></div>`
      ).join('');
    }

    // Stars
    document.querySelectorAll('.nw-stars').forEach(container=>{
      const field = container.dataset.field;
      container.innerHTML = [1,2,3,4,5].map(i=>`<span class="star material-icons-round" data-v="${i}">star</span>`).join('');
      container.querySelectorAll('.star').forEach(s=>{
        s.addEventListener('click',()=>{
          ratingValues[field] = parseInt(s.dataset.v);
          container.querySelectorAll('.star').forEach((st,idx)=> st.classList.toggle('active', idx < ratingValues[field]));
        });
      });
      // Pre-fill existing rating
      const existing = o['review_'+field] || 0;
      if(existing){
        ratingValues[field] = existing;
        container.querySelectorAll('.star').forEach((st,idx)=> st.classList.toggle('active', idx < existing));
      }
    });
    if(o.review_comment) document.getElementById('cod-rating-comment').value = o.review_comment;
  }

  // Toggle edit
  document.getElementById('btn-edit-title')?.addEventListener('click',()=>{
    const inp = document.getElementById('cod-edit-title');
    inp.disabled = !inp.disabled;
  });
  document.getElementById('btn-edit-details')?.addEventListener('click',()=>{
    const inp = document.getElementById('cod-edit-details');
    inp.disabled = !inp.disabled;
  });

  // Toggle rating form
  document.getElementById('btn-toggle-rating')?.addEventListener('click',()=>{
    const form = document.getElementById('cod-rating-form');
    form.style.display = form.style.display==='none'?'':'none';
  });

  // Submit rating
  document.getElementById('btn-submit-rating')?.addEventListener('click', async()=>{
    const comment = document.getElementById('cod-rating-comment').value.trim();
    try{
      const res = await API.post('/api/marketplace/requests/client/'+orderId+'/review/',{
        response_speed: ratingValues.response_speed,
        cost_value: ratingValues.cost_value,
        quality: ratingValues.quality,
        credibility: ratingValues.credibility,
        on_time: ratingValues.on_time,
        comment: comment
      });
      if(res.ok) UI.toast('تم إرسال التقييم بنجاح','success');
      else UI.toast('فشل إرسال التقييم','error');
    }catch(e){ UI.toast('خطأ في الاتصال','error');}
  });

  // Save edits
  document.getElementById('btn-save')?.addEventListener('click', async()=>{
    const title = document.getElementById('cod-edit-title').value.trim();
    const desc = document.getElementById('cod-edit-details').value.trim();
    if(title===order.title && desc===order.description){ history.back(); return; }
    try{
      const body = {};
      if(title!==order.title) body.title = title;
      if(desc!==order.description) body.description = desc;
      const res = await API.patch('/api/marketplace/requests/client/'+orderId+'/', body);
      if(res.ok){ UI.toast('تم حفظ التعديلات','success'); setTimeout(()=>history.back(),600); }
      else UI.toast('فشل الحفظ','error');
    }catch(e){ UI.toast('خطأ في الاتصال','error');}
  });

  // Chat
  document.getElementById('btn-open-chat')?.addEventListener('click',()=>{
    UI.toast('سيتم فتح المحادثة مع مقدم الخدمة قريباً','info');
  });

  dom.retry?.addEventListener('click', load);
  load();
})();
