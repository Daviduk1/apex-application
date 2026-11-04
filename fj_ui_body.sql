create or replace package body fj_ui as

  c_guest_page_size constant pls_integer := 4;
  c_admin_page_size constant pls_integer := 15;

  function e(p_text in varchar2) return varchar2 is
  begin
    return apex_escape.html(p_text);
  end e;

  function files return varchar2 is
  begin
    return v('APP_FILES');
  end files;

  function url(p_page in number, p_items in varchar2 default null, p_values in varchar2 default null,
               p_request in varchar2 default null, p_clear in varchar2 default null) return varchar2 is
  begin
    return apex_page.get_url(p_page => p_page, p_items => p_items, p_values => p_values,
                             p_request => p_request, p_clear_cache => p_clear);
  end url;

  -- the logout procedure lives at the ORDS root (/ords/apex_authentication.logout), but with
  -- friendly URLs SCRIPT_NAME is /ords/r/<workspace>/<app>, so strip the /r/... part
  function logout_url return varchar2 is
  begin
    return regexp_replace(owa_util.get_cgi_env('SCRIPT_NAME'), '/r/.*$', '')
        || '/apex_authentication.logout?p_app_id=' || v('APP_ID') || '&amp;p_session_id=' || v('APP_SESSION');
  end logout_url;

  function circles return varchar2 is
  begin
    return '<span class="fj-circle fj-circle--lg"></span><span class="fj-circle fj-circle--red"></span>'
        || '<span class="fj-circle fj-circle--sm"></span>';
  end circles;

  function icon_pin return varchar2 is
  begin
    return '<svg class="fj-ico" viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.6">'
        || '<path d="M12 21s-7-6.1-7-11.5A7 7 0 0 1 19 9.5C19 14.9 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/></svg>';
  end icon_pin;

  function icon_search return varchar2 is
  begin
    return '<svg class="fj-ico" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8">'
        || '<circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/></svg>';
  end icon_search;

  function pagination(p_total in number, p_size in number, p_current in number,
                      p_page_id in number, p_item in varchar2) return varchar2 is
    l_pages pls_integer := greatest(ceil(p_total / p_size), 1);
    l_html  varchar2(32767) := '<nav class="fj-pager">';
  begin
    for i in 1 .. l_pages loop
      l_html := l_html || '<a class="fj-pager__item' || case when i = p_current then ' is-active' end
             || '" href="' || url(p_page_id, p_item, to_char(i)) || '">' || i || '</a>';
    end loop;
    if p_current < l_pages then
      l_html := l_html || '<a class="fj-pager__item" href="' || url(p_page_id, p_item, to_char(p_current + 1))
             || '" aria-label="Next page">&rsaquo;</a>';
    end if;
    return l_html || '</nav>';
  end pagination;

  function social return varchar2 is
  begin
    return '<div class="fj-social">'
        || '<a href="#" aria-label="Instagram"><svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="#fff" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r="1" fill="#fff"/></svg></a>'
        || '<a href="#" aria-label="Facebook"><svg viewBox="0 0 24 24" width="13" height="13" fill="#fff"><path d="M14 8h3V4h-3c-2.8 0-4 1.8-4 4.3V10H7v4h3v8h4v-8h3l1-4h-4V8.6c0-.4.3-.6.6-.6z"/></svg></a>'
        || '<a href="#" aria-label="Twitter"><svg viewBox="0 0 24 24" width="13" height="13" fill="#fff"><path d="M22 5.9c-.7.3-1.5.6-2.4.7.9-.5 1.5-1.3 1.8-2.3-.8.5-1.7.8-2.6 1a4.1 4.1 0 0 0-7 3.7A11.6 11.6 0 0 1 3.4 4.7a4.1 4.1 0 0 0 1.3 5.5c-.7 0-1.3-.2-1.9-.5 0 2 1.4 3.7 3.3 4.1-.6.2-1.2.2-1.9.1.5 1.6 2.1 2.8 3.9 2.9A8.3 8.3 0 0 1 2 18.5 11.6 11.6 0 0 0 8.3 20.3c7.6 0 11.7-6.3 11.7-11.7v-.5c.8-.6 1.5-1.3 2-2.2z"/></svg></a>'
        || '</div>';
  end social;

  ------------------------------------------------------------------------------
  function assets return clob is
    l clob;
  begin
    l := q'~
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Urbanist:ital,wght@0,400;0,500;0,600;0,700;0,800;1,700&display=swap" rel="stylesheet">
<style>
:root{--fj-navy:#0F4A7B;--fj-coral:#F57D7D;--fj-red:#EB5468;--fj-teal:#62BECB;--fj-bg:#F9FBFD;--fj-line:#C3D1DE;--fj-text:#0F4A7B;--fj-muted:#5F7A93}
body,.t-Dialog-page{font-family:"Urbanist","Gilroy","Segoe UI",sans-serif;background:var(--fj-bg);color:var(--fj-text)}
.t-PageBody--blank .t-Body-contentInner{padding:0}
#fj-guest,#fj-admin,#fj-seeker{overflow-x:clip}
.t-Alert--page{top:96px!important}
.fj *{box-sizing:border-box}
.fj a{text-decoration:none;color:inherit}
.fj-wrap{max-width:1180px;margin:0 auto;padding:0 40px}
.fj-circle{position:absolute;border-radius:50%;border:2px solid var(--fj-teal);pointer-events:none}
.fj-circle--lg{width:64px;height:64px;right:-18px;top:62px}
.fj-circle--red{width:28px;height:28px;right:40px;top:150px;border-color:#E2474B}
.fj-circle--sm{width:30px;height:30px;right:60px;top:196px}
/* hero header */
.fj-hero{position:relative;background:var(--fj-navy);color:#fff;overflow:visible}
.fj-nav{display:flex;align-items:center;justify-content:space-between;height:86px}
.fj-nav img{height:34px;display:block}
.fj-nav nav{display:flex;align-items:center;gap:30px;font-size:13px;font-weight:500}
.fj-nav nav a{color:#E6EEF6;opacity:.85}
.fj-nav nav a.is-active{opacity:1;font-weight:700;color:#fff}
.fj-btn-white{background:#fff;color:var(--fj-navy)!important;opacity:1!important;font-weight:700;padding:6px 10px;border-radius:3px;font-size:12px}
.fj-hero h1{margin:0;font-weight:700;letter-spacing:.12em;font-size:38px;padding:42px 0 90px}
.fj-searchbar{position:relative;z-index:2;display:flex;align-items:center;background:#fff;border-radius:6px;box-shadow:0 10px 30px rgba(15,74,123,.12);padding:12px 12px 12px 20px;margin:-48px auto 0;max-width:1060px}
.fj-searchbar .fj-field{flex:1;display:flex;align-items:center;gap:12px;color:var(--fj-teal)}
.fj-searchbar .fj-field+.fj-field{border-left:1px solid #E3E9EF;padding-left:20px;margin-left:12px}
.fj-searchbar input{border:0;outline:0;width:100%;font:inherit;font-size:14px;color:var(--fj-navy);letter-spacing:.06em;background:transparent}
.fj-btn-red{background:var(--fj-red);color:#fff;border:0;border-radius:5px;padding:10px 26px;font:inherit;font-size:13px;letter-spacing:.06em;cursor:pointer}
.fj-btn-red:hover{filter:brightness(.95)}
/* guest list */
.fj-results-head{display:flex;justify-content:space-between;align-items:center;margin:56px 0 22px;font-size:13px;color:var(--fj-navy);max-width:610px;letter-spacing:.04em}
.fj-results-head select{border:0;background:transparent;font:inherit;font-weight:600;color:var(--fj-navy);cursor:pointer}
.fj-results-head label{color:#8DA2B5}
.fj-grid{display:grid;grid-template-columns:minmax(0,610px) minmax(0,1fr);gap:46px;align-items:start}
.fj-card{display:block;background:#fff;border-radius:6px;padding:26px 30px 22px;margin-bottom:26px;box-shadow:0 6px 24px rgba(15,74,123,.06);transition:transform .15s}
.fj-card:hover{transform:translateY(-2px)}
.fj-card__top{display:flex;justify-content:space-between;gap:12px}
.fj-card h3{margin:0;font-size:22px;font-weight:600;letter-spacing:.08em}
.fj-card .fj-salary{font-size:21px;font-weight:700;letter-spacing:.04em;white-space:nowrap}
.fj-loc{display:flex;align-items:center;gap:6px;color:var(--fj-navy);font-size:15px;letter-spacing:.06em;margin-top:6px}
.fj-loc .fj-ico{color:var(--fj-teal)}
.fj-card p{font-size:13px;line-height:1.55;letter-spacing:.05em;margin:18px 0 12px;color:var(--fj-navy)}
.fj-card__foot{text-align:right}
.fj-see-more{display:inline-block;background:var(--fj-red);color:#fff;font-size:11px;font-weight:600;letter-spacing:.06em;padding:6px 14px;border-radius:4px}
.fj-card.is-active{background:var(--fj-navy);color:#fff}
.fj-card.is-active .fj-loc,.fj-card.is-active p{color:#fff}
.fj-card.is-active .fj-see-more{background:#fff;color:var(--fj-red)}
.fj-detail{background:#fff;border-radius:6px;box-shadow:0 6px 24px rgba(15,74,123,.08);position:sticky;top:20px}
.fj-detail__head{padding:30px 34px 26px;border-bottom:1px solid #F7C6C6}
.fj-detail h2{margin:0;font-size:20px;font-weight:600;letter-spacing:.1em}
.fj-btn-navy{display:inline-block;background:var(--fj-navy);color:#fff!important;border:0;border-radius:3px;padding:8px 22px;font:inherit;font-size:13px;letter-spacing:.08em;margin-top:22px;cursor:pointer}
.fj-detail__body{padding:26px 34px 34px;font-size:12.5px;line-height:2;letter-spacing:.06em;color:#47657F}
.fj-detail__body p{margin:0 0 14px}
.fj-detail__body ul{margin:0 0 18px;padding-left:16px}
.fj-detail__body li{line-height:1.6;margin-bottom:10px}
.fj-detail__body li::marker{color:var(--fj-navy)}
.fj-detail__body ul.fj-facts li{margin-bottom:0}
.fj-detail__body h4{color:var(--fj-navy);font-size:12.5px;font-weight:700;margin:4px 0 16px}
.fj-empty{background:#fff;border-radius:6px;padding:40px;text-align:center;color:#8DA2B5}
.fj-pager{display:flex;gap:10px;margin:8px 0 60px}
.fj-pager__item{width:32px;height:32px;display:inline-flex;align-items:center;justify-content:center;border:1px solid #DCE4EB;border-radius:3px;background:#fff;font-size:12px;color:var(--fj-navy)}
.fj-pager__item.is-active{background:var(--fj-navy);color:#fff;border-color:var(--fj-navy)}
/* footer */
.fj-footer{background:var(--fj-navy);color:#fff;padding:48px 0 54px}
.fj-footer .fj-wrap{display:grid;grid-template-columns:2fr 1fr 1fr 1fr;gap:24px}
.fj-footer img{height:34px}
.fj-footer small{display:block;margin-top:14px;font-size:13px;letter-spacing:.08em}
.fj-footer small em{color:var(--fj-teal);font-style:italic}
.fj-footer h5{margin:0 0 14px;font-size:14px;font-weight:600}
.fj-footer ul{list-style:none;margin:0;padding:0;font-size:13px;line-height:2}
.fj-social{display:flex;gap:10px}
.fj-social a{width:34px;height:34px;border-radius:50%;background:rgba(255,255,255,.3);display:inline-flex;align-items:center;justify-content:center}
.fj-footer--admin .fj-wrap{display:flex;align-items:center;gap:40px;font-size:13px}
.fj-footer--admin .fj-social{margin-left:auto}
.fj-footer--admin{padding:22px 0}
/* admin */
.fj-hero--admin h1{font-style:italic;font-size:44px;letter-spacing:.02em;padding:24px 0 52px}
.fj-hero--admin .fj-nav img{height:46px}
.fj-userbar{display:flex;align-items:center;gap:18px}
.fj-bell{position:relative;display:inline-flex}
.fj-bell.has-new:after{content:"";position:absolute;top:0;right:1px;width:6px;height:6px;border-radius:50%;background:var(--fj-red)}
.fj-avatar{position:relative}
.fj-avatar summary{list-style:none;cursor:pointer;width:42px;height:42px;border-radius:50%;background:#0A2236;color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;border:2px solid #fff}
.fj-avatar summary::-webkit-details-marker{display:none}
.fj-menu{position:absolute;right:0;top:50px;background:#fff;color:var(--fj-navy);border-radius:6px;box-shadow:0 10px 30px rgba(0,0,0,.15);min-width:190px;padding:8px;z-index:20;font-size:13px}
.fj-menu span{display:block;padding:8px 10px;color:#8DA2B5}
.fj-menu a,.fj-menu button{display:block;width:100%;text-align:left;padding:8px 10px;border-radius:4px;border:0;background:none;font:inherit;color:var(--fj-navy);cursor:pointer}
.fj-menu a:hover,.fj-menu button:hover{background:#EEF3F8}
.fj-admin-tools{display:flex;justify-content:space-between;align-items:center;margin:56px 0 22px;gap:20px;flex-wrap:wrap}
.fj-searchbox{display:flex;align-items:center;gap:12px;background:#fff;border-radius:5px;box-shadow:0 6px 20px rgba(15,74,123,.08);padding:7px 7px 7px 18px;width:100%;max-width:380px;color:var(--fj-teal)}
.fj-searchbox input{flex:1;border:0;outline:0;font:inherit;font-size:13px;letter-spacing:.06em;color:var(--fj-navy);background:transparent}
.fj-searchbox .fj-btn-red{padding:7px 18px;font-size:12px}
.fj-btn-coral{background:var(--fj-red);color:#fff!important;border-radius:5px;padding:12px 20px;font-size:13px;font-weight:600;display:inline-flex;align-items:center;gap:8px;box-shadow:0 6px 16px rgba(235,84,104,.25)}
.fj-table{margin-bottom:28px}
.fj-trow{display:grid;grid-template-columns:24px 2.2fr 1.3fr 1.3fr 1fr 1.1fr;align-items:center;gap:8px;background:#fff;border-radius:4px;padding:0 26px 0 22px;height:52px;margin-bottom:8px;font-size:13px;box-shadow:0 2px 8px rgba(15,74,123,.04);color:#26445F}
.fj-trow--head{background:var(--fj-navy);color:#fff;height:46px;font-size:12.5px;box-shadow:none}
.fj-dot{width:6px;height:6px;border-radius:50%;background:var(--fj-red)}
.fj-trow .fj-act{justify-self:center;color:#8DA2B5;font-size:12.5px;padding:6px 0;width:96px;text-align:center;border:1px solid transparent;border-radius:2px;background:none;font-family:inherit;cursor:pointer}
.fj-trow:hover .fj-act--edit,.fj-trow:focus-within .fj-act--edit{background:var(--fj-red);color:#fff}
.fj-trow:hover .fj-act--del,.fj-trow:focus-within .fj-act--del{border-color:var(--fj-teal);color:var(--fj-teal)}
.fj-filter{justify-self:end;position:relative}
.fj-filter summary{list-style:none;cursor:pointer;display:flex;align-items:center;gap:6px}
.fj-filter summary::-webkit-details-marker{display:none}
.fj-filter .fj-menu{top:30px}
.fj-filter .fj-menu a.is-active{font-weight:700;background:#EEF3F8}
.fj-count-link{color:var(--fj-navy);font-weight:600;text-decoration:underline!important;text-underline-offset:3px}
/* admin tabs, dashboard, candidates */
.fj-tabs{display:flex;gap:6px;margin-left:auto;margin-right:28px}
.fj-tabs a{color:#CFE0EE;padding:8px 16px;border-radius:4px;font-size:13px;font-weight:600;letter-spacing:.04em}
.fj-tabs a:hover{color:#fff;background:rgba(255,255,255,.08)}
.fj-tabs a.is-active{background:rgba(255,255,255,.16);color:#fff}
.fj-stats{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:22px;margin:56px 0 30px}
.fj-stat{display:block;background:#fff;border-radius:6px;padding:22px 24px;box-shadow:0 6px 24px rgba(15,74,123,.06);border-top:4px solid var(--fj-navy);transition:transform .15s}
.fj-stat:hover{transform:translateY(-2px)}
.fj-stat--teal{border-color:var(--fj-teal)}.fj-stat--coral{border-color:var(--fj-coral)}.fj-stat--red{border-color:var(--fj-red)}
.fj-stat__label{display:block;font-size:12.5px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:#5F7A93}
.fj-stat strong{display:block;font-size:40px;font-weight:700;color:var(--fj-navy);margin:6px 0 2px;font-variant-numeric:tabular-nums}
.fj-stat small{font-size:12.5px;color:#8DA2B5;letter-spacing:.03em}
.fj-dash-grid{display:grid;grid-template-columns:1fr 1fr;gap:22px;margin-bottom:56px}
.fj-panel{background:#fff;border-radius:6px;box-shadow:0 6px 24px rgba(15,74,123,.06);padding:8px 0}
.fj-panel__head{display:flex;justify-content:space-between;align-items:center;padding:16px 24px 12px}
.fj-panel__head h3{margin:0;font-size:16px;font-weight:700;letter-spacing:.06em}
.fj-panel__head a{font-size:12.5px;font-weight:600;color:var(--fj-red)}
.fj-panel__row{display:flex;justify-content:space-between;align-items:center;gap:16px;padding:13px 24px;border-top:1px solid #EEF2F6;font-size:13px}
.fj-panel__row b{display:block;font-weight:600;color:var(--fj-navy)}
.fj-panel__row span{display:block;color:#8DA2B5;font-size:12px;margin-top:3px}
.fj-panel__row time{color:#5F7A93;font-size:12px;white-space:nowrap}
.fj-pill{background:#EEF3F8;color:var(--fj-navy);border-radius:999px;padding:5px 12px;font-size:12px;font-weight:600;white-space:nowrap}
.fj-select{display:flex;align-items:center;gap:10px;font-size:12.5px;font-weight:700;letter-spacing:.06em}
.fj-select select{height:42px;border:1px solid #DCE4EB;border-radius:5px;background:#fff;font:inherit;font-weight:500;color:var(--fj-navy);padding:0 10px;max-width:320px}
.fj-count{margin-left:auto;font-size:13px;color:#5F7A93}
.fj-trow--cand{grid-template-columns:2.2fr 1.2fr 2fr 1.1fr 1.4fr .8fr;height:auto;min-height:60px;padding:10px 24px}
.fj-trow--link{transition:box-shadow .15s,transform .15s}
.fj-trow--link:hover{box-shadow:0 6px 18px rgba(15,74,123,.12);transform:translateY(-1px)}
/* status pills + pipeline */
.fj-status{display:inline-block;border-radius:999px;padding:5px 12px;font-size:11.5px;font-weight:700;letter-spacing:.03em;white-space:nowrap;background:#EEF3F8;color:var(--fj-navy)}
.fj-status--shortlisted{background:#E3F4F6;color:#1F7C88}
.fj-status--test_submitted{background:#FFF3DC;color:#946200}
.fj-status--passed{background:#E2F5EA;color:#1E7A46}
.fj-status--rejected{background:#FDE8EA;color:#B3263A}
.fj-status--interview_scheduled{background:#E8EEFB;color:#2F55B5}
.fj-status--interviewed{background:#E3EEF8;color:var(--fj-navy)}
.fj-status--offered{background:#F3E8FB;color:#7A3BA8}
.fj-status--hired{background:#2E8B57;color:#fff}
.fj-status--offer_declined{background:#F1F3F5;color:#5F7A93}
.fj-status--pending{background:#FFF3DC;color:#946200}
.fj-status--confirmed{background:#E2F5EA;color:#1E7A46}
.fj-status--reschedule{background:#FDE8EA;color:#B3263A}
.fj-pipeline{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:12px;margin:0 0 30px}
.fj-pipeline__step{background:#fff;border-radius:6px;padding:14px 18px;box-shadow:0 6px 24px rgba(15,74,123,.06);display:flex;align-items:baseline;gap:10px;border-left:4px solid #C3D1DE}
.fj-pipeline__step strong{font-size:24px;color:var(--fj-navy);font-variant-numeric:tabular-nums}
.fj-pipeline__step span{font-size:12.5px;color:#5F7A93;font-weight:600}
.fj-pipeline__step--shortlisted{border-color:var(--fj-teal)}.fj-pipeline__step--test_submitted{border-color:#E8A93B}
.fj-pipeline__step--passed{border-color:#3BAA6E}.fj-pipeline__step--rejected{border-color:var(--fj-red)}
.fj-pipeline__step--interview_scheduled{border-color:#5B7FD6}.fj-pipeline__step--interviewed{border-color:var(--fj-navy)}
.fj-pipeline__step--offered{border-color:#9B5BC9}.fj-pipeline__step--hired{border-color:#2E8B57}.fj-pipeline__step--offer_declined{border-color:#8DA2B5}
.fj-stats--3{grid-template-columns:repeat(3,minmax(0,1fr));margin-top:-8px}
.fj-stat--green{border-color:#2E8B57}.fj-stat--purple{border-color:#9B5BC9}.fj-stat--blue{border-color:#5B7FD6}
.fj-panel__row.is-unread{background:#F2F8FD;box-shadow:inset 3px 0 0 var(--fj-red)}
.fj-panel__row p{margin:4px 0 0;color:#47657F;font-size:12.5px;line-height:1.5}
.fj-tag{display:inline-block;margin-left:10px;font:inherit;font-size:11px;font-weight:700;letter-spacing:.04em;padding:3px 9px;border-radius:999px;background:#E2F5EA;color:#1E7A46;border:0;cursor:pointer;vertical-align:middle}
.fj-tag:hover{background:#CDEBD9}
a.fj-panel__row:hover{background:#F7FAFC}
/* candidate detail */
.fj-back{display:inline-block;margin:36px 0 14px;font-size:13px;font-weight:600;color:var(--fj-navy)}
.fj-pad{padding:22px 26px;margin-bottom:22px}
.fj-pad h3{margin:0 0 14px;font-size:15px;font-weight:700;letter-spacing:.06em}
.fj-panel__head--flush{padding:0 0 14px}
.fj-panel__head--flush h3{margin:0}
.fj-cand-head{display:flex;align-items:center;gap:20px;padding:22px 26px;margin-bottom:22px}
.fj-cand-head__main{flex:1}
.fj-cand-head h2{margin:0;font-size:24px;letter-spacing:.04em}
.fj-cand-head p{margin:4px 0 0;color:#5F7A93;font-size:13.5px}
.fj-avatar-lg{width:58px;height:58px;border-radius:50%;background:var(--fj-navy);color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:20px;flex:none}
.fj-cand-grid{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1.5fr);gap:22px;align-items:start}
.fj-facts{display:grid;gap:12px}
.fj-fact{display:grid;grid-template-columns:110px 1fr;gap:10px;font-size:13.5px}
.fj-fact span{color:#8DA2B5}
.fj-fact b{font-weight:600;color:var(--fj-navy);overflow-wrap:anywhere}
.fj-cv-frame{width:100%;height:560px;border:1px solid #E3E9EF;border-radius:4px;background:#F4F7FA}
.fj-cv-img{display:block;max-width:100%;border:1px solid #E3E9EF;border-radius:4px}
.fj-cv-text{white-space:pre-wrap;background:#F7FAFC;border:1px solid #E3E9EF;border-radius:4px;padding:16px;font-size:12.5px;max-height:420px;overflow:auto;margin:0}
.fj-score{font-size:13px;color:#5F7A93}
.fj-answers{margin:0;padding-left:20px;display:grid;gap:12px}
.fj-answers li{padding:12px 14px;border-radius:5px;background:#F7FAFC;font-size:13px}
.fj-answers li.is-right{background:#EFF9F3}.fj-answers li.is-wrong{background:#FDF1F2}
.fj-answers p{margin:0 0 6px;font-weight:600;color:var(--fj-navy)}
.fj-answers div{display:flex;flex-wrap:wrap;justify-content:space-between;gap:8px}
.fj-answers em{font-style:normal;font-weight:600}
.fj-answers .is-right em{color:#1E7A46}.fj-answers .is-wrong em{color:#B3263A}
.fj-steps{list-style:none;margin:18px 0;padding:0;display:grid;grid-template-columns:repeat(6,1fr);gap:8px;counter-reset:s}
.fj-steps li{position:relative;padding-top:22px;font-size:12.5px;font-weight:600;color:#8DA2B5}
.fj-steps li:before{content:"";position:absolute;top:4px;left:0;width:12px;height:12px;border-radius:50%;border:2px solid #C3D1DE;background:#fff}
.fj-steps li:after{content:"";position:absolute;top:10px;left:18px;right:4px;height:2px;background:#E3E9EF}
.fj-steps li:last-child:after{display:none}
.fj-steps li.is-done{color:var(--fj-navy)}
.fj-steps li.is-done:before{background:var(--fj-teal);border-color:var(--fj-teal)}
.fj-steps small{display:block;font-weight:500;color:#8DA2B5;margin-top:2px;min-height:1em}
.fj-steps--v{grid-template-columns:1fr;gap:4px;margin:0}
.fj-steps--v li{padding:0 0 14px 24px}
.fj-steps--v li:before{top:2px}
.fj-steps--v li:after{top:18px;left:6px;right:auto;width:2px;height:calc(100% - 18px)}
.fj-screen{max-width:1100px;margin:0 auto;background:#fff;border-radius:6px;box-shadow:0 6px 24px rgba(15,74,123,.06);padding:22px 26px 4px}
.fj-screen .row{margin:0}.fj-screen .col{padding:0}
.fj-screen #P8_SCORE,.fj-screen #P8_INT_SCORE{max-width:160px!important}
.fj-screen #P8_INT_AT,.fj-screen #P8_OFFER_START{max-width:260px!important}
.fj-screen #P8_INT_MODE{max-width:260px!important}
.fj-signup-r{padding-top:10vh}
.fj-signup-form .t-Form-fieldContainer{margin-bottom:14px}
.fj-signup-form .t-Form-itemWrapper input{height:48px}
.fj-actions{display:flex;flex-wrap:wrap;align-items:center;gap:12px;margin:18px 0 60px}
.fj-actions .fj-btn-navy{margin:0}
.fj-btn-green{background:#2E8B57;color:#fff;border:0;border-radius:4px;padding:11px 22px;font:inherit;font-size:13px;font-weight:600;cursor:pointer}
.fj-btn-outline{background:#fff;color:#B3263A;border:1px solid #E7A1AB;border-radius:4px;padding:10px 22px;font:inherit;font-size:13px;font-weight:600;cursor:pointer}
.fj-btn-ghost{background:transparent;color:var(--fj-navy);border:1px solid #C3D1DE;border-radius:4px;padding:10px 20px;font:inherit;font-size:13px;font-weight:600;cursor:pointer;margin-left:auto}
.fj-hint{font-size:13px;color:#5F7A93;margin:0 0 18px}
.fj-actions .fj-hint{margin:0}
.fj-stage{margin-top:22px}
.fj-stage-title{margin:0 0 4px;font-size:15px;font-weight:700;letter-spacing:.06em;color:var(--fj-navy)}
.fj-stage-sub{margin:0 0 18px;font-size:13px;color:#5F7A93}
.fj-reply{margin-top:12px;padding:12px 14px;border-radius:5px;background:#F7FAFC;font-size:13px;color:#47657F;line-height:1.5}
.fj-reply b{color:var(--fj-navy)}
/* seeker interview + offer cards */
.fj-box{width:100%;background:#F7FAFC;border:1px solid #E3E9EF;border-radius:6px;padding:16px 18px;display:grid;gap:10px}
.fj-box h4{margin:0;font-size:14px;letter-spacing:.06em;color:var(--fj-navy)}
.fj-box .fj-fact{grid-template-columns:120px 1fr;font-size:13px}
.fj-box blockquote{margin:0;padding:10px 14px;border-left:3px solid var(--fj-teal);background:#fff;white-space:pre-wrap;font-size:13px;color:#26445F}
.fj-respond{width:100%;display:flex;flex-wrap:wrap;gap:10px;align-items:center}
.fj-respond label{width:100%;font-size:12.5px;font-weight:700;letter-spacing:.06em;color:var(--fj-navy)}
.fj-respond textarea{width:100%;min-height:64px;border:1px solid var(--fj-line);border-radius:6px;padding:10px 12px;font:inherit;font-size:13.5px;color:var(--fj-navy);resize:vertical}
.fj-respond .fj-btn-navy{margin:0}
/* tests admin */
.fj-qlist{display:grid;gap:16px;margin-bottom:56px}
.fj-qcard{padding:18px 22px}
.fj-qcard__head{display:flex;gap:14px;align-items:flex-start}
.fj-qcard__head p{flex:1;margin:0;font-weight:600;font-size:14px;line-height:1.5}
.fj-qnum{background:var(--fj-navy);color:#fff;border-radius:4px;padding:3px 8px;font-size:12px;font-weight:700}
.fj-qcard ul{list-style:none;margin:12px 0 0 46px;padding:0;display:grid;grid-template-columns:1fr 1fr;gap:6px 20px;font-size:13px;color:#47657F}
.fj-qcard li.is-correct{color:#1E7A46;font-weight:600}
.fj-qcard li em{font-style:normal;font-size:11.5px}
.fj-qcard__actions{display:flex;justify-content:flex-end;gap:6px;margin-top:10px}
.fj-qcard__actions .fj-act{color:var(--fj-navy);border:1px solid #DCE4EB;width:auto;padding:5px 16px;font:inherit;font-size:12.5px;font-weight:600;background:#fff;border-radius:3px;cursor:pointer}
.fj-qcard__actions .fj-act:hover{background:#F2F6FA}
.fj-qcard__actions .fj-act--del{color:#B3263A}
/* job seeker area */
.fj-avatar--sm summary{width:34px;height:34px;font-size:13px;border-width:1.5px}
.fj-avatar--sm .fj-menu{top:42px}
.fj-btn-applied{background:#2E8B57!important}
.fj-auth-sub{margin:-14px 0 30px;font-size:14px;color:#5F7A93}
.fj-auth-sub a,.fj-auth-alt a{color:var(--fj-red);font-weight:600}
.fj-auth-alt{margin:22px 0 0;font-size:13.5px;color:#5F7A93}
.fj-seeker-wrap{padding-top:56px;padding-bottom:60px;display:grid;grid-template-columns:minmax(0,1fr) 340px;gap:26px;align-items:start}
.fj-seeker-wrap>.fj-notes{order:2;position:sticky;top:20px}
.fj-seeker-wrap>.fj-empty,.fj-seeker-wrap>.fj-test-intro,.fj-seeker-wrap>.fj-test,.fj-seeker-wrap>.fj-btn-submit-test{grid-column:1/-1}
.fj-note{padding:12px 24px;border-top:1px solid #EEF2F6;font-size:13px}
.fj-note b{display:block;color:var(--fj-navy)}
.fj-note p{margin:4px 0;color:#47657F;line-height:1.5}
.fj-note time{font-size:11.5px;color:#8DA2B5}
.fj-note.is-unread{background:#F2F8FD;box-shadow:inset 3px 0 0 var(--fj-red)}
.fj-apps{display:grid;gap:18px}
.fj-app{background:#fff;border-radius:6px;box-shadow:0 6px 24px rgba(15,74,123,.06);padding:24px 28px}
.fj-app__top{display:flex;justify-content:space-between;gap:16px;align-items:flex-start}
.fj-app h3{margin:0;font-size:20px;font-weight:600;letter-spacing:.06em}
.fj-app__msg{font-size:13.5px;color:#47657F;line-height:1.6;display:flex;flex-wrap:wrap;align-items:center;gap:14px;justify-content:space-between}
.fj a.fj-btn-red,.fj a.fj-btn-test{color:#fff;text-decoration:none!important}
.fj-test-intro{padding:24px 28px}
.fj-test-intro h2{margin:0;font-size:22px;letter-spacing:.06em}
.fj-test-intro p{font-size:14px;color:#47657F;line-height:1.6;margin:14px 0 0}
.fj-test{display:grid;gap:16px}
.fj-q{background:#fff;border:0;border-radius:6px;box-shadow:0 6px 24px rgba(15,74,123,.06);padding:22px 26px;margin:0}
.fj-q legend{float:left;width:100%;font-size:15px;font-weight:600;color:var(--fj-navy);margin-bottom:14px;line-height:1.5}
.fj-q legend span{display:block;font-size:11.5px;letter-spacing:.1em;text-transform:uppercase;color:#8DA2B5;margin-bottom:4px}
.fj-q.is-missing{box-shadow:0 0 0 2px var(--fj-red)}
.fj-opt{clear:both;display:flex;align-items:center;gap:12px;padding:11px 14px;border:1px solid #DCE4EB;border-radius:5px;margin-bottom:8px;cursor:pointer;font-size:14px;color:#26445F}
.fj-opt:hover{border-color:var(--fj-navy)}
.fj-opt input{position:absolute;opacity:0;pointer-events:none}
.fj-opt__key{width:26px;height:26px;border-radius:50%;border:1px solid #C3D1DE;display:inline-flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;flex:none}
.fj-opt:has(input:checked){border-color:var(--fj-navy);background:#F2F8FD}
.fj-opt:has(input:checked) .fj-opt__key{background:var(--fj-navy);border-color:var(--fj-navy);color:#fff}
.fj-opt:has(input:focus-visible){outline:2px solid var(--fj-teal);outline-offset:2px}
.fj-trow--cand.fj-trow--head{min-height:46px}
.fj-person b{display:block;font-weight:600}
.fj-person a,.fj-person small{display:block;font-size:12px;color:#8DA2B5;margin-top:2px;overflow-wrap:anywhere}
.fj-cv{justify-self:start;border:1px solid var(--fj-teal);color:var(--fj-teal)!important;border-radius:3px;padding:5px 12px;font-size:12px;font-weight:600}
.fj-cv:hover{background:var(--fj-teal);color:#fff!important}
.fj-muted{color:#B4C3D1;font-size:12px}
/* login */
.fj-login-left{position:fixed;inset:0 auto 0 0;width:56.2vw;background:var(--fj-coral);color:#fff;padding:38px 0 0 83px;overflow:hidden;z-index:0;clip-path:polygon(0 0,100% 0,calc(100% - 5.7vw) 100%,0 100%)}
.fj-login-left:before{content:"";position:absolute;inset:0;background:var(--fj-navy);z-index:-1;clip-path:polygon(0 0,calc(100% - 4.7vw) 0,calc(100% - 10.4vw) 100%,0 100%)}
.fj-login-left img.fj-logo{height:55px;display:block}
.fj-login-left h1{font-weight:800;font-size:44px;line-height:1.3;margin:22vh 0 44px;max-width:480px;letter-spacing:.01em}
.fj-login-left img.fj-illus{width:min(508px,75%);display:block}
.fj-login-r{margin-left:56.2vw;position:relative;padding:30vh 80px 40px 3.4vw;min-height:100vh;overflow:hidden}
.fj-login-r h2{font-size:32px;font-weight:800;letter-spacing:.12em;margin:0 0 30px;color:var(--fj-navy)}
.fj-login-r .fj-circle--lg{top:60px;right:30px;width:80px;height:80px}
.fj-login-r .fj-circle--red{top:110px;right:110px;width:40px;height:40px}
.fj-login-r .fj-circle--sm{top:170px;right:160px;width:46px;height:46px}
.fj-login-form{max-width:490px}
.fj-login-btn{background:var(--fj-navy);color:#fff;border:0;border-radius:6px;padding:16px 60px;font:inherit;font-size:16px;font-weight:700;letter-spacing:.1em;cursor:pointer;margin-top:14px}
/* APEX form items restyled to match the design */
.fj-form .t-Form-fieldContainer{padding:0;margin-bottom:22px}
.fj-form .t-Form-labelContainer{padding:0 0 10px}
.fj-form .t-Form-label{font-size:12.5px;font-weight:700;letter-spacing:.1em;color:var(--fj-navy)}
.fj-form .t-Form-inputContainer{padding:0}
.fj-form .t-Form-itemWrapper input,.fj-form .t-Form-itemWrapper select,.fj-form .t-Form-itemWrapper textarea{border:1px solid var(--fj-line)!important;border-radius:6px!important;background:#fff!important;min-height:46px;font-family:inherit;font-size:14px;color:var(--fj-navy);box-shadow:none!important}
.fj-form .t-Form-itemWrapper input:focus,.fj-form .t-Form-itemWrapper select:focus,.fj-form .t-Form-itemWrapper textarea:focus{border-color:var(--fj-navy)!important}
.fj-form .t-Form-itemRequired-marker,.fj-form .t-Form-required{display:none}
.fj-form .is-required .t-Form-label:before,.fj-form .is-required .t-Form-label:after,.fj-form .is-required .t-Form-labelContainer:before{content:none!important;display:none!important}
.fj-form .t-Form-itemWrapper{width:100%}
.fj-form input.apex-item-text,.fj-form input[type=password],.fj-form select,.fj-form textarea{width:100%!important;max-width:none!important}
.fj-form .t-Form-itemWrapper>.apex-item-group,.fj-form .t-Form-itemWrapper>span{flex:1}
.fj-form a-date-picker{display:flex;width:100%}
.fj-form a-date-picker input{flex:1}
.fj-login-form .t-Form-label{font-weight:500;font-size:16px}
.fj-login-form .t-Form-itemWrapper input{height:56px}
.fj-login-form .t-Form-itemWrapper button{display:none}
.t-Dialog-page .fj-form .row{margin:0}
.t-Dialog-page .fj-form .col{padding:0}
.fj-form .t-Form-labelContainer--hiddenLabel{display:none}
.fj-form .t-Form-fieldContainer--hiddenLabel .t-Form-inputContainer{flex:0 0 100%;max-width:100%;width:100%}
.fj-form a-file-upload{display:block;width:100%}
.fj-form .a-FileDrop{width:100%;min-height:190px;border:1px solid var(--fj-line);border-radius:4px;background:#fff;color:var(--fj-navy);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;padding:28px 16px}
.fj-form .a-FileDrop-icon .a-Icon{display:none}
.fj-form .a-FileDrop-icon:before{content:"";display:block;width:44px;height:40px;background:no-repeat center/contain url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%230F4A7B' stroke-width='1.6' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M7 18a5 5 0 0 1-.9-9.9A6 6 0 0 1 17.7 7 4.5 4.5 0 0 1 18 16'/%3E%3Cpath d='M12 12v9M8.5 15.5 12 12l3.5 3.5'/%3E%3C/svg%3E")}
.fj-form .a-FileDrop-body{display:flex;flex-direction:column;align-items:center;gap:6px}
.fj-form .a-FileDrop-heading{font-size:12px;color:var(--fj-navy);font-weight:500}
.fj-form .a-FileDrop-description{font-size:11px;color:var(--fj-navy)}
.fj-form .a-FileDrop-action-choose{background:var(--fj-navy)!important;color:transparent!important;border-radius:4px;font-size:0!important;padding:8px 18px!important;box-shadow:none!important}
.fj-form .a-FileDrop-action-choose:after{content:"Browse files";color:#fff;font-size:11px;font-weight:600;letter-spacing:.02em}
.fj-dialog-head{padding:8px 0 22px}
.fj-dialog-head h2{margin:0;font-size:19px;font-weight:600;letter-spacing:.12em}
.fj-dialog-head p{margin:6px 0 0;font-size:11px;letter-spacing:.04em;color:#47657F}
.fj-dialog-head .fj-loc{font-size:12px}
.fj-btn-block{display:block;width:100%;background:var(--fj-navy);color:#fff;border:0;padding:16px;font:inherit;font-size:13px;font-weight:600;letter-spacing:.04em;cursor:pointer;margin:12px 0 30px}
.fj-dialog .ui-dialog-titlebar{background:var(--fj-bg);border:0;box-shadow:none}
.fj-dialog .ui-dialog-title{visibility:hidden}
.fj-dialog .ui-dialog-content,.t-Dialog-page .t-Dialog-body{background:var(--fj-bg)}
.t-Dialog-page .t-Dialog-body{padding:0 34px}
@media (max-width:900px){
 .fj-grid{grid-template-columns:1fr}.fj-detail{position:static}
 .fj-hero h1{font-size:28px}
 .fj-nav nav a:not(.fj-btn-white):not(.is-active){display:none}
 .fj-searchbar{flex-wrap:wrap;margin:-40px 16px 0}.fj-searchbar .fj-field+.fj-field{border:0;margin:10px 0 0;padding:0}.fj-searchbar .fj-btn-red{width:100%;margin-top:10px}
 .fj-wrap{padding:0 16px}
 .fj-footer .fj-wrap{grid-template-columns:1fr 1fr}
 .fj-trow{grid-template-columns:12px 2fr 1fr 1fr;font-size:12px;padding:0 10px}.fj-trow>:nth-child(5),.fj-trow>:nth-child(6){display:none}
 .fj-trow--cand{grid-template-columns:2fr 1.4fr 1fr}.fj-trow--cand>:nth-child(2),.fj-trow--cand>:nth-child(4),.fj-trow--cand>:nth-child(6){display:none}.fj-trow--cand>:nth-child(5){display:block}
 .fj-pipeline{grid-template-columns:1fr 1fr}.fj-cand-grid,.fj-seeker-wrap{grid-template-columns:1fr}.fj-seeker-wrap>.fj-notes{order:0;position:static}
 .fj-steps{grid-template-columns:1fr 1fr}.fj-qcard ul{grid-template-columns:1fr;margin-left:0}.fj-screen{margin:0 16px}.fj-btn-ghost{margin-left:0}
 .fj-tabs{margin:0 12px;gap:2px}.fj-tabs a{padding:6px 8px;font-size:12px}
 .fj-stats{grid-template-columns:1fr 1fr}.fj-dash-grid{grid-template-columns:1fr}
 .fj-count{margin-left:0}
 .fj-login-left{position:relative;width:100%;padding:32px 24px 40px}.fj-login-left:after{display:none}.fj-login-left h1{font-size:30px;margin:40px 0 24px}
 .fj-login-left{clip-path:none;width:100%}.fj-login-left:before{clip-path:none}
 .fj-login-r{margin-left:0;padding:40px 24px;min-height:0}
}
</style>~';
    -- one literal is limited to 32K, so the script is appended separately
    l := l || q'~
<script>
function fjSearch(){apex.page.submit({request:"SEARCH",set:{P1_KEYWORD:document.getElementById("fj_kw").value,P1_LOCATION:document.getElementById("fj_loc").value,P1_PAGE:"1",P1_JOB_ID:""},showWait:true});}
function fjSort(v){apex.page.submit({request:"SEARCH",set:{P1_SORT:v,P1_PAGE:"1",P1_JOB_ID:""},showWait:true});}
function fjAdminSearch(){apex.page.submit({request:"SEARCH",set:{P2_SEARCH:document.getElementById("fj_admin_kw").value,P2_PAGE:"1"},showWait:true});}
function fjAdminSort(v){apex.page.submit({request:"SEARCH",set:{P2_SORT:v,P2_PAGE:"1"},showWait:true});}
function fjDelete(id,title){apex.message.confirm("Delete “"+title+"” and all its applications?",function(ok){if(ok){apex.page.submit({request:"DELETE",set:{P2_DELETE_ID:id},showWait:true});}});}
function fjCandSearch(){apex.page.submit({request:"SEARCH",set:{P6_SEARCH:document.getElementById("fj_cand_kw").value,P6_PAGE:"1"},showWait:true});}
function fjCandJob(v){apex.page.submit({request:"SEARCH",set:{P6_JOB_ID:v,P6_PAGE:"1"},showWait:true});}
function fjCandStatus(v){apex.page.submit({request:"SEARCH",set:{P6_STATUS:v,P6_PAGE:"1"},showWait:true});}
function fjTestJob(v){apex.page.submit({request:"SEARCH",set:{P9_JOB_ID:v},showWait:true});}
function fjDeleteQ(id){apex.message.confirm("Delete this question? Past test results are kept.",function(ok){if(ok){apex.page.submit({request:"DELETE_Q",set:{P9_DELETE_ID:id},showWait:true});}});}
function fjAction(req,msg){apex.message.confirm(msg,function(ok){if(ok){apex.page.submit({request:req,showWait:true});}});}
function fjJobAction(req,id,msg){apex.message.confirm(msg,function(ok){if(ok){apex.page.submit({request:req,set:{P2_JOB_ID:String(id)},showWait:true});}});}
function fjRespond(req,id,msg,needNote){
  var n=document.getElementById("fj_note_"+id),v=n?n.value.trim():"";
  if(needNote&&!v){apex.message.alert("Please tell the employer which dates and times work for you.",function(){if(n){n.focus();}});return;}
  apex.message.confirm(msg,function(ok){if(ok){apex.page.submit({request:req,set:{P10_APP_ID:String(id),P10_NOTE:v},showWait:true});}});
}
function fjSubmitTest(total){
  var qs=document.querySelectorAll("#fj-test .fj-q"),ans=[],missing=0;
  qs.forEach(function(q){var c=q.querySelector("input:checked");q.classList.toggle("is-missing",!c);if(c){ans.push(c.getAttribute("data-qid")+":"+c.value);}else{missing++;}});
  function go(){apex.page.submit({request:"SUBMIT_TEST",set:{P13_ANSWERS:ans.join(",")},showWait:true});}
  apex.message.confirm(missing?("You have "+missing+" unanswered question"+(missing>1?"s":"")+". Submit anyway? You can only submit once."):"Submit your test? You can only submit once.",function(ok){if(ok){go();}});
}
function fjEnter(e,fn){if(e.key==="Enter"){e.preventDefault();fn();}}
document.addEventListener("DOMContentLoaded",function(){
  if(!window.apex||!apex.jQuery){return;}
  apex.jQuery(window).on("apexafterclosedialog",function(ev,data){
    if(document.getElementById("fj-admin")){apex.navigation.redirect(window.location.href);}
    else if(document.getElementById("fj-guest")){try{sessionStorage.setItem("fjMsg","Your application has been submitted. Track it under My Applications.");}catch(e){}apex.navigation.redirect(window.location.href);}
  });
  try{var m=sessionStorage.getItem("fjMsg");if(m){sessionStorage.removeItem("fjMsg");apex.message.showPageSuccess(m);}}catch(e){}
});
</script>~';
    return l;
  end assets;

  ------------------------------------------------------------------------------
  function login_left return clob is
  begin
    return '<div class="fj fj-login-left">'
        || '<img class="fj-logo" src="' || files || 'logo-employers.png" alt="FindJobs for employers">'
        || '<h1>Find the best candidates for your organisation.</h1>'
        || '<img class="fj-illus" src="' || files || 'login-illustration.png" alt="">'
        || '</div>';
  end login_left;

  function login_head return clob is
  begin
    return '<div class="fj">' || circles || '<h2>Login</h2></div>';
  end login_head;

  function login_button return clob is
  begin
    return '<div class="fj"><button type="button" class="fj-login-btn" onclick="apex.submit(''LOGIN'')">Login</button>'
        || '<p class="fj-auth-alt">Looking for a job? <a href="' || url(11) || '">Job seeker sign in</a></p></div>';
  end login_button;

  ------------------------------------------------------------------------------
  -- public site header (guest board, seeker pages) - adapts to who is signed in
  function site_header(p_title in varchar2, p_active in varchar2) return varchar2 is
    l_role varchar2(20) := fj_flow.current_role;
    l_user varchar2(255) := v('APP_USER');
    l_name varchar2(200);
    l_nav  varchar2(4000);
  begin
    l_nav := '<a' || case when p_active = 'JOBS' then ' class="is-active"' end || ' href="' || url(1, p_clear => '1') || '">Jobs</a>'
          || '<a href="#">Company Review</a><a href="#">Find Salaries</a>';
    if l_role = 'SEEKER' then
      select max(nvl(first_name, email)) into l_name from fj_users where email = lower(l_user);
      l_nav := l_nav || '<a' || case when p_active = 'MYAPPS' then ' class="is-active"' end || ' href="' || url(10) || '">My Applications</a>'
            || '<details class="fj-avatar fj-avatar--sm"><summary title="' || e(l_user) || '">' || e(upper(substr(l_name, 1, 1))) || '</summary>'
            || '<div class="fj-menu"><span>' || e(lower(l_user)) || '</span><a href="' || url(10) || '">My Applications</a>'
            || '<a href="' || logout_url || '">Sign out</a>'
            || '</div></details>';
    elsif l_role = 'ADMIN' then
      l_nav := l_nav || '<a class="fj-btn-white" href="' || url(5) || '">Dashboard</a>';
    else
      l_nav := l_nav || '<a href="' || url(11) || '">Sign in</a><a class="fj-btn-white" href="' || url(5) || '">Post Job</a>';
    end if;
    return '<header class="fj-hero"><div class="fj-wrap">'
        || '<div class="fj-nav"><a href="' || url(1, p_clear => '1') || '"><img src="' || files || 'logo.png" alt="FindJobs"></a>'
        || '<nav>' || l_nav || '</nav></div>'
        || '<h1>' || e(p_title) || '</h1></div>' || circles || '</header>';
  end site_header;

  function site_footer return varchar2 is
  begin
    return '<footer class="fj-footer"><div class="fj-wrap">'
        || '<div><img src="' || files || 'logo.png" alt="FindJobs"><small>&copy; 2021 <em>FindJobs</em></small></div>'
        || '<div><h5>Quick Links</h5><ul><li><a href="#">Home</a></li><li><a href="#">About</a></li><li><a href="#">Calendar</a></li><li><a href="#">Terms and condition</a></li></ul></div>'
        || '<div><h5>Quick Links</h5><ul><li><a href="#">Home</a></li><li><a href="#">About</a></li><li><a href="#">Calendar</a></li><li><a href="#">Terms and condition</a></li></ul></div>'
        || '<div><h5 style="font-weight:500">Social Media</h5>' || social || '</div>'
        || '</div></footer>';
  end site_footer;

  -- Apply button: seekers apply directly, everyone else signs in as a job seeker first
  function apply_button(p_job_id in number) return varchar2 is
    l_app_status varchar2(20);
  begin
    if fj_flow.current_role = 'SEEKER' then
      select max(status) into l_app_status
        from fj_applications
       where job_id = p_job_id and user_id = fj_flow.current_user_id;
      if l_app_status is not null then
        return '<a class="fj-btn-navy fj-btn-applied" href="' || url(10) || '">&#10003; Applied &middot; ' || e(fj_flow.status_label(l_app_status)) || '</a>';
      end if;
      return '<a class="fj-btn-navy" href="' || url(3, 'P3_JOB_ID', to_char(p_job_id), p_clear => '3') || '">Apply Via Find Job</a>';
    end if;
    return '<a class="fj-btn-navy" href="' || url(11, 'P11_JOB_ID', to_char(p_job_id), p_clear => '11') || '">Apply Via Find Job</a>';
  end apply_button;

  function status_pill(p_status in varchar2) return varchar2 is
  begin
    return '<span class="fj-status fj-status--' || lower(p_status) || '">' || e(fj_flow.status_label(p_status)) || '</span>';
  end status_pill;

  -- candidate's reply to an interview invitation
  function response_pill(p_response in varchar2) return varchar2 is
  begin
    return '<span class="fj-status fj-status--' || lower(p_response) || '">'
        || case p_response when 'CONFIRMED' then 'Confirmed' when 'RESCHEDULE' then 'New time requested' else 'Awaiting reply' end
        || '</span>';
  end response_pill;

  function fact(p_label in varchar2, p_value in varchar2) return varchar2 is
  begin
    return '<div class="fj-fact"><span>' || p_label || '</span><b>' || nvl(p_value, '&ndash;') || '</b></div>';
  end fact;

  -- interview details shared by the seeker card and the employer candidate page
  function interview_facts(p_at in date, p_mode in varchar2, p_location in varchar2, p_interviewer in varchar2) return varchar2 is
  begin
    return fact('When', e(fj_flow.format_when(p_at)))
        || fact('Type', e(fj_flow.mode_label(p_mode)))
        || case when p_location is not null then
             fact(case p_mode when 'VIDEO' then 'Meeting link' when 'PHONE' then 'Details' else 'Address' end,
                  case when regexp_like(p_location, '^https?://\S+$', 'i')
                       then '<a class="fj-count-link" href="' || e(p_location) || '" target="_blank" rel="noopener">' || e(p_location) || '</a>'
                       else e(p_location) end) end
        || case when p_interviewer is not null then fact('Interviewer', e(p_interviewer)) end;
  end interview_facts;

  function offer_facts(p_app_id in number, p_company in varchar2, p_salary in varchar2, p_start in date,
                       p_message in varchar2, p_letter_size in number, p_letter_name in varchar2) return varchar2 is
  begin
    return case when p_company is not null then fact('Company', e(p_company)) end
        || fact('Salary', e(p_salary))
        || fact('Start date', to_char(p_start, 'fmDay, DD Month YYYY'))
        || case when p_letter_size > 0 then
             fact('Offer letter', '<a class="fj-count-link" href="' || url(15, 'P15_ID', to_char(p_app_id)) || '">' || e(nvl(p_letter_name, 'Download')) || '</a>') end
        || case when p_message is not null then '<blockquote>' || e(p_message) || '</blockquote>' end;
  end offer_facts;

  ------------------------------------------------------------------------------
  -- job seeker sign in / sign up (pages 11, 12)
  function seeker_left return clob is
  begin
    return '<div class="fj fj-login-left fj-login-left--seeker">'
        || '<a href="' || url(1, p_clear => '1') || '"><img class="fj-logo" src="' || files || 'logo.png" alt="FindJobs"></a>'
        || '<h1>Find your dream job and get hired faster.</h1>'
        || '<img class="fj-illus" src="' || files || 'login-illustration.png" alt="">'
        || '</div>';
  end seeker_left;

  function seeker_login_head return clob is
  begin
    return '<div class="fj">' || circles || '<h2>Job Seeker Login</h2>'
        || '<p class="fj-auth-sub">New to FindJobs? <a href="' || url(12, 'P12_JOB_ID', v('P11_JOB_ID'), p_clear => '12') || '">Create an account</a></p></div>';
  end seeker_login_head;

  function seeker_login_button return clob is
  begin
    return '<div class="fj"><button type="button" class="fj-login-btn" onclick="apex.submit(''LOGIN'')">Login</button>'
        || '<p class="fj-auth-alt">Are you an employer? <a href="' || url(9999) || '">Employer sign in</a></p></div>';
  end seeker_login_button;

  function seeker_signup_head return clob is
  begin
    return '<div class="fj">' || circles || '<h2>Create Account</h2>'
        || '<p class="fj-auth-sub">Already have an account? <a href="' || url(11, 'P11_JOB_ID', v('P12_JOB_ID'), p_clear => '11') || '">Log in</a></p></div>';
  end seeker_signup_head;

  function seeker_signup_button return clob is
  begin
    return '<div class="fj"><button type="button" class="fj-login-btn" onclick="apex.page.submit({request:''SIGNUP'',validate:true,showWait:true})">Sign up</button></div>';
  end seeker_signup_button;

  ------------------------------------------------------------------------------
  -- page 10: job seeker's applications + notifications
  function my_apps_page return clob is
    l_user_id number := fj_flow.current_user_id;
    l_html    clob;
    l_n       pls_integer := 0;

    procedure add(p in varchar2) is
    begin
      l_html := l_html || p;
    end add;
  begin
    add('<div class="fj" id="fj-seeker">' || site_header('My Applications', 'MYAPPS') || '<div class="fj-wrap fj-seeker-wrap">');

    add('<section class="fj-panel fj-notes"><div class="fj-panel__head"><h3>Notifications</h3></div>');
    for n in (select * from fj_notifications where user_id = l_user_id order by created_at desc, id desc fetch first 8 rows only) loop
      l_n := l_n + 1;
      add('<div class="fj-note' || case when n.is_read = 'N' then ' is-unread' end || '"><b>' || e(n.title) || '</b>'
       || '<p>' || e(n.message) || '</p><time>' || to_char(n.created_at, 'fmDD Mon YYYY, HH:MI AM') || '</time></div>');
    end loop;
    if l_n = 0 then
      add('<div class="fj-empty">No notifications yet.</div>');
    end if;
    add('</section>');
    update fj_notifications set is_read = 'Y' where user_id = l_user_id and is_read = 'N';

    add('<div class="fj-apps">');
    l_n := 0;
    for a in (select a.*, j.title, j.location as job_location, j.salary_range, j.company_name,
                     dbms_lob.getlength(a.offer_letter) as letter_size
                from fj_applications a join fj_jobs j on j.id = a.job_id
               where a.user_id = l_user_id
               order by a.created_at desc) loop
      l_n := l_n + 1;
      add('<article class="fj-app"><div class="fj-app__top"><div><h3>' || e(a.title) || '</h3>'
       || '<div class="fj-loc">' || icon_pin || e(a.job_location) || ' &middot; ' || e(a.salary_range) || '</div></div>'
       || status_pill(a.status) || '</div>'
       || '<ol class="fj-steps">'
       || '<li class="is-done">Applied<small>' || to_char(a.created_at, 'fmDD Mon YYYY') || '</small></li>'
       || '<li class="' || case when a.shortlisted_at is not null then 'is-done' end || '">Shortlisted<small>' || to_char(a.shortlisted_at, 'fmDD Mon YYYY') || '</small></li>'
       || '<li class="' || case when a.test_submitted_at is not null then 'is-done' end || '">Aptitude test<small>' || to_char(a.test_submitted_at, 'fmDD Mon YYYY') || '</small></li>'
       || '<li class="' || case when a.interview_at is not null then 'is-done' end || '">Interview<small>' || to_char(a.interview_at, 'fmDD Mon YYYY') || '</small></li>'
       || '<li class="' || case when a.offered_at is not null then 'is-done' end || '">Offer<small>' || to_char(a.offered_at, 'fmDD Mon YYYY') || '</small></li>'
       || '<li class="' || case when a.hired_at is not null then 'is-done' end || '">Hired<small>' || to_char(a.hired_at, 'fmDD Mon YYYY') || '</small></li>'
       || '</ol><div class="fj-app__msg">');
      case a.status
        when 'APPLIED' then
          add('Your application is being reviewed by the employer. We will notify you when there is an update.');
        when 'SHORTLISTED' then
          add('You have been shortlisted! Take the aptitude test to move forward.'
           || '<a class="fj-btn-red fj-btn-test" href="' || url(13, 'P13_APP_ID', to_char(a.id), p_clear => '13') || '">Take aptitude test</a>');
        when 'TEST_SUBMITTED' then
          add('Thank you - your test was submitted on ' || to_char(a.test_submitted_at, 'fmDD Mon YYYY') || '. The employer is reviewing your result.');
        when 'PASSED' then
          add('<b>Congratulations!</b> You passed the aptitude test with a score of ' || a.test_score || '%. The employer will invite you to an interview soon.');
        when 'INTERVIEW_SCHEDULED' then
          add('<div class="fj-box"><h4>Your interview</h4>' || interview_facts(a.interview_at, a.interview_mode, a.interview_location, a.interviewer) || '</div>');
          if a.interview_response = 'PENDING' then
            add('<div class="fj-respond"><label for="fj_note_' || a.id || '">Message to the employer (required if you need another time)</label>'
             || '<textarea id="fj_note_' || a.id || '" maxlength="1000" placeholder="e.g. I can attend any time on Thursday or Friday afternoon."></textarea>'
             || '<button type="button" class="fj-btn-green" onclick="fjRespond(''CONFIRM_INTERVIEW'',' || a.id || ',''Confirm that you will attend this interview?'',false)">Confirm attendance</button>'
             || '<button type="button" class="fj-btn-outline" onclick="fjRespond(''RESCHEDULE_INTERVIEW'',' || a.id || ',''Ask the employer for another interview time?'',true)">Request another time</button></div>');
          elsif a.interview_response = 'CONFIRMED' then
            add('You confirmed that you will attend. Good luck!');
          else
            add('You asked for another time: &ldquo;' || e(a.interview_response_note) || '&rdquo; The employer will send you a new time.');
          end if;
        when 'INTERVIEWED' then
          add('<b>Great news!</b> You were successful in your interview. The employer is preparing a job offer for you.');
        when 'OFFERED' then
          add('<div class="fj-box"><h4>Your job offer</h4>' || offer_facts(a.id, a.company_name, a.offer_salary, a.offer_start_date, a.offer_message, a.letter_size, a.offer_letter_filename) || '</div>'
           || '<div class="fj-respond"><label for="fj_note_' || a.id || '">Message to the employer (optional)</label>'
           || '<textarea id="fj_note_' || a.id || '" maxlength="1000"></textarea>'
           || '<button type="button" class="fj-btn-green" onclick="fjRespond(''ACCEPT_OFFER'',' || a.id || ',''Accept this job offer?'',false)">Accept offer</button>'
           || '<button type="button" class="fj-btn-outline" onclick="fjRespond(''DECLINE_OFFER'',' || a.id || ',''Decline this job offer? This cannot be undone.'',false)">Decline</button></div>');
        when 'HIRED' then
          add('<b>Congratulations, you&rsquo;re hired!</b> You start on ' || to_char(a.offer_start_date, 'fmDay, DD Month YYYY')
           || '. The employer will contact you with your onboarding details.'
           || case when a.letter_size > 0 then '<a class="fj-cv" href="' || url(15, 'P15_ID', to_char(a.id)) || '">Download offer letter</a>' end);
        when 'OFFER_DECLINED' then
          add('You declined the offer for this role.');
        else
          add('The employer has decided not to move forward with this application'
           || case when a.test_score is not null and a.interviewed_at is null then ' (test score: ' || a.test_score || '%)' end || '.');
      end case;
      add('</div></article>');
    end loop;
    if l_n = 0 then
      add('<div class="fj-empty">You haven''t applied for any jobs yet. <a class="fj-count-link" href="' || url(1, p_clear => '1') || '">Browse jobs</a></div>');
    end if;
    add('</div></div>' || site_footer || '</div>');
    return l_html;
  end my_apps_page;

  ------------------------------------------------------------------------------
  -- page 13: aptitude test
  function test_page return clob is
    l_app_id   number := to_number(v('P13_APP_ID') default null on conversion error);
    l_html     clob;
    l_ok       boolean := false;
    l_test_job number;
    l_i        pls_integer := 0;
    l_total    number;

    procedure add(p in varchar2) is
    begin
      l_html := l_html || p;
    end add;

    function opt(p_qid in number, p_letter in varchar2, p_text in varchar2) return varchar2 is
    begin
      if p_text is null then
        return null;
      end if;
      return '<label class="fj-opt"><input type="radio" name="fjq_' || p_qid || '" value="' || p_letter || '" data-qid="' || p_qid || '">'
          || '<span class="fj-opt__key">' || p_letter || '</span><span>' || e(p_text) || '</span></label>';
    end opt;
  begin
    add('<div class="fj" id="fj-seeker">' || site_header('Aptitude Test', 'MYAPPS') || '<div class="fj-wrap fj-seeker-wrap">');
    for a in (select a.*, j.title, j.location as job_location
                from fj_applications a join fj_jobs j on j.id = a.job_id
               where a.id = l_app_id and a.user_id = fj_flow.current_user_id) loop
      if a.status <> 'SHORTLISTED' then
        add('<div class="fj-empty">This test has already been submitted or is not available. <a class="fj-count-link" href="' || url(10) || '">Back to My Applications</a></div>');
      else
        l_ok := true;
        l_test_job := fj_flow.test_job_id(a.job_id);
        l_total := fj_flow.question_count(l_test_job);
        add('<section class="fj-panel fj-test-intro"><h2>' || e(a.title) || '</h2><div class="fj-loc">' || icon_pin || e(a.job_location) || '</div>'
         || '<p>This test has <b>' || l_total || ' multiple-choice questions</b>. Choose one answer for each question, then select <b>Submit test</b>. '
         || 'You can only submit once, so check your answers before submitting.</p></section><div class="fj-test" id="fj-test">');
        for q in (select * from fj_test_questions
                   where (l_test_job is null and job_id is null) or job_id = l_test_job
                   order by seq, id) loop
          l_i := l_i + 1;
          add('<fieldset class="fj-q"><legend><span>Question ' || l_i || ' of ' || l_total || '</span>' || e(q.question) || '</legend>'
           || opt(q.id, 'A', q.option_a) || opt(q.id, 'B', q.option_b) || opt(q.id, 'C', q.option_c) || opt(q.id, 'D', q.option_d)
           || '</fieldset>');
        end loop;
        add('</div><button type="button" class="fj-btn-block fj-btn-submit-test" onclick="fjSubmitTest(' || l_total || ')">Submit test</button>');
      end if;
    end loop;
    if not l_ok and l_html not like '%fj-empty%' then
      add('<div class="fj-empty">Test not found. <a class="fj-count-link" href="' || url(10) || '">Back to My Applications</a></div>');
    end if;
    add('</div>' || site_footer || '</div>');
    return l_html;
  end test_page;

  ------------------------------------------------------------------------------
  function guest_page return clob is
    l_kw     varchar2(400) := trim(v('P1_KEYWORD'));
    l_loc    varchar2(400) := trim(v('P1_LOCATION'));
    l_sort   varchar2(20)  := nvl(v('P1_SORT'), 'LATEST');
    l_page   pls_integer   := greatest(nvl(to_number(v('P1_PAGE') default null on conversion error), 1), 1);
    l_job_id number        := to_number(v('P1_JOB_ID') default null on conversion error);
    l_total  number;
    l_first  number;
    l_html   clob;
    l_count  pls_integer := 0;

    procedure add(p in varchar2) is
    begin
      l_html := l_html || p;
    end add;
  begin
    select count(*)
      into l_total
      from fj_jobs j
     where j.is_filled = 'N'
       and (l_kw is null or instr(lower(j.title || ' ' || j.summary || ' ' || j.company_name || ' ' || j.sector), lower(l_kw)) > 0)
       and (l_loc is null or instr(lower(j.location), lower(regexp_replace(l_loc, ',\s*nigeria$', '', 1, 1, 'i'))) > 0);

    l_page := least(l_page, greatest(ceil(l_total / c_guest_page_size), 1));

    add('<div class="fj" id="fj-guest">' || site_header('Find Your Dream Job', 'JOBS')
     || '<div class="fj-wrap"><div class="fj-searchbar">'
     || '<label class="fj-field">' || icon_search
     || '<input id="fj_kw" type="text" placeholder="Job title or keyword" value="' || e(l_kw) || '" onkeydown="fjEnter(event,fjSearch)"></label>'
     || '<label class="fj-field">' || icon_pin
     || '<input id="fj_loc" type="text" placeholder="Location" value="' || e(nvl(l_loc, '')) || '" onkeydown="fjEnter(event,fjSearch)"></label>'
     || '<button type="button" class="fj-btn-red" onclick="fjSearch()">Search</button></div>'
     || '<div class="fj-results-head"><span>Showing ' || l_total || ' results</span>'
     || '<span><label for="fj_sort">Sort by:</label> <select id="fj_sort" onchange="fjSort(this.value)">'
     || '<option value="LATEST"' || case when l_sort = 'LATEST' then ' selected' end || '>Latest</option>'
     || '<option value="OLDEST"' || case when l_sort = 'OLDEST' then ' selected' end || '>Oldest</option>'
     || '<option value="TITLE"'  || case when l_sort = 'TITLE'  then ' selected' end || '>Title</option>'
     || '</select></span></div><div class="fj-grid"><div class="fj-list">');

    for r in (
      select j.*
        from fj_jobs j
       where j.is_filled = 'N'
         and (l_kw is null or instr(lower(j.title || ' ' || j.summary || ' ' || j.company_name || ' ' || j.sector), lower(l_kw)) > 0)
         and (l_loc is null or instr(lower(j.location), lower(regexp_replace(l_loc, ',\s*nigeria$', '', 1, 1, 'i'))) > 0)
       order by case when l_sort = 'TITLE' then lower(j.title) end,
                case when l_sort = 'OLDEST' then j.created_at end,
                case when l_sort not in ('OLDEST', 'TITLE') then j.created_at end desc,
                j.id desc
       offset (l_page - 1) * c_guest_page_size rows fetch next c_guest_page_size rows only
    ) loop
      l_count := l_count + 1;
      if l_count = 1 and (l_job_id is null) then
        l_first := r.id;
      end if;
      add('<a class="fj-card' || case when r.id = nvl(l_job_id, l_first) then ' is-active' end
       || '" href="' || url(1, 'P1_JOB_ID', to_char(r.id)) || '">'
       || '<div class="fj-card__top"><h3>' || e(r.title) || '</h3><span class="fj-salary">' || e(r.salary_range) || '</span></div>'
       || '<div class="fj-loc">' || icon_pin || e(r.location) || '</div>'
       || '<p>' || e(r.summary) || '</p><div class="fj-card__foot"><span class="fj-see-more">See more</span></div></a>');
    end loop;

    if l_count = 0 then
      add('<div class="fj-empty">No jobs match your search. Try a different keyword or location.</div>');
    end if;
    add('</div>');

    -- detail panel
    for d in (select * from fj_jobs where id = nvl(l_job_id, l_first) and is_filled = 'N') loop
      add('<aside class="fj-detail"><div class="fj-detail__head"><h2>' || e(d.title) || '</h2>'
       || '<div class="fj-loc">' || icon_pin || e(replace(d.location, ',', '')) || '</div>'
       || apply_button(d.id) || '</div>'
       || '<div class="fj-detail__body">');
      if d.description is not null then
        add('<p>' || e(d.description) || '</p>');
      end if;
      add('<ul class="fj-facts">'
       || case when d.min_qualification is not null then '<li>Minimum Qualification: ' || e(d.min_qualification) || '</li>' end
       || case when d.experience_level  is not null then '<li>Experience Level: ' || e(d.experience_level) || '</li>' end
       || case when d.experience_length is not null then '<li>Experience Length: ' || e(d.experience_length) || '</li>' end
       || case when d.employment_type   is not null then '<li>Employment Type: ' || e(d.employment_type) || '</li>' end
       || case when d.submission_deadline is not null then '<li>Submission Deadline: ' || to_char(d.submission_deadline, 'fmDD Mon YYYY') || '</li>' end
       || '</ul>');
      if d.requirements is not null then
        add('<h4>Job Description/Requirements</h4><ul>');
        for req in (select column_value as line from table(apex_string.split(d.requirements, chr(10))) where trim(column_value) is not null) loop
          add('<li>' || e(req.line) || '</li>');
        end loop;
        add('</ul>');
      end if;
      add('</div></aside>');
    end loop;

    add('</div>' || pagination(l_total, c_guest_page_size, l_page, 1, 'P1_PAGE') || '</div>');

    add('<footer class="fj-footer"><div class="fj-wrap">'
     || '<div><img src="' || files || 'logo.png" alt="FindJobs"><small>&copy; 2021 <em>FindJobs</em></small></div>'
     || '<div><h5>Quick Links</h5><ul><li><a href="#">Home</a></li><li><a href="#">About</a></li><li><a href="#">Calendar</a></li><li><a href="#">Terms and condition</a></li></ul></div>'
     || '<div><h5>Quick Links</h5><ul><li><a href="#">Home</a></li><li><a href="#">About</a></li><li><a href="#">Calendar</a></li><li><a href="#">Terms and condition</a></li></ul></div>'
     || '<div><h5 style="font-weight:500">Social Media</h5>' || social || '</div>'
     || '</div></footer></div>');
    return l_html;
  end guest_page;

  ------------------------------------------------------------------------------
  -- shared admin chrome (pages 2, 5, 6)
  function admin_header(p_title in varchar2, p_active in varchar2) return varchar2 is
    l_user   varchar2(255) := v('APP_USER');
    l_unread number;

    function tab(p_code in varchar2, p_page in number, p_label in varchar2) return varchar2 is
    begin
      return '<a href="' || url(p_page) || '"' || case when p_code = p_active then ' class="is-active" aria-current="page"' end
          || '>' || p_label || '</a>';
    end tab;
  begin
    select count(*) into l_unread from fj_notifications where user_id = fj_flow.current_user_id and is_read = 'N';
    return '<header class="fj-hero fj-hero--admin"><div class="fj-wrap">'
        || '<div class="fj-nav"><a href="' || url(5) || '"><img src="' || files || 'logo-employers.png" alt="FindJobs for employers"></a>'
        || '<nav class="fj-tabs">' || tab('DASH', 5, 'Dashboard') || tab('JOBS', 2, 'Jobs') || tab('CAND', 6, 'Candidates') || tab('TESTS', 9, 'Tests') || '</nav>'
        || '<div class="fj-userbar"><a class="fj-bell' || case when l_unread > 0 then ' has-new' end || '" href="' || url(5) || '#fj-updates" title="'
        || case when l_unread > 0 then l_unread || ' new candidate update' || case when l_unread <> 1 then 's' end else 'Candidate updates' end || '">'
        || '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#fff" stroke-width="1.6"><path d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2h-15z"/><path d="M10 20a2 2 0 0 0 4 0"/></svg></a>'
        || '<details class="fj-avatar"><summary title="' || e(l_user) || '">' || e(upper(substr(l_user, 1, 1))) || '</summary>'
        || '<div class="fj-menu"><span>' || e(lower(l_user)) || '</span>'
        || '<a href="' || url(1, p_clear => '1') || '">View job board</a>'
        || '<a href="' || logout_url || '">Sign out</a>'
        || '</div></details></div></div>'
        || '<h1>' || e(p_title) || '</h1></div>' || circles || '</header>';
  end admin_header;

  function admin_footer return varchar2 is
  begin
    return '<footer class="fj-footer fj-footer--admin"><div class="fj-wrap"><img src="' || files || 'logo.png" alt="FindJobs" style="height:28px">'
        || '<span>&copy; 2021 FindJobs</span><a href="#">Terms and condition</a>' || social || '</div></footer>';
  end admin_footer;

  ------------------------------------------------------------------------------
  function admin_page return clob is
    l_kw    varchar2(400) := trim(v('P2_SEARCH'));
    l_sort  varchar2(20)  := nvl(v('P2_SORT'), 'DEFAULT');
    l_page  pls_integer   := greatest(nvl(to_number(v('P2_PAGE') default null on conversion error), 1), 1);
    l_total number;
    l_html  clob;
    l_rows  pls_integer := 0;

    procedure add(p in varchar2) is
    begin
      l_html := l_html || p;
    end add;

    function sort_link(p_code in varchar2, p_label in varchar2) return varchar2 is
    begin
      return '<button type="button"' || case when p_code = l_sort then ' class="is-active"' end
          || ' onclick="fjAdminSort(''' || p_code || ''')">' || p_label || '</button>';
    end sort_link;
  begin
    select count(*) into l_total
      from fj_jobs
     where l_kw is null or instr(lower(title || ' ' || location || ' ' || company_name), lower(l_kw)) > 0;
    l_page := least(l_page, greatest(ceil(l_total / c_admin_page_size), 1));

    add('<div class="fj" id="fj-admin">' || admin_header('Jobs', 'JOBS')
     || '<div class="fj-wrap"><div class="fj-admin-tools"><div class="fj-searchbox">' || icon_search
     || '<input id="fj_admin_kw" type="text" placeholder="Search jobs" value="' || e(l_kw) || '" onkeydown="fjEnter(event,fjAdminSearch)">'
     || '<button type="button" class="fj-btn-red" onclick="fjAdminSearch()">Search</button></div>'
     || '<a class="fj-btn-coral" href="' || url(4, p_clear => '4') || '"><span style="font-size:18px;line-height:0">+</span> New Job</a></div>'
     || '<div class="fj-table" role="table"><div class="fj-trow fj-trow--head" role="row"><span></span><span>Job title</span><span>Date modified</span><span>Candidates</span><span></span>'
     || '<details class="fj-filter"><summary>Filter <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="#fff" stroke-width="2"><path d="M3 4h18l-7 8v6l-4 2v-8z"/></svg></summary>'
     || '<div class="fj-menu">' || sort_link('DEFAULT', 'Default order') || sort_link('MODIFIED', 'Recently modified') || sort_link('OLDEST', 'Oldest first')
     || sort_link('CANDIDATES', 'Most candidates') || sort_link('TITLE', 'Job title A-Z') || '</div></details></div>');

    for r in (
      select j.id, j.title, j.updated_at, j.is_filled,
             (select count(*) from fj_applications a where a.job_id = j.id) as candidates
        from fj_jobs j
       where l_kw is null or instr(lower(j.title || ' ' || j.location || ' ' || j.company_name), lower(l_kw)) > 0
       order by case when l_sort = 'TITLE' then lower(j.title) end,
                case when l_sort = 'OLDEST' then j.updated_at end,
                case when l_sort = 'CANDIDATES' then (select count(*) from fj_applications a where a.job_id = j.id) end desc,
                case when l_sort = 'MODIFIED' then j.updated_at end desc,
                j.id
       offset (l_page - 1) * c_admin_page_size rows fetch next c_admin_page_size rows only
    ) loop
      l_rows := l_rows + 1;
      add('<div class="fj-trow" role="row"><span class="fj-dot"></span><span>' || e(r.title)
       || case when r.is_filled = 'Y' then '<button type="button" class="fj-tag" title="Hidden from the job board. Click to reopen." onclick="fjJobAction(''REOPEN'','
               || r.id || ',' || apex_escape.js_literal('Reopen "' || r.title || '" and show it on the job board again?', '''') || ')">Filled</button>' end
       || '</span>'
       || '<span>' || to_char(r.updated_at, 'DD/fmMM/YY') || '</span>'
       || '<span><a class="fj-count-link" title="View candidates" href="' || url(6, 'P6_JOB_ID,P6_SEARCH,P6_STATUS,P6_PAGE', r.id || ',,,1') || '">' || r.candidates || '</a></span>'
       || '<a class="fj-act fj-act--edit" href="' || url(4, 'P4_ID', to_char(r.id), p_clear => '4') || '">Edit</a>'
       || '<button type="button" class="fj-act fj-act--del" onclick="fjDelete(' || r.id || ',' || apex_escape.js_literal(r.title, '''') || ')">Delete</button></div>');
    end loop;
    if l_rows = 0 then
      add('<div class="fj-empty">No jobs found.</div>');
    end if;

    add('</div>' || pagination(l_total, c_admin_page_size, l_page, 2, 'P2_PAGE') || '</div>'
     || admin_footer || '</div>');
    return l_html;
  end admin_page;

  ------------------------------------------------------------------------------
  function dashboard_page return clob is
    l_jobs   number;
    l_open   number;
    l_apps   number;
    l_recent number;
    l_apps7  number;
    l_int_week number;
    l_offers   number;
    l_hires    number;
    l_hires30  number;
    l_n        pls_integer;
    l_user_id  number := fj_flow.current_user_id;
    l_html   clob;

    procedure add(p in varchar2) is
    begin
      l_html := l_html || p;
    end add;

    function stat(p_mod in varchar2, p_label in varchar2, p_value in number, p_note in varchar2, p_href in varchar2) return varchar2 is
    begin
      return '<a class="fj-stat fj-stat--' || p_mod || '" href="' || p_href || '"><span class="fj-stat__label">' || p_label || '</span>'
          || '<strong>' || to_char(p_value, 'fm999G999G990') || '</strong><small>' || p_note || '</small></a>';
    end stat;
  begin
    select count(*),
           count(case when is_filled = 'N' and (submission_deadline is null or submission_deadline >= trunc(sysdate)) then 1 end),
           count(case when created_at >= trunc(sysdate) - 30 then 1 end)
      into l_jobs, l_open, l_recent
      from fj_jobs;
    select count(*), count(case when created_at >= trunc(sysdate) - 7 then 1 end),
           count(case when status = 'INTERVIEW_SCHEDULED' and interview_at >= trunc(sysdate, 'IW') and interview_at < trunc(sysdate, 'IW') + 7 then 1 end),
           count(case when status = 'OFFERED' then 1 end),
           count(case when status = 'HIRED' then 1 end),
           count(case when status = 'HIRED' and hired_at >= trunc(sysdate) - 30 then 1 end)
      into l_apps, l_apps7, l_int_week, l_offers, l_hires, l_hires30
      from fj_applications;

    add('<div class="fj" id="fj-admin">' || admin_header('Dashboard', 'DASH') || '<div class="fj-wrap">'
     || '<div class="fj-stats">'
     || stat('navy',  'Total jobs',         l_jobs,   'All jobs posted', url(2))
     || stat('teal',  'Open jobs',          l_open,   'Not filled, deadline not passed', url(2))
     || stat('coral', 'Total applications', l_apps,   l_apps7 || ' in the last 7 days', url(6, 'P6_JOB_ID,P6_SEARCH,P6_STATUS,P6_PAGE', ',,,1'))
     || stat('red',   'Recent jobs',        l_recent, 'Posted in the last 30 days', url(2, 'P2_SORT,P2_PAGE', 'MODIFIED,1'))
     || '</div><div class="fj-stats fj-stats--3">'
     || stat('blue',   'Interviews this week', l_int_week, 'Scheduled Monday to Sunday', url(6, 'P6_JOB_ID,P6_SEARCH,P6_STATUS,P6_PAGE', ',,INTERVIEW_SCHEDULED,1'))
     || stat('purple', 'Offers pending',       l_offers,   'Waiting for the candidate to reply', url(6, 'P6_JOB_ID,P6_SEARCH,P6_STATUS,P6_PAGE', ',,OFFERED,1'))
     || stat('green',  'Hires',                l_hires,    l_hires30 || ' in the last 30 days', url(6, 'P6_JOB_ID,P6_SEARCH,P6_STATUS,P6_PAGE', ',,HIRED,1'))
     || '</div><nav class="fj-pipeline" aria-label="Hiring pipeline">');
    for s in (select st.code, st.seq, count(a.id) as n
                from (select 'APPLIED' code, 1 seq from dual union all select 'SHORTLISTED', 2 from dual union all
                      select 'TEST_SUBMITTED', 3 from dual union all select 'PASSED', 4 from dual union all
                      select 'INTERVIEW_SCHEDULED', 5 from dual union all select 'INTERVIEWED', 6 from dual union all
                      select 'OFFERED', 7 from dual union all select 'HIRED', 8 from dual union all
                      select 'OFFER_DECLINED', 9 from dual union all select 'REJECTED', 10 from dual) st
                left join fj_applications a on a.status = st.code
               group by st.code, st.seq order by st.seq) loop
      add('<a class="fj-pipeline__step fj-pipeline__step--' || lower(s.code) || '" href="'
       || url(6, 'P6_JOB_ID,P6_SEARCH,P6_STATUS,P6_PAGE', ',,' || s.code || ',1') || '"><strong>' || to_char(s.n, 'fm999G990') || '</strong>'
       || '<span>' || case s.code when 'APPLIED' then 'Awaiting screening' when 'SHORTLISTED' then 'Test invited'
                                  when 'TEST_SUBMITTED' then 'Tests to score' when 'PASSED' then 'To interview'
                                  when 'INTERVIEW_SCHEDULED' then 'Interviewing' when 'INTERVIEWED' then 'Ready for offer'
                                  when 'OFFERED' then 'Offer sent' when 'HIRED' then 'Hired'
                                  when 'OFFER_DECLINED' then 'Offer declined' else 'Not selected' end || '</span></a>');
    end loop;
    add('</nav><div class="fj-dash-grid">');

    -- candidate replies to interviews and offers
    add('<section class="fj-panel" id="fj-updates"><div class="fj-panel__head"><h3>Candidate updates</h3></div>');
    l_n := 0;
    for n in (select * from fj_notifications where user_id = l_user_id order by created_at desc, id desc fetch first 6 rows only) loop
      l_n := l_n + 1;
      add('<a class="fj-panel__row' || case when n.is_read = 'N' then ' is-unread' end || '" href="' || url(8, 'P8_ID', to_char(n.application_id)) || '">'
       || '<div><b>' || e(n.title) || '</b><p>' || e(n.message) || '</p></div>'
       || '<time>' || to_char(n.created_at, 'fmDD Mon, HH:MI AM') || '</time></a>');
    end loop;
    if l_n = 0 then
      add('<div class="fj-empty">Candidate replies to interview invitations and offers will appear here.</div>');
    end if;
    add('</section>');
    update fj_notifications set is_read = 'Y' where user_id = l_user_id and is_read = 'N';

    add('<section class="fj-panel"><div class="fj-panel__head"><h3>Upcoming interviews</h3><a href="'
     || url(6, 'P6_JOB_ID,P6_SEARCH,P6_STATUS,P6_PAGE', ',,INTERVIEW_SCHEDULED,1') || '">View all</a></div>');
    l_n := 0;
    for r in (
      select a.id, a.first_name || ' ' || a.last_name as name, a.interview_at, a.interview_mode, a.interview_response, j.title
        from fj_applications a
        join fj_jobs j on j.id = a.job_id
       where a.status = 'INTERVIEW_SCHEDULED' and a.interview_at >= trunc(sysdate)
       order by a.interview_at
       fetch first 6 rows only
    ) loop
      l_n := l_n + 1;
      add('<a class="fj-panel__row" href="' || url(8, 'P8_ID', to_char(r.id)) || '"><div><b>' || e(r.name) || '</b>'
       || '<span>' || e(r.title) || ' &middot; ' || e(fj_flow.format_when(r.interview_at)) || ' &middot; ' || e(fj_flow.mode_label(r.interview_mode)) || '</span></div>'
       || response_pill(r.interview_response) || '</a>');
    end loop;
    if l_n = 0 then
      add('<div class="fj-empty">No upcoming interviews.</div>');
    end if;
    add('</section>');

    add('<section class="fj-panel"><div class="fj-panel__head"><h3>Recent jobs</h3><a href="' || url(2, 'P2_SORT,P2_PAGE', 'MODIFIED,1') || '">View all</a></div>');
    for r in (
      select j.id, j.title, j.location, j.created_at,
             (select count(*) from fj_applications a where a.job_id = j.id) as candidates
        from fj_jobs j
       order by j.created_at desc, j.id desc
       fetch first 6 rows only
    ) loop
      add('<div class="fj-panel__row"><div><b>' || e(r.title) || '</b><span>' || e(r.location) || ' &middot; posted ' || to_char(r.created_at, 'fmDD Mon YYYY') || '</span></div>'
       || '<a class="fj-pill" href="' || url(6, 'P6_JOB_ID,P6_SEARCH,P6_STATUS,P6_PAGE', r.id || ',,,1') || '">' || r.candidates || ' candidate' || case when r.candidates <> 1 then 's' end || '</a></div>');
    end loop;
    add('</section>');

    add('<section class="fj-panel"><div class="fj-panel__head"><h3>Latest applications</h3><a href="' || url(6, 'P6_JOB_ID,P6_SEARCH,P6_STATUS,P6_PAGE', ',,,1') || '">View all</a></div>');
    for r in (
      select a.id, a.first_name || ' ' || a.last_name as name, a.email, a.created_at, a.status, j.title
        from fj_applications a
        join fj_jobs j on j.id = a.job_id
       order by a.created_at desc, a.id desc
       fetch first 6 rows only
    ) loop
      add('<a class="fj-panel__row" href="' || url(8, 'P8_ID', to_char(r.id)) || '"><div><b>' || e(r.name) || '</b><span>' || e(r.title) || ' &middot; ' || e(r.email) || '</span></div>'
       || status_pill(r.status) || '</a>');
    end loop;
    if l_apps = 0 then
      add('<div class="fj-empty">No applications yet.</div>');
    end if;
    add('</section></div></div>' || admin_footer || '</div>');
    return l_html;
  end dashboard_page;

  ------------------------------------------------------------------------------
  function candidates_page return clob is
    l_kw     varchar2(400) := trim(v('P6_SEARCH'));
    l_job_id number        := to_number(v('P6_JOB_ID') default null on conversion error);
    l_status varchar2(20)  := v('P6_STATUS');
    l_page   pls_integer   := greatest(nvl(to_number(v('P6_PAGE') default null on conversion error), 1), 1);
    l_total  number;
    l_rows   pls_integer := 0;
    l_html   clob;

    procedure add(p in varchar2) is
    begin
      l_html := l_html || p;
    end add;

    function status_opt(p_code in varchar2) return varchar2 is
    begin
      return '<option value="' || p_code || '"' || case when p_code = l_status then ' selected' end || '>'
          || e(fj_flow.status_label(p_code)) || '</option>';
    end status_opt;
  begin
    select count(*) into l_total
      from fj_applications a
     where (l_job_id is null or a.job_id = l_job_id)
       and (l_status is null or a.status = l_status)
       and (l_kw is null or instr(lower(a.first_name || ' ' || a.last_name || ' ' || a.email || ' ' || a.phone || ' ' || a.location), lower(l_kw)) > 0);
    l_page := least(l_page, greatest(ceil(l_total / c_admin_page_size), 1));

    add('<div class="fj" id="fj-admin">' || admin_header('Candidates', 'CAND') || '<div class="fj-wrap">'
     || '<div class="fj-admin-tools"><div class="fj-searchbox">' || icon_search
     || '<input id="fj_cand_kw" type="text" placeholder="Search name, email or phone" value="' || e(l_kw) || '" onkeydown="fjEnter(event,fjCandSearch)">'
     || '<button type="button" class="fj-btn-red" onclick="fjCandSearch()">Search</button></div>'
     || '<label class="fj-select"><span>Job</span><select onchange="fjCandJob(this.value)"><option value="">All jobs</option>');
    for j in (select id, title, location from fj_jobs order by lower(title), location, id) loop
      add('<option value="' || j.id || '"' || case when j.id = l_job_id then ' selected' end || '>'
       || e(j.title) || ' &ndash; ' || e(j.location) || '</option>');
    end loop;
    add('</select></label><label class="fj-select"><span>Status</span><select onchange="fjCandStatus(this.value)"><option value="">All statuses</option>'
     || status_opt('APPLIED') || status_opt('SHORTLISTED') || status_opt('TEST_SUBMITTED') || status_opt('PASSED')
     || status_opt('INTERVIEW_SCHEDULED') || status_opt('INTERVIEWED') || status_opt('OFFERED') || status_opt('HIRED')
     || status_opt('OFFER_DECLINED') || status_opt('REJECTED')
     || '</select></label><span class="fj-count">' || to_char(l_total, 'fm999G999G990') || ' application' || case when l_total <> 1 then 's' end || '</span></div>'
     || '<div class="fj-table" role="table"><div class="fj-trow fj-trow--cand fj-trow--head" role="row">'
     || '<span>Candidate</span><span>Phone</span><span>Job applied for</span><span>Applied on</span><span>Status</span><span>Test score</span></div>');

    for r in (
      select a.id, a.first_name || ' ' || a.last_name as name, a.email, a.phone, a.created_at, a.status,
             a.test_score, a.test_auto_score, a.test_max_score,
             j.title, j.location as job_location
        from fj_applications a
        join fj_jobs j on j.id = a.job_id
       where (l_job_id is null or a.job_id = l_job_id)
         and (l_status is null or a.status = l_status)
         and (l_kw is null or instr(lower(a.first_name || ' ' || a.last_name || ' ' || a.email || ' ' || a.phone || ' ' || a.location), lower(l_kw)) > 0)
       order by a.created_at desc, a.id desc
       offset (l_page - 1) * c_admin_page_size rows fetch next c_admin_page_size rows only
    ) loop
      l_rows := l_rows + 1;
      add('<a class="fj-trow fj-trow--cand fj-trow--link" role="row" href="' || url(8, 'P8_ID', to_char(r.id)) || '" title="Open candidate">'
       || '<span class="fj-person"><b>' || e(r.name) || '</b><small>' || e(r.email) || '</small></span>'
       || '<span>' || nvl(e(r.phone), '&ndash;') || '</span>'
       || '<span class="fj-person"><b>' || e(r.title) || '</b><small>' || e(r.job_location) || '</small></span>'
       || '<span>' || to_char(r.created_at, 'fmDD Mon YYYY') || '</span>'
       || '<span>' || status_pill(r.status) || '</span>'
       || '<span>' || case when r.test_score is not null then r.test_score || '%'
                           when r.test_max_score > 0 then 'Auto ' || round(r.test_auto_score / r.test_max_score * 100) || '%'
                           else '<span class="fj-muted">&ndash;</span>' end || '</span>'
       || '</a>');
    end loop;
    if l_rows = 0 then
      add('<div class="fj-empty">No candidates found.</div>');
    end if;

    add('</div>' || pagination(l_total, c_admin_page_size, l_page, 6, 'P6_PAGE') || '</div>' || admin_footer || '</div>');
    return l_html;
  end candidates_page;

  ------------------------------------------------------------------------------
  -- page 8: candidate detail (top part: profile, job, CV, test answers)
  function candidate_top return clob is
    l_id   number := to_number(v('P8_ID') default null on conversion error);
    l_html clob;
    l_found boolean := false;

    procedure add(p in varchar2) is
    begin
      l_html := l_html || p;
    end add;

    function step(p_done in boolean, p_label in varchar2, p_note in varchar2) return varchar2 is
    begin
      return '<li' || case when p_done then ' class="is-done"' end || '>' || p_label || '<small>' || p_note || '</small></li>';
    end step;
  begin
    add('<div class="fj" id="fj-admin">' || admin_header('Candidate', 'CAND') || '<div class="fj-wrap">'
     || '<a class="fj-back" href="' || url(6) || '">&larr; All candidates</a>');
    for a in (select a.*, j.title, j.location as job_location, j.salary_range, j.employment_type, j.company_name,
                     dbms_lob.getlength(a.cv_blob) as cv_size, dbms_lob.getlength(a.offer_letter) as letter_size, u.id as account_id
                from fj_applications a
                join fj_jobs j on j.id = a.job_id
                left join fj_users u on u.id = a.user_id
               where a.id = l_id) loop
      l_found := true;
      add('<section class="fj-panel fj-cand-head"><div class="fj-avatar-lg">' || e(upper(substr(a.first_name, 1, 1) || substr(a.last_name, 1, 1))) || '</div>'
       || '<div class="fj-cand-head__main"><h2>' || e(a.first_name || ' ' || a.last_name) || '</h2>'
       || '<p>Applied for <b>' || e(a.title) || '</b> &middot; ' || e(a.job_location) || '</p></div>' || status_pill(a.status) || '</section>');

      add('<div class="fj-cand-grid"><div>'
       || '<section class="fj-panel fj-pad"><h3>Candidate details</h3><div class="fj-facts">'
       || fact('Email', '<a class="fj-count-link" href="mailto:' || e(a.email) || '">' || e(a.email) || '</a>')
       || fact('Phone', e(a.phone)) || fact('Location', e(a.location))
       || fact('Applied on', to_char(a.created_at, 'fmDD Mon YYYY, HH:MI AM'))
       || fact('Account', case when a.account_id is not null then 'Registered job seeker' else 'No account (legacy application)' end)
       || '</div></section>'
       || '<section class="fj-panel fj-pad"><h3>Job</h3><div class="fj-facts">'
       || fact('Title', e(a.title)) || fact('Company', e(a.company_name)) || fact('Location', e(a.job_location))
       || fact('Salary', e(a.salary_range)) || fact('Type', e(a.employment_type))
       || '</div></section>'
       || '<section class="fj-panel fj-pad"><h3>Progress</h3><ol class="fj-steps fj-steps--v">'
       || step(true, 'Applied', to_char(a.created_at, 'fmDD Mon YYYY'))
       || step(a.shortlisted_at is not null, 'Shortlisted &amp; test invited', to_char(a.shortlisted_at, 'fmDD Mon YYYY'))
       || step(a.test_submitted_at is not null, 'Test submitted', to_char(a.test_submitted_at, 'fmDD Mon YYYY'))
       || step(a.test_score is not null, 'Test scored', case when a.test_score is not null then a.test_score || '%' end)
       || step(a.interview_at is not null, 'Interview scheduled', case when a.interview_at is not null then e(fj_flow.format_when(a.interview_at)) end)
       || step(a.interviewed_at is not null, 'Interview result',
               case when a.interviewed_at is not null then a.interview_score || '% &middot; ' || to_char(a.interviewed_at, 'fmDD Mon YYYY') end)
       || step(a.offered_at is not null, 'Offer sent', to_char(a.offered_at, 'fmDD Mon YYYY'))
       || step(a.status in ('HIRED', 'OFFER_DECLINED', 'REJECTED'), 'Outcome',
               case when a.status in ('HIRED', 'OFFER_DECLINED', 'REJECTED')
                    then e(fj_flow.status_label(a.status)) || ' &middot; ' || to_char(coalesce(a.hired_at, a.offer_responded_at, a.decided_at), 'fmDD Mon YYYY') end)
       || '</ol></section></div>');

      add('<div>');
      -- interview
      if a.interview_at is not null then
        add('<section class="fj-panel fj-pad"><div class="fj-panel__head fj-panel__head--flush"><h3>Interview</h3>'
         || case when a.status = 'INTERVIEW_SCHEDULED' then response_pill(a.interview_response) end || '</div>'
         || '<div class="fj-facts">' || interview_facts(a.interview_at, a.interview_mode, a.interview_location, a.interviewer)
         || case when a.interviewed_at is not null then fact('Score', a.interview_score || '%') || fact('Notes', e(a.interview_notes)) end
         || '</div>'
         || case when a.interview_response_note is not null and a.status = 'INTERVIEW_SCHEDULED' then
              '<div class="fj-reply"><b>Candidate&rsquo;s message (' || to_char(a.interview_responded_at, 'fmDD Mon, HH:MI AM') || '):</b> '
              || e(a.interview_response_note) || '</div>' end
         || '</section>');
      end if;
      -- offer
      if a.offered_at is not null then
        add('<section class="fj-panel fj-pad"><div class="fj-panel__head fj-panel__head--flush"><h3>Offer</h3>'
         || case when a.status in ('OFFERED', 'HIRED', 'OFFER_DECLINED') then status_pill(a.status) end || '</div>'
         || '<div class="fj-facts">'
         || offer_facts(a.id, null, a.offer_salary, a.offer_start_date, a.offer_message, a.letter_size, a.offer_letter_filename)
         || fact('Sent', to_char(a.offered_at, 'fmDD Mon YYYY, HH:MI AM'))
         || case when a.offer_responded_at is not null then fact('Replied', to_char(a.offer_responded_at, 'fmDD Mon YYYY, HH:MI AM')) end
         || '</div>'
         || case when a.offer_response_note is not null then
              '<div class="fj-reply"><b>Candidate&rsquo;s message:</b> ' || e(a.offer_response_note) || '</div>' end
         || '</section>');
      end if;

      -- CV preview
      add('<section class="fj-panel fj-pad"><div class="fj-panel__head fj-panel__head--flush"><h3>CV</h3>');
      if a.cv_size > 0 then
        add('<a class="fj-cv" href="' || url(7, 'P7_ID,P7_INLINE', a.id || ',N') || '">Download ' || e(a.cv_filename) || '</a></div>');
        if lower(a.cv_mimetype) = 'application/pdf' then
          add('<iframe class="fj-cv-frame" title="CV preview" src="' || url(7, 'P7_ID,P7_INLINE', a.id || ',Y') || '"></iframe>');
        elsif lower(a.cv_mimetype) like 'image/%' then
          add('<img class="fj-cv-img" alt="CV preview" src="' || url(7, 'P7_ID,P7_INLINE', a.id || ',Y') || '">');
        elsif lower(a.cv_mimetype) like 'text/%' then
          add('<pre class="fj-cv-text">' || e(utl_raw.cast_to_varchar2(dbms_lob.substr(a.cv_blob, 3000, 1))) || '</pre>');
        else
          add('<div class="fj-empty">Preview is not available for this file type. Use Download to open it.</div>');
        end if;
      else
        add('</div><div class="fj-empty">No CV was uploaded with this application.</div>');
      end if;
      add('</section>');

      -- test answers
      if a.test_submitted_at is not null then
        add('<section class="fj-panel fj-pad"><div class="fj-panel__head fj-panel__head--flush"><h3>Aptitude test answers</h3>'
         || '<span class="fj-score">Auto-marked: <b>' || a.test_auto_score || ' / ' || a.test_max_score || '</b> ('
         || case when a.test_max_score > 0 then round(a.test_auto_score / a.test_max_score * 100) else 0 end || '%)</span></div><ol class="fj-answers">');
        for t in (select * from fj_test_answers where application_id = a.id order by seq) loop
          add('<li class="' || case when t.is_correct = 'Y' then 'is-right' else 'is-wrong' end || '"><p>' || e(t.question_text) || '</p>'
           || '<div><span>Answer: <b>' || nvl(e(t.chosen_option || '. ' || t.chosen_text), 'Not answered') || '</b></span>'
           || case when t.is_correct = 'Y' then '<em>&#10003; Correct</em>'
                   else '<em>&#10007; Correct answer: ' || e(t.correct_option || '. ' || t.correct_text) || '</em>' end
           || '</div></li>');
        end loop;
        add('</ol></section>');
      end if;
      add('</div></div>');
    end loop;
    if not l_found then
      add('<div class="fj-empty">Candidate not found.</div>');
    end if;
    add('</div></div>');
    return l_html;
  end candidate_top;

  -- page 8: action buttons under the screening form, depending on status
  function candidate_actions return clob is
    l_status    varchar2(20);
    l_name      varchar2(300);
    l_tested    date;
    l_interview date;
    l_offered   date;
    l_hired     date;
    l_filled    varchar2(1);
    l_job_title varchar2(400);
    l_html      varchar2(32767);

    function btn(p_class in varchar2, p_request in varchar2, p_label in varchar2, p_confirm in varchar2) return varchar2 is
    begin
      return '<button type="button" class="' || p_class || '" onclick="fjAction(''' || p_request || ''','
          || apex_escape.js_literal(p_confirm, '''') || ')">' || p_label || '</button>';
    end btn;
  begin
    select max(a.status), max(a.first_name || ' ' || a.last_name), max(a.test_submitted_at), max(a.interview_scheduled_at),
           max(a.offered_at), max(a.hired_at), max(j.is_filled), max(j.title)
      into l_status, l_name, l_tested, l_interview, l_offered, l_hired, l_filled, l_job_title
      from fj_applications a join fj_jobs j on j.id = a.job_id
     where a.id = to_number(v('P8_ID') default null on conversion error);
    if l_status is null then
      return '<div class="fj">' || admin_footer || '</div>';
    end if;
    l_html := '<div class="fj"><div class="fj-wrap"><div class="fj-actions">';
    if l_status = 'APPLIED' or (l_status = 'REJECTED' and l_tested is null) then
      l_html := l_html
        || btn('fj-btn-navy', 'SHORTLIST', 'Shortlist &amp; invite to test', 'Shortlist ' || l_name || ' and send them an invitation to take the aptitude test?')
        || case when l_status = 'APPLIED' then btn('fj-btn-outline', 'REJECT', 'Reject', 'Reject ' || l_name || '? They will be notified.') end;
    elsif l_status = 'SHORTLISTED' then
      l_html := l_html || '<p class="fj-hint">Invitation sent. Waiting for the candidate to take the aptitude test.</p>'
        || btn('fj-btn-outline', 'REJECT', 'Reject', 'Reject ' || l_name || '? They will be notified.');
    elsif l_status in ('TEST_SUBMITTED', 'PASSED') or (l_status = 'REJECTED' and l_interview is null) then
      l_html := l_html
        || case when l_status = 'PASSED' then
             btn('fj-btn-navy', 'SCHEDULE', 'Schedule interview &amp; notify', 'Invite ' || l_name || ' to an interview at the time entered above?') end
        || btn('fj-btn-green', 'PASS', case when l_status = 'TEST_SUBMITTED' then 'Pass candidate' else 'Mark test as passed' end,
               'Mark ' || l_name || ' as PASSED with the score entered above? They will be notified.')
        || btn('fj-btn-outline', 'FAIL', case when l_status = 'TEST_SUBMITTED' then 'Fail candidate' else 'Mark test as failed' end,
               'Mark ' || l_name || ' as NOT SELECTED with the score entered above? They will be notified.');
    elsif l_status = 'INTERVIEW_SCHEDULED' then
      l_html := l_html
        || btn('fj-btn-green', 'INTERVIEW_PASS', 'Passed interview', 'Record that ' || l_name || ' PASSED the interview with the score entered above? They will be notified.')
        || btn('fj-btn-outline', 'INTERVIEW_FAIL', 'Failed interview', 'Record that ' || l_name || ' did NOT pass the interview? They will be notified.')
        || btn('fj-btn-navy', 'SCHEDULE', 'Reschedule &amp; notify', 'Send ' || l_name || ' the new interview time entered above?');
    elsif l_status in ('INTERVIEWED', 'OFFER_DECLINED') then
      l_html := l_html
        || case when l_status = 'OFFER_DECLINED' then '<p class="fj-hint">The candidate declined the offer. You can send a revised offer.</p>' end
        || btn('fj-btn-green', 'OFFER', case when l_status = 'OFFER_DECLINED' then 'Send revised offer' else 'Send offer' end,
               'Send this job offer to ' || l_name || '?')
        || case when l_status = 'INTERVIEWED' then btn('fj-btn-outline', 'REJECT', 'Reject', 'Reject ' || l_name || '? They will be notified.') end;
    elsif l_status = 'OFFERED' then
      l_html := l_html || '<p class="fj-hint">Offer sent on ' || to_char(l_offered, 'fmDD Mon YYYY') || '. Waiting for the candidate to accept or decline.</p>'
        || btn('fj-btn-navy', 'OFFER', 'Update &amp; resend offer', 'Send the updated offer to ' || l_name || '?')
        || btn('fj-btn-outline', 'REJECT', 'Withdraw offer', 'Withdraw the offer to ' || l_name || '? They will be notified.');
    elsif l_status = 'HIRED' then
      l_html := l_html || '<p class="fj-hint">' || e(l_name) || ' accepted the offer on ' || to_char(l_hired, 'fmDD Mon YYYY') || '.'
        || case when l_filled = 'Y' then ' This job is marked as filled.' end || '</p>'
        || case when l_filled = 'N' then
             btn('fj-btn-navy', 'FILL_JOB', 'Mark job as filled', 'Mark "' || l_job_title || '" as filled? It will be removed from the job board, '
                 || 'and everyone still in the pipeline for this job will be told the position has been filled.') end;
    end if;
    l_html := l_html || '<button type="button" class="fj-btn-ghost" onclick="apex.page.submit({request:''SAVE_NOTES'',showWait:true})">Save notes</button>'
           || '</div></div>' || admin_footer || '</div>';
    return l_html;
  end candidate_actions;

  ------------------------------------------------------------------------------
  -- page 9: manage aptitude test questions
  function tests_page return clob is
    l_job_id number := to_number(v('P9_JOB_ID') default null on conversion error);
    l_html   clob;
    l_i      pls_integer := 0;
    l_title  varchar2(400);

    procedure add(p in varchar2) is
    begin
      l_html := l_html || p;
    end add;

    function opt(p_letter in varchar2, p_text in varchar2, p_correct in varchar2) return varchar2 is
    begin
      if p_text is null then
        return null;
      end if;
      return '<li' || case when p_letter = p_correct then ' class="is-correct"' end || '><b>' || p_letter || '</b> ' || e(p_text)
          || case when p_letter = p_correct then ' <em>&#10003; correct</em>' end || '</li>';
    end opt;
  begin
    if l_job_id is not null then
      select max(title || ' - ' || location) into l_title from fj_jobs where id = l_job_id;
    end if;
    add('<div class="fj" id="fj-admin">' || admin_header('Aptitude Tests', 'TESTS') || '<div class="fj-wrap">'
     || '<div class="fj-admin-tools"><label class="fj-select"><span>Test for</span><select onchange="fjTestJob(this.value)">'
     || '<option value="">General test (' || fj_flow.question_count(null) || ' questions)</option>');
    for j in (select id, title, location, (select count(*) from fj_test_questions q where q.job_id = j.id) as n
                from fj_jobs j order by lower(title), location, id) loop
      add('<option value="' || j.id || '"' || case when j.id = l_job_id then ' selected' end || '>' || e(j.title) || ' &ndash; ' || e(j.location)
       || ' (' || case when j.n = 0 then 'uses general test' else j.n || ' questions' end || ')</option>');
    end loop;
    add('</select></label><a class="fj-btn-coral" href="' || url(14, 'P14_JOB_ID', to_char(l_job_id), p_clear => '14')
     || '"><span style="font-size:18px;line-height:0">+</span> Add question</a></div>'
     || '<p class="fj-hint">' || case when l_job_id is null
          then 'The <b>general test</b> is used for every job that has no questions of its own.'
          else 'Questions for <b>' || e(l_title) || '</b>. ' || case when fj_flow.question_count(l_job_id) = 0
               then 'This job has no questions yet, so shortlisted candidates take the general test.' else 'Shortlisted candidates for this job take these questions.' end end
     || '</p><div class="fj-qlist">');
    for q in (select * from fj_test_questions
               where (l_job_id is null and job_id is null) or job_id = l_job_id
               order by seq, id) loop
      l_i := l_i + 1;
      add('<article class="fj-panel fj-qcard"><div class="fj-qcard__head"><span class="fj-qnum">Q' || l_i || '</span><p>' || e(q.question) || '</p>'
       || '<span class="fj-pill">' || q.points || ' pt' || case when q.points <> 1 then 's' end || '</span></div>'
       || '<ul>' || opt('A', q.option_a, q.correct_option) || opt('B', q.option_b, q.correct_option)
       || opt('C', q.option_c, q.correct_option) || opt('D', q.option_d, q.correct_option) || '</ul>'
       || '<div class="fj-qcard__actions"><a class="fj-act fj-act--edit" href="' || url(14, 'P14_ID', to_char(q.id), p_clear => '14') || '">Edit</a>'
       || '<button type="button" class="fj-act fj-act--del" onclick="fjDeleteQ(' || q.id || ')">Delete</button></div></article>');
    end loop;
    if l_i = 0 then
      add('<div class="fj-empty">No questions yet. Use <b>Add question</b> to create one.</div>');
    end if;
    add('</div></div>' || admin_footer || '</div>');
    return l_html;
  end tests_page;

  function question_head return clob is
  begin
    return '<div class="fj fj-dialog-head"><h2>' || case when v('P14_ID') is null then 'New Question' else 'Edit Question' end || '</h2>'
        || '<p>Multiple choice. Options C and D are optional. Choose which option is correct.</p></div>';
  end question_head;

  ------------------------------------------------------------------------------
  function apply_head return clob is
    l_html clob;
  begin
    for j in (select title, location from fj_jobs where id = to_number(v('P3_JOB_ID') default null on conversion error)) loop
      l_html := '<div class="fj fj-dialog-head"><h2>' || e(j.title) || '</h2><div class="fj-loc">' || icon_pin
             || e(replace(j.location, ',', '')) || '</div></div>';
    end loop;
    return nvl(l_html, to_clob('<div class="fj fj-dialog-head"><h2>Job not found</h2></div>'));
  end apply_head;

  function job_head return clob is
  begin
    return '<div class="fj fj-dialog-head"><h2>' || case when v('P4_ID') is null then 'New Job' else 'Edit Job' end || '</h2>'
        || '<p>Kindly provide the required information to get matched with suitable condidates</p></div>';
  end job_head;

  function submit_button(p_label in varchar2) return clob is
  begin
    return '<div class="fj"><button type="button" class="fj-btn-block" onclick="apex.page.submit({request:''SUBMIT'',validate:true,showWait:true})">'
        || e(p_label) || '</button></div>';
  end submit_button;

end fj_ui;
/