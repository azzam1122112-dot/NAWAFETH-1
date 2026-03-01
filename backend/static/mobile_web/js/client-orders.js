(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const dom={
  search:document.getElementById("co-search"),
  filters:document.getElementById("co-filters"),
  error:document.getElementById("co-error"),
  list:document.getElementById("co-list"),
  detail:document.getElementById("co-detail"),
  detailEmpty:document.getElementById("co-detail-empty"),
  detailBody:document.getElementById("co-detail-body")
};

const state={status:"",query:"",orders:[],selectedId:null,timer:null};

/* helpers */
function asList(p){if(Array.isArray(p))return p;if(p&&Array.isArray(p.results))return p.results;return[];}
function safe(v,f){return(v===undefined||v===null||v==="")?f||"-":String(v);}
function dispId(o){return"R"+String(o.id||0).padStart(6,"0");}
function fmtDate(d){if(!d)return"-";try{return new Date(d).toLocaleDateString("ar-SA",{year:"numeric",month:"short",day:"numeric"})}catch{return d;}}
function fmtMoney(v){if(v===undefined||v===null||v==="")return"-";const n=Number(v);return Number.isFinite(n)?n.toFixed(2)+" ر.س":safe(v);}
function typeLabel(t){return t==="urgent"?"عاجل":t==="competitive"?"تنافسي":"عادي";}
function statusLabel(sg,sl){return sl||({new:"جديد",in_progress:"تحت التنفيذ",completed:"مكتمل",cancelled:"ملغي"}[sg]||sg);}

/* fetch list */
async function loadOrders(){
  dom.list.innerHTML='<div class="nw-co-loading">جارٍ التحميل...</div>';
  try{
    let url="/api/marketplace/requests/client/";
    const params=[];
    if(state.status)params.push("status_group="+state.status);
    if(state.query)params.push("q="+encodeURIComponent(state.query));
    if(params.length)url+="?"+params.join("&");
    const data=await api.get(url);
    state.orders=asList(data);
    renderList();
  }catch(e){
    dom.list.innerHTML='<div class="nw-co-empty"><span class="material-icons-round">error_outline</span><p>تعذر تحميل الطلبات</p></div>';
  }
}

function renderList(){
  if(!state.orders.length){
    dom.list.innerHTML='<div class="nw-co-empty"><span class="material-icons-round">inbox</span><p>لا توجد طلبات</p></div>';
    return;
  }
  dom.list.innerHTML=state.orders.map(o=>{
    const sg=o.status_group||o.statusGroup||"new";
    const sl=o.status_label||o.statusLabel||"";
    const rt=o.request_type||o.requestType||"normal";
    return`<div class="nw-co-card ${state.selectedId===o.id?"is-selected":""}" data-id="${o.id}">
      <div class="nw-co-card-top">
        <span class="nw-co-card-id">${dispId(o)}</span>
        <span class="nw-co-card-type ${rt}">${typeLabel(rt)}</span>
      </div>
      <h3>${safe(o.title,"بدون عنوان")}</h3>
      <div class="nw-co-card-meta">
        <span class="nw-co-badge ${sg}">${statusLabel(sg,sl)}</span>
        <span><span class="material-icons-round">person</span>${safe(o.provider_name||o.providerName,"—")}</span>
        <span><span class="material-icons-round">calendar_today</span>${fmtDate(o.created_at||o.createdAt)}</span>
      </div>
    </div>`;
  }).join("");
  dom.list.querySelectorAll(".nw-co-card").forEach(c=>{
    c.addEventListener("click",()=>loadDetail(Number(c.dataset.id)));
  });
}

/* detail */
async function loadDetail(id){
  state.selectedId=id;
  renderList();
  dom.detailEmpty.hidden=true;
  dom.detailBody.hidden=false;
  dom.detailBody.innerHTML='<div class="nw-co-loading">جارٍ التحميل...</div>';
  dom.detail.classList.add("is-open");
  try{
    const d=await api.get("/api/marketplace/requests/client/"+id+"/");
    renderDetail(d);
  }catch(e){
    dom.detailBody.innerHTML='<p class="nw-co-empty">تعذر تحميل التفاصيل</p>';
  }
}

function renderDetail(d){
  const sg=d.status_group||d.statusGroup||"new";
  const sl=d.status_label||d.statusLabel||"";
  const rt=d.request_type||d.requestType||"normal";
  let html=`
    <button class="nw-co-detail-back" id="co-back"><span class="material-icons-round">arrow_forward</span>رجوع</button>
    <h2>${safe(d.title)}</h2>
    <div class="nw-co-detail-grid">
      <div class="nw-co-detail-item"><div class="lbl">رقم الطلب</div><div class="val">${dispId(d)}</div></div>
      <div class="nw-co-detail-item"><div class="lbl">الحالة</div><div class="val"><span class="nw-co-badge ${sg}">${statusLabel(sg,sl)}</span></div></div>
      <div class="nw-co-detail-item"><div class="lbl">النوع</div><div class="val">${typeLabel(rt)}</div></div>
      <div class="nw-co-detail-item"><div class="lbl">التصنيف</div><div class="val">${safe(d.category_name||d.categoryName)}</div></div>
      <div class="nw-co-detail-item"><div class="lbl">التصنيف الفرعي</div><div class="val">${safe(d.subcategory_name||d.subcategoryName)}</div></div>
      <div class="nw-co-detail-item"><div class="lbl">مقدم الخدمة</div><div class="val">${safe(d.provider_name||d.providerName)}</div></div>
      <div class="nw-co-detail-item"><div class="lbl">تاريخ الإنشاء</div><div class="val">${fmtDate(d.created_at||d.createdAt)}</div></div>`;
  if(sg==="completed"||sg==="in_progress"){
    html+=`<div class="nw-co-detail-item"><div class="lbl">المبلغ التقديري</div><div class="val">${fmtMoney(d.estimated_amount||d.estimatedAmount)}</div></div>`;
    html+=`<div class="nw-co-detail-item"><div class="lbl">المبلغ المستلم</div><div class="val">${fmtMoney(d.received_amount||d.receivedAmt)}</div></div>`;
  }
  if(sg==="completed"){
    html+=`<div class="nw-co-detail-item"><div class="lbl">المبلغ الفعلي</div><div class="val">${fmtMoney(d.actual_amount||d.actualAmount)}</div></div>`;
    html+=`<div class="nw-co-detail-item"><div class="lbl">تاريخ التسليم</div><div class="val">${fmtDate(d.delivered_at||d.deliveredAt)}</div></div>`;
  }
  if(sg==="cancelled"){
    html+=`<div class="nw-co-detail-item"><div class="lbl">تاريخ الإلغاء</div><div class="val">${fmtDate(d.canceled_at||d.canceledAt)}</div></div>`;
    html+=`<div class="nw-co-detail-item"><div class="lbl">سبب الإلغاء</div><div class="val">${safe(d.cancel_reason||d.cancelReason)}</div></div>`;
  }
  html+=`</div>`;
  // description
  if(d.description)html+=`<div class="nw-co-detail-item" style="margin-bottom:12px"><div class="lbl">الوصف</div><div class="val" style="font-weight:400;white-space:pre-wrap">${safe(d.description)}</div></div>`;

  // editable fields when new
  if(sg==="new"){
    html+=`<div class="nw-co-edit-form" id="co-edit-form">
      <input id="co-edit-title" placeholder="عنوان الطلب" value="${safe(d.title,"")}">
      <textarea id="co-edit-desc" placeholder="تفاصيل الطلب" rows="3">${safe(d.description,"")}</textarea>
      <button class="nw-btn" id="co-save-edit">حفظ التعديلات</button>
    </div>`;
  }

  // attachments
  const atts=d.attachments||[];
  if(atts.length){
    html+=`<div class="nw-co-att"><h4>المرفقات</h4><div class="nw-co-att-list">`;
    atts.forEach(a=>{
      const icon=a.file_type==="image"?"image":a.file_type==="video"?"videocam":"attach_file";
      html+=`<a class="nw-co-att-item" href="${a.file_url||a.fileUrl||"#"}" target="_blank"><span class="material-icons-round">${icon}</span>${a.file_type||"ملف"}</a>`;
    });
    html+=`</div></div>`;
  }

  // status logs
  const logs=d.status_logs||d.statusLogs||[];
  if(logs.length){
    html+=`<div class="nw-co-logs"><h4>سجل الحالة</h4>`;
    logs.forEach(l=>{
      html+=`<div class="nw-co-log-item"><div class="nw-co-log-dot"></div><div class="nw-co-log-text">
        <div class="from-to">${safe(l.from_status||l.fromStatus)} → ${safe(l.to_status||l.toStatus)}</div>
        ${l.note?'<div class="note">'+l.note+'</div>':""}
        <div class="date">${fmtDate(l.created_at||l.createdAt)}</div>
      </div></div>`;
    });
    html+=`</div>`;
  }

  // review form for completed
  if(sg==="completed"){
    html+=buildReviewSection(d);
  }

  dom.detailBody.innerHTML=html;

  // back button
  const backBtn=document.getElementById("co-back");
  if(backBtn)backBtn.addEventListener("click",()=>{state.selectedId=null;dom.detailBody.hidden=true;dom.detailEmpty.hidden=false;dom.detail.classList.remove("is-open");renderList();});

  // save edit
  const saveBtn=document.getElementById("co-save-edit");
  if(saveBtn)saveBtn.addEventListener("click",async()=>{
    const title=document.getElementById("co-edit-title").value.trim();
    const desc=document.getElementById("co-edit-desc").value.trim();
    if(!title){ui.toast("أدخل العنوان","warning");return;}
    try{
      await api.patch("/api/marketplace/requests/client/"+d.id+"/",{title,description:desc});
      ui.toast("تم الحفظ","success");
      loadDetail(d.id);
    }catch{ui.toast("فشل الحفظ","error");}
  });

  // review submit
  const revBtn=document.getElementById("co-submit-review");
  if(revBtn)revBtn.addEventListener("click",()=>submitReview(d.id));

  // star interactions
  dom.detailBody.querySelectorAll(".nw-co-star-group").forEach(group=>{
    const stars=group.querySelectorAll(".material-icons-round");
    stars.forEach((s,i)=>{
      s.addEventListener("click",()=>{
        stars.forEach((ss,j)=>ss.classList.toggle("filled",j<=i));
        group.dataset.value=i+1;
      });
    });
  });
}

function buildReviewSection(d){
  const criteria=[
    {key:"response_speed",label:"سرعة الاستجابة"},
    {key:"cost_value",label:"التكلفة مقابل الخدمة"},
    {key:"quality",label:"جودة الخدمة"},
    {key:"credibility",label:"المصداقية"},
    {key:"on_time",label:"وقت الإنجاز"}
  ];
  let html=`<div class="nw-co-review"><h4>تقييم الخدمة</h4>`;
  criteria.forEach(c=>{
    const existing=d["review_"+c.key]||0;
    html+=`<div class="nw-co-review-row"><label>${c.label}</label><div class="nw-co-star-group" data-key="${c.key}" data-value="${existing}">`;
    for(let i=1;i<=5;i++){
      html+=`<span class="material-icons-round ${i<=existing?"filled":""}">star</span>`;
    }
    html+=`</div></div>`;
  });
  const existingComment=d.review_comment||"";
  html+=`<textarea id="co-review-comment" placeholder="تعليق على الخدمة...">${existingComment}</textarea>`;
  html+=`<button class="nw-btn" id="co-submit-review">إرسال التقييم</button></div>`;
  return html;
}

async function submitReview(orderId){
  const payload={};
  dom.detailBody.querySelectorAll(".nw-co-star-group").forEach(g=>{
    payload["review_"+g.dataset.key]=Number(g.dataset.value)||0;
  });
  const comment=document.getElementById("co-review-comment");
  if(comment)payload.review_comment=comment.value.trim();
  try{
    await api.patch("/api/marketplace/requests/client/"+orderId+"/",payload);
    ui.toast("شكراً لتقييمك!","success");
  }catch{ui.toast("فشل إرسال التقييم","error");}
}

/* filters */
dom.filters.addEventListener("click",e=>{
  const chip=e.target.closest(".nw-co-chip");
  if(!chip)return;
  state.status=chip.dataset.status||"";
  dom.filters.querySelectorAll(".nw-co-chip").forEach(c=>c.classList.toggle("is-active",c===chip));
  loadOrders();
});

/* search */
dom.search.addEventListener("input",()=>{
  clearTimeout(state.timer);
  state.timer=setTimeout(()=>{state.query=dom.search.value.trim();loadOrders();},400);
});

/* init */
api.get("/api/accounts/me/").then(()=>loadOrders()).catch(()=>{
  dom.list.innerHTML='<div class="nw-co-empty"><span class="material-icons-round">lock</span><p>سجل دخولك أولاً</p></div>';
});
})();
