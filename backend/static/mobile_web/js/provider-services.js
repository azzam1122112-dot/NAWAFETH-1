(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const dom={
  list:document.getElementById("svc-list"),
  modal:document.getElementById("svc-modal"),
  form:document.getElementById("svc-form"),
  modalTitle:document.getElementById("modal-title"),
  addBtn:document.getElementById("add-svc-btn"),
  cancelBtn:document.getElementById("modal-cancel"),
  category:document.getElementById("m-category"),
  subcategory:document.getElementById("m-subcategory"),
  title:document.getElementById("m-title"),
  desc:document.getElementById("m-desc"),
  priceUnit:document.getElementById("m-price-unit"),
  priceFrom:document.getElementById("m-price-from"),
  priceTo:document.getElementById("m-price-to"),
  priceRange:document.getElementById("price-range"),
  active:document.getElementById("m-active")
};

let categories=[];
let services=[];
let editingId=null;

function safe(v,f){return(v===undefined||v===null||v==="")?f||"-":String(v);}
function fmtPrice(svc){
  const u=svc.price_unit||svc.priceUnit||"fixed";
  const f=svc.price_from||svc.priceFrom;
  const t=svc.price_to||svc.priceTo;
  if(u==="negotiable")return"قابل للتفاوض";
  const labels={fixed:"ثابت",starting_from:"يبدأ من",hour:"بالساعة",day:"باليوم"};
  let s=labels[u]||u;
  if(f)s+=" "+Number(f).toFixed(2);
  if(t)s+=" - "+Number(t).toFixed(2);
  return s+" ر.س";
}

async function loadCategories(){
  try{
    const data=await api.get("/api/providers/services/categories/");
    categories=Array.isArray(data)?data:(data.results||[]);
    dom.category.innerHTML='<option value="">اختر</option>';
    categories.forEach(c=>{
      dom.category.innerHTML+=`<option value="${c.id}">${c.name}</option>`;
    });
  }catch{}
}

dom.category.addEventListener("change",()=>{
  dom.subcategory.innerHTML='<option value="">اختر</option>';
  const cat=categories.find(c=>String(c.id)===dom.category.value);
  if(!cat)return;
  (cat.subcategories||cat.children||[]).forEach(s=>{
    dom.subcategory.innerHTML+=`<option value="${s.id}">${s.name}</option>`;
  });
});

dom.priceUnit.addEventListener("change",()=>{
  dom.priceRange.style.display=dom.priceUnit.value==="negotiable"?"none":"flex";
});

async function loadServices(){
  dom.list.innerHTML='<div class="nw-psvc-loading">جارٍ التحميل...</div>';
  try{
    const data=await api.get("/api/providers/services/my/");
    services=Array.isArray(data)?data:(data.results||[]);
    renderServices();
  }catch{
    dom.list.innerHTML='<div class="nw-psvc-empty"><span class="material-icons-round">error_outline</span><p>تعذر تحميل الخدمات</p></div>';
  }
}

function renderServices(){
  if(!services.length){
    dom.list.innerHTML='<div class="nw-psvc-empty"><span class="material-icons-round">design_services</span><p>لا توجد خدمات بعد</p><p style="font-size:.82rem">ابدأ بإضافة خدمتك الأولى</p></div>';
    return;
  }
  dom.list.innerHTML=services.map(s=>{
    const isActive=s.is_active!==false;
    return`<div class="nw-psvc-card" data-id="${s.id}">
      <div class="nw-psvc-card-top">
        <div>
          <h3>${safe(s.title)}</h3>
          <div class="nw-psvc-card-cat">${safe(s.category_name||s.categoryName)} > ${safe(s.subcategory_name||s.subcategoryName)}</div>
        </div>
        <div class="nw-psvc-actions">
          <button class="nw-psvc-btn edit" data-id="${s.id}" title="تعديل"><span class="material-icons-round">edit</span></button>
          <button class="nw-psvc-btn delete" data-id="${s.id}" title="حذف"><span class="material-icons-round">delete</span></button>
        </div>
      </div>
      ${s.description?'<div class="nw-psvc-card-desc">'+s.description+'</div>':""}
      <div class="nw-psvc-card-bottom">
        <span class="nw-psvc-price">${fmtPrice(s)}</span>
        <span class="nw-psvc-badge ${isActive?"active":"inactive"}">${isActive?"نشطة":"متوقفة"}</span>
      </div>
    </div>`;
  }).join("");

  // bind edit/delete
  dom.list.querySelectorAll(".nw-psvc-btn.edit").forEach(btn=>{
    btn.addEventListener("click",()=>openEdit(Number(btn.dataset.id)));
  });
  dom.list.querySelectorAll(".nw-psvc-btn.delete").forEach(btn=>{
    btn.addEventListener("click",()=>deleteService(Number(btn.dataset.id)));
  });
}

function openModal(svc){
  editingId=svc?svc.id:null;
  dom.modalTitle.textContent=svc?"تعديل الخدمة":"إضافة خدمة";
  dom.title.value=svc?svc.title||"":"";
  dom.desc.value=svc?svc.description||"":"";
  dom.priceUnit.value=svc?svc.price_unit||svc.priceUnit||"fixed":"fixed";
  dom.priceFrom.value=svc?svc.price_from||svc.priceFrom||"":"";
  dom.priceTo.value=svc?svc.price_to||svc.priceTo||"":"";
  dom.active.checked=svc?svc.is_active!==false:true;
  dom.priceRange.style.display=dom.priceUnit.value==="negotiable"?"none":"flex";
  // set category/subcategory
  if(svc){
    dom.category.value=svc.category_id||svc.categoryId||"";
    dom.category.dispatchEvent(new Event("change"));
    setTimeout(()=>{dom.subcategory.value=svc.subcategory_id||svc.subcategoryId||"";},100);
  }else{
    dom.category.value="";
    dom.subcategory.innerHTML='<option value="">اختر</option>';
  }
  dom.modal.classList.add("is-open");
}

function closeModal(){
  dom.modal.classList.remove("is-open");
  editingId=null;
}

function openEdit(id){
  const svc=services.find(s=>s.id===id);
  if(svc)openModal(svc);
}

async function deleteService(id){
  if(!confirm("هل تريد حذف هذه الخدمة؟"))return;
  try{
    await api.delete("/api/providers/services/"+id+"/");
    ui.toast("تم الحذف","success");
    loadServices();
  }catch{ui.toast("فشل الحذف","error");}
}

dom.addBtn.addEventListener("click",()=>openModal(null));
dom.cancelBtn.addEventListener("click",closeModal);
dom.modal.addEventListener("click",e=>{if(e.target===dom.modal)closeModal();});

dom.form.addEventListener("submit",async e=>{
  e.preventDefault();
  const payload={
    title:dom.title.value.trim(),
    description:dom.desc.value.trim(),
    subcategory_id:dom.subcategory.value,
    price_unit:dom.priceUnit.value,
    is_active:dom.active.checked
  };
  if(dom.priceUnit.value!=="negotiable"){
    if(dom.priceFrom.value)payload.price_from=dom.priceFrom.value;
    if(dom.priceTo.value)payload.price_to=dom.priceTo.value;
  }
  if(!payload.title||!payload.subcategory_id){ui.toast("أكمل الحقول المطلوبة","warning");return;}

  try{
    if(editingId){
      await api.patch("/api/providers/services/"+editingId+"/",payload);
      ui.toast("تم التحديث","success");
    }else{
      await api.post("/api/providers/services/",payload);
      ui.toast("تمت الإضافة","success");
    }
    closeModal();
    loadServices();
  }catch{ui.toast("فشل الحفظ","error");}
});

loadCategories();
loadServices();
})();
