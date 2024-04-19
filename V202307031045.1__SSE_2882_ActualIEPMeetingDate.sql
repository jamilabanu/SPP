 

/*

select   row_number() over(partition by  fi.StudentUid order by fi.datelocked desc) as FIIE_RowNumber, DateLocked, d.name as districName,CurrentDistrictId as DistrictId ,DateOfBirth ,studentid ,Firstname ,lastname , 
		   f.d.value('(Date/text())[1]', 'varchar(max)')   as [ActualFIIEDate], Fi.StudentUid
 into FIIELockedForm
from FormInstances fi 
outer apply fi.Data.nodes('Title') f(d)
left join Students s (nolock) on s.[Uid] = fi.[StudentUid]
left join Compliances c on c.Student_Uid=fi.StudentUid 	
left join FormTypes ft on ft.Id=fi.FormTypeId
left join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
join Districts d on e.currentDistrictId = d.Id
where   Locked=1 and  (ft.Name = 'Full and Individual Evaluation' and  ft.PluginType= 'Forms.FIEv2.Title') and( c.ReferralType ='NO' or  c.ReferralType ='' or  c.ReferralType is null )
		and f.d.value('(Report/text())[1]', 'varchar(max)') ='Full Individual and Initial Evaluation'
and currentDistrictId = 267 

drop table FIIELockedForm

select top 10 * from FIIELockedForm
where studentid = '102574'

select  * from FormTypes ft
where parentformtypeid = 9
--ft.Name= 'Individualized Education Program Meeting'

select top 10 * from FormInstances where FormTypeId = 9

select top 10 * from BriefIEP

select top 10 * from BriefIEP_Eligibility


drop table BriefIEP_Eligibility

*/
drop table BriefIEP
drop table IEP

-- Brief IEP --
select row_number() over(partition by  fi.StudentUid order by fi.datelocked desc) as RowNumber, 
fi.id as FormInstanceId,
f.d.value('(BriefIEPDate/text())[1]', 'date') as BriefIEPDate,
   d.name as districName,
   CurrentDistrictId as DistrictId ,
   DateOfBirth ,
   studentid ,
   Firstname ,
   lastname , Fi.StudentUid,
   InitialConsentForEvaluation, 
   c.ReferralType as ECIReferral
   into BriefIEP
from FormInstances fi 
outer apply fi.Data.nodes('Plugin') f(d)
inner join Students s (nolock) on s.[Uid] = fi.[StudentUid]
inner join FormTypes ft on ft.Id=fi.FormTypeId
inner join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
inner join Districts d on e.currentDistrictId = d.Id
left join Compliances c on c.Student_Uid=fi.StudentUid 	
where   Locked=1 and   ft.Name= 'Brief Individualized Education Program (IEP)'
--(ft.Name = 'Brief Individualized Education Program (IEP)' or ft.Name= 'Individualized Education Program Meeting') 
and currentDistrictId = 267 




-- Brief IEP - meets eligibility --
select fi.id as FormInstanceId, fi.ParentInstanceId,
f.d.value('(MeetsEvaluationCriteria/text())[1]', 'varchar(max)') as MeetsEvaluationCriteria,
     Fi.StudentUid 
   into BriefIEP_Eligibility
from FormInstances fi 
outer apply fi.Data.nodes('Section2') f(d)
inner join BriefIEP b on b.FormInstanceId = fi.ParentInstanceId --Section 2 from parent Brief
inner join Students s (nolock) on s.[Uid] = fi.[StudentUid]
inner join FormTypes ft on ft.Id=fi.FormTypeId
inner join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
inner join Districts d on e.currentDistrictId = d.Id
left join Compliances c on c.Student_Uid=fi.StudentUid 	
where   Locked=1  
and currentDistrictId = 267 
and FormTypeId = 203 
and b.RowNumber = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- IEP --  
drop table IEP

select row_number() over(partition by  fi.StudentUid order by f.d.value('(MeetingDate/text())[1]', 'date') asc) as RowNumber,
f.d.value('(MeetingDate/text())[1]', 'date')   as IEPMeetingDate,
f.d.value('(AnnualIEP/text())[1]', 'varchar(max)')   as isAnnualIEP, 
fi.id as FormInstanceId,
   d.name as districName,
   CurrentDistrictId as DistrictId ,
   DateOfBirth ,
   studentid ,
   Firstname ,
   lastname , Fi.StudentUid,
   InitialConsentForEvaluation, 
   c.ReferralType as ECIReferral
   into IEP
from FormInstances fi 
outer apply fi.Data.nodes('Plugin') f(d)
inner join Students s (nolock) on s.[Uid] = fi.[StudentUid]
inner join FormTypes ft on ft.Id=fi.FormTypeId
inner join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
inner join Districts d on e.currentDistrictId = d.Id
left join Compliances c on c.Student_Uid=fi.StudentUid 	
where   Locked=1 and  ft.id = 9
--(ft.Name = 'Brief Individualized Education Program (IEP)' or ft.Name= 'Individualized Education Program Meeting') 
and currentDistrictId = 267 
--and s.studentid = '100509'


--   IEP - meets eligibility --
drop table IEP_Eligibility

select fi.id as FormInstanceId, fi.ParentInstanceId,
f.d.value('(MeetsEvaluationCriteria/text())[1]', 'varchar(max)') as MeetsEvaluationCriteria,
     Fi.StudentUid 
   into IEP_Eligibility
from FormInstances fi 
outer apply fi.Data.nodes('Section2') f(d)
inner join IEP b on b.FormInstanceId = fi.ParentInstanceId --Section 2 from parent IEP
inner join Students s (nolock) on s.[Uid] = fi.[StudentUid]
inner join FormTypes ft on ft.Id=fi.FormTypeId
inner join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
inner join Districts d on e.currentDistrictId = d.Id
left join Compliances c on c.Student_Uid=fi.StudentUid 	
where   Locked=1  
and currentDistrictId = 267 
and FormTypeId = 121 
and b.RowNumber = 1

 ------------------------------------------------------------------------------------------------------------------------------------------------------------
 select * from FIIELockedForm

 -- SPP 12 --
 select f.studentid, f.ActualFIIEDate, BriefIEPDate, ECIReferral, c.ActualIEPMeetingDate 
 from FIIELockedForm_AllForms  f
 inner join BriefIEP b on b.StudentUid = f.StudentUid
 left join Compliances c on c.Student_Uid = f.studentuid
 where f.RowNumber = 1
 and BriefIEPDate >= f.ActualFIIEDate and c.ActualIEPMeetingDate <> BriefIEPDate
 and ECIReferral = 'Yes'

 UNION  
 
 select f.studentid, f.ActualFIIEDate, IEPMeetingDate, b.isAnnualIEP, ECIReferral, c.ActualIEPMeetingDate 
 from FIIELockedForm_AllForms  f
 inner join IEP b on b.StudentUid = f.StudentUid
 left join Compliances c on c.Student_Uid = f.studentuid
 where f.RowNumber = 1
 and IEPMeetingDate >= f.ActualFIIEDate and c.ActualIEPMeetingDate <> IEPMeetingDate
 and ECIReferral = 'Yes'
 and b.isAnnualIEP = 'Yes'



 --SPP 12 Eligibility -- 

 select * from FIIELockedForm_AllForms

 select  f.studentid, f.ActualFIIEDate, BriefIEPDate, ECIReferral, c.ActualIEPMeetingDate , be.MeetsEvaluationCriteria
 from FIIELockedForm_AllForms  f
 inner join BriefIEP b on b.StudentUid = f.StudentUid
 inner join BriefIEP_Eligibility be on be.parentinstanceid = b.formInstanceId
 left join Compliances c on c.Student_Uid = f.studentuid
 where f.FIIE_RowNumber = 1
 and ECIReferral = 'Yes'

 union

 select  f.studentid, f.ActualFIIEDate, IEPMeetingDate, ECIReferral, c.ActualIEPMeetingDate , be.MeetsEvaluationCriteria
 from FIIELockedForm_AllForms  f
 inner join IEP b on b.StudentUid = f.StudentUid
 inner join IEP_Eligibility be on be.parentinstanceid = b.formInstanceId
 left join Compliances c on c.Student_Uid = f.studentuid
 where f.FIIE_RowNumber = 1
 and ECIReferral = 'Yes'




  -- SPP 11 --
  drop table ActualIEP

 select f.StudentUid, f.studentid, f.ActualFIIEDate, BriefIEPDate as IEPDate ,NULL as isAnnualIEP, ECIReferral, c.Indicator11ActualIEPMeetingDate, 'SPP11' as Indicator, 'Brief' as IEPMeetingType
 into ActualIEP
 from FIIELockedForm_AllForms  f
 inner join BriefIEP b on b.StudentUid = f.StudentUid
 left join Compliances c on c.Student_Uid = f.studentuid
 where f.RowNumber = 1
 and BriefIEPDate >= f.ActualFIIEDate 
 and (c.Indicator11ActualIEPMeetingDate IS NULL or c.Indicator11ActualIEPMeetingDate <> BriefIEPDate)
 and ECIReferral != 'Yes'
 --and b.studentid = '100509'


  UNION  
 
 select f.StudentUid, f.studentid, f.ActualFIIEDate, IEPMeetingDate as IEPDate, b.isAnnualIEP, ECIReferral, c.Indicator11ActualIEPMeetingDate , 'SPP11' as Indicator, 'Annual' as IEPMeetingType
 from FIIELockedForm_AllForms  f
 inner join IEP b on b.StudentUid = f.StudentUid
 left join Compliances c on c.Student_Uid = f.studentuid
 where f.RowNumber = 1 and b.RowNumber = 1
 and IEPMeetingDate >= f.ActualFIIEDate 
 --and ( c.Indicator11ActualIEPMeetingDate IS NULL or c.Indicator11ActualIEPMeetingDate <> IEPMeetingDate)
 and ECIReferral != 'Yes'
 and b.isAnnualIEP = 'Yes' 
 --and f.studentid = '100509'


 


 drop table ActualIEP_AllForms

 select row_number() over(partition by  Studentid order by IEPDate desc) as RowNumber,* 
 into ActualIEP_AllForms
 from ActualIEP
  where studentid = '100509'

 select * from ActualIEP_AllForms
 where RowNumber = 1 
 and (Indicator11ActualIEPMeetingDate IS NULL or IEPDate <> Indicator11ActualIEPMeetingDate)

 select * from ActualIEP
 where studentid = '141598'

 select   row_number() over(partition by  fi.StudentUid order by fi.datelocked desc) as FIIE_RowNumber, DateLocked, d.name as districName,CurrentDistrictId as DistrictId ,DateOfBirth ,studentid ,Firstname ,lastname , 
		   f.d.value('(Date/text())[1]', 'varchar(max)')   as [ActualFIIEDate], Fi.StudentUid
-- into FIIELockedForm
from FormInstances fi 
outer apply fi.Data.nodes('Title') f(d)
left join Students s (nolock) on s.[Uid] = fi.[StudentUid]
left join Compliances c on c.Student_Uid=fi.StudentUid 	
left join FormTypes ft on ft.Id=fi.FormTypeId
left join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
join Districts d on e.currentDistrictId = d.Id
where   Locked=1 and  (ft.Name = 'Full and Individual Evaluation' and  ft.PluginType= 'Forms.FIEv2.Title') and( c.ReferralType ='NO' or  c.ReferralType ='' or  c.ReferralType is null )
		and f.d.value('(Report/text())[1]', 'varchar(max)') ='Full Individual and Initial Evaluation'
and s.studentid = '141598'



update c
set c.Indicator11ActualIEPMeetingDate = IEPDate
from ActualIEP_AllForms f
 inner join Compliances c on c.Student_Uid = f.studentuid
 where RowNumber = 1 
 and (c.Indicator11ActualIEPMeetingDate IS NULL or IEPDate <> f.Indicator11ActualIEPMeetingDate)

  

 select * from ActualIEP_AllForms where studentid = '102574'
 
 --SPP 11 Eligibility -- 
 select  f.studentid,   ECIReferral,  be.MeetsEvaluationCriteria, c.ReferralType
 into #DeterminedEligible
 from FIIELockedForm_AllForms  f
 inner join BriefIEP b on b.StudentUid = f.StudentUid
 inner join BriefIEP_Eligibility be on be.parentinstanceid = b.formInstanceId
 left join Compliances c on c.Student_Uid = f.studentuid
 where  
 f.FIIE_RowNumber = 1
 and ECIReferral != 'Yes'
 and be.MeetsEvaluationCriteria <> c.ReferralType


  union

 select  f.studentid, ECIReferral,  be.MeetsEvaluationCriteria, c.ReferralType
 from FIIELockedForm_AllForms  f
 inner join IEP b on b.StudentUid = f.StudentUid
 inner join IEP_Eligibility be on be.parentinstanceid = b.formInstanceId
 left join Compliances c on c.Student_Uid = f.studentuid
 where  f.FIIE_RowNumber = 1
 and ECIReferral != 'Yes'
 and be.MeetsEvaluationCriteria <> c.ReferralType


 select d.studentid, s.uid, c.DeterminedEligible,d.MeetsEvaluationCriteria
 from #DeterminedEligible d
 inner join students s on s.StudentId = d.studentid
 inner join compliances c on c.Student_Uid = s.Uid
 where replace( c.DeterminedEligible, ';', '') != d.MeetsEvaluationCriteria
 --and d.studentid = '141598'

 drop table FIIELockedForm_AllForms

 select * from FIIELockedForm_AllForms

  select  * 
 into FIIELockedForm_AllForms
 from FIIELockedForm
 where FIIE_RowNumber = 1



 select * -- f.studentid, ECIReferral,  be.MeetsEvaluationCriteria, c.ReferralType
 from FIIELockedForm_AllForms  f
 --inner join IEP b on b.StudentUid = f.StudentUid
 --inner join IEP_Eligibility be on be.parentinstanceid = b.formInstanceId
 --left join Compliances c on c.Student_Uid = f.studentuid
  where f.studentid = '141598'


  
 -----------
 -- Remove the Actual IEP Mtg Date on Program Compliance (either SPP 11 or SPP 12) if there was no Actual FIIE date.
 -------------

 select Indicator11ActualIEPMeetingDate , ActualIEPMeetingDate, c.*
 from compliances c
 where Student_Uid not in (select distinct Student_Uid from FIIELockedForm_AllForms where rowNumber = 1)



select top 10 * from BriefIEP

select top 10 * from BriefIEP_Eligibility
 
select top 10 * from IEP

select top 10 * from IEP_Eligibility

select * from students where studentid = '106525'
select Indicator11ActualIEPMeetingDate, * from Compliances where Student_Uid = '2730ECBA-1EF5-4F99-AC25-E0B984315925'

2023-04-11 00:00:00.000


 select * -- f.studentid, f.ActualFIIEDate, IEPMeetingDate as IEPDate, b.isAnnualIEP, ECIReferral, c.Indicator11ActualIEPMeetingDate , 'SPP11' as Indicator, 'Annual' as IEPMeetingType
 from FIIELockedForm_AllForms  f
 inner join IEP b on b.StudentUid = f.StudentUid
 --left join Compliances c on c.Student_Uid = f.studentuid
 where f.studentid = '102574'

 -- f.RowNumber = 1
 and IEPMeetingDate >= f.ActualFIIEDate and c.Indicator11ActualIEPMeetingDate <> IEPMeetingDate
 and ECIReferral != 'Yes'
 and b.isAnnualIEP = 'Yes'

 select * from FIIELockedForm_AllForms
  where studentid = '100509'
 

 select * from ActualIEP
  where studentid = '100509'


 select * from ActualIEP_AllForms
  where studentid = '100509'
 