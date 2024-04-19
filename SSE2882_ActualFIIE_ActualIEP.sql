
begin tran

select top 10 * from students s join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where StudentId in ('152944', '166445') and CurrentDistrictId = 267

44F6D022-DA5A-4938-A67A-6E65650257E3
	 -------------Actual FIIE---------------------

IF object_id('tempdb..#student_ActualFIIE') IS NOT NULL DROP TABLE #student_ActualFIIE

create table #student_ActualFIIE (RowNumber int, DateLocked datetime, districName varchar(100),DistrictId int,DateOfBirth datetime ,studentid varchar(100),Firstname varchar(100),lastname varchar(100), InitialConsentForEvaluation datetime, Indicator11ActualFIIEDate datetime, StudentUid uniqueidentifier) 
					
--For SPP indicator 11 Actual FIIE
insert into #student_ActualFIIE
select   row_number() over(partition by  fi.StudentUid order by fi.datelocked desc) as RowNumber, DateLocked, d.name as districName,CurrentDistrictId as DistrictId ,DateOfBirth ,studentid ,Firstname ,lastname , InitialConsentForEvaluation,
		   f.d.value('(Date/text())[1]', 'varchar(max)')   as [Indicator11ActualFIIEDate], Fi.StudentUid
from FormInstances fi 
outer apply fi.Data.nodes('Title') f(d)
left join Students s (nolock) on s.[Uid] = fi.[StudentUid]
left join Compliances c on c.Student_Uid=fi.StudentUid 	
left join FormTypes ft on ft.Id=fi.FormTypeId
left join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
join Districts d on e.currentDistrictId = d.Id
where   Locked=1 and  fi.DateLocked >'2022-03-01' and  (ft.Name = 'Full and Individual Evaluation' and  ft.PluginType= 'Forms.FIEv2.Title') and( c.ReferralType ='NO' or  c.ReferralType ='' or  c.ReferralType is null )
		and c.InitialConsentForEvaluation is not null and  f.d.value('(Report/text())[1]', 'varchar(max)') ='Full Individual and Initial Evaluation'
	 and s.Uid in ('6F3ACFFF-00D5-47FA-8161-6B35EF44114C', '44F6D022-DA5A-4938-A67A-6E65650257E3')

	 -------------Actual IEP---------------------

	 IF object_id('tempdb..#student_ActualIEP') IS NOT NULL DROP TABLE #student_ActualIEP

create table #student_ActualIEP (RowNumber int, DateLocked datetime, districName varchar(100),DistrictId int,DateOfBirth datetime ,studentid varchar(100),Firstname varchar(100),lastname varchar(100), StatusDescription varchar(100),  InitialConsentForEvaluation datetime, ActualIEPMeetingDate datetime, StudentUid uniqueidentifier) 
					
--For SPP indicator 11 IEP
insert into #student_ActualIEP
select   row_number() over(partition by  fi.StudentUid order by fi.datelocked asc) as RowNumber, DateLocked, d.name as districName, currentDistrictId as DistrictId ,DateOfBirth ,studentid ,Firstname ,lastname , pts.StatusDescription,InitialConsentForEvaluation,
		 case when fi.FormTypeId=9 then f.d.value('(MeetingDate/text())[1]', 'varchar(max)') when fi.FormTypeId=8  then  f.d.value('(BriefIEPDate/text())[1]', 'varchar(max)') end  as [ActualIEPMeetingDate], Fi.StudentUid
from FormInstances fi 
outer apply fi.Data.nodes('Plugin') f(d)
left join Students s (nolock) on s.[Uid] = fi.[StudentUid]
left join Compliances c on c.Student_Uid=fi.StudentUid 	
left join FormTypes ft on ft.Id=fi.FormTypeId
left join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
left join ProgramStatusTypes pts on pts.Id=e.ProgramSpecialEducationStatusId
join ProgramTypes pt on pt.Id=pts.ProgramTypeId and pt.Name='Special Education' 
join Districts d on e.currentDistrictId = d.Id
where   Locked=1 and     (pts.StatusDescription='DNQ' or pts.StatusDescription='Initial') and  (ft.Name = 'Brief Individualized Education Program (IEP)' or ft.Name= 'Individualized Education Program Meeting') 
		  and c.InitialConsentForEvaluation is not null
		  and s.Uid in ('6F3ACFFF-00D5-47FA-8161-6B35EF44114C', '44F6D022-DA5A-4938-A67A-6E65650257E3')
  
	--Identify the Actual FIIE Date and populate the Actual IEP Mtg Date with the first IEP “Annual” Mtg OR Brief IEP Mtg Date that occurs AFTER the Actual FIIE Date
	--update Compliances set Indicator11ActualIEPMeetingDate= iep.ActualIEPMeetingDate  
	select *
	from Compliances c
	inner join #student_ActualFIIE fiie on fiie.StudentUid=c.Student_Uid
	inner join #student_ActualIEP iep on iep.StudentUid=c.Student_Uid
	where fiie.Indicator11ActualFIIEDate is not null  
	and iep.RowNumber=1
	and iep.ActualIEPMeetingDate > fiie.Indicator11ActualFIIEDate  


	-- Do NOT populate the Actual IEP Mtg Date if there was no Actual FIIE Date
	-- Remove the Actual IEP Mtg Date if there was no Actual FIIE date
	--update Compliances set Indicator11ActualIEPMeetingDate= null
	select *
	from Compliances c
	inner join #student_ActualIEP iep on iep.StudentUid=c.Student_Uid
	left join #student_ActualFIIE fiie on fiie.StudentUid=c.Student_Uid
	where fiie.Indicator11ActualFIIEDate is null   


	IF object_id('tempdb..#student_ActualFIIE') IS NOT NULL DROP TABLE #student_ActualFIIE
	IF object_id('tempdb..#student_ActualIEP') IS NOT NULL DROP TABLE #student_ActualIEP
	
	rollback tran