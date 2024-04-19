
 
--begin tran


IF object_id('tempdb..#ConsentForEval') IS NOT NULL DROP TABLE #ConsentForEval
IF object_id('tempdb..#student') IS NOT NULL DROP TABLE #student
IF object_id('tempdb..#tmp') IS NOT NULL DROP TABLE #tmp


drop table ConsentForEval
drop table Compliances_ConsentForEval
drop table Compliances_ConsentForEval_LatestForm

--declare @districtId int = 674 --Marullo
 
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
--and e.CurrentDistrictId = @districtId
and currentDistrictId <> 267 
--and s.studentid = '204959'

 
Select distinct s.StudentId, Student_Uid,  
t.ConsentDate AS ConsentDate_FromForm, 
c.InitialConsentForEvaluation AS ConsentDate_FromCompliance,
currentDistrictId,NumberOfAbsences, 
Indicator11TSDSParentalConsentDate,
Indicator12TSDSParentalConsentDate,
Indicator11FIIEDueDate, 
Indicator12FIIEDueDate,  
Indicator11IEPMeetingDueDate,
IEPMeetingDueDate2,
d.name as districName ,
DateOfBirth ,
--CONVERT(int,ROUND(DATEDIFF(hour,DateOfBirth,GETDATE())/8766.0,0)) AS Age, 
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
--where  currentDistrictId <> 267 
--and s.studentid = '394243'
--and Year(InitialConsentForEvaluation) = '2023'
--and s.studentid in ('572828') 


--select top 1 Indicator11FIIEDueDate, Ind11_FIIEDueDate,ConsentDate_FromCompliance , DATEADD(d, 45+4,  ConsentDate_FromCompliance), NumberOfAbsences, 
--dbo.fnAdjustSchoolDays_TSDS(dd.DistrictId, ConsentDate_FromCompliance, 49)
--from Compliances_ManualUpdate m
--inner join districtdates dd on dd.DistrictId = m.currentDistrictId
--inner join DistrictSpecialDates dsd on dsd.DistrictDatesId = dd.id
--where studentid = '368414'


--select top 10 * from DistrictSpecialDates

  
 update m
 set ConsentDate_FromForm = e.ConsentDate
 from ConsentForEval e 
 inner join Compliances_ManualUpdate m on m.studentid = e.StudentId
 inner join Compliances c on c.Student_Uid = e.StudentUid
 where e.ConsentDate is not null


  update m
 set Age = (CONVERT(int,CONVERT(char(8),e.ConsentDate,112))-CONVERT(char(8),m.DateOfBirth,112))/10000
 from ConsentForEval e 
 inner join Compliances_ManualUpdate m on m.studentid = e.StudentId
 inner join Compliances c on c.Student_Uid = e.StudentUid
 where e.ConsentDate is not null

--select * from Compliances_ManualUpdate
--where studentid in ('141598') 



 
--select  IDENTITY(int, 1, 1) as ROW_ID, *
--into Compliances_ManualUpdate
--from Compliances_ManualUpdate 
--where RowNumber = 1

alter table Compliances_ManualUpdate add AdjustDay datetime
alter table Compliances_ManualUpdate add SchooldaysMoved int
alter table Compliances_ManualUpdate add Ind11_TSDSParentConsentDate datetime
alter table Compliances_ManualUpdate add Ind11_FIIEDueDate datetime
alter table Compliances_ManualUpdate add Ind11_IEPMeetingDueDate datetime
alter table Compliances_ManualUpdate add thirdBirthday datetime
alter table Compliances_ManualUpdate add Ind12_TSDSParentConsentDate datetime
alter table Compliances_ManualUpdate add Ind12_FIIEDueDate datetime
alter table Compliances_ManualUpdate add Ind12_IEPMeetingDueDate datetime

alter table Compliances_ManualUpdate add YearOfConsent int

--select * from Compliances_ManualUpdate
--where ConsentDate_FromCompliance is not null and ConsentDate_FromForm is null
--and CurrentDistrictId <> 267
-- and YearOfConsent = 2023


update Compliances_ManualUpdate
set YearOfConsent = Year(ConsentDate_FromCompliance)


CREATE UNIQUE INDEX student_uid
ON Compliances_ManualUpdate (student_uid);

CREATE UNIQUE INDEX studentid
ON Compliances_ManualUpdate (studentid);


CREATE   INDEX YearOfConsent
ON Compliances_ManualUpdate (YearOfConsent);
 

 

 ----------------------------------------------------------------------------------------------------------------------------------------------



----SPP12 - TSDSParentConsentDate--
--update Compliances_ManualUpdate 
--set Ind12_TSDSParentConsentDate = (select [dbo].[fnAdjustSchoolDays_TSDS](currentDistrictId, ConsentDate_FromForm, 1))
--where ECIReferral = 'Yes'


--update Compliances_ManualUpdate 
--set Ind12_TSDSParentConsentDate = (select [dbo].[fnAdjustSchoolDays_TSDS](currentDistrictId, ConsentDate_FromCompliance, 1))
--where ECIReferral = 'Yes'

--SPP11 - TSDSParentConsentDate--
--update m 
--set Ind11_TSDSParentConsentDate = (select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](currentDistrictId, ConsentDate_FromForm, f.ActualFIIEDate, 1))
--from Compliances_ManualUpdate m 
--inner join FIIELockedForm f on f.studentid = m.StudentId
--where ECIReferral != 'Yes' 


--select Ind11_TSDSParentConsentDate , m.*
--from Compliances_ManualUpdate m 
--inner join FIIELockedForm f on f.studentid = m.StudentId
--where ECIReferral != 'Yes' 
--and m.studentid = '394243'

--update m 
--set Ind11_TSDSParentConsentDate = (select [dbo].[fnAdjustSchoolDays_TSDSParentConsentDate](currentDistrictId, ConsentDate_FromCompliance, f.ActualFIIEDate, 1))
--from Compliances_ManualUpdate m 
--inner join FIIELockedForm f on f.studentid = m.StudentId
--where ECIReferral != 'Yes' 
--and ConsentDate_FromForm is null

---- Age > 3

-- select top 1000 Ind11_TSDSParentConsentDate, *
-- from Compliances_ManualUpdate m 
--inner join FIIELockedForm f on f.studentid = m.StudentId
--where ECIReferral != 'Yes' 



----thirdBirthday--
--update Compliances_ManualUpdate 
--set thirdBirthday = DATEADD(year, 3, DateOfBirth)
--where Age < 3

---- SPP12 ONLY - FIIEDueDate, IEPMeetingDueDate --
--update Compliances_ManualUpdate 
--set Ind12_FIIEDueDate = thirdBirthday, Ind12_IEPMeetingDueDate = thirdBirthday
--where ECIReferral = 'Yes'-- and Age < 3




--select top 1000 * from Compliances_ManualUpdate
  
	------------------------------------------------------------------------------------------------------
	--SPP 11 FIIE Due Date--

DECLARE @student_uid uniqueidentifier

DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR  
 
 select  DISTINCT  top 100 student_uid 
 from Compliances_ManualUpdate c
 inner join students s on s.Uid = c.Student_Uid
inner join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1 and e.CurrentDistrictId = c.currentDistrictId
inner join Districts d on e.currentDistrictId = d.Id
inner join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
 --where ConsentDate_FromCompliance is not null and ConsentDate_FromForm is null 
 --and c.currentDistrictId <> 267 and    c.ECIReferral != 'Yes' and c.Age is null
 --and YearOfConsent = 2023
 --and c.Ind12_FIIEDueDate is null


 --and FIIEDueDate is null
 --15932
 --14302

OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @student_uid
WHILE @@FETCH_STATUS = 0
BEGIN 

begin tran
    --Do something with Id here
	-- get current district for student one by one 
		declare @currentDistrict int = ( Select top 1 currentDistrictId from Compliances_ManualUpdate where Student_Uid = @student_uid )
		declare @initialConsentDate datetime =(Select top 1 ConsentDate_FromCompliance from Compliances_ManualUpdate where Student_Uid = @student_uid)
		
		--fetch current year and next year for InitialConsentForEvaluation
		declare @currentyear int  = (select year(@initialConsentDate))
		declare @summerBreak datetime = cast( (select cast(@Currentyear as varchar)+'-06-01' ) as datetime)
		declare @previousAcademicYear varchar(8)
		declare @currentAcademicYear varchar(8)
		declare @nextAcademicYear varchar(8)
		declare @SchooldaysMoved int=0 		
	
		-- for find current academic year
		if (@initialConsentDate<@summerBreak)
		begin 
			set @currentAcademicYear  =  cast( (@currentyear - 1 )as varchar) +'-'+substring(cast(@currentyear as varchar),3,2)
		end
		else 
		begin 
			set @currentAcademicYear =  cast( (@currentyear)as varchar) +'-'+substring(cast((@currentyear+1)as varchar),3,2)
		end
				
		--for find next academic year
		set @nextAcademicYear = substring(@currentAcademicYear,1,2)+substring(@currentAcademicYear,6,2)+'-'+cast(cast(substring(@currentAcademicYear,6,2) as int)+ 1 as varchar)
		set @nextAcademicYear = (Select AcademicYear from DistrictDates where DistrictId = @currentDistrict and AcademicYear=@nextAcademicYear)
		
		-- summer break is different form academic calendar ( Need to use previous and current academic year to calculate date originated in previous year)		
		if (@initialConsentDate < (Select FirstDayCurrentYear from DistrictDates where DistrictId = @currentDistrict and AcademicYear=@currentAcademicYear))
		begin
			set @previousAcademicYear= substring(@currentAcademicYear,1,2)+cast(cast(substring(@currentAcademicYear,3,2)as int)-1 as varchar)+'-'+substring(@currentAcademicYear,3,2)
			if exists( select AcademicYear from DistrictDates where DistrictId = @currentDistrict and AcademicYear=@previousAcademicYear)
			begin 					
				set @nextAcademicYear=@currentAcademicYear
				set @currentAcademicYear=@previousAcademicYear
			end			
		end

		--calculate school days 
		declare @safeItterations int = 300 
		declare @IsInvaliddate bit = 0		
		declare @MovedUnder45 int=0
		declare @spacialCase bit =0
		declare @AdjustDay datetime 
		declare @LastSchoolDay datetime = (Select LastDayCurrentYear from DistrictDates where DistrictId = @currentDistrict and AcademicYear=@currentAcademicYear)
		declare @FirstSchoolDay datetime = (Select FirstDayCurrentYear from DistrictDates where DistrictId = @currentDistrict and AcademicYear=@currentAcademicYear)
		
		if (@currentAcademicYear = null)
		begin 
			-- loop will not execute below
			set @SchooldaysMoved = 100
		end

		set @AdjustDay=@LastSchoolDay
		
		--calculate school days from last day of school (checking for criteria 45+ or 35-44 or 0-34)
		while (@SchooldaysMoved < 45 and @AdjustDay > @FirstSchoolDay )
		begin 
			
				Set @AdjustDay =(SELECT DATEADD(day,-1,@AdjustDay))

				--for holiday existance and school day count
				if not exists  (Select ds.SpecialDate from DistrictDates dd left join DistrictSpecialDates ds on dd.Id= ds.DistrictDatesId where dd.DistrictId = @currentDistrict and dd.AcademicYear=@currentAcademicYear and  SpecialDate= @AdjustDay  )
				begin
					set @SchooldaysMoved = @SchooldaysMoved + 1
				end	

				set @safeItterations = @safeItterations - 1
				if (@safeItterations=0)
				begin 
					set @SchooldaysMoved=100					
				end 
				if (@initialConsentDate=@AdjustDay)
				begin 
					set @MovedUnder45=@SchooldaysMoved
				end
		end
		
		--prevent from error
		if (@currentAcademicYear is not null)
		begin 
			set @SchooldaysMoved=0
			set @AdjustDay = @initialConsentDate
			set @safeItterations =300
		end
		
		--for school day between 35 to 44
		if (@MovedUnder45 is not null and @MovedUnder45>=35 and @MovedUnder45<45 )
		begin 
				set @spacialCase = 1
				Set @AdjustDay =  cast (cast(YEAR(@LastSchoolDay) as varchar)+'-06-30' as datetime)				
		end		
		
		--for school day 45+ or 0-34
		declare @workingLastDay datetime = (Select LastDayCurrentYear from DistrictDates where DistrictId = @currentDistrict and AcademicYear=@currentAcademicYear)
		declare @absentDay int = (select NumberOfAbsences from Compliances_ManualUpdate  where Student_Uid = @student_uid and NumberOfAbsences>2)
		
		while (@SchooldaysMoved < 45+isnull(@absentDay,0)  and @spacialCase =0 )
		begin	
				
				Set @AdjustDay =(SELECT DATEADD(day,1,@AdjustDay))
				
				--calculate school days for current academic year
				if (@AdjustDay <= @workingLastDay)
				begin 
					if not exists  (Select ds.SpecialDate from DistrictDates dd left join DistrictSpecialDates ds on dd.Id= ds.DistrictDatesId where dd.DistrictId = @currentDistrict and dd.AcademicYear=@currentAcademicYear and  SpecialDate= @AdjustDay )
					begin
						set @SchooldaysMoved = @SchooldaysMoved + 1
					end	
								
				end

				--when school days lies in next academic year
				if (@AdjustDay >= @workingLastDay and  @nextAcademicYear is not null)
				begin 										
					 set @currentAcademicYear=@nextAcademicYear
					 set @workingLastDay = (Select LastDayCurrentYear from DistrictDates where DistrictId = @currentDistrict and AcademicYear=@nextAcademicYear)
					 declare @firstSchooldays datetime = (Select FirstDayCurrentYear from DistrictDates where DistrictId = @currentDistrict and AcademicYear=@nextAcademicYear)
					 
					  --apply != 45 for exact 45 days
					 if (@firstSchooldays is not  null and @SchooldaysMoved != (45+isnull(@absentDay,0)) )
					 begin
						set @AdjustDay = DATEADD(day,-1,@firstSchooldays)                        
					 end
					 else if (@LastSchoolDay is not null)
					 begin
						set @AdjustDay = @LastSchoolDay    
					 end
				end
				else if (@AdjustDay >= @workingLastDay and @nextAcademicYear is null)
				begin
					Set @AdjustDay =(DATEADD(day,45-@SchooldaysMoved,@AdjustDay))
					set @SchooldaysMoved = 100
				end 

				set @safeItterations = @safeItterations - 1

				if (@safeItterations=0)
				begin 
					set @SchooldaysMoved=100					
				end 
									
		end 	
		 
		--	update  #student set Indicator11FIIEDueDate=@AdjustDay where RowNumber=@count and @SchooldaysMoved<=100
			update  s 
			set  schooldaysMoved = @SchooldaysMoved , Ind11_FIIEDueDate = @AdjustDay
			from Compliances_ManualUpdate s 			 
			where  Student_Uid = @student_uid and @SchooldaysMoved<=100 and Age >= 3
			

commit tran

    --PRINT @PractitionerId
    FETCH NEXT FROM MY_CURSOR INTO @student_uid
END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR





--Indicator11 FIIE Due Date
select  c.Indicator11FIIEDueDate ,a.Ind11_FIIEDueDate
from Compliances_ManualUpdate a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where (c.Indicator11FIIEDueDate is null or c.Indicator11FIIEDueDate <> a.Ind11_FIIEDueDate)
  
  
  
update c
set Indicator11FIIEDueDate = a.Ind11_FIIEDueDate 
from Compliances_ManualUpdate a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where (c.Indicator11FIIEDueDate is null or c.Indicator11FIIEDueDate <> a.Ind11_FIIEDueDate)



	------------------------------------------------------------------------------------------------------
	--SPP 11 IEP Meeting Due Date--

--------------- With FIIE Locked form -- ----------------
select Ind11_FIIEDueDate, *
			from Compliances_ManualUpdate s 
 where Ind11_FIIEDueDate is not null

drop table FIIELockedForm

select    d.name as districName,CurrentDistrictId as DistrictId ,DateOfBirth ,studentid ,Firstname ,lastname ,  
		   f.d.value('(Date/text())[1]', 'datetime')   as [ActualFIIEDate], DateLocked, Fi.StudentUid
into FIIELockedForm
from FormInstances fi 
outer apply fi.Data.nodes('Title') f(d)
left join Students s (nolock) on s.[Uid] = fi.[StudentUid]
left join Compliances c on c.Student_Uid=fi.StudentUid 	
left join FormTypes ft on ft.Id=fi.FormTypeId
left join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
join Districts d on e.currentDistrictId = d.Id
where   Locked=1 and  (ft.Name = 'Full and Individual Evaluation' and  ft.PluginType= 'Forms.FIEv2.Title') and( c.ReferralType ='NO' or  c.ReferralType ='' or  c.ReferralType is null )
		and c.InitialConsentForEvaluation is not null and  f.d.value('(Report/text())[1]', 'varchar(max)') ='Full Individual and Initial Evaluation'
and currentDistrictId <> 267 

drop table FIIELockedForm_AllForms

select  row_number() over(partition by  StudentUid order by ActualFIIEDate desc) as RowNumber, *
into FIIELockedForm_AllForms
from FIIELockedForm
 

 

 update e
 set e.Ind11_IEPMeetingDueDate = DATEADD(day,30, f.ActualFIIEDate)  
 from Compliances_ManualUpdate e
 inner join FIIELockedForm_AllForms f on e.Student_Uid = f.StudentUid
 where currentDistrictId <> 267 and ECIReferral != 'Yes' and f.RowNumber = 1
 
-- select   e.Ind11_IEPMeetingDueDate ,dd.BeginningOfFollowingYear
-- from Compliances_ManualUpdate e 
-- inner join FIIELockedForm_AllForms f on e.Student_Uid = f.StudentUid  
--inner join Students s on s.uid = f.StudentUid
--inner join Compliances c on c.Student_Uid = f.StudentUid
--inner join DistrictDates dd on dd.DistrictId = f.DistrictId
--where RowNumber = 1 and   ECIReferral != 'Yes' 
--and DATEADD(day,30, f.ActualFIIEDate) > dd.LastDayCurrentYear
--and DATEADD(day,30, f.ActualFIIEDate) < dd.BeginningOfFollowingYear


 -- when IEP Meeting Due date is in summer --
 update e
 set e.Ind11_IEPMeetingDueDate = dd.BeginningOfFollowingYear
 from Compliances_ManualUpdate e 
 inner join FIIELockedForm_AllForms f on e.Student_Uid = f.StudentUid  
inner join Students s on s.uid = f.StudentUid
inner join Compliances c on c.Student_Uid = f.StudentUid
inner join DistrictDates dd on dd.DistrictId = f.DistrictId
where RowNumber = 1 and   ECIReferral != 'Yes' 
and DATEADD(day,30, f.ActualFIIEDate) > dd.LastDayCurrentYear
and DATEADD(day,30, f.ActualFIIEDate) < dd.BeginningOfFollowingYear



 update c
 set c.Indicator11IEPMeetingDueDate = DATEADD(day,30, f.ActualFIIEDate)  
 from Compliances c
 inner join  Compliances_ManualUpdate e on e.Student_Uid = c.Student_Uid
 inner join FIIELockedForm_AllForms f on e.Student_Uid = f.StudentUid
 where currentDistrictId <> 267 and ECIReferral != 'Yes' and f.RowNumber = 1

 -- when IEP Meeting Due date is in summer --
  update c
 set c.Indicator11IEPMeetingDueDate = e.Ind11_IEPMeetingDueDate  
 from Compliances c
 inner join  Compliances_ManualUpdate e on e.Student_Uid = c.Student_Uid
 inner join FIIELockedForm_AllForms f on e.Student_Uid = f.StudentUid
 inner join DistrictDates dd on dd.DistrictId = f.DistrictId
 where currentDistrictId <> 267 and ECIReferral != 'Yes' and f.RowNumber = 1
 and DATEADD(day,30, f.ActualFIIEDate) > dd.LastDayCurrentYear
and DATEADD(day,30, f.ActualFIIEDate) < dd.BeginningOfFollowingYear


 

 


--------------------

--scenario 2 

 Select e.NumberOfAbsences, convert(varchar(5),Indicator11FIIEDueDate,110), Indicator11FIIEDueDate , Indicator11IEPMeetingDueDate,DATEADD(day,15,FirstDayCurrentYear)  ,  e.*
 from Compliances_ManualUpdate e
 inner join districtdates dd on dd.DistrictId = e.CurrentDistrictId
 where  Indicator11FIIEDueDate  = '06-30-2022'
 and Indicator11FIIEDueDate < FirstDayCurrentYear
 and isnull(e.NumberOfAbsences, 0) < 3
-- and e.StudentId = '862932'
 and e.YearOfConsent = year(FirstDayCurrentYear)

and e.studentid = '326394'  

select * from districts where name like '%alief%'

 update e
 set Ind11_IEPMeetingDueDate ='2022-08-29'--DATEADD(day,15,dd.FirstDayCurrentYear)
 from Compliances_ManualUpdate e
 inner join districtdates dd on dd.DistrictId = e.CurrentDistrictId
 where  Indicator11FIIEDueDate  = '06-30-2022'
 and Indicator11FIIEDueDate < FirstDayCurrentYear
 and isnull(e.NumberOfAbsences, 0) < 3 
 and e.currentDistrictId = 441
  
  select IEPMeetingDueDate, Indicator11IEPMeetingDueDate, * from compliances
  where Student_Uid = 'C10A9160-AC13-490E-8D9B-77861B8ACD61'

 update c
set Indicator11IEPMeetingDueDate = a.Ind11_IEPMeetingDueDate 
from Compliances_ManualUpdate a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where  currentDistrictId <> 267 and ECIReferral != 'Yes'
 -- and convert(varchar(5),a.Indicator11FIIEDueDate,110) = '06-30'
 and  isnull(a.NumberOfAbsences, 0) < 3 
  and a.currentDistrictId = 441

 


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
--select top 10 * -- c.Indicator11TSDSParentalConsentDate ,a.Ind11_TSDSParentConsentDate 
--from Compliances_ManualUpdate a 
--inner join Compliances c on c.Student_Uid = a.Student_Uid
--where ( c.Indicator11TSDSParentalConsentDate is null or c.Indicator11TSDSParentalConsentDate <> a.Ind11_TSDSParentConsentDate)
 
 
update c
set Indicator11TSDSParentalConsentDate = a.Ind11_TSDSParentConsentDate 
from Compliances_ManualUpdate a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where ( c.Indicator11TSDSParentalConsentDate is null or c.Indicator11TSDSParentalConsentDate <> a.Ind11_TSDSParentConsentDate)
 
--Indicator12TSDSParentalConsentDate

--select  c.Indicator12TSDSParentalConsentDate ,a.Ind12_TSDSParentConsentDate 
--from Compliances_ManualUpdate a 
--inner join Compliances c on c.Student_Uid = a.Student_Uid
--where c.Indicator12TSDSParentalConsentDate <> a.Ind12_TSDSParentConsentDate


update c
set Indicator12TSDSParentalConsentDate = a.Ind12_TSDSParentConsentDate 
from Compliances_ManualUpdate a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator12TSDSParentalConsentDate <> a.Ind12_TSDSParentConsentDate


--Indicator11 FIIE Due Date
select  c.Indicator11FIIEDueDate ,a.Ind11_FIIEDueDate
from Compliances_ManualUpdate a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where (c.Indicator11FIIEDueDate is null or c.Indicator11FIIEDueDate <> a.Ind11_FIIEDueDate)
  
  
  
update c
set Indicator11FIIEDueDate = a.Ind11_FIIEDueDate 
from Compliances_ManualUpdate a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where (c.Indicator11FIIEDueDate is null or c.Indicator11FIIEDueDate <> a.Ind11_FIIEDueDate)



--Indicator12 FIIE Due Date
--select  c.Indicator12FIIEDueDate ,a.Ind12_FIIEDueDate
--from Compliances_ManualUpdate a 
--inner join Compliances c on c.Student_Uid = a.Student_Uid
--where  --c.Indicator12FIIEDueDate <> a.Ind12_FIIEDueDate
---- and
--a.student_uid = '5306A84F-F15C-499F-806D-0112FAFB5185'

update c
set Indicator12FIIEDueDate = a.Ind12_FIIEDueDate 
from Compliances_ManualUpdate a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator12FIIEDueDate <> a.Ind12_FIIEDueDate



----Indicator11 IEP Meeting Due Date----






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
--and e.CurrentDistrictId = @districtId
and currentDistrictId <> 267 


 
update c
set Indicator11IEPMeetingDueDate = a.Ind11_IEPMeetingDueDate 
from Compliances_ManualUpdate a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where  currentDistrictId <> 267 and ECIReferral != 'Yes'
and a.YearOfConsent = 2023




 