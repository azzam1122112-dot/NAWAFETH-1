/* ── Urgent Request JS ── */
(function(){
  const API = window.NawafethApi;
  const UI  = window.NawafethUi;

  const catSelect = document.getElementById('ur-category');
  const subSelect = document.getElementById('ur-subcategory');
  const form      = document.getElementById('ur-form');
  const loading   = document.getElementById('ur-loading');
  const successEl = document.getElementById('ur-success');
  const descTa    = document.getElementById('ur-desc');
  const countEl   = document.getElementById('ur-desc-count');
  const dispatchInput = document.getElementById('ur-dispatch');

  let categories = [];
  let files = [];

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

  // Radio chips
  document.querySelectorAll('.nw-radio-chip').forEach(chip=>{
    chip.addEventListener('click',()=>{
      document.querySelectorAll('.nw-radio-chip').forEach(c=>{
        c.classList.remove('is-active');
        c.querySelector('.material-icons-round').textContent='radio_button_unchecked';
      });
      chip.classList.add('is-active');
      chip.querySelector('.material-icons-round').textContent='radio_button_checked';
      dispatchInput.value = chip.dataset.val;
    });
  });

  descTa.addEventListener('input',()=>{ countEl.textContent = descTa.value.length; });

  // File uploads
  function addFiles(fl){ Array.from(fl).forEach(f=> files.push(f)); renderPreviews(); }
  document.getElementById('ur-file-img').addEventListener('change', e=> addFiles(e.target.files));
  document.getElementById('ur-file-doc').addEventListener('change', e=> addFiles(e.target.files));

  function renderPreviews(){
    const box = document.getElementById('ur-previews');
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
    const sub = subSelect.value;
    const desc = descTa.value.trim();
    if(!sub){ UI.toast('اختر التصنيف الفرعي','error'); return; }
    if(!desc){ UI.toast('أدخل وصفًا للخدمة','error'); return; }

    const cat = categories.find(c=> c.id == catSelect.value);
    const fd = new FormData();
    fd.append('title', 'طلب عاجل - '+(cat?cat.name:''));
    fd.append('description', desc);
    fd.append('request_type', 'urgent');
    fd.append('subcategory', sub);
    fd.append('dispatch_mode', dispatchInput.value);
    files.forEach(f=> fd.append('images', f));

    const btn = document.getElementById('ur-submit');
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
    btn.innerHTML='<span class="material-icons-round">send</span> إرسال الطلب';
  });

  init();
})();
