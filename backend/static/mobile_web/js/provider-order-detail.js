/* ── Provider Order Detail JS ── */
(function(){
  const API = window.NawafethApi;
  const UI  = window.NawafethUi;
  const orderId = window.location.pathname.split('/').filter(Boolean).pop();

  const dom = {
    loading: document.getElementById('pod-loading'),
    error:   document.getElementById('pod-error'),
    body:    document.getElementById('pod-body'),
  };

  let order = null;

  async function load(){
    dom.loading.style.display=''; dom.error.style.display='none'; dom.body.style.display='none';
    try{
      const res = await API.get('/api/marketplace/requests/provider/' + orderId + '/');
      if(!res.ok) throw new Error();
      order = await res.json();
      render();
    }catch(e){
      dom.loading.style.display='none'; dom.error.style.display='';
    }
  }

  function fmt(d){ if(!d) return '-'; return new Date(d).toLocaleDateString('ar-SA');}
  function fmtISO(d){ if(!d) return ''; const dt=new Date(d); return dt.toISOString().slice(0,10);}
  function sc(sg){ return{completed:'nw-status-completed',cancelled:'nw-status-cancelled',in_progress:'nw-status-in_progress',new:'nw-status-new'}[sg]||'';}

  function render(){
    dom.loading.style.display='none'; dom.body.style.display='';
    const o = order, sg = o.status_group || 'new';

    // Client
    document.getElementById('pod-client-name').textContent = o.client_name || 'غير متوفر';
    document.getElementById('pod-client-phone').textContent = o.client_phone || 'غير متوفر';
    document.getElementById('pod-client-city').textContent = o.city || 'غير متوفر';

    // Header
    document.getElementById('pod-display-id').textContent = o.display_id || '#'+o.id;
    const badge = document.getElementById('pod-type-badge');
    if(o.request_type && o.request_type!=='normal'){
      badge.style.display=''; badge.textContent=o.request_type_label||o.request_type;
      badge.className='nw-badge nw-badge-type '+o.request_type;
    }
    const pill = document.getElementById('pod-status-pill');
    pill.textContent = o.status_label||sg; pill.className='nw-pill '+sc(sg);
    document.getElementById('pod-category').textContent = [o.category_name,o.subcategory_name].filter(Boolean).join(' / ');
    document.getElementById('pod-created-at').textContent = fmt(o.created_at);

    // Title & desc
    document.getElementById('pod-title').textContent = o.title||'';
    document.getElementById('pod-desc').textContent = o.description||'';

    // Attachments
    const atts = o.attachments||[];
    const attBox = document.getElementById('pod-attachments');
    if(atts.length){
      attBox.innerHTML = atts.map(a=>{
        const icon={image:'image',video:'videocam',audio:'audiotrack'}[a.file_type]||'attach_file';
        return `<div class="nw-att-item"><span class="material-icons-round">${icon}</span><span class="nw-att-name">${(a.file_url||'').split('/').pop()}</span><span class="nw-att-badge">${a.file_type.toUpperCase()}</span></div>`;
      }).join('');
    }

    // Status logs
    const logs = o.status_logs||[];
    if(logs.length){
      document.getElementById('pod-log-card').style.display='';
      document.getElementById('pod-logs').innerHTML = logs.map(l=>
        `<div class="nw-tl-item"><div class="nw-tl-dot"></div><div class="nw-tl-text"><div class="nw-tl-transition">${l.from_status||'—'} → ${l.to_status}</div>${l.note?'<div class="nw-tl-note">'+l.note+'</div>':''}${l.created_at?'<div class="nw-tl-time">'+fmt(l.created_at)+'</div>':''}</div></div>`
      ).join('');
    }

    // Action sections by status
    document.getElementById('pod-act-new').style.display = sg==='new'?'':'none';
    document.getElementById('pod-act-progress').style.display = sg==='in_progress'?'':'none';
    document.getElementById('pod-act-completed').style.display = sg==='completed'?'':'none';
    document.getElementById('pod-act-cancelled').style.display = sg==='cancelled'?'':'none';

    // Pre-fill
    if(sg==='in_progress'){
      if(o.expected_delivery_at) document.getElementById('inp-upd-exp-date').value = fmtISO(o.expected_delivery_at);
      if(o.estimated_service_amount) document.getElementById('inp-upd-estimated').value = o.estimated_service_amount;
      if(o.received_amount) document.getElementById('inp-upd-received').value = o.received_amount;
    }
    if(sg==='completed'){
      document.getElementById('pod-c-delivered').textContent = fmt(o.delivered_at);
      document.getElementById('pod-c-actual').textContent = o.actual_service_amount ? o.actual_service_amount+' SR' : '-';
      if(o.review_rating!=null){
        document.getElementById('pod-c-review-group').style.display='';
        document.getElementById('pod-c-review').textContent = o.review_rating+'/5 — '+(o.review_comment||'');
      }
    }
    if(sg==='cancelled'){
      document.getElementById('pod-x-date').textContent = fmt(o.canceled_at);
      document.getElementById('pod-x-reason').textContent = o.cancel_reason||'-';
    }
  }

  // ─── Actions ───
  async function apiAction(endpoint, body, successMsg){
    try{
      const res = await API.post('/api/marketplace/requests/provider/'+orderId+'/'+endpoint+'/', body||{});
      if(res.ok){ UI.toast(successMsg,'success'); load(); }
      else{ const d=await res.json().catch(()=>({})); UI.toast(d.detail||d.error||'فشلت العملية','error'); }
    }catch(e){ UI.toast('خطأ في الاتصال','error');}
  }

  document.getElementById('btn-accept')?.addEventListener('click', ()=> apiAction('accept',{},'تم قبول الطلب'));

  document.getElementById('btn-start')?.addEventListener('click', ()=>{
    const expDate = document.getElementById('inp-exp-date').value;
    const est = document.getElementById('inp-estimated').value;
    const rec = document.getElementById('inp-received').value;
    if(!expDate){ UI.toast('حدد موعد التسليم المتوقع','error'); return; }
    if(!est||!rec){ UI.toast('أدخل القيمة المقدرة والمبلغ المستلم','error'); return; }
    apiAction('start',{
      expected_delivery_at: expDate,
      estimated_service_amount: est,
      received_amount: rec,
      note: document.getElementById('inp-note').value.trim()||undefined
    },'تم بدء التنفيذ');
  });

  document.getElementById('btn-reject')?.addEventListener('click', ()=>{
    const reason = document.getElementById('inp-cancel-reason').value.trim();
    if(!reason){ UI.toast('الرجاء كتابة سبب الإلغاء','error'); return; }
    apiAction('reject',{ cancel_reason: reason },'تم إلغاء الطلب');
  });

  document.getElementById('btn-update-progress')?.addEventListener('click', ()=>{
    apiAction('update-progress',{
      expected_delivery_at: document.getElementById('inp-upd-exp-date').value||undefined,
      estimated_service_amount: document.getElementById('inp-upd-estimated').value||undefined,
      received_amount: document.getElementById('inp-upd-received').value||undefined,
      note: document.getElementById('inp-upd-note').value.trim()||undefined
    },'تم تحديث التقدم');
  });

  document.getElementById('btn-complete')?.addEventListener('click', ()=>{
    const dd = document.getElementById('inp-delivered-date').value;
    const amt = document.getElementById('inp-actual-amount').value;
    if(!dd){ UI.toast('حدد موعد التسليم الفعلي','error'); return; }
    if(!amt){ UI.toast('أدخل قيمة الخدمة الفعلية','error'); return; }
    apiAction('complete',{ delivered_at: dd, actual_service_amount: amt },'تم إكمال الطلب');
  });

  document.getElementById('btn-prog-reject')?.addEventListener('click', ()=>{
    const reason = document.getElementById('inp-prog-cancel').value.trim();
    if(!reason){ UI.toast('الرجاء كتابة سبب الإلغاء','error'); return; }
    apiAction('reject',{ cancel_reason: reason },'تم إلغاء الطلب');
  });

  document.getElementById('btn-chat')?.addEventListener('click',()=> UI.toast('سيتم فتح المحادثة مع العميل قريباً','info'));
  document.getElementById('btn-retry')?.addEventListener('click', load);

  load();
})();
