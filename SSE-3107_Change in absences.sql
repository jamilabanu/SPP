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

 select t.*,dd.FirstDayCurrentYear 
 from  tmp_3107_sept t 
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
inner join districtdates dd on dd.DistrictId = t.currentDistrictId
 where  ProgramSpecialEducationStatusId in (3,6)
 and Indicator11FIIEDueDate_1020 is not null
 and Indicator11FIIEDueDate_1020 <> Indicator11FIIEDueDate_NEW
 and dd.AcademicYear = '2023-24'

 and Indicator11FIIEDueDate_1020 = '6/30/2023'

 select t.*
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_sept t on t.Student_Uid = e.StudentUid
 where  ProgramSpecialEducationStatusId in (3,6)
  and t.Student_Uid = 'C525C19F-B6A5-4112-A06D-1E9055612156'

 --and t.CurrentDistrictId = 384
 and t.Indicator11FIIEDueDate_1020 = '06-30-2023'
 and t.NumberOfAbsences >= 3



--10/20 new absences--
select  c.NumberOfAbsences, t.numberofabsences, c.DateUpdated, t.* 
from compliances c 
inner join tmp_3107_sept t on t.student_Uid = c.student_uid
where c.NumberOfAbsences > 0
and c.DateUpdated> '10/20/2023'
and  isnull(c.NumberOfAbsences,0) <> isnull(t.numberofabsences, 0)


update t
set t.NumberOfAbsences = c.numberofabsences
from compliances c 
inner join tmp_3107_sept t on t.student_Uid = c.student_uid
where c.NumberOfAbsences > 0
and c.DateUpdated> '10/20/2023'
and  isnull(c.NumberOfAbsences,0) <> isnull(t.numberofabsences, 0)





 ----Indicator11IEPMtgDueDate_1020 --

    update t
 set Indicator11IEPMtgDueDate_1020 = (Select dbo.fnAdjustSchoolDays(e.currentDistrictId, dd.FirstDayCurrentYear, 14))
 from tmp_3107_sept t
 inner join districtdates dd on dd.DistrictId = t.CurrentDistrictId
   inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
 where  ProgramSpecialEducationStatusId in (3,6)
 and  Indicator11FIIEDueDate_1020  = '06-30-2023' 
 and AcademicYear = '2023-24'
 --and Indicator11IEPMtgDueDate_1020 is null
 

  
 update t
 set Indicator11FIIEDueDate_1020 = (Select dbo.fnAdjustSchoolDays(t.currentDistrictId, t.InitialConsentForEvaluation, (45+t.NumberOfAbsences))),
 Indicator11IEPMtgDueDate_1020 = DATEADD(day,30,(Select dbo.fnAdjustSchoolDays(t.currentDistrictId, t.InitialConsentForEvaluation, (45))))
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_sept t on t.Student_Uid = e.StudentUid
 where  ProgramSpecialEducationStatusId in (3,6)
 --and t.CurrentDistrictId = 384
 and t.Indicator11FIIEDueDate_1020 = '06-30-2023'
 and t.NumberOfAbsences >= 3
  --and Indicator11IEPMtgDueDate_1020 is null



  update t
 set Indicator11IEPMtgDueDate_1020 = DATEADD(day,30, c.Indicator11ActualFIIEDate)  
 from tmp_3107_sept t inner join compliances c on c.Student_Uid = t.Student_Uid
  where  c.Indicator11ActualFIIEDate is not null 
   and Indicator11IEPMtgDueDate_1020 is null

  update e
set Indicator11IEPMtgDueDate_1020 = dd.BeginningOfFollowingYear
 --select e.* from tmp_3107_sept e 
 from tmp_3107_sept e inner join Students s on s.uid = e.Student_Uid
inner join Compliances c on c.Student_Uid = e.Student_Uid
inner join DistrictDates dd on dd.DistrictId = e.currentDistrictId
where RowNumber = 1 and   ECIReferral != 'Yes' 
and DATEADD(day,30, Indicator11FIIEDueDate_1020) > dd.LastDayCurrentYear
and DATEADD(day,30,Indicator11FIIEDueDate_1020) < dd.BeginningOfFollowingYear
and dd.AcademicYear = '2022-23'
and Indicator11FIIEDueDateUpdated  != '06-30-2023' 
   and Indicator11IEPMtgDueDate_1020 is null
   
   and e.student_uid = '1291FFC5-98C4-44CA-A1D1-71EFF1EBD8A9'

 






 --summer
 update t set Indicator11IEPMtgDueDate_1020 = dd.FirstDayCurrentYear
 --select t.* from compliances c 
  from compliances c
inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_sept t on t.Student_Uid = e.StudentUid
 inner join districtdates dd on dd.DistrictId = t.currentDistrictId
  inner join districtdates dd2 on dd2.DistrictId = t.currentDistrictId
 where   ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6
 --and e.studentuid = '1291FFC5-98C4-44CA-A1D1-71EFF1EBD8A9'
 and dd.AcademicYear = '2023-24'
 --and month(Indicator11IEPMtgDueDate_NEW) in (5,6,7,8)
 --and year( Indicator11IEPMtgDueDate_NEW) = 2023
 and Indicator11IEPMtgDueDate_NEW < dd.FirstDayCurrentYear
  and dd2.AcademicYear = '2022-23'
 and Indicator11IEPMtgDueDate_NEW > dd2.LastDayCurrentYear


 update e
 set e.Indicator11IEPMtgDueDate_1020 = DATEADD(day,30, e.Indicator11FIIEDueDate_1020)  
 from tmp_3107_sept e
 where Indicator11IEPMtgDueDate_1020 is null


  update t
 set t.Indicator11IEPMtgDueDate_1020 = DATEADD(day,30, f.ActualFIIEDate) 
 from tmp_3107_monday t 
 inner join FIIELockedForm_AllForms f on f.StudentUid = t.Student_Uid

 update t
set Indicator11IEPMtgDueDate_1020 = dd.FirstDayCurrentYear  
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_monday t on t.Student_Uid = e.StudentUid
 inner join districtdates dd on dd.DistrictId = t.currentDistrictId
  inner join districtdates dd2 on dd2.DistrictId = t.currentDistrictId
 where   ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6
 and dd.AcademicYear = '2023-24' 
 and t.Indicator11IEPMtgDueDate_1020 < dd.FirstDayCurrentYear
  and dd2.AcademicYear = '2022-23'
 and Indicator11IEPMtgDueDate_1020 > dd2.LastDayCurrentYear 
