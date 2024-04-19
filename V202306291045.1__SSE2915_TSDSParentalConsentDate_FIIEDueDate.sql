
 
--begin tran

IF object_id('tempdb..#ConsentForEval') IS NOT NULL DROP TABLE #ConsentForEval
IF object_id('tempdb..#student') IS NOT NULL DROP TABLE #student
IF object_id('tempdb..#tmp') IS NOT NULL DROP TABLE #tmp


drop table ConsentForEval
drop table Compliances_ConsentForEval
drop table Compliances_ConsentForEval_LatestForm

--declare @districtId int = 674 --Marullo
 
select count(*)
s.StudentId,  fi.studentuid, 
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(max)') as TypeOfEvaluation,
f.d.value('(GivePermission/text())[1]', 'varchar(max)') as GivePermission,
f.d.value('(ParentSignatureDate/text())[1]', 'datetime') as ParentSignatureDate,
f.d.value('(Date/text())[1]', 'datetime') as ConsentDate
--into ConsentForEval
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where formtypeid = 165
--and e.CurrentDistrictId = @districtId
and currentDistrictId <> 267 
--and s.studentid = '204959'

 
Select row_number() over(partition by  t.StudentUid order by t.ParentSignatureDate asc) AS RowNumber, Student_Uid,  
ConsentDate AS ConsentDate_FromForm, 
InitialConsentForEvaluation AS ConsentDate_FromCompliance,currentDistrictId,NumberOfAbsences, 
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
s.studentid ,Firstname ,lastname,c.DateUpdated, 
c.ReferralType as ECIReferral
into Compliances_ConsentForEval
from Compliances c
inner join ConsentForEval t on t.studentuid = c.Student_Uid
inner join students s on s.Uid = c.Student_Uid
inner join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
inner join Districts d on e.currentDistrictId = d.Id
inner join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
where TypeOfEvaluation = 'Initial' 
and currentDistrictId = 267 
-- and s.studentid = '492705'
 
select  IDENTITY(int, 1, 1) as ROW_ID, *
into Compliances_ConsentForEval_LatestForm
from Compliances_ConsentForEval 
where RowNumber = 1

alter table Compliances_ConsentForEval_LatestForm add AdjustDay datetime
alter table Compliances_ConsentForEval_LatestForm add SchooldaysMoved int
alter table Compliances_ConsentForEval_LatestForm add Ind11_TSDSParentConsentDate datetime
alter table Compliances_ConsentForEval_LatestForm add Ind11_FIIEDueDate datetime
alter table Compliances_ConsentForEval_LatestForm add Ind11_IEPMeetingDueDate datetime
alter table Compliances_ConsentForEval_LatestForm add thirdBirthday datetime
alter table Compliances_ConsentForEval_LatestForm add Ind12_TSDSParentConsentDate datetime
alter table Compliances_ConsentForEval_LatestForm add Ind12_FIIEDueDate datetime
alter table Compliances_ConsentForEval_LatestForm add Ind12_IEPMeetingDueDate datetime

 ----------------------------------------------------------------------------------------------------------------------------------------------



--SPP12 - TSDSParentConsentDate--
update Compliances_ConsentForEval_LatestForm 
set Ind12_TSDSParentConsentDate = (select [dbo].[fnAdjustSchoolDays](currentDistrictId, ConsentDate_FromForm, 1))
where ECIReferral = 'Yes'

--SPP11 - TSDSParentConsentDate--
update Compliances_ConsentForEval_LatestForm 
set Ind11_TSDSParentConsentDate = (select [dbo].[fnAdjustSchoolDays](currentDistrictId, ConsentDate_FromForm, 1))
where Age > 3


--thirdBirthday--
update Compliances_ConsentForEval_LatestForm 
set thirdBirthday = DATEADD(year, 3, DateOfBirth)
where Age < 3

-- SPP12 ONLY - FIIEDueDate, IEPMeetingDueDate --
update Compliances_ConsentForEval_LatestForm 
set Ind12_FIIEDueDate = thirdBirthday, Ind12_IEPMeetingDueDate = thirdBirthday
where ECIReferral = 'Yes'-- and Age < 3



 
  
	------------------------------------------------------------------------------------------------------
	--SPP 11 FIIE Due Date--

DECLARE @student_uid uniqueidentifier

DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR  
 
 select  DISTINCT   student_uid from Compliances_ConsentForEval_LatestForm
 where currentDistrictId = 267 and Age >= 3 --and ECIReferral != 'Yes' --and FIIEDueDate is null
 --15932
 --14302

OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @student_uid
WHILE @@FETCH_STATUS = 0
BEGIN 

begin tran
    --Do something with Id here
	-- get current district for student one by one 
		declare @currentDistrict int = 267--(Select top 1 currentDistrictId from Compliances_ConsentForEval_LatestForm where Student_Uid = @student_uid )
		declare @initialConsentDate datetime =(Select top 1 ConsentDate_FromForm from Compliances_ConsentForEval_LatestForm where Student_Uid = @student_uid)
		
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
		declare @absentDay int = (select NumberOfAbsences from Compliances_ConsentForEval_LatestForm where Student_Uid = @student_uid and NumberOfAbsences>2)
		
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
			set AdjustDay = @AdjustDay, SchooldaysMoved = @SchooldaysMoved , Ind11_FIIEDueDate = @AdjustDay
			from Compliances_ConsentForEval_LatestForm s 			 
			where  Student_Uid = @student_uid and @SchooldaysMoved<=100 and Age >= 3
			

commit tran

    --PRINT @PractitionerId
    FETCH NEXT FROM MY_CURSOR INTO @student_uid
END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR


	------------------------------------------------------------------------------------------------------
	--SPP 11 IEP Meeting Due Date--

--------------- With FIIE Locked form -- ----------------
select   row_number() over(partition by  fi.StudentUid order by fi.datelocked desc) as RowNumber, DateLocked, d.name as districName,CurrentDistrictId as DistrictId ,DateOfBirth ,studentid ,Firstname ,lastname , InitialConsentForEvaluation,
		   f.d.value('(Date/text())[1]', 'varchar(max)')   as [Indicator11ActualFIIEDate], Fi.StudentUid
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
and currentDistrictId = 267 


DECLARE @student_uid uniqueidentifier

DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR  
 
 select  DISTINCT   student_uid 
 from Compliances_ConsentForEval_LatestForm e
 inner join FIIELockedForm f on e.Student_Uid = f.StudentUid
 where currentDistrictId = 267 and Age >= 3 
 
 --and ECIReferral != 'Yes' --and FIIEDueDate is null
 
OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @student_uid
WHILE @@FETCH_STATUS = 0
BEGIN 

begin tran
    --Do something with Id here
	-- get current district for student one by one 
		declare @currentDistrict int = 267--(Select top 1 currentDistrictId from Compliances_ConsentForEval_LatestForm where Student_Uid = @student_uid )
		declare @initialConsentDate datetime =(Select top 1 Indicator11ActualFIIEDate  
												from Compliances_ConsentForEval_LatestForm e
												 inner join FIIELockedForm f on e.Student_Uid = f.StudentUid
												 where currentDistrictId = 267 and Age >= 3 
												and Student_Uid = @student_uid)
		
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
		declare @absentDay int = (select NumberOfAbsences from Compliances_ConsentForEval_LatestForm where Student_Uid = @student_uid and NumberOfAbsences>2)
		
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
			set AdjustDay = @AdjustDay, SchooldaysMoved = @SchooldaysMoved , Ind11_IEPMeetingDueDate = @AdjustDay
			from Compliances_ConsentForEval_LatestForm s 			 
			where  Student_Uid = @student_uid and @SchooldaysMoved<=100 and Age >= 3
			

commit tran

    --PRINT @PractitionerId
    FETCH NEXT FROM MY_CURSOR INTO @student_uid
END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR


--------------- WithOUT FIIE Locked form -- ----------------
 

DECLARE @student_uid uniqueidentifier

DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR  
 
 select  DISTINCT   student_uid 
 from Compliances_ConsentForEval_LatestForm e
 left join FIIELockedForm f on e.Student_Uid = f.StudentUid
 where currentDistrictId = 267 and Age >= 3 
 and Indicator11ActualFIIEDate is null

 --and ECIReferral != 'Yes' --and FIIEDueDate is null
 
OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @student_uid
WHILE @@FETCH_STATUS = 0
BEGIN 

begin tran
    --Do something with Id here
	-- get current district for student one by one 
		declare @currentDistrict int = 267--(Select top 1 currentDistrictId from Compliances_ConsentForEval_LatestForm where Student_Uid = @student_uid )
		declare @initialConsentDate datetime =(Select top 1 Indicator11FIIEDueDate
												from Compliances_ConsentForEval_LatestForm e
												 inner join FIIELockedForm f on e.Student_Uid = f.StudentUid
												 where currentDistrictId = 267 and Age >= 3 
												and Student_Uid = @student_uid)
		
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
		declare @absentDay int = (select NumberOfAbsences from Compliances_ConsentForEval_LatestForm where Student_Uid = @student_uid and NumberOfAbsences>2)
		
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
			set AdjustDay = @AdjustDay, SchooldaysMoved = @SchooldaysMoved , Ind11_IEPMeetingDueDate = @AdjustDay
			from Compliances_ConsentForEval_LatestForm s 			 
			where  Student_Uid = @student_uid and @SchooldaysMoved<=100 and Age >= 3
			

commit tran

    --PRINT @PractitionerId
    FETCH NEXT FROM MY_CURSOR INTO @student_uid
END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR


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
and currentDistrictId = 267 



--Indicator11TSDSParentalConsentDate
select  c.Indicator11TSDSParentalConsentDate ,a.Ind11_TSDSParentConsentDate 
from Compliances_ConsentForEval_LatestForm a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator11TSDSParentalConsentDate <> a.Ind11_TSDSParentConsentDate

 
update c
set Indicator11TSDSParentalConsentDate = a.Ind11_TSDSParentConsentDate 
from Compliances_ConsentForEval_LatestForm a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator11TSDSParentalConsentDate <> a.Ind11_TSDSParentConsentDate

--Indicator12TSDSParentalConsentDate

select  c.Indicator12TSDSParentalConsentDate ,a.Ind12_TSDSParentConsentDate 
from Compliances_ConsentForEval_LatestForm a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator12TSDSParentalConsentDate <> a.Ind12_TSDSParentConsentDate


update c
set Indicator12TSDSParentalConsentDate = a.Ind12_TSDSParentConsentDate 
from Compliances_ConsentForEval_LatestForm a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator12TSDSParentalConsentDate <> a.Ind12_TSDSParentConsentDate


--Indicator11 FIIE Due Date
select  c.Indicator11FIIEDueDate ,a.Ind11_FIIEDueDate
from Compliances_ConsentForEval_LatestForm a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator11FIIEDueDate <> a.Ind11_FIIEDueDate

update c
set Indicator11FIIEDueDate = a.Ind11_FIIEDueDate 
from Compliances_ConsentForEval_LatestForm a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator11FIIEDueDate <> a.Ind11_FIIEDueDate



--Indicator12 FIIE Due Date
select  c.Indicator12FIIEDueDate ,a.Ind12_FIIEDueDate
from Compliances_ConsentForEval_LatestForm a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator12FIIEDueDate <> a.Ind12_FIIEDueDate

update c
set Indicator12FIIEDueDate = a.Ind12_FIIEDueDate 
from Compliances_ConsentForEval_LatestForm a 
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
and currentDistrictId = 267 


select  c.Indicator11IEPMeetingDueDate ,a.Ind11_IEPMeetingDueDate
from Compliances_ConsentForEval_LatestForm a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator11IEPMeetingDueDate <> a.Ind11_IEPMeetingDueDate
 

update c
set Indicator11IEPMeetingDueDate = a.Ind11_IEPMeetingDueDate 
from Compliances_ConsentForEval_LatestForm a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where c.Indicator11IEPMeetingDueDate <> a.Ind11_IEPMeetingDueDate
and currentDistrictId = 267 and Age >= 3 


----------------------------------------------------------------------------------------------
---TESTING ---
select Indicator11IEPMeetingDueDate , Ind11_IEPMeetingDueDate from Compliances_ConsentForEval_LatestForm 
where studentid = '172158'

select   *
from Compliances_ConsentForEval_LatestForm a  
where  studentid = '112521'

select  *
from Compliances_ConsentForEval_LatestForm a 
inner join Compliances c on c.Student_Uid = a.Student_Uid
where  studentid = 'ER052919'


 (select [dbo].[fnAdjustSchoolDays](267, '6/7/2023', 1))


 select s.StudentId,  fi.studentuid, 
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(max)') as TypeOfEvaluation,
f.d.value('(GivePermission/text())[1]', 'varchar(max)') as GivePermission,
f.d.value('(ParentSignatureDate/text())[1]', 'datetime') as ParentSignatureDate,
f.d.value('(Date/text())[1]', 'datetime') as ConsentDate
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where formtypeid = 165
--and e.CurrentDistrictId = @districtId
and currentDistrictId = 267 
and s.studentid = '204959'


Select row_number() over(partition by  t.StudentUid order by t.ParentSignatureDate asc) AS RowNumber, Student_Uid,  
ConsentDate AS ConsentDate_FromForm, 
InitialConsentForEvaluation AS ConsentDate_FromCompliance,currentDistrictId,NumberOfAbsences, 
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
s.studentid ,Firstname ,lastname,c.DateUpdated, 
c.ReferralType as ECIReferral
into Compliances_ManualUpdate
from Compliances c
left join ConsentForEval t on t.studentuid = c.Student_Uid and t.ConsentDate is null
inner join students s on s.Uid = c.Student_Uid
inner join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
inner join Districts d on e.currentDistrictId = d.Id
inner join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
where  currentDistrictId = 267 
and s.studentid = '204959'

