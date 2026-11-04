create or replace package fj_flow as
  c_mail_from constant varchar2(255) := 'no-reply@findjobs.app';

  function current_user_id return number;
  function current_role return varchar2;
  function is_admin return boolean;
  function is_seeker return boolean;
  function status_label(p_status in varchar2) return varchar2;
  function mode_label(p_mode in varchar2) return varchar2;
  function format_when(p_date in date) return varchar2;    -- "Tuesday, 4 November 2026 at 10:00 AM"
  function test_job_id(p_job_id in number) return number;   -- job id if it has its own questions, else null (general)
  function question_count(p_job_id in number) return number;

  procedure signup(p_email in varchar2, p_password in varchar2, p_first_name in varchar2,
                   p_last_name in varchar2, p_phone in varchar2, p_location in varchar2);
  procedure notify(p_application_id in number, p_title in varchar2, p_message in varchar2);
  procedure notify_employers(p_application_id in number, p_title in varchar2, p_message in varchar2);
  procedure shortlist(p_application_id in number, p_notes in varchar2);
  procedure reject(p_application_id in number, p_notes in varchar2);
  procedure submit_test(p_application_id in number, p_answers in varchar2);   -- "questionId:Option,..."
  procedure decide(p_application_id in number, p_score in varchar2, p_passed in boolean, p_notes in varchar2);
  procedure schedule_interview(p_application_id in number, p_at in date, p_mode in varchar2,
                               p_location in varchar2, p_interviewer in varchar2);
  procedure respond_interview(p_application_id in number, p_confirm in boolean, p_note in varchar2);
  procedure record_interview(p_application_id in number, p_score in varchar2, p_passed in boolean, p_notes in varchar2);
  procedure send_offer(p_application_id in number, p_salary in varchar2, p_start_date in date,
                       p_message in varchar2, p_letter in varchar2);   -- p_letter: name in apex_application_temp_files
  procedure respond_offer(p_application_id in number, p_accept in boolean, p_note in varchar2);
  procedure fill_job(p_job_id in number);     -- mark filled, close and notify everyone still in the pipeline
  procedure reopen_job(p_job_id in number);
end fj_flow;
/