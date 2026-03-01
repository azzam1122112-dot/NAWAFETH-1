(function(){
"use strict";
const api=window.NawafethApi;
if(!api)return;

const params=new URLSearchParams(window.location.search);
const initCat=params.get("category")||"";

const state={query:"",categoryId:initCat,sort:"",providers:[],timer:null};

const dom={
  search:document.getElementById("sp-search"),
  cats:document.getElementById("sp-cats"),
  count:document.getElementById("sp-count"),
  grid:document.getElementById("sp-grid"),
  sortBtn:document.getElementById("sp-sort-btn"),
  sortMenu:document.getElementById("sp-sort-menu")
};

function safe(v,f){return(v===undefined||v===null||v==="")?f||"-":String(v);}

/* categories */
async function loadCategories(){
  try{
    const data=await api.get("/api/providers/categories/");
    const cats=Array.isArray(data)?data:(data.results||[]);
    let html='<button class="nw-sp-cat '+(state.categoryId?'':'is-active')+'" data-id="">الكل</button>';
    cats.forEach(c=>{
      html+=`<button class="nw-sp-cat ${String(c.id)===state.categoryId?'is-active':''}" data-id="${c.id}">${c.name}</button>`;
    });
    dom.cats.innerHTML=html;
    dom.cats.addEventListener("click",e=>{
      const chip=e.target.closest(".nw-sp-cat");
      if(!chip)return;
      state.categoryId=chip.dataset.id;
      dom.cats.querySelectorAll(".nw-sp-cat").forEach(c=>c.classList.toggle("is-active",c===chip));
      loadProviders();
    });
  }catch{}
}

/* providers */
async function loadProviders(){
  dom.grid.innerHTML='<div class="nw-sp-loading">جارٍ البحث...</div>';
  try{
    let url="/api/providers/list/?page_size=30";
    if(state.query)url+="&q="+encodeURIComponent(state.query);
    if(state.categoryId)url+="&category_id="+state.categoryId;
    if(state.sort)url+="&ordering="+state.sort;
    const data=await api.get(url);
    state.providers=Array.isArray(data)?data:(data.results||[]);
    dom.count.textContent=state.providers.length+" نتيجة";
    renderProviders();
  }catch{
    dom.grid.innerHTML='<div class="nw-sp-empty"><span class="material-icons-round">error_outline</span><p>تعذر البحث</p></div>';
  }
}

function renderProviders(){
  if(!state.providers.length){
    dom.grid.innerHTML='<div class="nw-sp-empty"><span class="material-icons-round">search_off</span><p>لا توجد نتائج</p></div>';
    return;
  }
  dom.grid.innerHTML=state.providers.map(p=>{
    const name=p.display_name||p.displayName||"مزود";
    const img=p.profile_image||p.profileImage||"";
    const cover=p.cover_image||p.coverImage||"";
    const verified=p.is_verified||p.isVerified||p.is_verified_blue||p.isVerifiedBlue;
    return`<div class="nw-sp-card" data-id="${p.id}">
      <div class="nw-sp-card-cover">${cover?'<img src="'+cover+'" alt="">':''}</div>
      <div class="nw-sp-card-avatar">${img?'<img src="'+img+'" alt="">':name.charAt(0)}</div>
      ${verified?'<span class="nw-sp-card-verified material-icons-round">verified</span>':''}
      <div class="nw-sp-card-body">
        <div class="nw-sp-card-name">${name}</div>
        <div class="nw-sp-card-city">${safe(p.city)}</div>
        <div class="nw-sp-card-stats">
          <span><span class="material-icons-round">star</span>${Number(p.rating_avg||p.ratingAvg||0).toFixed(1)}</span>
          <span><span class="material-icons-round">people</span>${p.followers_count||p.followersCount||0}</span>
          <span><span class="material-icons-round">check_circle</span>${p.completed_requests||p.completedRequests||0}</span>
        </div>
      </div>
    </div>`;
  }).join("");

  dom.grid.querySelectorAll(".nw-sp-card").forEach(c=>{
    c.addEventListener("click",()=>location.href="/web/providers/"+c.dataset.id+"/");
  });
}

/* search debounce */
dom.search.addEventListener("input",()=>{
  clearTimeout(state.timer);
  state.timer=setTimeout(()=>{state.query=dom.search.value.trim();loadProviders();},400);
});

/* sort */
dom.sortBtn.addEventListener("click",()=>dom.sortMenu.classList.toggle("is-open"));
dom.sortMenu.addEventListener("click",e=>{
  const opt=e.target.closest(".nw-sp-sort-opt");
  if(!opt)return;
  state.sort=opt.dataset.sort;
  dom.sortMenu.querySelectorAll(".nw-sp-sort-opt").forEach(o=>o.classList.toggle("is-active",o===opt));
  dom.sortMenu.classList.remove("is-open");
  loadProviders();
});
document.addEventListener("click",e=>{
  if(!e.target.closest(".nw-sp-sortbar"))dom.sortMenu.classList.remove("is-open");
});

loadCategories();
loadProviders();
})();
