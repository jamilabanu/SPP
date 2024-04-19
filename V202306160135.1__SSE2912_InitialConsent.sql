 
begin tran
IF object_id('tempdb..#Compliances_ConsentForEval') IS NOT NULL DROP TABLE #Compliances_ConsentForEval
IF object_id('tempdb..#ConsentForEval') IS NOT NULL DROP TABLE #ConsentForEval
 
create table #Compliances_ConsentForEval (RowNumber int, Student_Uid uniqueidentifier, Indicator11TSDSParentalConsentDate datetime, InitialConsentForEvaluation datetime, currentDistrictId int,districName varchar(100),DateOfBirth datetime ,studentid varchar(100),Firstname varchar(100),lastname varchar(100),DateUpdated datetime, ECIReferral varchar(100)) 

select s.StudentId,  fi.studentuid, 
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(max)') as TypeOfEvaluation,
f.d.value('(GivePermission/text())[1]', 'varchar(max)') as GivePermission,
f.d.value('(ParentSignatureDate/text())[1]', 'datetime') as ParentSignatureDate,
f.d.value('(Date/text())[1]', 'datetime') as ConsentDate
into #ConsentForEval
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where formtypeid = 165
and e.CurrentDistrictId = 267

select * from #ConsentForEval

--and fi.StudentUid in ( 'F5C7303E-521D-46FE-808F-AAC5D8C3D040', '53301729-0E53-468A-8C64-4E61AFA01C61', 'B4F954B8-FAB4-44BA-A579-2D330C79B71C')


Select row_number() over(partition by  t.StudentUid order by t.ParentSignatureDate asc) AS RowNumber,  Student_Uid, Indicator11TSDSParentalConsentDate,InitialConsentForEvaluation,currentDistrictId,d.Name as districName ,DateOfBirth  , s.studentid,Firstname,lastname,c.DateUpdated, c.ReferralType as ECIReferral, t.TypeOfEvaluation, t.GivePermission, t.ParentSignatureDate, t.ConsentDate
into #Compliances_ConsentForEval
from Compliances c
inner join #ConsentForEval t on t.studentuid = c.Student_Uid
inner join students s on s.Uid = c.Student_Uid
inner join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
left join Districts d on e.currentDistrictId = d.Id
where   t.TypeOfEvaluation = 'Initial' 
and e.CurrentDistrictId = 267

select * from #Compliances_ConsentForEval

--SPP 12--
select e.StudentId, InitialConsentForEvaluation2, e.GivePermission, e.ECIReferral, ParentSignatureDate
--, e.* 
from #Compliances_ConsentForEval e 
left join Compliances c on c.Student_Uid = e.Student_Uid
where ECIReferral = 'Yes'
and GivePermission = 'Yes'
and RowNumber = 1
and c.InitialConsentForEvaluation2 != ParentSignatureDate

update c
set InitialConsentForEvaluation2 = ParentSignatureDate
from #Compliances_ConsentForEval e 
left join Compliances c on c.Student_Uid = e.Student_Uid
where ECIReferral = 'Yes'
and GivePermission = 'Yes'
and RowNumber = 1
and c.InitialConsentForEvaluation2 != ParentSignatureDate
 
  
--SPP 11--
select e.StudentId, c.InitialConsentForEvaluation, e.GivePermission, e.ECIReferral, ParentSignatureDate
--, e.* 
from #Compliances_ConsentForEval e 
left join Compliances c on c.Student_Uid = e.Student_Uid
where GivePermission = 'Yes'
and ECIReferral in ( 'No', '')
and RowNumber = 1
and c.InitialConsentForEvaluation != ParentSignatureDate

update c
set InitialConsentForEvaluation = ParentSignatureDate
from #Compliances_ConsentForEval e 
left join Compliances c on c.Student_Uid = e.Student_Uid
where ECIReferral in ( 'No', '')
and GivePermission = 'Yes'
and RowNumber = 1
and c.InitialConsentForEvaluation != ParentSignatureDate


--Remove data if TypeOfEvaluation != Initial--

/*
the goal is to make sure we do not REMOVE a date that was manually entered. SO, if the date of the NOT Initial matches the date in the field, then remove it. If the doesn't match OR if there is no Consent for Eval in the system, we are making the assumption that the user manually entered the date.
*/


select e.StudentId, e.TypeOfEvaluation, c.InitialConsentForEvaluation, c.InitialConsentForEvaluation2, e.ParentSignatureDate, e.GivePermission
from #ConsentForEval e
inner join compliances c on c.Student_Uid = e.StudentUid
where TypeOfEvaluation != 'Initial'
and ( c.InitialConsentForEvaluation = ParentSignatureDate OR c.InitialConsentForEvaluation2 = ParentSignatureDate)


--SPP11--
update c
set c.InitialConsentForEvaluation = NULL 
from #ConsentForEval e
inner join compliances c on c.Student_Uid = e.StudentUid
where TypeOfEvaluation != 'Initial'
and c.InitialConsentForEvaluation = ParentSignatureDate


--SPP12--
update c
set c.InitialConsentForEvaluation2 = NULL 
from #ConsentForEval e
inner join compliances c on c.Student_Uid = e.StudentUid
where TypeOfEvaluation != 'Initial'
and c.InitialConsentForEvaluation2 = ParentSignatureDate


-- no eval in the system --
select top 10 c.InitialConsentForEvaluation, c.InitialConsentForEvaluation2, * 
from compliances c 
left join #ConsentForEval e on c.Student_Uid = e.StudentUid and e.TypeOfEvaluation = NULL
where (c.InitialConsentForEvaluation != NULL or c.InitialConsentForEvaluation2 != NULL)



 IF object_id('tempdb..#Compliances_ConsentForEval') IS NOT NULL DROP TABLE #Compliances_ConsentForEval
 IF object_id('tempdb..#ConsentForEval') IS NOT NULL DROP TABLE #ConsentForEval

rollback tran




