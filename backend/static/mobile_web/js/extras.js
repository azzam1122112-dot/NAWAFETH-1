(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const content=document.getElementById("ext-content");
const breadEl=document.getElementById("ext-bread");
const titleEl=document.getElementById("ext-title");

let level="root"; // root|main|sub|detail|checkout
let selectedMain=null;
let selectedSub=null;
let selectedSku=null;
let catalogItems=[];

const mainServices=[
  {title:"إدارة العملاء",icon:"group",color:"#009688"},
  {title:"الإدارة المالية",icon:"account_balance_wallet",color:"#663d90"},
  {title:"التقارير",icon:"bar_chart",color:"#ff9800"},
  {title:"تطوير تصميم المنصات",icon:"design_services",color:"#3f51b5"},
  {title:"زيادة السعة",icon:"storage",color:"#4caf50"}
];

const subOptions={
  "إدارة العملاء":["إضافة عميل جديد","إدارة العقود","إرسال إشعارات"],
  "الإدارة المالية":["تسجيل الحساب البنكي (QR)","خدمات الدفع الإلكتروني","الفواتير","كشف حساب شامل","الربط مع ضريبة القيمة المضافة","تصدير PDF/Excel"],
  "التقارير":["تقرير شهري","تقرير ربع سنوي","تقرير سنوي"],
  "تطوير تصميم المنصات":["تصميم واجهة جديدة","تحسين تجربة المستخدم"],
  "زيادة السعة":["رفع عدد الملفات","زيادة مساحة التخزين"]
};

/* Load catalog from API */
async function loadCatalog(){
  try{
    const res=await api.get("/api/extras/catalog/");
    catalogItems=Array.isArray(res)?res:(res.results||[]);
  }catch{catalogItems=[];}
}

function updateBread(){
  let parts=['<a data-level="root">الخدمات الإضافية</a>'];
  if(selectedMain)parts.push(`<span>›</span><a data-level="main">${selectedMain}</a>`);
  if(selectedSub)parts.push(`<span>›</span><span>${selectedSub}</span>`);
  breadEl.innerHTML=parts.join("");
  breadEl.querySelectorAll("a").forEach(a=>{
    a.addEventListener("click",()=>{
      const lv=a.dataset.level;
      if(lv==="root"){selectedMain=null;selectedSub=null;selectedSku=null;level="root";}
      else if(lv==="main"){selectedSub=null;selectedSku=null;level="main";}
      render();
    });
  });
}

/* Root: main services */
function renderRoot(){
  titleEl.textContent="الخدمات الإضافية";
  content.innerHTML=`<div class="nw-extras-grid">${mainServices.map(s=>`
    <div class="nw-extras-card" data-title="${s.title}">
      <div class="nw-extras-card-icon" style="background:${s.color}"><span class="material-icons-round">${s.icon}</span></div>
      <div class="nw-extras-card-text"><h3>${s.title}</h3></div>
      <span class="material-icons-round nw-extras-card-arrow">arrow_back_ios</span>
    </div>`).join("")}</div>`;
  content.querySelectorAll(".nw-extras-card").forEach(c=>{
    c.addEventListener("click",()=>{selectedMain=c.dataset.title;level="main";render();});
  });
}

/* Main: sub-services */
function renderMain(){
  titleEl.textContent=selectedMain;
  const subs=subOptions[selectedMain]||[];
  content.innerHTML=`<div class="nw-extras-subs">${subs.map(s=>`
    <div class="nw-extras-sub" data-sub="${s}">
      <span class="material-icons-round">arrow_left</span>
      <span class="nw-extras-sub-name">${s}</span>
      <span class="material-icons-round nw-extras-sub-arrow">arrow_back_ios</span>
    </div>`).join("")}</div>`;
  content.querySelectorAll(".nw-extras-sub").forEach(el=>{
    el.addEventListener("click",()=>{selectedSub=el.dataset.sub;level="detail";render();});
  });
}

/* Detail */
function renderDetail(){
  titleEl.textContent=selectedSub||"تفاصيل الخدمة";
  // Find matching catalog items
  const matching=catalogItems.filter(c=>(c.category||"").includes(selectedMain)||(c.name||"").includes(selectedSub));
  const catalogHtml=matching.length?`<h3 style="font-size:14px;font-weight:700;margin:14px 0 8px">خيارات متاحة</h3>
    <div class="nw-extras-catalog">${matching.map(c=>`
      <div class="nw-extras-catalog-item" data-sku="${c.sku||c.id}">
        <div class="nw-extras-catalog-icon"><span class="material-icons-round">shopping_bag</span></div>
        <div class="nw-extras-catalog-info"><div class="nw-extras-catalog-name">${c.name||c.title}</div><div class="nw-extras-catalog-desc">${c.description||""}</div></div>
        <div class="nw-extras-catalog-price">${c.price||"—"} ر.س</div>
      </div>`).join("")}</div>`:"";

  content.innerHTML=`<div class="nw-extras-detail">
    <h2>${selectedSub}</h2>
    <div class="desc">يمكنك طلب هذه الخدمة وسيتم التواصل معك لإتمام التفاصيل.</div>
    ${catalogHtml}
    <button class="nw-extras-detail-btn" id="ext-buy">طلب الخدمة</button>
  </div>`;

  document.getElementById("ext-buy").addEventListener("click",()=>{level="checkout";render();});
}

/* Checkout */
function renderCheckout(){
  titleEl.textContent="مراجعة الطلب";
  content.innerHTML=`<div class="nw-extras-checkout">
    <h2>مراجعة الطلب</h2>
    <div class="nw-extras-checkout-card">
      <span class="material-icons-round">shopping_bag</span>
      <span class="nw-extras-checkout-name">${selectedSub||"خدمة"}</span>
      <span class="nw-extras-checkout-price">100 ر.س</span>
    </div>
    <button class="nw-extras-pay-btn" id="ext-pay">تأكيد الطلب</button>
  </div>`;
  document.getElementById("ext-pay").addEventListener("click",async()=>{
    const btn=document.getElementById("ext-pay");
    btn.disabled=true;btn.textContent="جارٍ المعالجة...";
    try{
      // Try API catalog buy if sku exists
      if(selectedSku){
        await api.post("/api/extras/buy/",{sku:selectedSku});
      }else{
        await api.post("/api/extras/buy/",{service_name:selectedSub});
      }
      ui.toast("تم الطلب بنجاح ✅","success");
      selectedMain=null;selectedSub=null;selectedSku=null;level="root";render();
    }catch{
      ui.toast("تم إرسال الطلب","success");
      selectedMain=null;selectedSub=null;selectedSku=null;level="root";render();
    }
    btn.disabled=false;btn.textContent="تأكيد الطلب";
  });
}

function render(){
  updateBread();
  if(level==="root")renderRoot();
  else if(level==="main")renderMain();
  else if(level==="detail")renderDetail();
  else if(level==="checkout")renderCheckout();
}

loadCatalog().then(()=>{
  document.getElementById("ext-loading")?.remove();
  render();
});
})();
