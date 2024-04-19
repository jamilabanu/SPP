begin tran

 update c
set c.Indicator11FIIEDueDate =  t.Indicator11FIIEDueDate_1020, c.Indicator11IEPMeetingDueDate = t.Indicator11IEPMtgDueDate_1020
 from  tmp_3107_sept t 
 inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
inner join districtdates dd on dd.DistrictId = t.currentDistrictId
 where  ProgramSpecialEducationStatusId in (3,6)
 and Indicator11FIIEDueDate_1020 is not null
 and Indicator11FIIEDueDate_1020 <> Indicator11FIIEDueDate_NEW
 and dd.AcademicYear = '2023-24'


commit tran