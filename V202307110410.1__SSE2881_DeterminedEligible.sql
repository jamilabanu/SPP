 
 drop table FIIELockedForm


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
 
 
 drop table FIIELockedForm_AllForms

 select * from FIIELockedForm_AllForms

  select  * 
 into FIIELockedForm_AllForms
 from FIIELockedForm
 where FIIE_RowNumber = 1

 --SPP 12 Eligibility --  

 --select  f.studentid, f.ActualFIIEDate, BriefIEPDate, ECIReferral, c.ActualIEPMeetingDate , be.MeetsEvaluationCriteria
 --from FIIELockedForm_AllForms  f
 --inner join BriefIEP b on b.StudentUid = f.StudentUid
 --inner join BriefIEP_Eligibility be on be.parentinstanceid = b.formInstanceId
 --left join Compliances c on c.Student_Uid = f.studentuid
 --where f.FIIE_RowNumber = 1
 --and ECIReferral = 'Yes'

 --union

 --select  f.studentid, f.ActualFIIEDate, IEPMeetingDate, ECIReferral, c.ActualIEPMeetingDate , be.MeetsEvaluationCriteria
 --from FIIELockedForm_AllForms  f
 --inner join IEP b on b.StudentUid = f.StudentUid
 --inner join IEP_Eligibility be on be.parentinstanceid = b.formInstanceId
 --left join Compliances c on c.Student_Uid = f.studentuid
 --where f.FIIE_RowNumber = 1
 --and ECIReferral = 'Yes'

  
 
 --SPP 11 Eligibility --
 drop table DeterminedEligible

 select  f.studentid,   ECIReferral,  be.MeetsEvaluationCriteria, c.ReferralType
 into DeterminedEligible
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


 --select d.studentid, s.uid, c.DeterminedEligible,d.MeetsEvaluationCriteria
 --from DeterminedEligible d
 --inner join students s on s.StudentId = d.studentid
 --inner join compliances c on c.Student_Uid = s.Uid
 --where replace( c.DeterminedEligible, ';', '') != d.MeetsEvaluationCriteria
 --and d.studentid = '141598'

  
 update c
 set DeterminedEligible = MeetsEvaluationCriteria
 from DeterminedEligible d
 inner join students s on s.StudentId = d.studentid
 inner join compliances c on c.Student_Uid = s.Uid
 where replace( c.DeterminedEligible, ';', '') != d.MeetsEvaluationCriteria
  
  
 