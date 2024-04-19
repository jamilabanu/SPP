begin tran

update c
set c.Indicator11TSDSParentalConsentDate =  t.Indicator11TSDSParentalConsentDate_NEW 
from TSDS_3106_S2 t
  inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
where (isnull(c.Indicator11TSDSParentalConsentDate, '') != t.Indicator11TSDSParentalConsentDate_NEW)

update c
set c.Indicator11TSDSParentalConsentDate =  t.Indicator11TSDSParentalConsentDate_NEW 
from TSDS_3106_S1 t
  inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
where (isnull(c.Indicator11TSDSParentalConsentDate, '') != t.Indicator11TSDSParentalConsentDate_NEW)
and  t.Student_Uid not in (select distinct student_uid from TSDS_3106_S2) 

commit tran
