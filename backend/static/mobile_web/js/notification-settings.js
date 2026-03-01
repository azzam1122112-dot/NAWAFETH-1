(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const tiersEl=document.getElementById("ns-tiers");
const loadingEl=document.getElementById("ns-loading");
const upgradeEl=document.getElementById("ns-upgrade");
const urls=window.NAWAFETH_WEB_CONFIG?.urls||{};

const tierOrder=["basic","leading","professional","extra"];
const tierLabels={basic:"الباقة الأساسية",leading:"الباقة الرائدة",professional:"الباقة الاحترافية",extra:"الباقة المميزة"};
const tierIcons={basic:"star",leading:"rocket_launch",professional:"auto_awesome",extra:"diamond"};

let preferences=[];
const savingKeys=new Set();

document.getElementById("ns-upgrade-cancel").addEventListener("click",()=>upgradeEl.classList.remove("is-visible"));
document.getElementById("ns-upgrade-go").addEventListener("click",()=>{
  upgradeEl.classList.remove("is-visible");
  window.location.href=urls.plans||"/web/plans/";
});

async function load(){
  loadingEl.style.display="";
  try{
    const res=await api.get("/api/notifications/preferences/");
    preferences=Array.isArray(res)?res:(res.results||res.preferences||[]);
    render();
  }catch{
    loadingEl.innerHTML='<span style="color:#E53935">تعذر تحميل الإعدادات</span>';
  }
}

function groupByTier(){
  const grouped={};
  preferences.forEach(p=>{
    const t=p.tier||"basic";
    if(!grouped[t])grouped[t]=[];
    grouped[t].push(p);
  });
  return grouped;
}

function render(){
  loadingEl.style.display="none";
  tiersEl.querySelectorAll(".nw-tier-card").forEach(c=>c.remove());
  const grouped=groupByTier();

  tierOrder.forEach((tier,idx)=>{
    const prefs=grouped[tier];
    if(!prefs||!prefs.length)return;
    const allLocked=prefs.every(p=>p.locked);
    const enabled=prefs.filter(p=>p.enabled&&!p.locked).length;

    const card=document.createElement("div");
    card.className="nw-tier-card"+(idx===0?" is-open":"");
    card.innerHTML=`
      <div class="nw-tier-header">
        <div class="nw-tier-icon"><span class="material-icons-round">${tierIcons[tier]||"star"}</span></div>
        <div class="nw-tier-title">${tierLabels[tier]||tier}</div>
        ${allLocked?'<span class="nw-tier-locked">مقفلة</span>':""}
        <span class="nw-tier-count">${enabled}/${prefs.length}</span>
        <span class="material-icons-round nw-tier-arrow">expand_more</span>
      </div>
      <div class="nw-tier-body">${prefs.map(p=>buildPrefItem(p)).join("")}</div>`;

    card.querySelector(".nw-tier-header").addEventListener("click",()=>card.classList.toggle("is-open"));
    tiersEl.appendChild(card);
  });

  bindSwitches();
}

function buildPrefItem(p){
  const locked=p.locked;
  return`<div class="nw-pref-item ${locked?"is-locked":""}" data-key="${p.key}">
    <div class="nw-pref-info">
      <div class="nw-pref-title">${p.title||p.key}</div>
      ${locked?'<div class="nw-pref-locked-hint">يتطلب ترقية الباقة</div>':""}
    </div>
    <div class="nw-pref-icon" id="ns-icon-${p.key}"></div>
    <label class="nw-switch">
      <input type="checkbox" ${p.enabled?"checked":""} ${locked?"disabled":""} data-key="${p.key}" data-locked="${locked?1:0}">
      <span class="nw-switch-slider"></span>
    </label>
  </div>`;
}

function bindSwitches(){
  tiersEl.querySelectorAll('.nw-switch input').forEach(inp=>{
    inp.addEventListener("change",async()=>{
      const key=inp.dataset.key;
      if(inp.dataset.locked==="1"){
        inp.checked=!inp.checked;
        upgradeEl.classList.add("is-visible");
        return;
      }
      const iconEl=document.getElementById("ns-icon-"+key);
      if(iconEl)iconEl.innerHTML='<div class="nw-pref-saving"></div>';
      try{
        await api.patch("/api/notifications/preferences/",[{key,enabled:inp.checked}]);
        const pref=preferences.find(p=>p.key===key);
        if(pref)pref.enabled=inp.checked;
        ui.toast("تم الحفظ","success");
      }catch{
        inp.checked=!inp.checked;
        ui.toast("فشل حفظ الإعداد","error");
      }
      if(iconEl)iconEl.innerHTML="";
      // Update counts
      render();
    });
  });
}

load();
})();
