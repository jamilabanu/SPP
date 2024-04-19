
begin tran


select * from districts where name like '%marullo%'

select top 10 * from students s 
join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where StudentId in ('YY08564064' ) and CurrentDistrictId = 674

306F3931-E883-4AB9-B1FB-8057C462B74E

1. Student should be initial/referral
2. FIIE form (Title shuld be "Full Individual and Initial Evaluation")
3. 

-------------Actual FIIE---------------------
drop table ActualFIIE


 --For SPP indicator 11 Actual FIIE
 select   row_number() over(partition by  fi.StudentUid order by fi.datelocked desc) as RowNumber, 
DateLocked, 
d.name as districName,
CurrentDistrictId as DistrictId ,
DateOfBirth ,
studentid ,
Firstname ,
lastname , 
InitialConsentForEvaluation,
f.d.value('(Date/text())[1]', 'varchar(max)')   as [Indicator11ActualFIIEDate], 
Fi.StudentUid 
into ActualFIIE
from FormInstances fi 
outer apply fi.Data.nodes('Title') f(d)
left join Students s (nolock) on s.[Uid] = fi.[StudentUid]
left join Compliances c on c.Student_Uid=fi.StudentUid 	
left join FormTypes ft on ft.Id=fi.FormTypeId
left join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
join Districts d on e.currentDistrictId = d.Id
where   Locked=1 
and    fi.DateLocked >'2023-01-01' 
and  ft.PluginType in ( 'Forms.FIEv2.Title') 
and  f.d.value('(Report/text())[1]', 'varchar(max)') ='Full Individual and Initial Evaluation'
and( c.ReferralType ='NO' or  c.ReferralType ='' or  c.ReferralType is null )
and c.InitialConsentForEvaluation is not null 
and e.ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6

union

--UPLOAD--
select   row_number() over(partition by  fi.StudentUid order by fi.datelocked desc) as RowNumber, 
DateLocked, 
d.name as districName,
CurrentDistrictId as DistrictId ,
DateOfBirth ,
studentid ,
Firstname ,
lastname , 
InitialConsentForEvaluation,
f.d.value('(Date/text())[1]', 'varchar(max)')   as [Indicator11ActualFIIEDate], 
Fi.StudentUid 
--, fi.Data
--ft.Name,
--ft.PluginType,
--fi.Data,
--fi.DateLocked
from FormInstances fi 
outer apply fi.Data.nodes('FIEUpload') f(d)
left join Students s (nolock) on s.[Uid] = fi.[StudentUid]
left join Compliances c on c.Student_Uid=fi.StudentUid 	
left join FormTypes ft on ft.Id=fi.FormTypeId
left join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
join Districts d on e.currentDistrictId = d.Id
where   Locked=1 
--and s.Uid in ('306F3931-E883-4AB9-B1FB-8057C462B74E')
and  fi.DateLocked >'2023-01-01' 
and  ft.PluginType in (  'Forms.FIEv2.FIEUpload') 
and  f.d.value('(Report/text())[1]', 'varchar(max)') ='Full Individual and Initial Evaluation'
--and  (ft.Name = 'Full and Individual Evaluation' 
and( c.ReferralType ='NO' or  c.ReferralType ='' or  c.ReferralType is null )
and c.InitialConsentForEvaluation is not null 
and e.ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6


select * from ActualFIIE
where StudentUid in ('306F3931-E883-4AB9-B1FB-8057C462B74E') 


-------------Actual IEP---------------------
 
 drop table ActualIEP_3086
					
--For SPP indicator 11 IEP
 
select   row_number() over(partition by  fi.StudentUid order by fi.datelocked asc) as RowNumber, DateLocked, d.name as districName, currentDistrictId as DistrictId ,DateOfBirth ,studentid ,Firstname ,lastname , pts.StatusDescription,InitialConsentForEvaluation,
		 case when fi.FormTypeId=9 then f.d.value('(MeetingDate/text())[1]', 'varchar(max)') when fi.FormTypeId=8  then  f.d.value('(BriefIEPDate/text())[1]', 'varchar(max)') end  as [ActualIEPMeetingDate], Fi.StudentUid
 into ActualIEP_3086
from FormInstances fi 
outer apply fi.Data.nodes('Plugin') f(d)
left join Students s (nolock) on s.[Uid] = fi.[StudentUid]
left join Compliances c on c.Student_Uid=fi.StudentUid 	
left join FormTypes ft on ft.Id=fi.FormTypeId
left join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
left join ProgramStatusTypes pts on pts.Id=e.ProgramSpecialEducationStatusId
join ProgramTypes pt on pt.Id=pts.ProgramTypeId and pt.Name='Special Education' 
join Districts d on e.currentDistrictId = d.Id
where Locked=1 
and (pts.StatusDescription='DNQ' or pts.StatusDescription='Initial') 
and (ft.Name = 'Brief Individualized Education Program (IEP)' or ft.Name= 'Individualized Education Program Meeting') 
and c.InitialConsentForEvaluation is not null
--and s.Uid in ('306F3931-E883-4AB9-B1FB-8057C462B74E')
  


	--Identify the Actual FIIE Date and populate the Actual IEP Mtg Date with the first IEP “Annual” Mtg OR Brief IEP Mtg Date that occurs AFTER the Actual FIIE Date
	--update Compliances set Indicator11ActualIEPMeetingDate= iep.ActualIEPMeetingDate  
	drop table FIIE_IEP
	
	select fiie.*,  iep.ActualIEPMeetingDate ,  DATEDIFF(d, fiie.Indicator11ActualFIIEDate , iep.ActualIEPMeetingDate) AS DateDiff 
	into FIIE_IEP
	from Compliances c
	inner join ActualFIIE fiie on fiie.StudentUid=c.Student_Uid
	inner join ActualIEP_3086 iep on iep.StudentUid=c.Student_Uid
	where  
	--fiie.StudentId in ('465151', '459168')
	--and isnull(iep.ActualIEPMeetingDate,'') > isnull(fiie.Indicator11ActualFIIEDate, '')  
	---and 
	--and 
	fiie.Indicator11ActualFIIEDate is not null  
	and fiie.RowNumber = 1 
	
	and c.Student_Uid in ('A689FED9-6ECC-497B-B0C7-000E41C13B45')
  
  select datediff(d,'1/4/2023','1/26/2023')

  drop table First_IEP

  select studentUid, min(DateDiff ) as FirstIEPDateDiff
  into First_IEP
  from FIIE_IEP
  where DateDiff > 0 --and studentUid in ('A689FED9-6ECC-497B-B0C7-000E41C13B45')
  group by studentUid
  order by studentUid

  select * from #FIIE_IEP

    select top 10 * from #First_IEP where studentid in ('465151', '459168')


  ---FINAL data 11/10---
  drop table SSE_3086

  select fi.* 
  --into SSE_3086
  from FIIE_IEP fi
  inner join First_IEP f on fi.StudentUid = f.StudentUid
  where fi.DateDiff > 0 
  and fi.DateDiff = f.FirstIEPDateDiff
  --order by fi.StudentUid

  select s.ActualIEPMeetingDate, c.ActualIEPMeetingDate 
  from SSE_3086 s inner join Compliances c on c.Student_Uid = s.StudentUid
  where isnull(s.ActualIEPMeetingDate, '') != isnull(c.ActualIEPMeetingDate , '')
  select * from SSE_3086

  update c
  set ActualIEPMeetingDate = s.ActualIEPMeetingDate
  from SSE_3086 s inner join Compliances c on c.Student_Uid = s.StudentUid
  --where isnull(s.ActualIEPMeetingDate, '') != isnull(c.ActualIEPMeetingDate , '')


    select * 
	from ActualIEP_3086 
	where StudentUid in ('A689FED9-6ECC-497B-B0C7-000E41C13B45')


  ----Multiple FIIE - Steph confirmed to use the latest on 10/30
  /*
  select distinct studentuid
  into #uid
  from ActualFIIE 
  where StudentUid in (select studentuid from ActualIEP_3086)
  group by studentuid
  having count(*) > 1

  select * from ActualFIIE 
  where StudentUid in (select StudentUid from #uid)
  and studentid = '118304'
  order by studentuid
  */


	-- Do NOT populate the Actual IEP Mtg Date if there was no Actual FIIE Date
	-- Remove the Actual IEP Mtg Date if there was no Actual FIIE date
	--update Compliances set Indicator11ActualIEPMeetingDate= null
	select *
	from Compliances c
	inner join #student_ActualIEP iep on iep.StudentUid=c.Student_Uid
	left join #student_ActualFIIE fiie on fiie.StudentUid=c.Student_Uid
	where fiie.Indicator11ActualFIIEDate is null   

	  