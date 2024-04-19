




--Scenario 1: TSDS Parental Consent Date = Initial Consent + 1 School Day (No Forms)--

drop table TSDS_3106_S1 

select c.Student_Uid, s.studentid, e.CurrentDistrictId,  InitialConsentForEvaluation, c.Indicator11TSDSParentalConsentDate , 
(select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](currentDistrictId, InitialConsentForEvaluation, null, 1)) AS Indicator11TSDSParentalConsentDate_NEW 
--(select [dbo].[fnAdjustSchoolDays_TSDS](currentDistrictId, InitialConsentForEvaluation, 1)) AS Indicator11TSDSParentalConsentDate_NEW --, c.ReferralType
into TSDS_3106_S1
from Compliances c 
inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
inner join students s on s.uId = c.Student_Uid
where  InitialConsentForEvaluation >= '01/01/2023'  --and s.StudentId = 'x305'
--and ReferralType = 'Yes' 
and c.Indicator11TSDSParentalConsentDate != (select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](currentDistrictId, InitialConsentForEvaluation, null, 1))

select * from districtdates where districtid = 698

select * from TSDS_3106_S1 where studentid = '076184'
select [dbo].[fnAdjustSchoolDays_TSDS](267, '2023-06-06 00:00:00.000', 1)
select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](247, '07/27/2023',null, 1)

select top 10 * from DistrictDates where districtid = 142 and AcademicYear = '2023-24'
select  d.*, d2.*
--d.Id
--,d.FirstDayCurrentYear
--, d.LastDayCurrentYear
--, d.AcademicYear
--,d2.LastDayCurrentYear
from DistrictDates d (nolock) inner join DistrictDates d2 on d2.DistrictId = d.DistrictId
where d.DistrictId = 142
and d.AcademicYear = '2023-24'
and d2.AcademicYear = '2022-23'
and ('2023-05-25' between d2.LastDayCurrentYear and d.FirstDayCurrentYear) 

--update c
--set Indicator11TSDSParentalConsentDate = (select [dbo].[fnAdjustSchoolDays_TSDS](currentDistrictId, InitialConsentForEvaluation, 1))
--from Compliances c 
--inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
--where InitialConsentForEvaluation> '01/01/2023'
--and ReferralType = 'Yes'
--and c.Indicator11TSDSParentalConsentDate != (select [dbo].[fnAdjustSchoolDays_TSDS](currentDistrictId, InitialConsentForEvaluation, 1))



--Scenario 2: TSDS Parental Consent Date = Initial Consent + 1 School Day (With Forms) --
/*
Based on Districts Academic Year and School Day Calendars, when the 
- Notice of Evaluation > Initial, 
- Consent for Evaluation > Initial and 
- contains a parent signature date of 01/01/2023 to current date and 
- that date has populated the Initial Consent for Evaluation date field on PC, I see that we have data fixed the 
-> SPP 11 > TSDS Parental Consent Date to = Initial Consent + 1 School Day.  
*/


--Notice of Eval = Initial--

drop table NoticeOfEval

select  s.StudentId,  fi.studentuid, 
f.d.value('(DateOfNotice/text())[1]', 'datetime')   as [Notice],
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(20)')   as TypeOfEvaluation
into NoticeOfEval
from forminstances fi
outer apply fi.Data.nodes('Plugin') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where formtypeid = 173
--and s.StudentId = '3122020KD'
and f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(10)')= 'Initial'
and fi.studentuid not in (select fi2.StudentUid from forminstances fi2
					outer apply fi2.Data.nodes('Plugin') f(d)
					inner join students s2 on s2.Uid = fi2.StudentUid
					inner join Enrollments e2 on e2.StudentUid = s2.Uid and e2.ActiveRecord = 1
					where formtypeid = 173
					--and s2.StudentId = '3122020KD'
					and f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(20)')= 'Reevaluation'
					)

  

-- Consent form = Initial --
select * from ConsentForEval_3107_Sept where ParentSignatureDate is not null

drop table student_3106_sept

Select row_number() over(partition by  t.StudentUid order by t.ParentSignatureDate asc) AS RowNumber, Student_Uid,  Indicator11FIIEDueDate, Indicator12FIIEDueDate, c.InitialConsentForEvaluation AS InitialConsentForEvaluation_FROMPC ,currentDistrictId,NumberOfAbsences, d.name as districName ,DateOfBirth ,s.studentid ,Firstname ,lastname,c.DateUpdated, c.ReferralType as ECIReferral, t.ConsentDate, t.ParentSignatureDate
into student_3106_sept
from Compliances c
inner join ConsentForEval_3107_Sept t on t.studentuid = c.Student_Uid
left join students s on s.Uid = c.Student_Uid
left join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
left join Districts d on e.currentDistrictId = d.Id
left join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
where t.ParentSignatureDate is not null
and t.StudentId = '065071'


select * from student_3106_sept 
where studentid = '3122020KD'

 drop table tmp_3106_sept


select  IDENTITY(int, 1, 1) as ROW_ID, *
into tmp_3106_sept
from student_3106_sept
where RowNumber = 1

select * from tmp_3106_sept
where studentid = 'AA09252018EY'


select t.*, s.TypeOfEvaluation
from tmp_3106_sept t inner join ConsentForEval_3107_Sept s on s.studentuid = t.Student_Uid
where s.TypeOfEvaluation = 'Initial'
and t.ConsentDate >= '1/1/2023'

drop table TSDS_3106_S2

select t.Student_Uid, t.studentid, t.CurrentDistrictId, t.districName,s.TypeOfEvaluation AS Consent_TypeOfEvaluation, n.TypeOfEvaluation AS Notice_TypeOfEvaluation, c.Indicator11TSDSParentalConsentDate, t.ConsentDate, 
(select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](t.currentDistrictId, t.ParentSignatureDate, c.Indicator11ActualFIIEDate, 1)) as Indicator11TSDSParentalConsentDate_NEW
, t.ParentSignatureDate
, c.Indicator11ActualFIIEDate
into TSDS_3106_S2
from Compliances c 
inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
inner join tmp_3106_sept t on t.Student_Uid = c.Student_Uid
inner join ConsentForEval_3107_Sept s on s.studentuid = t.Student_Uid
inner join NoticeOfEval n on n.StudentUid = t.Student_Uid
where InitialConsentForEvaluation >= '01/01/2023'
 --and   t.studentid = '3122020KD' 
--and ReferralType = 'Yes'
--and n.TypeOfEvaluation = 'Initial'
and s.TypeOfEvaluation = 'Initial'
and isnull(t.ECIReferral,'') != 'Yes'
and c.Indicator11TSDSParentalConsentDate != (select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](t.currentDistrictId,t.ParentSignatureDate, c.Indicator11ActualFIIEDate, 1))

 select * from TSDS_3106_S2
 where  studentid = 'AA09252018EY' 


select [dbo].[fnAdjustSchoolDays_TSDS](698, '2023-08-09 00:00:00.000', 1)

select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](183, '08/15/2023', null , 1)


-- send to Steph--
-- Scenario 2:
select * from TSDS_3106_S2
where studentid = '8282019'

select * from ConsentForEval_3107_Sept
where studentid = '8282019'

-- Scenario 1:
select * from TSDS_3106_S1
where student_uid not in (select distinct student_uid from TSDS_3106_S2)
and studentid = '8282019'


-- FINAL 11/03 --
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

-- Scenario 3/ Scenario 4:  --
/*
- Notice of Evaluation > Re-evaluation, 
- Consent for Evaluation > Re-evaluation and 
- contains a parent signature date of 01/01/2023 to current date.  
-> Do not populate anything for SPP 11 (
	-Initial Consent for Evaluation, 
	-TSDS Parental Consent, 
	-FIIE Due Date or 
	-IEP Meeting Due Date) 
	when the Notice of Evaluation and Consent for Evaluation form evaluation types are marked as Re-evaluation.
*/


-- Notice of Eval = ReEval /NULL--
select s.StudentId,  fi.studentuid, 
f.d.value('(DateOfNotice/text())[1]', 'datetime')   as [Notice],
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(12)')   as TypeOfEvaluation
into NoticeOfEval_ReEvalBlank
from forminstances fi
outer apply fi.Data.nodes('Plugin') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where formtypeid = 173
and f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(12)') in( 'Reevaluation', NULL)
--and s.StudentId = 'T01312020'

 
-- send to steph. last 4 columns will be removed.
select s.* , c.InitialConsentForEvaluation, c.Indicator11TSDSParentalConsentDate,  c.Indicator11FIIEDueDate, c.Indicator11IEPMeetingDueDate 
from ConsentForEval_3107_Sept s
inner join compliances c on c.Student_Uid = s.studentuid
inner join NoticeOfEval_ReEvalBlank n on n.StudentUid = s.studentuid
where ((s.TypeOfEvaluation= 'Reevaluation' or s.TypeOfEvaluation is null  ) and (n.TypeOfEvaluation= 'Reevaluation' or n.TypeOfEvaluation is null  ) )
and ConsentDate >= '1/1/2023'
and (c.InitialConsentForEvaluation is not null
or c.Indicator11TSDSParentalConsentDate  is not null or   c.Indicator11FIIEDueDate  is not null or  c.Indicator11IEPMeetingDueDate  is not null)