
--begin tran

IF object_id('tempdb..#ConsentForEval') IS NOT NULL DROP TABLE #ConsentForEval
IF object_id('tempdb..#student') IS NOT NULL DROP TABLE #student
IF object_id('tempdb..#tmp') IS NOT NULL DROP TABLE #tmp

declare @districtId int = 674 --Marullo

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
and e.CurrentDistrictId = @districtId



Select row_number() over(partition by  t.StudentUid order by t.ParentSignatureDate asc) AS RowNumber, Student_Uid,  Indicator11TSDSParentalConsentDate, Indicator12TSDSParentalConsentDate,InitialConsentForEvaluation,currentDistrictId,d.name as districName ,DateOfBirth  ,s.studentid,Firstname,lastname,c.DateUpdated,  c.ReferralType as ECIReferral
into #student
from Compliances c
inner join #ConsentForEval t on t.studentuid = c.Student_Uid
left join students s on s.Uid = c.Student_Uid
left join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
left join Districts d on e.currentDistrictId = d.Id
left join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
where CurrentDistrictId = @districtId
  


select  IDENTITY(int, 1, 1) as ROW_ID, * --, AdjustDay datetime
into #tmp
from #student 
where
RowNumber = 1

alter table #tmp add AdjustDay datetime
alter table #tmp add SchooldaysMoved int
 
declare @rowId int;
SET @rowId = 1 ;   
WHILE @rowId <= (select ROW_ID from #tmp where ROW_ID = @rowId) 
BEGIN  
		
		-- get current district for student one by one 
		declare @currentDistrict int = (Select top 1 currentDistrictId from #tmp where row_id = @rowId)
		declare @initialConsentDate datetime =(Select InitialConsentForEvaluation from #tmp where row_id = @rowId)
		
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
		
		--prevent from error
		if (@currentAcademicYear is not null)
		begin 
			set @SchooldaysMoved=0
			set @AdjustDay = @initialConsentDate
			set @safeItterations =300
		end
		
		--for school day 45+ or 0-34
		declare @workingLastDay datetime = (Select LastDayCurrentYear from DistrictDates where DistrictId = @currentDistrict and AcademicYear=@currentAcademicYear)
				
		while (@SchooldaysMoved < 1  )
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
					 if (@firstSchooldays is not  null and @SchooldaysMoved != (45) )
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
			

			update  s 
			set AdjustDay = @AdjustDay, SchooldaysMoved = @SchooldaysMoved 
			from #tmp s 			 
			where  row_id = @rowId and @SchooldaysMoved<=100
			

	set @rowId = @rowId+1
END				
			
		 
	--	IF object_id('tempdb..#student') IS NOT NULL DROP TABLE #student
	--select * from #tmp

	----- Indicator11TSDSParentalConsentDate ---
	select c.Indicator11TSDSParentalConsentDate, t.AdjustDay, t.SchooldaysMoved
	from Compliances  c inner join #tmp t on t.student_uid = c.student_uid
	where t.SchooldaysMoved < 100 and ECIReferral in ( 'No', '')

	update c
	set Indicator11TSDSParentalConsentDate = t.AdjustDay
	from Compliances  c inner join #tmp t on t.student_uid = c.student_uid
	where t.SchooldaysMoved < 100 and ECIReferral in ( 'No', '')

	----- Indicator12TSDSParentalConsentDate ---
	select c.Indicator12TSDSParentalConsentDate, t.AdjustDay, t.SchooldaysMoved
	from Compliances  c inner join #tmp t on t.student_uid = c.student_uid
	where t.SchooldaysMoved < 100 and ECIReferral  = 'Yes'

	update c
	set Indicator12TSDSParentalConsentDate = t.AdjustDay
	from Compliances  c inner join #tmp t on t.student_uid = c.student_uid
	where t.SchooldaysMoved < 100 and ECIReferral   = 'Yes'

	
--rollback tran