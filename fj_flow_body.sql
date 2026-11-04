create or replace package body fj_flow as

  function current_user_id return number is
    l_id number;
  begin
    select max(id) into l_id from fj_users where email = lower(v('APP_USER'));
    return l_id;
  end current_user_id;

  function current_role return varchar2 is
    l_role varchar2(20);
  begin
    select max(role) into l_role from fj_users where email = lower(v('APP_USER'));
    return l_role;
  end current_role;

  function is_admin return boolean is
  begin
    return current_role = 'ADMIN';
  end is_admin;

  function is_seeker return boolean is
  begin
    return current_role = 'SEEKER';
  end is_seeker;

  function status_label(p_status in varchar2) return varchar2 is
  begin
    return case p_status
             when 'APPLIED'             then 'Under review'
             when 'SHORTLISTED'         then 'Shortlisted - test pending'
             when 'TEST_SUBMITTED'      then 'Test submitted'
             when 'PASSED'              then 'Test passed'
             when 'INTERVIEW_SCHEDULED' then 'Interview scheduled'
             when 'INTERVIEWED'         then 'Interview passed'
             when 'OFFERED'             then 'Offer made'
             when 'HIRED'               then 'Hired'
             when 'OFFER_DECLINED'      then 'Offer declined'
             when 'REJECTED'            then 'Not selected'
             else initcap(p_status)
           end;
  end status_label;

  function mode_label(p_mode in varchar2) return varchar2 is
  begin
    return case p_mode when 'IN_PERSON' then 'In person' when 'VIDEO' then 'Video call' when 'PHONE' then 'Phone call' end;
  end mode_label;

  function format_when(p_date in date) return varchar2 is
  begin
    return to_char(p_date, 'fmDay, DD Month YYYY') || ' at ' || ltrim(to_char(p_date, 'HH:MI AM'), '0');
  end format_when;

  function test_job_id(p_job_id in number) return number is
    l_n number;
  begin
    select count(*) into l_n from fj_test_questions where job_id = p_job_id;
    return case when l_n > 0 then p_job_id end;
  end test_job_id;

  function question_count(p_job_id in number) return number is
    l_n number;
  begin
    select count(*) into l_n from fj_test_questions
     where (p_job_id is null and job_id is null) or job_id = p_job_id;
    return l_n;
  end question_count;

  -- seekers may only act on their own applications
  procedure check_owner(p_app in fj_applications%rowtype) is
  begin
    if p_app.user_id is null or p_app.user_id <> current_user_id then
      raise_application_error(-20001, 'This application does not belong to your account.');
    end if;
  end check_owner;

  procedure signup(p_email in varchar2, p_password in varchar2, p_first_name in varchar2,
                   p_last_name in varchar2, p_phone in varchar2, p_location in varchar2) is
    l_email fj_users.email%type := lower(trim(p_email));
    l_n     number;
  begin
    if l_email is null or not regexp_like(l_email, '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$') then
      raise_application_error(-20001, 'Please enter a valid email address.');
    end if;
    if p_password is null or length(p_password) < 8 then
      raise_application_error(-20001, 'Your password must be at least 8 characters long.');
    end if;
    select count(*) into l_n from fj_users where email = l_email;
    if l_n > 0 then
      raise_application_error(-20001, 'An account with this email already exists. Please log in instead.');
    end if;
    insert into fj_users (email, full_name, password_hash, role, first_name, last_name, phone, location)
    values (l_email, trim(p_first_name || ' ' || p_last_name), fj_auth.hash_password(l_email, p_password),
            'SEEKER', trim(p_first_name), trim(p_last_name), trim(p_phone), trim(p_location));
  end signup;

  procedure notify(p_application_id in number, p_title in varchar2, p_message in varchar2) is
    l_notif_id number;
    l_status   varchar2(100);
  begin
    for a in (select a.user_id, coalesce(u.email, a.email) as email, a.first_name
                from fj_applications a
                left join fj_users u on u.id = a.user_id
               where a.id = p_application_id) loop
      insert into fj_notifications (user_id, application_id, recipient_email, title, message)
      values (a.user_id, p_application_id, a.email, p_title, substr(p_message, 1, 2000))
      returning id into l_notif_id;

      begin
        apex_mail.send(
          p_to        => a.email,
          p_from      => c_mail_from,
          p_subj      => 'FindJobs: ' || p_title,
          p_body      => 'Hi ' || a.first_name || ',' || chr(10) || chr(10) || p_message || chr(10) || chr(10)
                         || 'Log in to FindJobs and open "My Applications" to see the details.' || chr(10) || chr(10) || 'The FindJobs team',
          p_body_html => '<p>Hi ' || apex_escape.html(a.first_name) || ',</p><p>' || apex_escape.html(p_message) || '</p>'
                         || '<p>Log in to FindJobs and open <b>My Applications</b> to see the details.</p><p>The FindJobs team</p>');
        l_status := 'QUEUED';
      exception
        when others then
          l_status := substr('FAILED: ' || sqlerrm, 1, 100);
      end;
      update fj_notifications set email_status = l_status where id = l_notif_id;
    end loop;
  end notify;

  -- candidate replies (interview / offer) go to every employer account
  procedure notify_employers(p_application_id in number, p_title in varchar2, p_message in varchar2) is
    l_notif_id number;
    l_status   varchar2(100);
  begin
    for u in (select id, email, nvl(first_name, 'there') as first_name from fj_users where role = 'ADMIN') loop
      insert into fj_notifications (user_id, application_id, recipient_email, title, message)
      values (u.id, p_application_id, u.email, p_title, substr(p_message, 1, 2000))
      returning id into l_notif_id;

      begin
        apex_mail.send(
          p_to        => u.email,
          p_from      => c_mail_from,
          p_subj      => 'FindJobs: ' || p_title,
          p_body      => 'Hi ' || u.first_name || ',' || chr(10) || chr(10) || p_message || chr(10) || chr(10)
                         || 'Log in to FindJobs for employers and open the candidate to see the details.' || chr(10) || chr(10) || 'FindJobs',
          p_body_html => '<p>Hi ' || apex_escape.html(u.first_name) || ',</p><p>' || apex_escape.html(p_message) || '</p>'
                         || '<p>Log in to FindJobs for employers and open the candidate to see the details.</p><p>FindJobs</p>');
        l_status := 'QUEUED';
      exception
        when others then
          l_status := substr('FAILED: ' || sqlerrm, 1, 100);
      end;
      update fj_notifications set email_status = l_status where id = l_notif_id;
    end loop;
  end notify_employers;

  procedure shortlist(p_application_id in number, p_notes in varchar2) is
    l_job_id number;
    l_title  fj_jobs.title%type;
    l_status fj_applications.status%type;
  begin
    select a.job_id, j.title, a.status into l_job_id, l_title, l_status
      from fj_applications a join fj_jobs j on j.id = a.job_id
     where a.id = p_application_id;
    if l_status not in ('APPLIED', 'REJECTED') then
      raise_application_error(-20001, 'This candidate has already been shortlisted.');
    end if;
    if question_count(test_job_id(l_job_id)) = 0 then
      raise_application_error(-20001, 'There are no aptitude test questions yet. Add questions under Tests before shortlisting.');
    end if;
    update fj_applications
       set status = 'SHORTLISTED', shortlisted_at = sysdate, decided_at = null,
           screening_notes = p_notes
     where id = p_application_id;
    notify(p_application_id, 'You have been shortlisted',
           'Good news! Your application for "' || l_title || '" has been shortlisted. '
           || 'Please log in to FindJobs and take the aptitude test from My Applications.');
  end shortlist;

  procedure reject(p_application_id in number, p_notes in varchar2) is
    l_title fj_jobs.title%type;
  begin
    select j.title into l_title
      from fj_applications a join fj_jobs j on j.id = a.job_id
     where a.id = p_application_id;
    update fj_applications
       set status = 'REJECTED', decided_at = sysdate, screening_notes = p_notes
     where id = p_application_id;
    notify(p_application_id, 'Update on your application',
           'Thank you for applying for "' || l_title || '". After careful review, we will not be moving forward '
           || 'with your application at this time. We wish you the best in your job search.');
  end reject;

  procedure submit_test(p_application_id in number, p_answers in varchar2) is
    l_app      fj_applications%rowtype;
    l_test_job number;
    l_choice   varchar2(1);
    l_auto     number := 0;
    l_max      number := 0;
    l_seq      pls_integer := 0;
    l_answers  apex_t_varchar2 := apex_string.split(p_answers, ',');
  begin
    select * into l_app from fj_applications where id = p_application_id for update;
    check_owner(l_app);
    if l_app.status <> 'SHORTLISTED' then
      raise_application_error(-20001, 'This test has already been submitted or is no longer available.');
    end if;

    l_test_job := test_job_id(l_app.job_id);
    for q in (select * from fj_test_questions
               where (l_test_job is null and job_id is null) or job_id = l_test_job
               order by seq, id) loop
      l_seq    := l_seq + 1;
      l_choice := null;
      for i in 1 .. l_answers.count loop
        if l_answers(i) like q.id || ':%' then
          l_choice := upper(substr(l_answers(i), instr(l_answers(i), ':') + 1, 1));
        end if;
      end loop;
      l_max := l_max + q.points;
      if l_choice = q.correct_option then
        l_auto := l_auto + q.points;
      end if;
      insert into fj_test_answers (application_id, question_id, seq, question_text, chosen_option, chosen_text,
                                   correct_option, correct_text, points, is_correct)
      values (p_application_id, q.id, l_seq, q.question, l_choice,
              case l_choice when 'A' then q.option_a when 'B' then q.option_b when 'C' then q.option_c when 'D' then q.option_d end,
              q.correct_option,
              case q.correct_option when 'A' then q.option_a when 'B' then q.option_b when 'C' then q.option_c when 'D' then q.option_d end,
              q.points, case when l_choice = q.correct_option then 'Y' else 'N' end);
    end loop;

    update fj_applications
       set status = 'TEST_SUBMITTED', test_submitted_at = sysdate,
           test_auto_score = l_auto, test_max_score = l_max
     where id = p_application_id;
  end submit_test;

  procedure decide(p_application_id in number, p_score in varchar2, p_passed in boolean, p_notes in varchar2) is
    l_score     number := to_number(trim(replace(p_score, '%')) default null on conversion error);
    l_title     fj_jobs.title%type;
    l_status    fj_applications.status%type;
    l_interview date;
  begin
    if l_score is null or l_score < 0 or l_score > 100 then
      raise_application_error(-20001, 'Enter a final test score between 0 and 100.');
    end if;
    select j.title, a.status, a.interview_scheduled_at into l_title, l_status, l_interview
      from fj_applications a join fj_jobs j on j.id = a.job_id
     where a.id = p_application_id;
    if l_status not in ('TEST_SUBMITTED', 'PASSED', 'REJECTED') or l_interview is not null then
      raise_application_error(-20001, 'The aptitude test result can no longer be changed for this candidate.');
    end if;
    update fj_applications
       set status = case when p_passed then 'PASSED' else 'REJECTED' end,
           test_score = l_score, decided_at = sysdate, screening_notes = p_notes
     where id = p_application_id;
    if p_passed then
      notify(p_application_id, 'You passed the aptitude test',
             'Congratulations! You passed the aptitude test for "' || l_title || '" with a score of ' || l_score
             || '%. The employer will invite you to an interview soon.');
    else
      notify(p_application_id, 'Your aptitude test result',
             'Thank you for taking the aptitude test for "' || l_title || '". Your score was ' || l_score
             || '%, which did not meet the requirement for this role. We encourage you to apply for other roles on FindJobs.');
    end if;
  end decide;

  procedure schedule_interview(p_application_id in number, p_at in date, p_mode in varchar2,
                               p_location in varchar2, p_interviewer in varchar2) is
    l_title    fj_jobs.title%type;
    l_status   fj_applications.status%type;
    l_mode     varchar2(20) := upper(p_mode);
    l_location varchar2(500) := trim(p_location);
  begin
    if p_at is null then
      raise_application_error(-20001, 'Choose the interview date and time.');
    end if;
    if p_at < trunc(sysdate) then
      raise_application_error(-20001, 'The interview date cannot be in the past.');
    end if;
    if l_mode is null or l_mode not in ('IN_PERSON', 'VIDEO', 'PHONE') then
      raise_application_error(-20001, 'Choose how the interview will take place.');
    end if;
    if l_mode in ('IN_PERSON', 'VIDEO') and l_location is null then
      raise_application_error(-20001, case l_mode when 'VIDEO' then 'Enter the video meeting link.' else 'Enter the interview address.' end);
    end if;
    select j.title, a.status into l_title, l_status
      from fj_applications a join fj_jobs j on j.id = a.job_id
     where a.id = p_application_id;
    if l_status not in ('PASSED', 'INTERVIEW_SCHEDULED') then
      raise_application_error(-20001, 'Only candidates who passed the aptitude test can be invited to an interview.');
    end if;
    update fj_applications
       set status = 'INTERVIEW_SCHEDULED', interview_at = p_at, interview_mode = l_mode,
           interview_location = l_location, interviewer = trim(p_interviewer),
           interview_scheduled_at = sysdate, interview_response = 'PENDING',
           interview_response_note = null, interview_responded_at = null
     where id = p_application_id;
    notify(p_application_id,
           case when l_status = 'INTERVIEW_SCHEDULED' then 'Your interview has been rescheduled' else 'Interview invitation' end,
           case when l_status = 'INTERVIEW_SCHEDULED' then 'Your interview for "' || l_title || '" has a new time. '
                else 'Congratulations! You are invited to an interview for "' || l_title || '". ' end
           || 'When: ' || format_when(p_at) || '. Type: ' || mode_label(l_mode) || '.'
           || case when l_location is not null then
                ' ' || case l_mode when 'VIDEO' then 'Meeting link' when 'PHONE' then 'Details' else 'Address' end || ': ' || l_location || '.' end
           || case when trim(p_interviewer) is not null then ' Interviewer: ' || trim(p_interviewer) || '.' end
           || ' Please log in to FindJobs to confirm your attendance or request another time.');
  end schedule_interview;

  procedure respond_interview(p_application_id in number, p_confirm in boolean, p_note in varchar2) is
    l_app   fj_applications%rowtype;
    l_title fj_jobs.title%type;
    l_note  varchar2(1000) := substr(trim(p_note), 1, 1000);
  begin
    select * into l_app from fj_applications where id = p_application_id for update;
    check_owner(l_app);
    if l_app.status <> 'INTERVIEW_SCHEDULED' then
      raise_application_error(-20001, 'This interview is no longer open for a response.');
    end if;
    if not p_confirm and l_note is null then
      raise_application_error(-20001, 'Please tell the employer which dates and times work for you.');
    end if;
    select title into l_title from fj_jobs where id = l_app.job_id;
    update fj_applications
       set interview_response = case when p_confirm then 'CONFIRMED' else 'RESCHEDULE' end,
           interview_response_note = l_note, interview_responded_at = sysdate
     where id = p_application_id;
    if p_confirm then
      notify_employers(p_application_id, 'Interview confirmed',
        l_app.first_name || ' ' || l_app.last_name || ' confirmed the interview for "' || l_title || '" on '
        || format_when(l_app.interview_at) || '.' || case when l_note is not null then ' Message: ' || l_note end);
    else
      notify_employers(p_application_id, 'New interview time requested',
        l_app.first_name || ' ' || l_app.last_name || ' cannot attend the interview for "' || l_title || '" on '
        || format_when(l_app.interview_at) || ' and asked for another time: ' || l_note);
    end if;
  end respond_interview;

  procedure record_interview(p_application_id in number, p_score in varchar2, p_passed in boolean, p_notes in varchar2) is
    l_score  number := to_number(trim(replace(p_score, '%')) default null on conversion error);
    l_title  fj_jobs.title%type;
    l_status fj_applications.status%type;
  begin
    if l_score is null or l_score < 0 or l_score > 100 then
      raise_application_error(-20001, 'Enter an interview score between 0 and 100.');
    end if;
    select j.title, a.status into l_title, l_status
      from fj_applications a join fj_jobs j on j.id = a.job_id
     where a.id = p_application_id;
    if l_status <> 'INTERVIEW_SCHEDULED' then
      raise_application_error(-20001, 'There is no scheduled interview to record a result for.');
    end if;
    update fj_applications
       set status = case when p_passed then 'INTERVIEWED' else 'REJECTED' end,
           interview_score = l_score, interview_notes = p_notes, interviewed_at = sysdate,
           decided_at = case when p_passed then decided_at else sysdate end
     where id = p_application_id;
    if p_passed then
      notify(p_application_id, 'Interview result',
             'Great news! You were successful in your interview for "' || l_title || '". '
             || 'The employer is preparing a job offer for you.');
    else
      notify(p_application_id, 'Interview result',
             'Thank you for attending the interview for "' || l_title || '". After careful consideration, we will not be moving '
             || 'forward with your application. We wish you the best in your job search.');
    end if;
  end record_interview;

  procedure send_offer(p_application_id in number, p_salary in varchar2, p_start_date in date,
                       p_message in varchar2, p_letter in varchar2) is
    l_title   fj_jobs.title%type;
    l_company fj_jobs.company_name%type;
    l_status  fj_applications.status%type;
    l_salary  varchar2(200) := trim(p_salary);
  begin
    if l_salary is null then
      raise_application_error(-20001, 'Enter the salary being offered.');
    end if;
    if p_start_date is null then
      raise_application_error(-20001, 'Choose the start date.');
    end if;
    if p_start_date < trunc(sysdate) then
      raise_application_error(-20001, 'The start date cannot be in the past.');
    end if;
    select j.title, j.company_name, a.status into l_title, l_company, l_status
      from fj_applications a join fj_jobs j on j.id = a.job_id
     where a.id = p_application_id;
    if l_status not in ('INTERVIEWED', 'OFFERED', 'OFFER_DECLINED') then
      raise_application_error(-20001, 'An offer can only be sent after the candidate passes the interview.');
    end if;
    -- a new letter replaces the previous one; without one the previous letter is kept
    for f in (select blob_content, filename, mime_type from apex_application_temp_files where name = p_letter) loop
      update fj_applications
         set offer_letter = f.blob_content, offer_letter_filename = f.filename, offer_letter_mimetype = f.mime_type
       where id = p_application_id;
    end loop;
    update fj_applications
       set status = 'OFFERED', offer_salary = l_salary, offer_start_date = p_start_date,
           offer_message = p_message, offered_at = sysdate,
           offer_response_note = null, offer_responded_at = null
     where id = p_application_id;
    notify(p_application_id,
           case when l_status = 'OFFERED' then 'Your job offer has been updated' else 'You have received a job offer' end,
           case when l_status = 'OFFERED' then 'Your offer for "' || l_title || '" has been updated. '
                else 'Congratulations! ' || nvl(l_company, 'The employer') || ' is offering you the position of "' || l_title || '". ' end
           || 'Salary: ' || l_salary || '. Start date: ' || to_char(p_start_date, 'fmDay, DD Month YYYY') || '. '
           || 'Please log in to FindJobs to review the offer and accept or decline it.');
  end send_offer;

  procedure respond_offer(p_application_id in number, p_accept in boolean, p_note in varchar2) is
    l_app   fj_applications%rowtype;
    l_title fj_jobs.title%type;
    l_note  varchar2(1000) := substr(trim(p_note), 1, 1000);
  begin
    select * into l_app from fj_applications where id = p_application_id for update;
    check_owner(l_app);
    if l_app.status <> 'OFFERED' then
      raise_application_error(-20001, 'This offer is no longer open for a response.');
    end if;
    select title into l_title from fj_jobs where id = l_app.job_id;
    update fj_applications
       set status = case when p_accept then 'HIRED' else 'OFFER_DECLINED' end,
           offer_response_note = l_note, offer_responded_at = sysdate, decided_at = sysdate,
           hired_at = case when p_accept then sysdate end
     where id = p_application_id;
    if p_accept then
      notify(p_application_id, 'Welcome aboard!',
             'You have accepted the offer for "' || l_title || '". Your start date is '
             || to_char(l_app.offer_start_date, 'fmDay, DD Month YYYY') || '. The employer will contact you with your onboarding details.');
      notify_employers(p_application_id, 'Offer accepted',
             l_app.first_name || ' ' || l_app.last_name || ' accepted the offer for "' || l_title || '" and starts on '
             || to_char(l_app.offer_start_date, 'fmDay, DD Month YYYY') || '.'
             || case when l_note is not null then ' Message: ' || l_note end);
    else
      notify_employers(p_application_id, 'Offer declined',
             l_app.first_name || ' ' || l_app.last_name || ' declined the offer for "' || l_title || '".'
             || case when l_note is not null then ' Reason: ' || l_note end);
    end if;
  end respond_offer;

  procedure fill_job(p_job_id in number) is
    l_title fj_jobs.title%type;
  begin
    select title into l_title from fj_jobs where id = p_job_id for update;
    update fj_jobs set is_filled = 'Y', filled_at = sysdate where id = p_job_id;
    -- pending offers are left for the employer to handle
    for a in (select id from fj_applications
               where job_id = p_job_id
                 and status in ('APPLIED', 'SHORTLISTED', 'TEST_SUBMITTED', 'PASSED', 'INTERVIEW_SCHEDULED', 'INTERVIEWED')) loop
      update fj_applications set status = 'REJECTED', decided_at = sysdate where id = a.id;
      notify(a.id, 'Position filled',
             'Thank you for your interest in "' || l_title || '". This position has now been filled, so we have closed your application. '
             || 'We appreciate the time you invested and encourage you to apply for other roles on FindJobs.');
    end loop;
  end fill_job;

  procedure reopen_job(p_job_id in number) is
  begin
    update fj_jobs set is_filled = 'N', filled_at = null where id = p_job_id;
  end reopen_job;

end fj_flow;
/