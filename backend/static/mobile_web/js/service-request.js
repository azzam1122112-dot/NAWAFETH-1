(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const params=new URLSearchParams(window.location.search);
const preProvider=params.get("provider")||"";
const preService=params.get("service")||"";

const state={requestType:"normal",dispatchMode:"nearest",categories:[],imageFiles:[],docFiles:[]};

const dom={
  typePicker:document.getElementById("type-picker"),
  form:document.getElementById("svc-req-form"),
  category:document.getElementById("req-category"),
  subcategory:document.getElementById("req-subcategory"),
  city:document.getElementById("req-city"),
  title:document.getElementById("req-title"),
  details:document.getElementById("req-details"),
  deadline:document.getElementById("req-deadline"),
  titleCount:document.getElementById("title-count"),
  detailsCount:document.getElementById("details-count"),
  dispatchSection:document.getElementById("dispatch-section"),
  deadlineGroup:document.getElementById("deadline-group"),
  attImages:document.getElementById("att-images"),
  attFiles:document.getElementById("att-files"),
  attPreview:document.getElementById("att-preview"),
  success:document.getElementById("svc-success")
};

/* request type */
dom.typePicker.addEventListener("click",e=>{
  const chip=e.target.closest(".nw-svc-type-chip");
  if(!chip)return;
  state.requestType=chip.dataset.type;
  dom.typePicker.querySelectorAll(".nw-svc-type-chip").forEach(c=>c.classList.toggle("is-active",c===chip));
  // show/hide dispatch for urgent
  dom.dispatchSection.style.display=state.requestType==="urgent"?"block":"none";
  // show/hide deadline for competitive
  dom.deadlineGroup.style.display=state.requestType==="urgent"?"none":"block";
  // lock type if provider is set
  if(preProvider)state.requestType="normal";
});

if(preProvider){
  dom.typePicker.querySelectorAll(".nw-svc-type-chip").forEach(c=>{
    if(c.dataset.type!=="normal"){c.style.opacity=".4";c.style.pointerEvents="none";}
  });
}

/* dispatch mode */
document.querySelectorAll(".nw-dispatch-chip").forEach(chip=>{
  chip.addEventListener("click",()=>{
    state.dispatchMode=chip.dataset.mode;
    document.querySelectorAll(".nw-dispatch-chip").forEach(c=>c.classList.toggle("is-active",c===chip));
  });
});

/* char counts */
dom.title.addEventListener("input",()=>{dom.titleCount.textContent=dom.title.value.length;});
dom.details.addEventListener("input",()=>{dom.detailsCount.textContent=dom.details.value.length;});

/* categories */
async function loadCategories(){
  try{
    const data=await api.get("/api/providers/categories/");
    state.categories=Array.isArray(data)?data:(data.results||[]);
    state.categories.forEach(c=>{
      const opt=document.createElement("option");
      opt.value=c.id;opt.textContent=c.name;
      dom.category.appendChild(opt);
    });
  }catch{}
}

dom.category.addEventListener("change",()=>{
  dom.subcategory.innerHTML='<option value="">اختر التصنيف الفرعي</option>';
  const cat=state.categories.find(c=>String(c.id)===dom.category.value);
  if(!cat)return;
  const subs=cat.subcategories||cat.children||[];
  subs.forEach(s=>{
    const opt=document.createElement("option");
    opt.value=s.id;opt.textContent=s.name;
    dom.subcategory.appendChild(opt);
  });
});

/* attachments */
dom.attImages.addEventListener("change",()=>{
  for(const f of dom.attImages.files)state.imageFiles.push(f);
  renderAttachments();
});
dom.attFiles.addEventListener("change",()=>{
  for(const f of dom.attFiles.files)state.docFiles.push(f);
  renderAttachments();
});

function renderAttachments(){
  let html="";
  state.imageFiles.forEach((f,i)=>{
    const url=URL.createObjectURL(f);
    html+=`<div class="nw-attach-item"><img src="${url}" alt=""><button class="remove" data-type="image" data-idx="${i}">×</button></div>`;
  });
  state.docFiles.forEach((f,i)=>{
    html+=`<div class="nw-attach-file"><span class="material-icons-round">description</span>${f.name}<button class="remove" data-type="file" data-idx="${i}" style="margin-right:auto;background:none;border:none;color:#E53935;cursor:pointer">×</button></div>`;
  });
  dom.attPreview.innerHTML=html;
  dom.attPreview.querySelectorAll(".remove").forEach(btn=>{
    btn.addEventListener("click",()=>{
      if(btn.dataset.type==="image")state.imageFiles.splice(Number(btn.dataset.idx),1);
      else state.docFiles.splice(Number(btn.dataset.idx),1);
      renderAttachments();
    });
  });
}

/* submit */
dom.form.addEventListener("submit",async e=>{
  e.preventDefault();
  const title=dom.title.value.trim();
  const desc=dom.details.value.trim();
  const sub=dom.subcategory.value;
  if(!title||!desc||!sub){ui.toast("أكمل الحقول المطلوبة","warning");return;}

  const fd=new FormData();
  fd.append("title",title);
  fd.append("description",desc);
  fd.append("request_type",state.requestType);
  fd.append("subcategory",sub);
  if(dom.city.value)fd.append("city",dom.city.value);
  if(preProvider)fd.append("provider",preProvider);
  if(dom.deadline.value&&state.requestType!=="urgent")fd.append("quote_deadline",dom.deadline.value);
  if(state.requestType==="urgent")fd.append("dispatch_mode",state.dispatchMode);
  state.imageFiles.forEach(f=>fd.append("images",f));
  state.docFiles.forEach(f=>fd.append("files",f));

  try{
    const submitBtn=dom.form.querySelector('button[type=submit]');
    submitBtn.disabled=true;submitBtn.textContent="جارٍ الإرسال...";
    await api.postForm("/api/marketplace/requests/create/",fd);
    dom.form.style.display="none";
    dom.success.style.display="block";
    document.querySelector(".nw-svc-type-picker").style.display="none";
  }catch(err){
    ui.toast("فشل إرسال الطلب","error");
    const submitBtn=dom.form.querySelector('button[type=submit]');
    submitBtn.disabled=false;submitBtn.textContent="إرسال الطلب";
  }
});

loadCategories();
})();
