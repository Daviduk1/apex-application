create or replace package body fj_auth as
  c_pepper constant varchar2(64) := 'FJ$7q!Lr2#Zx9vKp';

  function hash_password(p_email in varchar2, p_password in varchar2) return varchar2 is
    l_hash varchar2(128);
  begin
    select rawtohex(standard_hash(lower(trim(p_email)) || '|' || p_password || '|' || c_pepper, 'SHA256'))
      into l_hash
      from dual;
    return l_hash;
  end hash_password;

  function authenticate(p_username in varchar2, p_password in varchar2) return boolean is
    l_stored fj_users.password_hash%type;
  begin
    select password_hash
      into l_stored
      from fj_users
     where email = lower(trim(p_username));
    return l_stored = hash_password(p_username, p_password);
  exception
    when no_data_found then
      return false;
  end authenticate;

  procedure create_user(p_email in varchar2, p_password in varchar2, p_full_name in varchar2 default null) is
  begin
    insert into fj_users (email, full_name, password_hash)
    values (lower(trim(p_email)), p_full_name, hash_password(p_email, p_password));
  end create_user;

  procedure set_password(p_email in varchar2, p_password in varchar2) is
  begin
    update fj_users
       set password_hash = hash_password(p_email, p_password)
     where email = lower(trim(p_email));
  end set_password;
end fj_auth;
/