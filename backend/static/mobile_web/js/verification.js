(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

let step=0;
let selectedType=null; // "blue"|"green"
let blueOption=null;   // "person"|"company"|"other"
const greenOptions=new Set();
let uploadedFiles=[];

const panel=document.getElementById("verif-panel");
const prevBtn=document.getElementById("verif-prev");
const nextBtn=document.getElementById("verif-next");
const stepsEl=document.getElementById("verif-steps");
const successEl=document.getElementById("verif-success");

/* Step indicators */
function updateSteps(){
  stepsEl.querySelectorAll(".nw-verif-step").forEach((el,i)=>{
    el.classList.toggle("active",i===step);
    el.classList.toggle("done",i<step);
  });
  stepsEl.querySelectorAll(".nw-verif-line").forEach((el,i)=>{el.classList.toggle("done",i<step);});
  prevBtn.hidden=step===0;
  nextBtn.textContent=step===2?"تأكيد الطلب":"التالي";
}

/* Validation */
function canProceed(){
  if(step===0)return!!selectedType;
  if(step===1){
    if(selectedType==="blue"){
      if(!blueOption)return false;
      if(blueOption==="person"){
        const id=document.getElementById("vf-id");
        const dob=document.getElementById("vf-dob");
        return id&&id.value.trim().length>=8&&dob&&dob.value;
      }
      if(blueOption==="company"){
        const cr=document.getElementById("vf-cr");
        const crDate=document.getElementById("vf-crdate");
        return cr&&cr.value.trim().length>=5&&crDate&&crDate.value;
      }
      if(blueOption==="other")return uploadedFiles.length>0;
    }
    if(selectedType==="green")return greenOptions.size>0&&uploadedFiles.length>0;
  }
  return true;
}

function refreshBtn(){nextBtn.disabled=!canProceed();}

/* Render step 1 */
function renderStep1(){
  panel.innerHTML=`
    <h3 style="font-size:16px;font-weight:700;margin:0 0 4px">اختر نوع التوثيق المناسب لك</h3>
    <p style="font-size:13px;color:#777;margin-bottom:18px">يمكنك توثيق هويتك أو اعتمادك المهني للحصول على ثقة أكبر لدى العملاء.</p>
    <div class="nw-verif-badges">
      <div class="nw-badge-card ${selectedType==="blue"?"is-selected":""}" data-type="blue">
        <div class="nw-badge-card-head">
          <div class="nw-badge-card-icon blue"><span class="material-icons-round">verified</span></div>
          <div class="nw-badge-card-text">
            <h3>التوثيق بالشارة الزرقاء</h3>
            <p>إثبات الهوية الشخصية أو السجل التجاري كمنشأة.</p>
          </div>
        </div>
        <div class="nw-badge-card-price">100 ر.س/سنة</div>
        <span class="nw-badge-card-tag blue">هوية / سجل تجاري</span>
      </div>
      <div class="nw-badge-card ${selectedType==="green"?"is-selected":""}" data-type="green">
        <div class="nw-badge-card-head">
          <div class="nw-badge-card-icon green"><span class="material-icons-round">workspace_premium</span></div>
          <div class="nw-badge-card-text">
            <h3>التوثيق بالشارة الخضراء</h3>
            <p>توثيق اعتمادك المهني وشهاداتك وخبراتك العملية.</p>
          </div>
        </div>
        <div class="nw-badge-card-price">150 ر.س/سنة</div>
        <span class="nw-badge-card-tag green">اعتمادات مهنية</span>
      </div>
    </div>`;
  panel.querySelectorAll(".nw-badge-card").forEach(c=>{
    c.addEventListener("click",()=>{
      selectedType=c.dataset.type;
      renderStep1();
      refreshBtn();
    });
  });
}

/* Render step 2 */
function renderStep2(){
  if(!selectedType){panel.innerHTML='<p style="color:#999;text-align:center">يرجى اختيار نوع الشارة أولاً</p>';return;}
  if(selectedType==="blue")renderBlueForm();
  else renderGreenForm();
}

function renderBlueForm(){
  let formHtml="";
  if(blueOption==="person"){
    formHtml=`<div class="nw-verif-field"><label>رقم الهوية / الإقامة</label><input id="vf-id" type="text" placeholder="أدخل رقم الهوية"></div>
    <div class="nw-verif-field"><label>تاريخ الميلاد</label><input id="vf-dob" type="date"></div>`;
  }else if(blueOption==="company"){
    formHtml=`<div class="nw-verif-field"><label>رقم السجل التجاري</label><input id="vf-cr" type="text" placeholder="أدخل رقم السجل"></div>
    <div class="nw-verif-field"><label>تاريخ السجل</label><input id="vf-crdate" type="date"></div>`;
  }else if(blueOption==="other"){
    formHtml=uploadSection();
  }

  panel.innerHTML=`
    <h3 style="font-size:14px;font-weight:700;margin:0 0 10px">اختر نوع التوثيق بالشارة الزرقاء</h3>
    <div class="nw-verif-options">
      <div class="nw-opt-card ${blueOption==="person"?"is-selected":""}" data-opt="person">
        <div class="nw-opt-card-icon"><span class="material-icons-round">person</span></div>
        <div class="nw-opt-card-text"><h4>فرد</h4><p>توثيق هوية شخصية لمستخدم واحد.</p></div>
        <div class="nw-opt-card-radio"></div>
      </div>
      <div class="nw-opt-card ${blueOption==="company"?"is-selected":""}" data-opt="company">
        <div class="nw-opt-card-icon"><span class="material-icons-round">apartment</span></div>
        <div class="nw-opt-card-text"><h4>كيان تجاري</h4><p>شركة أو مؤسسة بسجل تجاري موثق.</p></div>
        <div class="nw-opt-card-radio"></div>
      </div>
      <div class="nw-opt-card ${blueOption==="other"?"is-selected":""}" data-opt="other">
        <div class="nw-opt-card-icon"><span class="material-icons-round">description</span></div>
        <div class="nw-opt-card-text"><h4>أوراق رسمية</h4><p>خطابات، عقود، أو مستندات رسمية أخرى.</p></div>
        <div class="nw-opt-card-radio"></div>
      </div>
    </div>
    <div id="vf-subform" style="margin-top:14px">${formHtml}</div>`;

  panel.querySelectorAll(".nw-opt-card").forEach(c=>{
    c.addEventListener("click",()=>{blueOption=c.dataset.opt;renderBlueForm();refreshBtn();});
  });
  bindFormInputs();
  bindUpload();
}

function renderGreenForm(){
  const opts=["توثيق الاعتماد المهني","توثيق الرخص التنظيمية","توثيق الخبرات العملية","توثيق الدرجة العلمية والأكاديمية","توثيق الشهادات الاحترافية","توثيق كفو"];
  panel.innerHTML=`
    <h3 style="font-size:14px;font-weight:700;margin:0 0 10px">اختر العناصر التي ترغب في توثيقها</h3>
    <div class="nw-verif-checks">${opts.map(o=>`<span class="nw-verif-chip ${greenOptions.has(o)?"is-selected":""}" data-opt="${o}">${o}</span>`).join("")}</div>
    ${uploadSection()}
    <p style="font-size:12px;color:#999;margin-top:10px">أرفق صور الشهادات أو التراخيص أو المستندات الداعمة.</p>`;

  panel.querySelectorAll(".nw-verif-chip").forEach(c=>{
    c.addEventListener("click",()=>{
      const v=c.dataset.opt;
      greenOptions.has(v)?greenOptions.delete(v):greenOptions.add(v);
      renderGreenForm();refreshBtn();
    });
  });
  bindUpload();
}

function uploadSection(){
  const chips=uploadedFiles.map((f,i)=>`<span class="nw-verif-file-chip">${f.name.slice(0,25)}<span class="nw-verif-file-rm" data-i="${i}">&times;</span></span>`).join("");
  return`<div class="nw-verif-upload" id="vf-upload-area"><span class="material-icons-round">cloud_upload</span><div style="font-size:12px;color:#999;margin-top:4px">اضغط لإضافة مستند</div></div>
  <input type="file" id="vf-file" accept="image/*,.pdf" hidden multiple>
  <div class="nw-verif-files" id="vf-files">${chips}</div>`;
}

function bindUpload(){
  const area=document.getElementById("vf-upload-area");
  const inp=document.getElementById("vf-file");
  if(area&&inp){
    area.addEventListener("click",()=>inp.click());
    inp.addEventListener("change",()=>{
      Array.from(inp.files).forEach(f=>uploadedFiles.push(f));
      if(selectedType==="blue")renderBlueForm();else renderGreenForm();
      refreshBtn();
    });
  }
  document.querySelectorAll(".nw-verif-file-rm").forEach(el=>{
    el.addEventListener("click",()=>{uploadedFiles.splice(+el.dataset.i,1);if(selectedType==="blue")renderBlueForm();else renderGreenForm();refreshBtn();});
  });
}

function bindFormInputs(){
  document.querySelectorAll("#vf-subform input").forEach(inp=>{inp.addEventListener("input",refreshBtn);});
}

/* Render step 3 */
function renderStep3(){
  const isBlue=selectedType==="blue";
  const amount=isBlue?100:150;
  let details="";
  if(isBlue){
    const labels={person:"فرد",company:"كيان تجاري",other:"أوراق رسمية"};
    details=`<div class="nw-verif-summary-row"><span>النوع الفرعي</span><span>${labels[blueOption]||"-"}</span></div>`;
  }else{
    details=`<div class="nw-verif-summary-row"><span>العناصر المحددة</span><span>${greenOptions.size} عناصر</span></div>`;
  }
  panel.innerHTML=`
    <h3 style="font-size:16px;font-weight:700;margin:0 0 4px">مراجعة الطلب</h3>
    <p style="font-size:13px;color:#777;margin-bottom:16px">تحقق من تفاصيل طلب التوثيق قبل إتمام عملية الدفع.</p>
    <div class="nw-verif-summary">
      <div class="nw-verif-summary-row"><span>نوع التوثيق</span><span>${isBlue?"الشارة الزرقاء":"الشارة الخضراء"}</span></div>
      ${details}
      <div class="nw-verif-summary-row"><span>المستندات المرفقة</span><span>${uploadedFiles.length} ملف</span></div>
      <div class="nw-verif-total"><span>المبلغ</span><span>${amount} ر.س/سنة</span></div>
    </div>`;
}

/* Submit */
async function submit(){
  nextBtn.disabled=true;
  nextBtn.textContent="جارٍ الإرسال...";
  try{
    const requirements=[];
    if(selectedType==="blue"){
      requirements.push({badge_type:"blue",code:"B1"});
    }else{
      const codeMap={"توثيق الاعتماد المهني":"G1","توثيق الرخص التنظيمية":"G2","توثيق الخبرات العملية":"G3","توثيق الدرجة العلمية والأكاديمية":"G4","توثيق الشهادات الاحترافية":"G5","توثيق كفو":"G6"};
      greenOptions.forEach(o=>requirements.push({badge_type:"green",code:codeMap[o]||"G1"}));
    }
    const res=await api.post("/api/verification/requests/create/",{badge_type:selectedType,requirements});
    const rid=res.id;

    if(rid&&uploadedFiles.length){
      let docType=selectedType==="blue"?(blueOption==="company"?"cr":"national_id"):"certificate";
      for(const f of uploadedFiles){
        const fd=new FormData();
        fd.append("file",f);
        fd.append("doc_type",docType);
        await api.upload(`/api/verification/requests/${rid}/documents/`,fd);
      }
    }
    successEl.classList.add("is-visible");
  }catch{
    ui.toast("فشل إرسال الطلب","error");
  }
  nextBtn.disabled=false;
  nextBtn.textContent="تأكيد الطلب";
}

/* Nav */
nextBtn.addEventListener("click",()=>{
  if(step===2){submit();return;}
  step++;updateSteps();render();refreshBtn();
});
prevBtn.addEventListener("click",()=>{
  if(step>0){step--;updateSteps();render();refreshBtn();}
});
document.getElementById("verif-ok").addEventListener("click",()=>{
  successEl.classList.remove("is-visible");
  window.location.href=window.NAWAFETH_WEB_CONFIG?.urls?.providerDashboard||"/web/provider/dashboard/";
});

function render(){
  if(step===0)renderStep1();
  else if(step===1)renderStep2();
  else renderStep3();
}

updateSteps();render();refreshBtn();
})();
