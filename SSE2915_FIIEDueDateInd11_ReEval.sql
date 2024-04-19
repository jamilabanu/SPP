drop table Compliances_ConsentForEval_ReEval
drop table Compliances_ConsentForEval_ReEval_Latest


Select row_number() over(partition by  t.StudentUid order by t.ParentSignatureDate asc) AS RowNumber, Student_Uid,  Indicator11FIIEDueDate, Indicator12FIIEDueDate, InitialConsentForEvaluation,currentDistrictId,NumberOfAbsences, d.name as districName ,DateOfBirth ,
CONVERT(int,ROUND(DATEDIFF(hour,DateOfBirth,GETDATE())/8766.0,0)) AS Age, 
s.studentid ,Firstname ,lastname,c.DateUpdated, c.ReferralType as ECIReferral
into Compliances_ConsentForEval_ReEval
from Compliances c
inner join ConsentForEval t on t.studentuid = c.Student_Uid
inner join students s on s.Uid = c.Student_Uid
inner join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
inner join Districts d on e.currentDistrictId = d.Id
inner join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
where TypeOfEvaluation != 'Initial'
--where CurrentDistrictId = @districtId 
and currentDistrictId = 267 


select  IDENTITY(int, 1, 1) as ROW_ID, * 
into Compliances_ConsentForEval_ReEval_Latest
from Compliances_ConsentForEval_ReEval


select * from Compliances_ConsentForEval_ReEval
where RowNumber = 1



select Indicator12FIIEDueDate, Ind12_FIIEDueDate, * from Compliances_ConsentForEval_LatestForm
where Indicator12FIIEDueDate is not null and Ind12_FIIEDueDate is null