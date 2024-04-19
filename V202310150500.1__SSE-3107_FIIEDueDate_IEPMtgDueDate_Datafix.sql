begin tran

update c
set c.Indicator11FIIEDueDate =  t.Indicator11FIIEDueDate_NEW, c.Indicator11IEPMeetingDueDate = t.Indicator11IEPMtgDueDate_NEW
from tmp_3107_sept t
  inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
where t.InitialConsentForEvaluation >= '1/1/2023'
and ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
and (c.Indicator11FIIEDueDate != t.Indicator11FIIEDueDate_NEW or c.Indicator11IEPMeetingDueDate != t.Indicator11IEPMtgDueDate_NEW)


update c
set c.Indicator11FIIEDueDate =  t.Indicator11FIIEDueDate_NEW, c.Indicator11IEPMeetingDueDate = t.Indicator11IEPMtgDueDate_NEW
from tmp_3107_monday t
  inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
where t.InitialConsentForEvaluation >= '1/1/2023'
and ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
and (c.Indicator11FIIEDueDate != t.Indicator11FIIEDueDate_NEW or c.Indicator11IEPMeetingDueDate != t.Indicator11IEPMtgDueDate_NEW)


commit tran