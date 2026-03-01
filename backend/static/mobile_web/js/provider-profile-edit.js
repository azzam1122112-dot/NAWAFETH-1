(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const panels={
  account:document.getElementById("panel-account"),
  general:document.getElementById("panel-general"),
  extra:document.getElementById("panel-extra")
};
const tabs=document.getElementById("pp-tabs");
const fillBar=document.getElementById("pp-fill");
const pctEl=document.getElementById("pp-pct");
const compBlock=document.getElementById("pp-completion");

let profile={};

/* tabs */
tabs.addEventListener("click",e=>{
  const tab=e.target.closest(".nw-pp-tab");
  if(!tab)return;
  tabs.querySelectorAll(".nw-pp-tab").forEach(t=>t.classList.toggle("is-active",t===tab));
  Object.keys(panels).forEach(k=>panels[k].classList.toggle("is-active",k===tab.dataset.tab));
});

function safe(v){return(v===undefined||v===null||v==="")?"-":String(v);}

function buildField(key,label,value,inputType,options){
  const isEmpty=!value||value==="-";
  let inputHtml="";
  if(inputType==="textarea"){
    inputHtml=`<textarea data-key="${key}">${value||""}</textarea>`;
  }else if(inputType==="select"&&options){
    inputHtml=`<select data-key="${key}">${options.map(o=>`<option value="${o}" ${o===value?"selected":""}>${o}</option>`).join("")}</select>`;
  }else{
    inputHtml=`<input type="text" data-key="${key}" value="${value||""}">`;
  }
  return`<div class="nw-pp-field" data-key="${key}">
    <div class="nw-pp-field-header">
      <span class="nw-pp-field-label">${label}</span>
      <button class="nw-pp-field-edit"><span class="material-icons-round">edit</span>تعديل</button>
    </div>
    <div class="nw-pp-field-value ${isEmpty?"empty":""}">${isEmpty?"لم يُحدد بعد":safe(value)}</div>
    <div class="nw-pp-field-input">${inputHtml}<button class="nw-pp-save" data-key="${key}">حفظ</button></div>
  </div>`;
}

const cities=["الرياض","جدة","مكة المكرمة","المدينة المنورة","الدمام","الخبر","الطائف","تبوك","بريدة","خميس مشيط","حائل","نجران","جازان","ينبع","أبها","الأحساء","القطيف","الجبيل"];

async function load(){
  Object.values(panels).forEach(p=>{p.innerHTML='<div class="nw-pp-loading">جارٍ التحميل...</div>';});
  try{
    profile=await api.get("/api/providers/profile/my/");
    render();
  }catch{
    panels.account.innerHTML='<div class="nw-pp-loading" style="color:#E53935">تعذر تحميل الملف</div>';
  }
}

function render(){
  // completion
  const pct=profile.profile_completion||profile.profileCompletion||30;
  compBlock.hidden=false;
  fillBar.style.width=pct+"%";
  pctEl.textContent=pct+"% مكتمل";

  // Tab 1
  panels.account.innerHTML=[
    buildField("display_name","اسم العرض",profile.display_name||profile.displayName,"text"),
    buildField("provider_type","نوع الحساب",profile.provider_type||profile.providerType,"text"),
    buildField("bio","نبذة",profile.bio,"textarea"),
    buildField("about_details","التخصص",profile.about_details||profile.aboutDetails,"textarea")
  ].join("");

  // Tab 2
  panels.general.innerHTML=[
    buildField("years_experience","سنوات الخبرة",profile.years_experience||profile.yearsExperience,"text"),
    buildField("languages","اللغات",profile.languages,"text"),
    buildField("city","المدينة",profile.city,"select",cities)
  ].join("");

  // Tab 3
  panels.extra.innerHTML=[
    buildField("qualifications","المؤهلات",profile.qualifications,"textarea"),
    buildField("website","الموقع الإلكتروني",profile.website,"text"),
    buildField("social_links","روابط التواصل",profile.social_links||profile.socialLinks,"text"),
    buildField("whatsapp","واتساب",profile.whatsapp,"text"),
    buildField("seo_keywords","كلمات مفتاحية SEO",profile.seo_keywords||profile.seoKeywords,"textarea")
  ].join("");

  bindEdits();
}

function bindEdits(){
  document.querySelectorAll(".nw-pp-field-edit").forEach(btn=>{
    btn.addEventListener("click",()=>{
      const field=btn.closest(".nw-pp-field");
      field.classList.toggle("is-editing");
    });
  });

  document.querySelectorAll(".nw-pp-save").forEach(btn=>{
    btn.addEventListener("click",async()=>{
      const key=btn.dataset.key;
      const field=btn.closest(".nw-pp-field");
      const input=field.querySelector("[data-key]");
      if(!input)return;
      const value=input.value.trim();
      const payload={};
      payload[key]=value;
      btn.textContent="جارٍ الحفظ...";
      btn.disabled=true;
      try{
        await api.patch("/api/providers/profile/my/",payload);
        profile[key]=value;
        field.classList.remove("is-editing");
        const valEl=field.querySelector(".nw-pp-field-value");
        valEl.textContent=value||"لم يُحدد بعد";
        valEl.classList.toggle("empty",!value);
        ui.toast("تم الحفظ","success");
      }catch{
        ui.toast("فشل الحفظ","error");
      }
      btn.textContent="حفظ";
      btn.disabled=false;
    });
  });
}

load();
})();
