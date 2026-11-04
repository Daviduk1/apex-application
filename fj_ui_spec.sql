create or replace package fj_ui as
  function assets       return clob;  -- global CSS + JS (page 0)
  function login_left   return clob;  -- page 9999 left panel
  function login_head   return clob;  -- page 9999 "Login" heading + decorations
  function login_button return clob;  -- page 9999 Login button
  function guest_page   return clob;  -- page 1
  function admin_page   return clob;  -- page 2
  function dashboard_page  return clob;  -- page 5
  function candidates_page return clob;  -- page 6
  function candidate_top     return clob;  -- page 8 (profile, CV, answers)
  function candidate_actions return clob;  -- page 8 (action buttons)
  function tests_page        return clob;  -- page 9
  function my_apps_page      return clob;  -- page 10
  function seeker_left          return clob;  -- pages 11/12 left panel
  function seeker_login_head    return clob;  -- page 11
  function seeker_login_button  return clob;  -- page 11
  function seeker_signup_head   return clob;  -- page 12
  function seeker_signup_button return clob;  -- page 12
  function test_page         return clob;  -- page 13
  function question_head     return clob;  -- page 14 header
  function apply_head   return clob;  -- page 3 header
  function job_head     return clob;  -- page 4 header
  function submit_button(p_label in varchar2) return clob;
end fj_ui;
/