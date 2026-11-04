create or replace package fj_auth as
  function hash_password(p_email in varchar2, p_password in varchar2) return varchar2;
  function authenticate(p_username in varchar2, p_password in varchar2) return boolean;
  procedure create_user(p_email in varchar2, p_password in varchar2, p_full_name in varchar2 default null);
  procedure set_password(p_email in varchar2, p_password in varchar2);
end fj_auth;
/