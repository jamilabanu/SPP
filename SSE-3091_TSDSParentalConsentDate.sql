
 
--begin tran


IF object_id('tempdb..#ConsentForEval') IS NOT NULL DROP TABLE #ConsentForEval
IF object_id('tempdb..#student') IS NOT NULL DROP TABLE #student
IF object_id('tempdb..#tmp') IS NOT NULL DROP TABLE #tmp


drop table ConsentForEval
drop table Compliances_ManualUpdate

truncate table Compliances_ManualUpdate

--declare @districtId int = 674 --Marullo
 

 -- Consent For Evaluation form --
select s.StudentId,  fi.studentuid, 
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(max)') as TypeOfEvaluation,
f.d.value('(GivePermission/text())[1]', 'varchar(max)') as GivePermission,
f.d.value('(ParentSignatureDate/text())[1]', 'datetime') as ParentSignatureDate,
f.d.value('(Date/text())[1]', 'datetime') as ConsentDate
into ConsentForEval
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where formtypeid = 165
and f.d.value('(ParentSignatureDate/text())[1]', 'datetime') >= '3/21/2023'
--and e.CurrentDistrictId = @districtId
--and currentDistrictId <> 267 
--and s.studentid = '204959'


 -- WITH FORM --
 insert into Compliances_ManualUpdate ([StudentId], [Student_Uid], TypeOfEvaluation, [ConsentDate_FromForm], [ConsentDate_FromCompliance], [currentDistrictId], [NumberOfAbsences], [Indicator11TSDSParentalConsentDate], [districName], [DateOfBirth], [Age], [Age_FromPC], [Firstname], [lastname], [DateUpdated], [ECIReferral])

 Select distinct s.StudentId, Student_Uid,  TypeOfEvaluation,
t.ConsentDate AS ConsentDate_FromForm, 
c.InitialConsentForEvaluation AS ConsentDate_FromCompliance,
currentDistrictId,NumberOfAbsences, 
Indicator11TSDSParentalConsentDate,
d.name as districName ,
DateOfBirth , 
(CONVERT(int,CONVERT(char(8),ConsentDate,112))-CONVERT(char(8),DateOfBirth,112))/10000 AS Age,
(CONVERT(int,CONVERT(char(8),InitialConsentForEvaluation,112))-CONVERT(char(8),DateOfBirth,112))/10000 AS Age_FromPC,
Firstname ,lastname,c.DateUpdated, 
c.ReferralType as ECIReferral
--into Compliances_ManualUpdate
from Compliances c
inner join students s on s.Uid = c.Student_Uid
inner join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
inner join Districts d on e.currentDistrictId = d.Id
inner join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
inner join ConsentForEval t on t.studentuid = c.Student_Uid --and t.ConsentDate is null
where t.TypeOfEvaluation = 'Initial'


select * from Compliances_ManualUpdate


update Compliances_ManualUpdate
set [ConsentDate_FromCompliance] = null



-- WITHOUT FORM -- 
insert into Compliances_ManualUpdate ([StudentId], [Student_Uid], TypeOfEvaluation, [ConsentDate_FromForm], [ConsentDate_FromCompliance], [currentDistrictId], [NumberOfAbsences], [Indicator11TSDSParentalConsentDate], [districName], [DateOfBirth], [Age], [Age_FromPC], [Firstname], [lastname], [DateUpdated], [ECIReferral])
Select distinct s.StudentId, Student_Uid,  null,
--t.ConsentDate AS ConsentDate_FromForm, 
null as ConsentDate_FromForm,
c.InitialConsentForEvaluation AS ConsentDate_FromCompliance,
currentDistrictId,NumberOfAbsences, 
Indicator11TSDSParentalConsentDate,
d.name as districName ,
DateOfBirth , 
(CONVERT(int,CONVERT(char(8),ConsentDate,112))-CONVERT(char(8),DateOfBirth,112))/10000 AS Age,
(CONVERT(int,CONVERT(char(8),InitialConsentForEvaluation,112))-CONVERT(char(8),DateOfBirth,112))/10000 AS Age_FromPC,
Firstname ,lastname,c.DateUpdated, 
c.ReferralType as ECIReferral
--into Compliances_ManualUpdate
from Compliances c
inner join students s on s.Uid = c.Student_Uid
inner join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
inner join Districts d on e.currentDistrictId = d.Id
inner join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
left join ConsentForEval t on t.studentuid = c.Student_Uid and t.ConsentDate is null
where c.InitialConsentForEvaluation >= '03/21/2023'
and s.Uid not in (select student_uid from Compliances_ManualUpdate)
--where  currentDistrictId <> 267 
--and s.studentid = '394243'
--and Year(InitialConsentForEvaluation) = '2023'
--and s.studentid in ('572828') 
 

 

 alter table Compliances_ManualUpdate add Ind11_TSDSParentConsentDate datetime 

 alter table Compliances_ManualUpdate add Ind11_TSDSParentConsentDate_2 datetime 
 
 

CREATE UNIQUE INDEX student_uid
ON Compliances_ManualUpdate (student_uid);

CREATE UNIQUE INDEX studentid
ON Compliances_ManualUpdate (studentid);


  
 
-- Send report to Stephanie for validation --  
select  [StudentId], [Student_Uid], TypeOfEvaluation, [ConsentDate_FromForm], [ConsentDate_FromCompliance], [Indicator11TSDSParentalConsentDate] as [Indicator11TSDSParentalConsentDate_Current], 
Ind11_TSDSParentConsentDate as Ind11_TSDSParentConsentDate_Updated, 
Ind11_TSDSParentConsentDate_2 as Ind11_TSDSParentConsentDate_Updated_2,
[currentDistrictId], [districName], [DateOfBirth], [Firstname], [lastname], [DateUpdated]
from Compliances_ManualUpdate
where  [Indicator11TSDSParentalConsentDate]  <> Ind11_TSDSParentConsentDate
--and 
studentid = '0863621'



select c.*, m.* from Compliances_ManualUpdate m 
inner join ConsentForEval c on c.StudentUid = m.student_uid
where m.studentid = '234604'

--- FROM FORM --- 
select Ind11_TSDSParentConsentDate, ConsentDate_FromForm, (select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](currentDistrictId, ConsentDate_FromForm, null, 1))
from Compliances_ManualUpdate m 
where  ConsentDate_FromForm is not null
--and ConsentDate_FromCompliance is null


update m 
set Ind11_TSDSParentConsentDate = (select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](currentDistrictId, ConsentDate_FromForm, null, 1))
from Compliances_ManualUpdate m 
where   ConsentDate_FromForm is not null
--and ConsentDate_FromCompliance is null

update m 
set Ind11_TSDSParentConsentDate_2 = (select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](currentDistrictId, ConsentDate_FromForm, null, 1))
from Compliances_ManualUpdate m 
where   ConsentDate_FromForm is not null



--- FROM COMPLIANCE --- 
select Ind11_TSDSParentConsentDate, ConsentDate_FromCompliance, (select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](currentDistrictId, ConsentDate_FromCompliance, null, 1))
from Compliances_ManualUpdate m 
where  
  ConsentDate_FromCompliance is not null


update m 
set Ind11_TSDSParentConsentDate = (select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](currentDistrictId, ConsentDate_FromCompliance, null, 1))
from Compliances_ManualUpdate m 
where   ConsentDate_FromCompliance is not null


update m 
set Ind11_TSDSParentConsentDate_2 = (select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](currentDistrictId, ConsentDate_FromCompliance, null, 1))
from Compliances_ManualUpdate m 
where   ConsentDate_FromForm is not null


-----------------------------------------------------------------------------------------------------------------------------------------
--- UPDATE PC ----

-- Archive current PC -- 
select c.*
into [SEMWeb_Archive].dbo.Backup_Compliances_CyFair
from Compliances c
inner join ConsentForEval t on t.studentuid = c.Student_Uid
inner join students s on s.Uid = c.Student_Uid
inner join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
inner join Districts d on e.currentDistrictId = d.Id
inner join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
where TypeOfEvaluation = 'Initial' 
and currentDistrictId <> 267 


--Indicator11TSDSParentalConsentDate

select c.[Indicator11TSDSParentalConsentDate], a.Ind11_TSDSParentConsentDate
from Compliances_ManualUpdate a
inner join Compliances c on c.Student_Uid = a.Student_Uid
where  c.[Indicator11TSDSParentalConsentDate]  <> a.Ind11_TSDSParentConsentDate


update c
set Indicator11TSDSParentalConsentDate = a.Ind11_TSDSParentConsentDate 
from Compliances_ManualUpdate a
inner join Compliances c on c.Student_Uid = a.Student_Uid
where  c.[Indicator11TSDSParentalConsentDate]  <> a.Ind11_TSDSParentConsentDate


-- [Indicator11TSDSParentalConsentDate] is null --
update c
set Indicator11TSDSParentalConsentDate = a.Ind11_TSDSParentConsentDate 
from Compliances_ManualUpdate a
inner join Compliances c on c.Student_Uid = a.Student_Uid
where  c.[Indicator11TSDSParentalConsentDate] is null


-- consentdate is in summer -- 
update c
set Indicator11TSDSParentalConsentDate = a.Ind11_TSDSParentConsentDate_2 
from Compliances_ManualUpdate a
inner join Compliances c on c.Student_Uid = a.Student_Uid
where  Ind11_TSDSParentConsentDate <> Ind11_TSDSParentConsentDate_2


 


  
-------------------TESTING-----
select c.[Indicator11TSDSParentalConsentDate], a.Ind11_TSDSParentConsentDate, *
from Compliances_ManualUpdate a
inner join Compliances c on c.Student_Uid = a.Student_Uid
where   
studentid = 'T07062020KQ'


select [Indicator11TSDSParentalConsentDate], Ind11_TSDSParentConsentDate, Ind11_TSDSParentConsentDate_2, * 
from Compliances_ManualUpdate 
where  Ind11_TSDSParentConsentDate <> Ind11_TSDSParentConsentDate_2
and studentid = 'T07062020KQ'

select [Indicator11TSDSParentalConsentDate],* from compliances
where Student_Uid = '122F1EA0-4634-4CE2-88DE-0C4813360B2F'


(select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](441, '2023-07-31 00:00:00.000', null, 1))