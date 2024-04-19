

-- SPP 12 - TSDSParentalConsentDate--
select  * from Compliances_ConsentForEval_LatestForm 
where ECIReferral = 'Yes'
and Indicator12TSDSParentalConsentDate != Ind12_TSDSParentConsentDate


-- SPP 12 - FIIEDueDate--
select  * from Compliances_ConsentForEval_LatestForm 
where ECIReferral = 'Yes'
and Indicator12FIIEDueDate != Ind12_FIIEDueDate

 


-- SPP 11 - FIIEDueDate--
select  * from Compliances_ConsentForEval_LatestForm 
where Age >= 3 
and Indicator11FIIEDueDate != Ind11_FIIEDueDate

-- SPP 11 - TSDSParentalConsentDate--
select  * from Compliances_ConsentForEval_LatestForm 
where Age >= 3 
and Indicator11TSDSParentalConsentDate != Ind11_TSDSParentConsentDate



select top 10 * from districts where name like 'cy%'

select count(*) from Compliances_ConsentForEval_LatestForm 
where ECIReferral != 'Yes'
AND IEPMeetingDueDate is null
and currentDistrictId = 267


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