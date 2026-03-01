(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const dom={
  search:document.getElementById("po-search"),
  filters:document.getElementById("po-filters"),
  list:document.getElementById("po-list"),
  detail:document.getElementById("po-detail"),
  detailEmpty:document.getElementById("po-detail-empty"),
  detailBody:document.getElementById("po-detail-body")
};

const state={status:"",query:"",orders:[],selectedId:null,timer:null};
function asList(p){if(Array.isArray(p))return p;if(p&&Array.isArray(p.results))return p.results;return[];}
function safe(v,f){return(v===undefined||v===null||v==="")?f||"-":String(v);}
function dispId(o){return"R"+String(o.id||0).padStart(6,"0");}
function fmtDate(d){if(!d)return"-";try{return new Date(d).toLocaleDateString("ar-SA",{year:"numeric",month:"short",day:"numeric"})}catch{return d;}}
function fmtMoney(v){if(v===undefined||v===null||v==="")return"-";const n=Number(v);return Number.isFinite(n)?n.toFixed(2)+" ر.س":safe(v);}
function typeLabel(t){return t==="urgent"?"عاجل":t==="competitive"?"تنافسي":"عادي";}
function statusLabel(sg,sl){return sl||({new:"جديد",in_progress:"تحت التنفيذ",completed:"مكتمل",cancelled:"ملغي"}[sg]||sg);}

async function loadOrders(){
  dom.list.innerHTML='<div class="nw-po-loading">جارٍ التحميل...</div>';
  try{
    let url="/api/marketplace/requests/provider/";
    if(state.status)url+="?status_group="+state.status;
    const data=await api.get(url);
    state.orders=asList(data);
    if(state.query){
      const q=state.query.toLowerCase();
      state.orders=state.orders.filter(o=>(o.title||"").toLowerCase().includes(q)||(o.client_name||o.clientName||"").toLowerCase().includes(q));
    }
    renderList();
  }catch{
    dom.list.innerHTML='<div class="nw-po-empty"><span class="material-icons-round">error_outline</span><p>تعذر تحميل الطلبات</p></div>';
  }
}

function renderList(){
  if(!state.orders.length){
    dom.list.innerHTML='<div class="nw-po-empty"><span class="material-icons-round">inbox</span><p>لا توجد طلبات</p></div>';
    return;
  }
  dom.list.innerHTML=state.orders.map(o=>{
    const sg=o.status_group||o.statusGroup||"new";
    const sl=o.status_label||o.statusLabel||"";
    const rt=o.request_type||o.requestType||"normal";
    return`<div class="nw-po-card ${state.selectedId===o.id?"is-selected":""}" data-id="${o.id}">
      <div class="nw-po-card-top"><span class="nw-po-card-id">${dispId(o)}</span><span class="nw-po-card-type ${rt}">${typeLabel(rt)}</span></div>
      <h3>${safe(o.title,"بدون عنوان")}</h3>
      <div class="nw-po-card-meta">
        <span class="nw-po-badge ${sg}">${statusLabel(sg,sl)}</span>
        <span><span class="material-icons-round">person</span>${safe(o.client_name||o.clientName,"—")}</span>
        <span><span class="material-icons-round">calendar_today</span>${fmtDate(o.created_at||o.createdAt)}</span>
      </div>
    </div>`;
  }).join("");
  dom.list.querySelectorAll(".nw-po-card").forEach(c=>c.addEventListener("click",()=>loadDetail(Number(c.dataset.id))));
}

async function loadDetail(id){
  state.selectedId=id;
  renderList();
  dom.detailEmpty.hidden=true;
  dom.detailBody.hidden=false;
  dom.detailBody.innerHTML='<div class="nw-po-loading">جارٍ التحميل...</div>';
  dom.detail.classList.add("is-open");
  try{
    const d=await api.get("/api/marketplace/requests/provider/"+id+"/");
    renderDetail(d);
  }catch{
    dom.detailBody.innerHTML='<p class="nw-po-empty">تعذر تحميل التفاصيل</p>';
  }
}

function renderDetail(d){
  const sg=d.status_group||d.statusGroup||"new";
  const sl=d.status_label||d.statusLabel||"";
  const rt=d.request_type||d.requestType||"normal";
  let h=`<button class="nw-po-detail-back" id="po-back"><span class="material-icons-round">arrow_forward</span>رجوع</button>`;
  h+=`<h2>${safe(d.title)}</h2>`;

  // client info
  h+=`<div class="nw-po-detail-grid">
    <div class="nw-po-detail-item"><div class="lbl">العميل</div><div class="val">${safe(d.client_name||d.clientName)}</div></div>
    <div class="nw-po-detail-item"><div class="lbl">هاتف العميل</div><div class="val">${safe(d.client_phone||d.clientPhone)}</div></div>
    <div class="nw-po-detail-item"><div class="lbl">المدينة</div><div class="val">${safe(d.city)}</div></div>
    <div class="nw-po-detail-item"><div class="lbl">رقم الطلب</div><div class="val">${dispId(d)}</div></div>
    <div class="nw-po-detail-item"><div class="lbl">الحالة</div><div class="val"><span class="nw-po-badge ${sg}">${statusLabel(sg,sl)}</span></div></div>
    <div class="nw-po-detail-item"><div class="lbl">النوع</div><div class="val">${typeLabel(rt)}</div></div>
    <div class="nw-po-detail-item"><div class="lbl">التصنيف</div><div class="val">${safe(d.category_name||d.categoryName)}</div></div>
    <div class="nw-po-detail-item"><div class="lbl">تاريخ الإنشاء</div><div class="val">${fmtDate(d.created_at||d.createdAt)}</div></div>
  </div>`;

  // description
  if(d.description)h+=`<div class="nw-po-detail-item" style="margin-bottom:12px"><div class="lbl">الوصف</div><div class="val" style="font-weight:400;white-space:pre-wrap">${safe(d.description)}</div></div>`;

  // attachments
  const atts=d.attachments||[];
  if(atts.length){
    h+=`<div class="nw-po-att"><h4>المرفقات</h4><div class="nw-po-att-list">`;
    atts.forEach(a=>{
      const icon=a.file_type==="image"?"image":a.file_type==="video"?"videocam":"attach_file";
      h+=`<a class="nw-po-att-item" href="${a.file_url||a.fileUrl||"#"}" target="_blank"><span class="material-icons-round">${icon}</span>${a.file_type||"ملف"}</a>`;
    });
    h+=`</div></div>`;
  }

  // action forms by status
  if(sg==="new"){
    h+=`<div class="nw-po-action-section"><h4>إجراءات الطلب</h4>
      <div class="nw-po-action-btns">
        <button class="nw-po-btn accept" id="po-accept">قبول الطلب</button>
        <button class="nw-po-btn reject" id="po-reject-btn">رفض الطلب</button>
      </div>
      <div id="po-start-form" style="margin-top:12px">
        <h4>بدء التنفيذ</h4>
        <div class="nw-form-group"><label>تاريخ التسليم المتوقع</label><input type="date" id="po-expected-date"></div>
        <div class="nw-form-group"><label>المبلغ التقديري</label><input type="number" id="po-est-amount" placeholder="0.00"></div>
        <div class="nw-form-group"><label>المبلغ المستلم</label><input type="number" id="po-recv-amount" placeholder="0.00"></div>
        <div class="nw-form-group"><label>ملاحظة</label><textarea id="po-start-note" rows="2"></textarea></div>
        <button class="nw-po-btn start" id="po-start">بدء التنفيذ</button>
      </div>
      <div id="po-reject-form" style="margin-top:12px;display:none">
        <div class="nw-form-group"><label>سبب الرفض</label><textarea id="po-reject-reason" rows="2"></textarea></div>
        <button class="nw-po-btn reject" id="po-reject">تأكيد الرفض</button>
      </div>
    </div>`;
  }

  if(sg==="in_progress"){
    h+=`<div class="nw-po-action-section"><h4>تحديث التقدم</h4>
      <div class="nw-form-group"><label>تاريخ التسليم المتوقع</label><input type="date" id="po-upd-date" value="${d.expected_delivery_at||d.expectedDeliveryAt||""}"></div>
      <div class="nw-form-group"><label>المبلغ التقديري</label><input type="number" id="po-upd-est" placeholder="0.00" value="${d.estimated_service_amount||d.estimatedServiceAmount||""}"></div>
      <div class="nw-form-group"><label>المبلغ المستلم</label><input type="number" id="po-upd-recv" placeholder="0.00" value="${d.received_amount||d.receivedAmount||""}"></div>
      <div class="nw-form-group"><label>ملاحظة</label><textarea id="po-upd-note" rows="2"></textarea></div>
      <div class="nw-po-action-btns">
        <button class="nw-po-btn update" id="po-update">حفظ التحديث</button>
        <button class="nw-po-btn complete" id="po-complete-btn">إكمال الطلب</button>
        <button class="nw-po-btn reject" id="po-cancel-btn">إلغاء الطلب</button>
      </div>
      <div id="po-complete-form" style="margin-top:12px;display:none">
        <h4>إكمال الطلب</h4>
        <div class="nw-form-group"><label>تاريخ التسليم الفعلي</label><input type="date" id="po-del-date"></div>
        <div class="nw-form-group"><label>المبلغ الفعلي</label><input type="number" id="po-actual-amount" placeholder="0.00"></div>
        <div class="nw-form-group"><label>ملاحظة</label><textarea id="po-del-note" rows="2"></textarea></div>
        <button class="nw-po-btn complete" id="po-complete">تأكيد الإكمال</button>
      </div>
      <div id="po-cancel-form" style="margin-top:12px;display:none">
        <div class="nw-form-group"><label>سبب الإلغاء</label><textarea id="po-cancel-reason" rows="2"></textarea></div>
        <button class="nw-po-btn reject" id="po-cancel">تأكيد الإلغاء</button>
      </div>
    </div>`;
  }

  if(sg==="completed"){
    h+=`<div class="nw-po-detail-grid">
      <div class="nw-po-detail-item"><div class="lbl">تاريخ التسليم</div><div class="val">${fmtDate(d.delivered_at||d.deliveredAt)}</div></div>
      <div class="nw-po-detail-item"><div class="lbl">المبلغ الفعلي</div><div class="val">${fmtMoney(d.actual_service_amount||d.actualServiceAmount)}</div></div>
    </div>`;
    if(d.review_rating||d.review_comment){
      h+=`<div class="nw-po-review"><h4>تقييم العميل</h4>`;
      if(d.review_rating)h+=`<div class="stars">${"★".repeat(Math.round(d.review_rating))}${"☆".repeat(5-Math.round(d.review_rating))}</div>`;
      if(d.review_comment)h+=`<p style="font-size:.85rem;margin-top:4px">${d.review_comment}</p>`;
      h+=`</div>`;
    }
  }

  if(sg==="cancelled"){
    h+=`<div class="nw-po-detail-grid">
      <div class="nw-po-detail-item"><div class="lbl">تاريخ الإلغاء</div><div class="val">${fmtDate(d.canceled_at||d.canceledAt)}</div></div>
      <div class="nw-po-detail-item"><div class="lbl">سبب الإلغاء</div><div class="val">${safe(d.cancel_reason||d.cancelReason)}</div></div>
    </div>`;
  }

  // logs
  const logs=d.status_logs||d.statusLogs||[];
  if(logs.length){
    h+=`<div class="nw-po-logs"><h4>سجل الحالة</h4>`;
    logs.forEach(l=>{
      h+=`<div class="nw-po-log-item"><div class="nw-po-log-dot"></div><div class="nw-po-log-text">
        <div class="from-to">${safe(l.from_status||l.fromStatus)} → ${safe(l.to_status||l.toStatus)}</div>
        ${l.note?'<div class="note">'+l.note+'</div>':""}
        <div class="date">${fmtDate(l.created_at||l.createdAt)}</div>
      </div></div>`;
    });
    h+=`</div>`;
  }

  dom.detailBody.innerHTML=h;
  bindDetailActions(d);
}

function bindDetailActions(d){
  const back=document.getElementById("po-back");
  if(back)back.addEventListener("click",()=>{state.selectedId=null;dom.detailBody.hidden=true;dom.detailEmpty.hidden=false;dom.detail.classList.remove("is-open");renderList();});

  // Accept
  const acceptBtn=document.getElementById("po-accept");
  if(acceptBtn)acceptBtn.addEventListener("click",async()=>{
    try{await api.post("/api/marketplace/requests/provider/"+d.id+"/accept/");ui.toast("تم قبول الطلب","success");loadDetail(d.id);}catch{ui.toast("فشل القبول","error");}
  });

  // Reject toggle
  const rejectBtn=document.getElementById("po-reject-btn");
  const rejectForm=document.getElementById("po-reject-form");
  if(rejectBtn&&rejectForm)rejectBtn.addEventListener("click",()=>{rejectForm.style.display=rejectForm.style.display==="none"?"block":"none";});

  // Reject confirm
  const rejectConfirm=document.getElementById("po-reject");
  if(rejectConfirm)rejectConfirm.addEventListener("click",async()=>{
    const reason=(document.getElementById("po-reject-reason")||{}).value||"";
    try{await api.post("/api/marketplace/requests/provider/"+d.id+"/reject/",{cancel_reason:reason});ui.toast("تم رفض الطلب","success");loadOrders();}catch{ui.toast("فشل الرفض","error");}
  });

  // Start
  const startBtn=document.getElementById("po-start");
  if(startBtn)startBtn.addEventListener("click",async()=>{
    const payload={
      expected_delivery_at:(document.getElementById("po-expected-date")||{}).value||undefined,
      estimated_service_amount:(document.getElementById("po-est-amount")||{}).value||undefined,
      received_amount:(document.getElementById("po-recv-amount")||{}).value||undefined,
      note:(document.getElementById("po-start-note")||{}).value||undefined
    };
    try{await api.post("/api/marketplace/requests/provider/"+d.id+"/start/",payload);ui.toast("تم بدء التنفيذ","success");loadDetail(d.id);}catch{ui.toast("فشل بدء التنفيذ","error");}
  });

  // Update progress
  const updateBtn=document.getElementById("po-update");
  if(updateBtn)updateBtn.addEventListener("click",async()=>{
    const payload={
      expected_delivery_at:(document.getElementById("po-upd-date")||{}).value||undefined,
      estimated_service_amount:(document.getElementById("po-upd-est")||{}).value||undefined,
      received_amount:(document.getElementById("po-upd-recv")||{}).value||undefined,
      note:(document.getElementById("po-upd-note")||{}).value||undefined
    };
    try{await api.patch("/api/marketplace/requests/provider/"+d.id+"/progress/",payload);ui.toast("تم التحديث","success");loadDetail(d.id);}catch{ui.toast("فشل التحديث","error");}
  });

  // Complete toggle
  const compBtn=document.getElementById("po-complete-btn");
  const compForm=document.getElementById("po-complete-form");
  if(compBtn&&compForm)compBtn.addEventListener("click",()=>{compForm.style.display=compForm.style.display==="none"?"block":"none";});

  // Complete confirm
  const compConfirm=document.getElementById("po-complete");
  if(compConfirm)compConfirm.addEventListener("click",async()=>{
    const payload={
      delivered_at:(document.getElementById("po-del-date")||{}).value||undefined,
      actual_service_amount:(document.getElementById("po-actual-amount")||{}).value||undefined,
      note:(document.getElementById("po-del-note")||{}).value||undefined
    };
    try{await api.post("/api/marketplace/requests/provider/"+d.id+"/complete/",payload);ui.toast("تم إكمال الطلب","success");loadDetail(d.id);}catch{ui.toast("فشل الإكمال","error");}
  });

  // Cancel toggle
  const cancelBtn=document.getElementById("po-cancel-btn");
  const cancelForm=document.getElementById("po-cancel-form");
  if(cancelBtn&&cancelForm)cancelBtn.addEventListener("click",()=>{cancelForm.style.display=cancelForm.style.display==="none"?"block":"none";});

  // Cancel confirm
  const cancelConfirm=document.getElementById("po-cancel");
  if(cancelConfirm)cancelConfirm.addEventListener("click",async()=>{
    const reason=(document.getElementById("po-cancel-reason")||{}).value||"";
    try{await api.post("/api/marketplace/requests/provider/"+d.id+"/reject/",{cancel_reason:reason});ui.toast("تم إلغاء الطلب","success");loadOrders();}catch{ui.toast("فشل الإلغاء","error");}
  });
}

/* filters */
dom.filters.addEventListener("click",e=>{
  const chip=e.target.closest(".nw-po-chip");
  if(!chip)return;
  state.status=chip.dataset.status||"";
  dom.filters.querySelectorAll(".nw-po-chip").forEach(c=>c.classList.toggle("is-active",c===chip));
  loadOrders();
});

/* search */
dom.search.addEventListener("input",()=>{
  clearTimeout(state.timer);
  state.timer=setTimeout(()=>{state.query=dom.search.value.trim();loadOrders();},400);
});

/* init */
api.get("/api/accounts/me/").then(()=>loadOrders()).catch(()=>{
  dom.list.innerHTML='<div class="nw-po-empty"><span class="material-icons-round">lock</span><p>سجل دخولك أولاً</p></div>';
});
})();
