
 

 select * from tmp_3107_sept_2
 where student_uid = 'C54F632F-C6F2-4C73-8425-9FE679E13304' 
--begin tran

IF object_id('tempdb..#ConsentForEval') IS NOT NULL DROP TABLE #ConsentForEval
IF object_id('tempdb..#student') IS NOT NULL DROP TABLE #student
IF object_id('tempdb..#tmp') IS NOT NULL DROP TABLE #tmp

 
 select s.StudentId,  fi.studentuid, 
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(max)') as TypeOfEvaluation,
f.d.value('(GivePermission/text())[1]', 'varchar(max)') as GivePermission,
f.d.value('(ParentSignatureDate/text())[1]', 'datetime') as ParentSignatureDate,
f.d.value('(Date/text())[1]', 'datetime') as ConsentDate
--into ConsentForEval_3107_Sept_2
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where formtypeid = 165  
and f.d.value('(ParentSignatureDate/text())[1]', 'datetime') is null
and f.d.value('(Date/text())[1]', 'datetime') >= '01/01/2023'
--and fi.StudentUid = 'C54F632F-C6F2-4C73-8425-9FE679E13304' 
--and e.CurrentDistrictId = @districtId
 --and studentid = '0857453'

Select row_number() over(partition by  t.StudentUid order by t.ParentSignatureDate asc) AS RowNumber, Student_Uid,  Indicator11FIIEDueDate, Indicator12FIIEDueDate, InitialConsentForEvaluation,currentDistrictId,NumberOfAbsences, d.name as districName ,DateOfBirth ,s.studentid ,Firstname ,lastname,c.DateUpdated, c.ReferralType as ECIReferral
into student_3107_sept_2
from Compliances c
inner join ConsentForEval_3107_Sept_2 t on t.studentuid = c.Student_Uid
left join students s on s.Uid = c.Student_Uid
left join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
left join Districts d on e.currentDistrictId = d.Id
left join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
--where CurrentDistrictId = @districtId 


select * from tmp_3107_sept_2 where StudentId  = '170626'

 
select  IDENTITY(int, 1, 1) as ROW_ID, *
into tmp_3107_sept_2
from student_3107_sept_2
where RowNumber = 1

alter table tmp_3107_sept_2 add AdjustDay datetime
alter table tmp_3107_sept_2 add SchooldaysMoved int
alter table tmp_3107_sept_2 add Indicator11FIIEDueDateUpdated datetime
alter table tmp_3107_sept_2 add Indicator11IEPMtgDueDateUpdated datetime

alter table tmp_3107_sept_2 add Processed int
 

 update tmp_3107_sept_2
 set Processed = null
 where  Indicator11FIIEDueDateUpdated is not null

 --select * from tmp_3107_sept_2 where student_uid = '47D94929-292A-4E41-85D3-E0065D8FDEBD'

DECLARE @student_uid uniqueidentifier

DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR  
 

 select  DISTINCT top 10000  student_uid 
 from tmp_3107_sept_2 c
-- inner join students s on s.Uid = c.Student_Uid
--inner join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1 and e.CurrentDistrictId = c.currentDistrictId
where processed is null
 
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
		declare @currentDistrict int = ( Select top 1 currentDistrictId from tmp_3107_sept_2 where Student_Uid = @student_uid )
		declare @initialConsentDate datetime =(Select top 1 InitialConsentForEvaluation from tmp_3107_sept_2 where Student_Uid = @student_uid)
		
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
		declare @absentDay int = (select NumberOfAbsences from tmp_3107_sept_2  where Student_Uid = @student_uid and NumberOfAbsences>2)
		
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
			set  schooldaysMoved = @SchooldaysMoved , Indicator11FIIEDueDateUpdated = @AdjustDay, Processed = 1
			from tmp_3107_sept_2 s 			 
			where  Student_Uid = @student_uid and @SchooldaysMoved<=100 --and Age >= 3
			

commit tran

    --PRINT @PractitionerId
    FETCH NEXT FROM MY_CURSOR INTO @student_uid
END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR

--------------------------------------------------------------------------------------------------------------------


select * from tmp_3107_sept_2 
where CurrentDistrictId = 267 and StudentId in ('RG312003', '224316')
month(Indicator11IEPMtgDueDateUpdated) = 6

 
			
		 
	--	IF object_id('tempdb..#student') IS NOT NULL DROP TABLE #student
	--select * from #tmp

	----- Indicator11FIIEDueDate ---
	--select c.Indicator11FIIEDueDate,   t.AdjustDay, t.SchooldaysMoved
	--from Compliances  c inner join tmp_3107_sept_2 t on t.student_uid = c.student_uid
	--where t.SchooldaysMoved < 100 and ECIReferral in ( 'No', '')

	--update c
	--set Indicator11FIIEDueDate = t.AdjustDay
	--from Compliances  c inner join tmp_3107_sept_2 t on t.student_uid = c.student_uid
	--where t.SchooldaysMoved < 100
	--and ECIReferral in ( 'No', '')




	---IEP Meeting Due date ---
	  update e
 set e.Indicator11IEPMtgDueDateUpdated = DATEADD(day,30, e.Indicator11FIIEDueDateUpdated)  
 from tmp_3107_sept_2 e


 select * from tmp_3107_sept_2
 where studentid in ('170626', '224316')


 -- when IEP Meeting Due date is in summer --
 select Indicator11FIIEDueDateUpdated, e.Indicator11IEPMtgDueDateUpdated , dd.BeginningOfFollowingYear
 from tmp_3107_sept_2 e 
 inner join Students s on s.uid = e.Student_Uid
inner join Compliances c on c.Student_Uid = e.Student_Uid
inner join DistrictDates dd on dd.DistrictId = e.currentDistrictId
where RowNumber = 1 and   ECIReferral != 'Yes' 
and DATEADD(day,30, Indicator11FIIEDueDateUpdated) > dd.LastDayCurrentYear
and DATEADD(day,30,Indicator11FIIEDueDateUpdated) < dd.BeginningOfFollowingYear
and dd.AcademicYear = '2022-23'
and Indicator11FIIEDueDateUpdated  != '06-30-2023' 


update e
set Indicator11IEPMtgDueDateUpdated = dd.BeginningOfFollowingYear
 from tmp_3107_sept_2 e 
 inner join Students s on s.uid = e.Student_Uid
inner join Compliances c on c.Student_Uid = e.Student_Uid
inner join DistrictDates dd on dd.DistrictId = e.currentDistrictId
where RowNumber = 1 and   ECIReferral != 'Yes' 
and DATEADD(day,30, Indicator11FIIEDueDateUpdated) > dd.LastDayCurrentYear
and DATEADD(day,30,Indicator11FIIEDueDateUpdated) < dd.BeginningOfFollowingYear
and dd.AcademicYear = '2022-23'
and Indicator11FIIEDueDateUpdated  != '06-30-2023' 





-- FIIE Due Date 06-30-2023 --

 select Indicator11IEPMtgDueDateUpdated, DATEADD(day,15,dd.FirstDayCurrentYear), e.*
  from tmp_3107_sept_2 e
 inner join districtdates dd on dd.DistrictId = e.CurrentDistrictId
 where  Indicator11FIIEDueDate  = '06-30-2023'
 and Indicator11FIIEDueDate < FirstDayCurrentYear
 and isnull(e.NumberOfAbsences, 0) < 3 
--and  CurrentDistrictId = 41 
and e.currentDistrictId = 603


 
 select distinct dd.FirstDayCurrentYear, Indicator11IEPMtgDueDateUpdated --Indicator11IEPMtgDueDateUpdated, DATEADD(day,15,dd.FirstDayCurrentYear), e.*
  from tmp_3107_sept_2 e
 inner join districtdates dd on dd.DistrictId = e.CurrentDistrictId
 where  Indicator11FIIEDueDate  = '06-30-2023'
 and Indicator11FIIEDueDate < FirstDayCurrentYear
 and isnull(e.NumberOfAbsences, 0) < 3
 and AcademicYear = '2023-24'
 order by dd.FirstDayCurrentYear

  
   update e
 set Indicator11IEPMtgDueDateUpdated = (Select dbo.fnAdjustSchoolDays(e.currentDistrictId, dd.FirstDayCurrentYear, 15))
 from tmp_3107_sept_2 e
 inner join districtdates dd on dd.DistrictId = e.CurrentDistrictId
 where  Indicator11FIIEDueDateUpdated  = '06-30-2023' 
 and AcademicYear = '2023-24'

 --update e 
 --set Indicator11IEPMtgDueDateUpdated = '2023-09-01' --DATEADD(day,15,dd.FirstDayCurrentYear)
 --from tmp_3107_sept_2 e
 --inner join districtdates dd on dd.DistrictId = e.CurrentDistrictId
 --where  Indicator11FIIEDueDate  = '06-30-2023'
 --and Indicator11FIIEDueDate < FirstDayCurrentYear
 --and isnull(e.NumberOfAbsences, 0) < 3 
 --and e.currentDistrictId = 142


select FirstDayCurrentYear, * from districtdates where DistrictId = 73 and AcademicYear = '2023-24'
select top 10 * from DistrictSpecialDates where DistrictDatesId = 5543

select * from tmp_3107_sept_2
where studentid = '0857453'



------FINAL SCRIPT----
update c
set c.Indicator11FIIEDueDate =  t.Indicator11FIIEDueDateUpdated, c.Indicator11IEPMeetingDueDate = t.Indicator11IEPMtgDueDateUpdated
from tmp_3107_sept_2 t
  inner join Compliances  c  on t.student_uid = c.student_uid
where t.InitialConsentForEvaluation >= '1/1/2023'
and (c.Indicator11FIIEDueDate != t.Indicator11FIIEDueDateUpdated or c.Indicator11IEPMeetingDueDate != t.Indicator11IEPMtgDueDateUpdated)