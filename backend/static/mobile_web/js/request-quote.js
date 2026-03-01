/* ── Request Quote JS ── */
(function(){
  const API = window.NawafethApi;
  const UI  = window.NawafethUi;

  const catSelect = document.getElementById('rq-category');
  const subSelect = document.getElementById('rq-subcategory');
  const form      = document.getElementById('rq-form');
  const loading   = document.getElementById('rq-loading');
  const successEl = document.getElementById('rq-success');
  const detailsTa = document.getElementById('rq-details');
  const countEl   = document.getElementById('rq-details-count');

  let categories = [];
  let files = [];

  // Load categories
  async function init(){
    try{
      const res = await API.get('/api/content/categories/');
      if(res.ok){
        categories = await res.json();
        categories.forEach(c=>{
          catSelect.insertAdjacentHTML('beforeend',`<option value="${c.id}">${c.name}</option>`);
        });
      }
    }catch(e){}
    loading.style.display='none'; form.style.display='';
  }

  catSelect.addEventListener('change',()=>{
    const cat = categories.find(c=> c.id == catSelect.value);
    subSelect.innerHTML = '<option value="">اختر الفرعي</option>';
    if(cat && cat.subcategories){
      cat.subcategories.forEach(s=>{
        subSelect.insertAdjacentHTML('beforeend',`<option value="${s.id}">${s.name}</option>`);
      });
    }
  });

  // Counter
  detailsTa.addEventListener('input',()=>{
    countEl.textContent = detailsTa.value.length;
  });

  // File uploads
  function addFiles(fileList){
    Array.from(fileList).forEach(f=> files.push(f));
    renderPreviews();
  }
  document.getElementById('rq-file-img').addEventListener('change', e=> addFiles(e.target.files));
  document.getElementById('rq-file-doc').addEventListener('change', e=> addFiles(e.target.files));

  function renderPreviews(){
    const box = document.getElementById('rq-previews');
    box.innerHTML = files.map((f,i)=>{
      const isImg = f.type.startsWith('image/');
      const thumb = isImg ? `<img src="${URL.createObjectURL(f)}">` : `<span class="material-icons-round" style="font-size:20px;color:#aaa;line-height:50px;text-align:center;width:100%">insert_drive_file</span>`;
      return `<div class="nw-attach-thumb">${thumb}<button class="nw-att-remove" data-idx="${i}" type="button">&times;</button></div>`;
    }).join('');
    box.querySelectorAll('.nw-att-remove').forEach(btn=>{
      btn.addEventListener('click',()=>{ files.splice(parseInt(btn.dataset.idx),1); renderPreviews(); });
    });
  }

  // Submit
  form.addEventListener('submit', async(e)=>{
    e.preventDefault();
    const sub = document.getElementById('rq-subcategory').value;
    const title = document.getElementById('rq-title').value.trim();
    const details = detailsTa.value.trim();
    if(!sub){ UI.toast('اختر التصنيف الفرعي','error'); return; }
    if(!title){ UI.toast('أدخل عنوان الطلب','error'); return; }
    if(!details){ UI.toast('أدخل تفاصيل الطلب','error'); return; }

    const fd = new FormData();
    fd.append('title', title);
    fd.append('description', details);
    fd.append('request_type', 'competitive');
    fd.append('subcategory', sub);
    const deadline = document.getElementById('rq-deadline').value;
    if(deadline) fd.append('quote_deadline', deadline);
    files.forEach(f=> fd.append('files', f));

    const btn = document.getElementById('rq-submit');
    btn.disabled = true;
    btn.innerHTML = '<div class="nw-spinner" style="width:16px;height:16px;border-width:2px"></div>';

    try{
      const res = await API.postForm('/api/marketplace/requests/', fd);
      if(res.ok){
        form.style.display='none'; successEl.style.display='';
      }else{
        const d = await res.json().catch(()=>({}));
        UI.toast(d.detail||d.error||'فشل إرسال الطلب','error');
      }
    }catch(e){
      UI.toast('خطأ في الاتصال','error');
    }
    btn.disabled=false;
    btn.innerHTML='<span class="material-icons-round">send</span> تقديم الطلب';
  });

  init();
})();
