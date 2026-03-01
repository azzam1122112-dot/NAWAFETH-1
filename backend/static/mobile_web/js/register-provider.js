(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const cities=["الرياض","جدة","مكة المكرمة","المدينة المنورة","الدمام","الخبر","الطائف","تبوك","بريدة","خميس مشيط","حائل","نجران","جازان","ينبع","أبها","الأحساء","القطيف","الجبيل"];
const providerTypes=[
  {value:"individual",label:"فرد"},
  {value:"company",label:"شركة / مؤسسة"},
  {value:"freelancer",label:"عامل حر"}
];

let step=0;
const data={
  display_name:"",bio:"",provider_type:"individual",city:"",
  categories:[],
  phone:"",whatsapp:"",website:""
};
let categories=[];

const contentEl=document.getElementById("reg-content");
const stepsEl=document.getElementById("reg-steps");
const prevBtn=document.getElementById("reg-prev");
const nextBtn=document.getElementById("reg-next");
const fillBar=document.getElementById("reg-fill");
const pctEl=document.getElementById("reg-pct");
const successEl=document.getElementById("reg-success");
const urls=window.NAWAFETH_WEB_CONFIG?.urls||{};

/* Load categories */
async function loadCategories(){
  try{
    const res=await api.get("/api/providers/categories/");
    categories=Array.isArray(res)?res:(res.results||[]);
  }catch{categories=[];}
}

/* Step indicators */
function updateUI(){
  stepsEl.querySelectorAll(".nw-reg-step-item").forEach((el,i)=>{
    el.classList.toggle("active",i===step);
    el.classList.toggle("done",i<step);
  });
  prevBtn.hidden=step===0;
  nextBtn.textContent=step===2?"إنشاء الحساب":"التالي";
  const pct=Math.round(calcProgress()*100);
  fillBar.style.width=pct+"%";
  pctEl.textContent=pct+"%";
}

function calcProgress(){
  let filled=0,total=8;
  if(data.display_name)filled++;
  if(data.bio)filled++;
  if(data.provider_type)filled++;
  if(data.city)filled++;
  if(data.categories.length)filled++;
  if(data.phone)filled++;
  if(data.whatsapp)filled++;
  if(data.website)filled++;
  return filled/total;
}

/* Step 1: Personal Info */
function renderStep1(){
  contentEl.innerHTML=`
    <div class="nw-reg-field">
      <label>الاسم التعريفي *</label>
      <input id="rf-name" type="text" placeholder="اسمك كمقدم خدمة" value="${data.display_name}" maxlength="80">
    </div>
    <div class="nw-reg-field">
      <label>نوع الحساب</label>
      <select id="rf-type">${providerTypes.map(t=>`<option value="${t.value}" ${t.value===data.provider_type?"selected":""}>${t.label}</option>`).join("")}</select>
    </div>
    <div class="nw-reg-field">
      <label>نبذة تعريفية</label>
      <textarea id="rf-bio" placeholder="اكتب نبذة مختصرة عنك" maxlength="500">${data.bio}</textarea>
      <div class="hint">حتى 500 حرف</div>
    </div>
    <div class="nw-reg-field">
      <label>المدينة *</label>
      <select id="rf-city"><option value="">اختر المدينة</option>${cities.map(c=>`<option value="${c}" ${c===data.city?"selected":""}>${c}</option>`).join("")}</select>
    </div>`;
  bindStep1();
}

function bindStep1(){
  ["rf-name","rf-type","rf-bio","rf-city"].forEach(id=>{
    const el=document.getElementById(id);
    if(el)el.addEventListener("input",()=>{collectStep1();updateUI();});
    if(el)el.addEventListener("change",()=>{collectStep1();updateUI();});
  });
}

function collectStep1(){
  data.display_name=(document.getElementById("rf-name")?.value||"").trim();
  data.provider_type=document.getElementById("rf-type")?.value||"individual";
  data.bio=(document.getElementById("rf-bio")?.value||"").trim();
  data.city=document.getElementById("rf-city")?.value||"";
}

/* Step 2: Service Classification */
function renderStep2(){
  contentEl.innerHTML=`
    <h3 style="font-size:15px;font-weight:700;margin:0 0 6px">اختر تصنيفات خدماتك</h3>
    <p style="font-size:13px;color:#777;margin-bottom:14px">اختر التصنيفات التي تقدم فيها خدماتك (يمكنك اختيار أكثر من واحد)</p>
    <div class="nw-reg-chips" id="rf-cats">
      ${categories.map(c=>`<span class="nw-reg-chip ${data.categories.includes(c.id||c.name)?"is-selected":""}" data-id="${c.id||c.name}">${c.name||c.title}</span>`).join("")}
    </div>
    ${!categories.length?'<p style="color:#999;font-size:13px;margin-top:12px">لا توجد تصنيفات متاحة حالياً</p>':""}`;
  document.querySelectorAll("#rf-cats .nw-reg-chip").forEach(chip=>{
    chip.addEventListener("click",()=>{
      const id=chip.dataset.id;
      const numId=parseInt(id);
      const val=isNaN(numId)?id:numId;
      const idx=data.categories.indexOf(val);
      if(idx>=0)data.categories.splice(idx,1);else data.categories.push(val);
      chip.classList.toggle("is-selected");
      updateUI();
    });
  });
}

/* Step 3: Contact Info */
function renderStep3(){
  contentEl.innerHTML=`
    <div class="nw-reg-field">
      <label>رقم الجوال *</label>
      <input id="rf-phone" type="tel" placeholder="05xxxxxxxx" value="${data.phone}">
    </div>
    <div class="nw-reg-field">
      <label>واتساب</label>
      <input id="rf-wa" type="tel" placeholder="05xxxxxxxx" value="${data.whatsapp}">
    </div>
    <div class="nw-reg-field">
      <label>الموقع الإلكتروني (اختياري)</label>
      <input id="rf-web" type="url" placeholder="https://..." value="${data.website}">
    </div>`;
  ["rf-phone","rf-wa","rf-web"].forEach(id=>{
    const el=document.getElementById(id);
    if(el)el.addEventListener("input",()=>{collectStep3();updateUI();});
  });
}

function collectStep3(){
  data.phone=(document.getElementById("rf-phone")?.value||"").trim();
  data.whatsapp=(document.getElementById("rf-wa")?.value||"").trim();
  data.website=(document.getElementById("rf-web")?.value||"").trim();
}

/* Navigation */
nextBtn.addEventListener("click",async()=>{
  if(step===0)collectStep1();
  if(step===2){collectStep3();await submitRegistration();return;}
  if(step<2){step++;updateUI();render();}
});
prevBtn.addEventListener("click",()=>{
  if(step===0)return;
  if(step===2)collectStep3();
  step--;updateUI();render();
});

async function submitRegistration(){
  if(!data.display_name||!data.city){ui.toast("أكمل الحقول المطلوبة","error");return;}
  nextBtn.disabled=true;nextBtn.textContent="جارٍ الإنشاء...";
  try{
    await api.post("/api/providers/register/",{
      display_name:data.display_name,
      provider_type:data.provider_type,
      bio:data.bio,
      city:data.city,
      categories:data.categories,
      phone:data.phone,
      whatsapp:data.whatsapp,
      website:data.website
    });
    // Set provider mode
    try{await api.post("/api/accounts/mode/",{mode:"provider"});}catch{}
    successEl.classList.add("is-visible");
  }catch(err){
    ui.toast("فشل إنشاء الحساب","error");
  }
  nextBtn.disabled=false;nextBtn.textContent="إنشاء الحساب";
}

document.getElementById("reg-go").addEventListener("click",()=>{
  window.location.href=urls.providerDashboard||"/web/provider/dashboard/";
});

function render(){
  if(step===0)renderStep1();
  else if(step===1)renderStep2();
  else renderStep3();
}

loadCategories().then(()=>{updateUI();render();});
})();
