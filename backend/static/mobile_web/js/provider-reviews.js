(function(){
"use strict";
const api=window.NawafethApi,ui=window.NawafethUi;
if(!api||!ui)return;

const dom={
  avg:document.getElementById("rev-avg"),
  stars:document.getElementById("rev-stars"),
  count:document.getElementById("rev-count"),
  bars:document.getElementById("rev-bars"),
  list:document.getElementById("rev-list"),
  sort:document.getElementById("rev-sort")
};

let providerId=null;
let reviews=[];

const criteria=[
  {key:"response_speed",label:"سرعة الاستجابة"},
  {key:"cost_value",label:"التكلفة مقابل الخدمة"},
  {key:"quality",label:"جودة الخدمة"},
  {key:"credibility",label:"المصداقية"},
  {key:"on_time",label:"وقت الإنجاز"}
];

function safe(v,f){return(v===undefined||v===null||v==="")?f||"-":String(v);}
function fmtDate(d){if(!d)return"";try{return new Date(d).toLocaleDateString("ar-SA",{year:"numeric",month:"short",day:"numeric"})}catch{return d;}}

async function init(){
  try{
    const profile=await api.get("/api/accounts/me/");
    providerId=profile.provider_profile_id||profile.providerProfileId;
    if(!providerId){
      dom.list.innerHTML='<div class="nw-rev-empty"><span class="material-icons-round">info</span><p>يجب أن يكون لديك حساب مزود خدمة</p></div>';
      return;
    }
    loadRating();
    loadReviews();
  }catch{
    dom.list.innerHTML='<div class="nw-rev-empty"><span class="material-icons-round">lock</span><p>سجل دخولك أولاً</p></div>';
  }
}

async function loadRating(){
  try{
    const r=await api.get("/api/reviews/provider/"+providerId+"/rating/");
    const avg=Number(r.rating_avg||r.ratingAvg||0);
    dom.avg.textContent=avg.toFixed(1);
    dom.stars.textContent="★".repeat(Math.round(avg))+"☆".repeat(5-Math.round(avg));
    dom.count.textContent=(r.rating_count||r.ratingCount||0)+" تقييم";
    // criteria bars
    dom.bars.innerHTML=criteria.map(c=>{
      const val=Number(r[c.key+"_avg"]||0);
      const pct=Math.round(val/5*100);
      return`<div class="nw-rev-bar-row">
        <span class="nw-rev-bar-label">${c.label}</span>
        <div class="nw-rev-bar"><div class="nw-rev-bar-fill" style="width:${pct}%"></div></div>
        <span class="nw-rev-bar-val">${val.toFixed(1)}</span>
      </div>`;
    }).join("");
  }catch{}
}

async function loadReviews(){
  dom.list.innerHTML='<div class="nw-rev-loading">جارٍ التحميل...</div>';
  try{
    const data=await api.get("/api/reviews/provider/"+providerId+"/");
    reviews=Array.isArray(data)?data:(data.results||[]);
    sortAndRender();
  }catch{
    dom.list.innerHTML='<div class="nw-rev-empty"><span class="material-icons-round">error_outline</span><p>تعذر تحميل المراجعات</p></div>';
  }
}

function sortAndRender(){
  const sorted=[...reviews];
  const s=dom.sort.value;
  if(s==="highest")sorted.sort((a,b)=>(b.rating||0)-(a.rating||0));
  else if(s==="lowest")sorted.sort((a,b)=>(a.rating||0)-(b.rating||0));
  else sorted.sort((a,b)=>new Date(b.created_at||0)-new Date(a.created_at||0));
  renderReviews(sorted);
}

function renderReviews(list){
  if(!list.length){
    dom.list.innerHTML='<div class="nw-rev-empty"><span class="material-icons-round">rate_review</span><p>لا توجد مراجعات بعد</p></div>';
    return;
  }
  dom.list.innerHTML=list.map(r=>{
    const rating=Math.round(r.rating||0);
    const name=r.client_name||r.clientName||"عميل";
    let html=`<div class="nw-rev-card" data-id="${r.id}">
      <div class="nw-rev-card-top">
        <div class="nw-rev-card-user">
          <div class="nw-rev-card-avatar">${name.charAt(0)}</div>
          <div><div class="nw-rev-card-name">${name}</div><div class="nw-rev-card-date">${fmtDate(r.created_at||r.createdAt)}</div></div>
        </div>
        <div class="nw-rev-card-stars">${"★".repeat(rating)}${"☆".repeat(5-rating)}</div>
      </div>`;
    if(r.comment)html+=`<div class="nw-rev-card-comment">${r.comment}</div>`;
    // existing reply
    if(r.provider_reply||r.providerReply){
      const edited=r.provider_reply_is_edited||r.providerReplyIsEdited;
      html+=`<div class="nw-rev-reply">
        <div class="nw-rev-reply-label"><span class="material-icons-round" style="font-size:14px">reply</span>ردك${edited?" (معدل)":""}</div>
        <div class="nw-rev-reply-text">${r.provider_reply||r.providerReply}</div>
      </div>`;
      html+=`<button class="nw-rev-reply-toggle" data-id="${r.id}" data-action="edit">تعديل الرد</button>`;
    }else{
      html+=`<button class="nw-rev-reply-toggle" data-id="${r.id}" data-action="add">إضافة رد</button>`;
    }
    // reply form (hidden)
    html+=`<div class="nw-rev-reply-form" id="reply-form-${r.id}" style="display:none">
      <textarea id="reply-text-${r.id}" placeholder="اكتب ردك...">${r.provider_reply||r.providerReply||""}</textarea>
      <button data-id="${r.id}">إرسال</button>
    </div>`;
    html+=`</div>`;
    return html;
  }).join("");

  // bind reply toggles
  dom.list.querySelectorAll(".nw-rev-reply-toggle").forEach(btn=>{
    btn.addEventListener("click",()=>{
      const form=document.getElementById("reply-form-"+btn.dataset.id);
      form.style.display=form.style.display==="none"?"flex":"none";
    });
  });

  // bind reply submits
  dom.list.querySelectorAll(".nw-rev-reply-form button").forEach(btn=>{
    btn.addEventListener("click",async()=>{
      const id=btn.dataset.id;
      const text=document.getElementById("reply-text-"+id).value.trim();
      if(!text){ui.toast("اكتب ردك","warning");return;}
      try{
        await api.post("/api/reviews/"+id+"/reply/",{text});
        ui.toast("تم إرسال الرد","success");
        loadReviews();
      }catch{ui.toast("فشل إرسال الرد","error");}
    });
  });
}

dom.sort.addEventListener("change",sortAndRender);

init();
})();
