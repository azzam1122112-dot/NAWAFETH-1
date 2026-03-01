(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const statusMap={new:"جديد",in_review:"قيد المراجعة",quoted:"تم التسعير",pending_payment:"بانتظار الدفع",active:"مفعل",rejected:"مرفوض",expired:"منتهي",cancelled:"ملغي"};
const adMap={banner_home:"بانر الصفحة الرئيسية",banner_category:"بانر صفحة القسم",banner_search:"بانر صفحة البحث",popup_home:"نافذة منبثقة رئيسية",popup_category:"نافذة منبثقة داخل قسم",featured_top5:"تمييز ضمن أول 5",featured_top10:"تمييز ضمن أول 10",boost_profile:"تعزيز الملف",push_notification:"إشعار دفع"};
const cities=["الرياض","جدة","مكة المكرمة","المدينة المنورة","الدمام","الخبر","الطائف","تبوك","بريدة","خميس مشيط","حائل","نجران","جازان","ينبع","أبها","الأحساء","القطيف","الجبيل"];

const listEl=document.getElementById("promo-list");
const emptyEl=document.getElementById("promo-empty");
const formEl=document.getElementById("promo-form");
const tabsEl=document.getElementById("promo-tabs");

/* City dropdown */
const citySelect=document.getElementById("pf-city");
cities.forEach(c=>{const o=document.createElement("option");o.value=c;o.textContent=c;citySelect.appendChild(o);});

/* Files */
const uploadArea=document.getElementById("pf-upload-area");
const fileInput=document.getElementById("pf-file");
const chipsEl=document.getElementById("pf-files-chips");
let assetFiles=[];

uploadArea.addEventListener("click",()=>fileInput.click());
fileInput.addEventListener("change",()=>{
  Array.from(fileInput.files).forEach(f=>assetFiles.push(f));
  renderChips();
  fileInput.value="";
});

function renderChips(){
  chipsEl.innerHTML=assetFiles.map((f,i)=>`<span class="nw-promo-chip">${f.name.slice(0,20)}<span class="nw-promo-chip-rm" data-i="${i}">&times;</span></span>`).join("");
  chipsEl.querySelectorAll(".nw-promo-chip-rm").forEach(el=>{
    el.addEventListener("click",()=>{assetFiles.splice(+el.dataset.i,1);renderChips();});
  });
}

/* Tabs */
tabsEl.addEventListener("click",e=>{
  const tab=e.target.closest(".nw-promo-tab");
  if(!tab)return;
  tabsEl.querySelectorAll(".nw-promo-tab").forEach(t=>t.classList.toggle("is-active",t===tab));
  const isCreate=tab.dataset.tab==="create";
  formEl.classList.toggle("is-active",isCreate);
  listEl.style.display=isCreate?"none":"";
});

/* Load my requests */
async function loadRequests(){
  listEl.querySelectorAll(".nw-promo-card").forEach(c=>c.remove());
  try{
    const res=await api.get("/api/promo/requests/my/");
    const items=Array.isArray(res)?res:(res.results||[]);
    emptyEl.hidden=items.length>0;
    items.forEach(r=>{
      const s=r.status||"new";
      const dt=r.created_at?r.created_at.slice(0,10):"";
      listEl.insertAdjacentHTML("beforeend",`
        <div class="nw-promo-card">
          <div class="nw-promo-card-head">
            <div class="nw-promo-card-icon"><span class="material-icons-round">campaign</span></div>
            <div class="nw-promo-card-info">
              <div class="nw-promo-card-title">${r.title||"طلب ترويج"}</div>
              ${r.code?`<div class="nw-promo-card-code">${r.code}</div>`:""}
            </div>
            <span class="nw-promo-badge" data-s="${s}">${statusMap[s]||s}</span>
          </div>
          <div class="nw-promo-card-meta">
            <span class="material-icons-round">ad_units</span> ${adMap[r.ad_type]||r.ad_type||"—"}
            <span style="flex:1"></span>
            <span class="material-icons-round">calendar_today</span> ${dt}
          </div>
        </div>`);
    });
  }catch{
    emptyEl.hidden=false;
  }
}

/* Submit */
document.getElementById("pf-submit").addEventListener("click",async()=>{
  const title=document.getElementById("pf-title").value.trim();
  const start=document.getElementById("pf-start").value;
  const end=document.getElementById("pf-end").value;
  if(!title){ui.toast("العنوان مطلوب","error");return;}
  if(!start||!end){ui.toast("حدد تاريخ البداية والنهاية","error");return;}
  if(end<=start){ui.toast("تاريخ النهاية يجب أن يكون بعد البداية","error");return;}

  const btn=document.getElementById("pf-submit");
  btn.disabled=true;btn.textContent="جارٍ الإرسال...";

  try{
    const body={
      title,
      ad_type:document.getElementById("pf-adtype").value,
      start_at:new Date(start).toISOString(),
      end_at:new Date(end).toISOString(),
      frequency:document.getElementById("pf-freq").value,
      position:document.getElementById("pf-pos").value,
    };
    const city=document.getElementById("pf-city").value;
    if(city)body.target_city=city;
    const redirect=document.getElementById("pf-redirect").value.trim();
    if(redirect)body.redirect_url=redirect;
    const mt=document.getElementById("pf-msgtitle").value.trim();
    if(mt)body.message_title=mt;
    const mb=document.getElementById("pf-msgbody").value.trim();
    if(mb)body.message_body=mb;

    const res=await api.post("/api/promo/requests/create/",body);
    const rid=res.id;

    // Upload assets
    if(rid&&assetFiles.length){
      for(const f of assetFiles){
        const fd=new FormData();
        fd.append("file",f);
        fd.append("asset_type","image");
        await api.upload(`/api/promo/requests/${rid}/assets/`,fd);
      }
    }

    ui.toast("تم إرسال طلب الترويج بنجاح","success");
    // Reset form
    document.getElementById("pf-title").value="";
    document.getElementById("pf-start").value="";
    document.getElementById("pf-end").value="";
    document.getElementById("pf-redirect").value="";
    document.getElementById("pf-msgtitle").value="";
    document.getElementById("pf-msgbody").value="";
    assetFiles=[];renderChips();

    // Switch to list tab
    tabsEl.querySelector('[data-tab="list"]').click();
    loadRequests();
  }catch(err){
    ui.toast("فشل إرسال الطلب","error");
  }
  btn.disabled=false;btn.textContent="إرسال الطلب";
});

loadRequests();
})();
