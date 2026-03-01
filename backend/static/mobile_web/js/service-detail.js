(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const container=document.getElementById("svc-content");
const serviceId=window.location.pathname.split("/").filter(Boolean).pop();

let currentSlide=0;
let images=[];
let isLiked=false;

function safe(v,f){return(v===undefined||v===null||v==="")?f||"-":String(v);}
function fmtMoney(v){if(v===undefined||v===null||v==="")return"تواصل للسعر";const n=Number(v);return Number.isFinite(n)?n.toFixed(2)+" ر.س":String(v);}

function priceDisplay(svc){
  const unit=svc.price_unit||svc.priceUnit||"fixed";
  const from=svc.price_from||svc.priceFrom;
  const to=svc.price_to||svc.priceTo;
  if(unit==="negotiable")return"قابل للتفاوض";
  if(from&&to)return fmtMoney(from)+" - "+fmtMoney(to);
  if(from)return"يبدأ من "+fmtMoney(from);
  return fmtMoney(from);
}

async function load(){
  try{
    const svc=await api.get("/api/providers/services/"+serviceId+"/");
    render(svc);
  }catch{
    container.innerHTML='<div class="nw-svc-empty"><span class="material-icons-round">error_outline</span><p>تعذر تحميل الخدمة</p></div>';
  }
}

function render(svc){
  const provider=svc.provider||{};
  images=svc.images||svc.portfolio_images||[];
  if(!images.length&&svc.image)images=[svc.image];

  let h="";

  // provider header
  const pName=provider.display_name||provider.displayName||safe(svc.provider_name);
  const pImg=provider.profile_image||provider.profileImage||"";
  const pId=provider.id||svc.provider_id||svc.providerId||"";
  h+=`<div class="nw-svc-provider">
    <div class="nw-svc-provider-avatar">${pImg?'<img src="'+pImg+'" alt="">':pName.charAt(0)}</div>
    <div class="nw-svc-provider-info">
      <div class="nw-svc-provider-name">${pName}</div>
      <div class="nw-svc-provider-cat">${safe(svc.category_name||svc.categoryName)}</div>
    </div>
    ${pId?'<button class="nw-svc-provider-link" onclick="location.href=\'/web/providers/'+pId+'/\'">عرض الملف</button>':""}
  </div>`;

  // image slider
  if(images.length){
    h+=`<div class="nw-svc-card"><div class="nw-svc-slider" id="svc-slider">
      <img id="svc-slide-img" src="${images[0].url||images[0]}" alt="">
      <button class="nw-svc-slider-nav prev" id="svc-prev"><span class="material-icons-round">chevron_right</span></button>
      <button class="nw-svc-slider-nav next" id="svc-next"><span class="material-icons-round">chevron_left</span></button>
    </div>`;
    if(images.length>1){
      h+=`<div class="nw-svc-slider-dots" id="svc-dots">`;
      images.forEach((_,i)=>h+=`<button class="nw-svc-slider-dot ${i===0?"is-active":""}" data-idx="${i}"></button>`);
      h+=`</div>`;
      h+=`<div class="nw-svc-thumbs">`;
      images.forEach((img,i)=>h+=`<div class="nw-svc-thumb ${i===0?"is-active":""}" data-idx="${i}"><img src="${img.url||img}" alt=""></div>`);
      h+=`</div>`;
    }
    h+=`</div>`;
  }

  // title + price + meta
  h+=`<div class="nw-svc-card"><div class="nw-svc-card-header">
    <h1>${safe(svc.title)}</h1>
    <div class="nw-svc-price">${priceDisplay(svc)}</div>
    <div class="nw-svc-meta">
      <span><span class="material-icons-round">category</span>${safe(svc.subcategory_name||svc.subcategoryName)}</span>
      <span><span class="material-icons-round">favorite</span><span id="svc-likes">${svc.likes_count||svc.likesCount||0}</span></span>
      ${svc.is_active!==false?'<span style="color:#2E7D32"><span class="material-icons-round">check_circle</span>نشطة</span>':'<span style="color:#9E9E9E"><span class="material-icons-round">pause_circle</span>متوقفة</span>'}
    </div>
  </div></div>`;

  // description
  const desc=svc.description||"";
  h+=`<div class="nw-svc-desc"><h3>وصف الخدمة</h3><p id="svc-desc-text">${safe(desc)}</p>
    ${desc.length>200?'<button class="nw-svc-toggle" id="svc-toggle-desc">عرض المزيد</button>':""}
  </div>`;

  // actions
  h+=`<div class="nw-svc-actions">
    <a class="nw-btn" href="/web/services/request/?provider=${pId}&service=${serviceId}">طلب الخدمة</a>
    <button class="nw-svc-like-btn" id="svc-like"><span class="material-icons-round">favorite_border</span>إعجاب</button>
  </div>`;

  // comments section
  h+=`<div class="nw-svc-comments"><h3>التعليقات</h3>
    <div id="svc-comments-list"></div>
    <div class="nw-svc-add-comment">
      <input id="svc-comment-input" placeholder="أضف تعليقاً...">
      <button id="svc-comment-send">إرسال</button>
    </div>
  </div>`;

  container.innerHTML=h;
  bindSlider();
  bindActions(svc);
  loadComments();
}

function bindSlider(){
  if(!images.length)return;
  const img=document.getElementById("svc-slide-img");
  const prev=document.getElementById("svc-prev");
  const next=document.getElementById("svc-next");
  const dots=document.getElementById("svc-dots");
  const thumbs=container.querySelectorAll(".nw-svc-thumb");

  function goTo(i){
    currentSlide=(i+images.length)%images.length;
    img.src=images[currentSlide].url||images[currentSlide];
    if(dots)dots.querySelectorAll(".nw-svc-slider-dot").forEach((d,j)=>d.classList.toggle("is-active",j===currentSlide));
    thumbs.forEach((t,j)=>t.classList.toggle("is-active",j===currentSlide));
  }
  if(prev)prev.addEventListener("click",()=>goTo(currentSlide-1));
  if(next)next.addEventListener("click",()=>goTo(currentSlide+1));
  if(dots)dots.addEventListener("click",e=>{const dot=e.target.closest(".nw-svc-slider-dot");if(dot)goTo(Number(dot.dataset.idx));});
  thumbs.forEach(t=>t.addEventListener("click",()=>goTo(Number(t.dataset.idx))));
}

function bindActions(svc){
  const likeBtn=document.getElementById("svc-like");
  if(likeBtn)likeBtn.addEventListener("click",async()=>{
    try{
      isLiked=!isLiked;
      const endpoint=isLiked?"/api/providers/services/"+serviceId+"/like/":"/api/providers/services/"+serviceId+"/unlike/";
      await api.post(endpoint);
      likeBtn.classList.toggle("is-liked",isLiked);
      likeBtn.querySelector(".material-icons-round").textContent=isLiked?"favorite":"favorite_border";
      const likesEl=document.getElementById("svc-likes");
      if(likesEl){let c=Number(likesEl.textContent)||0;likesEl.textContent=isLiked?c+1:Math.max(0,c-1);}
    }catch{/* ignore */}
  });

  const toggle=document.getElementById("svc-toggle-desc");
  const descText=document.getElementById("svc-desc-text");
  if(toggle&&descText){
    let expanded=false;
    const fullText=descText.textContent;
    descText.textContent=fullText.substring(0,200)+"...";
    toggle.addEventListener("click",()=>{
      expanded=!expanded;
      descText.textContent=expanded?fullText:fullText.substring(0,200)+"...";
      toggle.textContent=expanded?"عرض أقل":"عرض المزيد";
    });
  }
}

async function loadComments(){
  const list=document.getElementById("svc-comments-list");
  try{
    const data=await api.get("/api/providers/services/"+serviceId+"/comments/");
    const comments=Array.isArray(data)?data:(data.results||[]);
    if(!comments.length){list.innerHTML='<p style="color:var(--nw-text-secondary);font-size:.82rem">لا توجد تعليقات بعد</p>';return;}
    list.innerHTML=comments.map(c=>`
      <div class="nw-svc-comment">
        <div class="nw-svc-comment-avatar">${(c.user_name||c.userName||"م").charAt(0)}</div>
        <div class="nw-svc-comment-body">
          <div class="nw-svc-comment-name">${c.user_name||c.userName||"مستخدم"}</div>
          <div class="nw-svc-comment-text">${c.text||c.comment||""}</div>
          <div class="nw-svc-comment-date">${c.created_at?new Date(c.created_at).toLocaleDateString("ar-SA"):""}</div>
          ${c.reply?'<div class="nw-svc-comment-reply">'+c.reply+'</div>':""}
        </div>
      </div>`).join("");
  }catch{
    list.innerHTML='<p style="color:var(--nw-text-secondary);font-size:.82rem">لا توجد تعليقات</p>';
  }

  const sendBtn=document.getElementById("svc-comment-send");
  const input=document.getElementById("svc-comment-input");
  if(sendBtn&&input)sendBtn.addEventListener("click",async()=>{
    const text=input.value.trim();
    if(!text)return;
    try{
      await api.post("/api/providers/services/"+serviceId+"/comments/",{text});
      input.value="";
      ui.toast("تم إضافة التعليق","success");
      loadComments();
    }catch{ui.toast("فشل إضافة التعليق","error");}
  });
}

load();
})();
