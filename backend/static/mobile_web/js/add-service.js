(function(){
"use strict";
const api=window.NawafethApi;
if(!api)return;

const grid=document.getElementById("cats-grid");

async function loadCategories(){
  try{
    const data=await api.get("/api/providers/categories/");
    const cats=Array.isArray(data)?data:(data.results||[]);
    if(!cats.length){grid.innerHTML='<p class="nw-add-cat-loading">لا توجد تصنيفات</p>';return;}
    grid.innerHTML=cats.map(c=>
      `<a class="nw-add-cat-chip" href="/web/search/providers/?category=${c.id}">${c.name}</a>`
    ).join("");
  }catch{
    grid.innerHTML='<p class="nw-add-cat-loading">تعذر تحميل التصنيفات</p>';
  }
}

loadCategories();
})();
