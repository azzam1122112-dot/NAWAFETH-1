/* ── Complete Profile JS ── */
(function(){
  const API = window.NawafethApi;
  const UI  = window.NawafethUi;

  const dom = {
    loading : document.getElementById('cp-loading'),
    error   : document.getElementById('cp-error'),
    body    : document.getElementById('cp-body'),
    fill    : document.getElementById('cp-progress-fill'),
    percent : document.getElementById('cp-percent'),
  };

  const BASE_WEIGHT = 0.30;
  const SECTION_WEIGHT = (1 - BASE_WEIGHT) / 6; // ≈ 11.67% per section
  const sectionIds = ['service_details','additional','contact_full','lang_loc','content','seo'];

  let profile = null;

  async function load(){
    dom.loading.style.display=''; dom.error.style.display='none'; dom.body.style.display='none';
    try{
      const res = await API.get('/api/providers/profile/');
      if(!res.ok) throw new Error();
      profile = await res.json();
      render();
    }catch(e){
      dom.loading.style.display='none'; dom.error.style.display='';
    }
  }

  function isSectionComplete(id){
    if(!profile) return false;
    const map = {
      service_details: profile.is_service_details_complete,
      additional: profile.is_additional_details_complete,
      contact_full: profile.is_contact_info_complete,
      lang_loc: profile.is_language_location_complete,
      content: profile.is_content_complete,
      seo: profile.is_seo_complete,
    };
    return !!map[id];
  }

  function calcPercent(){
    let pct = profile.profile_completion != null ? profile.profile_completion : BASE_WEIGHT;
    return Math.round(pct * 100);
  }

  function render(){
    dom.loading.style.display='none'; dom.body.style.display='';
    const pct = calcPercent();
    dom.fill.style.width = pct + '%';
    dom.percent.textContent = pct + '%';

    const sectionPct = Math.round(SECTION_WEIGHT * 100);

    sectionIds.forEach(id=>{
      const el = document.querySelector(`[data-section="${id}"]`);
      if(!el) return;
      const done = isSectionComplete(id);
      el.querySelector('.nw-cp-extra').textContent = 'يمثل حوالي '+sectionPct+'٪ من اكتمال الملف.';

      if(done){
        el.classList.add('is-done');
        const arrow = el.querySelector('.nw-cp-arrow');
        if(arrow) arrow.outerHTML = '<span class="material-icons-round nw-cp-check">check_circle</span>';
      }
    });
  }

  // Section click → navigate to edit or show toast
  document.querySelectorAll('.nw-cp-section[data-section]').forEach(el=>{
    el.addEventListener('click',()=>{
      const section = el.dataset.section;
      // For web, we redirect to the provider profile edit page with section param
      const editUrl = (window.NAWAFETH_WEB_CONFIG?.urls?.providerProfileEdit || '/web/provider/profile-edit/');
      window.location.href = editUrl + '?section=' + section;
    });
  });

  document.getElementById('btn-cp-retry')?.addEventListener('click', load);

  load();
})();
