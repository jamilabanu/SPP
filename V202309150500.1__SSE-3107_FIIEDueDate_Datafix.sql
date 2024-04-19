
 

 truncate table ConsentForEval_3107_Sept
 
 insert into ConsentForEval_3107_Sept ([StudentId], [studentuid], [TypeOfEvaluation], [GivePermission], [ParentSignatureDate], [ConsentDate])
 
select s.StudentId,  fi.studentuid, 
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(max)') as TypeOfEvaluation,
f.d.value('(GivePermission/text())[1]', 'varchar(max)') as GivePermission,
f.d.value('(ParentSignatureDate/text())[1]', 'datetime') as ParentSignatureDate,
f.d.value('(Date/text())[1]', 'datetime') as ConsentDate
--into ConsentForEval_3107_Sept
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where formtypeid = 165  and studentid = '0864163'
and f.d.value('(ParentSignatureDate/text())[1]', 'datetime') >= '01/01/2023'
and f.d.value('(Date/text())[1]', 'datetime') is not null
--and fi.StudentUid = 'C54F632F-C6F2-4C73-8425-9FE679E13304' 
--and e.CurrentDistrictId = @districtId
 --and studentid = '0841226'

 --UNION

  insert into ConsentForEval_3107_Sept ([StudentId], [studentuid], [TypeOfEvaluation], [GivePermission], [ParentSignatureDate], [ConsentDate])


  drop table #ConsentForm_NoParentSignature

  select s.StudentId,  fi.studentuid, 
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(max)') as TypeOfEvaluation,
f.d.value('(GivePermission/text())[1]', 'varchar(max)') as GivePermission,
f.d.value('(ParentSignatureDate/text())[1]', 'datetime') as ParentSignatureDate,
f.d.value('(Date/text())[1]', 'datetime') as ConsentDate
--into ConsentForEval_3107_Sept_2
into #ConsentForm_NoParentSignature
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where formtypeid = 165   --and studentid = '0722555'
and f.d.value('(ParentSignatureDate/text())[1]', 'datetime') is null
and f.d.value('(Date/text())[1]', 'datetime') >= '01/01/2023'
--and  studentid = '0841226'



/*
select * from ConsentForEval_3107_Sept where studentuid = '030A02F5-6F4E-4BED-9E56-B9E5A33E8193'


select * from student_3107_sept where student_uid = '030A02F5-6F4E-4BED-9E56-B9E5A33E8193'

select * from tmp_3107_sept
where student_uid = '030A02F5-6F4E-4BED-9E56-B9E5A33E8193'
*/
 
  drop table student_3107_sept 
  drop table tmp_3107_sept


Select row_number() over(partition by  t.StudentUid order by t.ParentSignatureDate asc) AS RowNumber, Student_Uid,  Indicator11FIIEDueDate, Indicator12FIIEDueDate, InitialConsentForEvaluation,currentDistrictId,NumberOfAbsences, d.name as districName ,DateOfBirth ,s.studentid ,Firstname ,lastname,c.DateUpdated, c.ReferralType as ECIReferral, t.ConsentDate
--into student_3107_sept
from Compliances c
inner join ConsentForEval_3107_Sept t on t.studentuid = c.Student_Uid
left join students s on s.Uid = c.Student_Uid
left join Enrollments e on e.StudentUid=c.Student_Uid and e.ActiveRecord = 1
left join Districts d on e.currentDistrictId = d.Id
left join DistrictDates dd on dd.DistrictId =e.CurrentDistrictId
--where CurrentDistrictId = @districtId 
 where student_uid = '6FAB2A8E-7AD1-4A2A-964E-8BFA8581D084'


----select * from tmp_3107_sept where StudentId  = '0854401'

 
select  IDENTITY(int, 1, 1) as ROW_ID, *
into tmp_3107_sept
from student_3107_sept
where RowNumber = 1

alter table tmp_3107_sept add AdjustDay datetime
alter table tmp_3107_sept add SchooldaysMoved int
alter table tmp_3107_sept add Indicator11FIIEDueDate_1020 datetime
alter table tmp_3107_sept add Indicator11IEPMtgDueDate_1020 datetime

alter table tmp_3107_sept add Processed int
 

 --update tmp_3107_sept
 --set Processed = 1
 --where  Indicator11FIIEDueDateUpdated is not null

 --select * from tmp_3107_sept where student_uid = 'A1E66CF6-09D4-4196-B691-6344103820F6'

DECLARE @student_uid uniqueidentifier

DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR  
 
 select  DISTINCT top 100  student_uid 
 from tmp_3107_sept c
 where Processed is null
 
 
OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @student_uid
WHILE @@FETCH_STATUS = 0
BEGIN 

begin tran
    --Do something with Id here
	-- get current district for student one by one 
		declare @currentDistrict int = ( Select top 1 currentDistrictId from tmp_3107_sept where Student_Uid = @student_uid )
		declare @initialConsentDate datetime =(Select top 1 InitialConsentForEvaluation from tmp_3107_sept where Student_Uid = @student_uid)
		
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
		declare @absentDay int = (select NumberOfAbsences from tmp_3107_sept  where Student_Uid = @student_uid and NumberOfAbsences>2)
		
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
			from tmp_3107_sept s 			 
			where  Student_Uid = @student_uid and @SchooldaysMoved<=100 --and Age >= 3
			

commit tran

    --PRINT @PractitionerId
    FETCH NEXT FROM MY_CURSOR INTO @student_uid
END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR

--------------------------------------------------------------------------------------------------------------------


select * from tmp_3107_sept 
where CurrentDistrictId = 384 and StudentId in ('0864163' )
month(Indicator11IEPMtgDueDateUpdated) = 6

 
			
		 
	--	IF object_id('tempdb..#student') IS NOT NULL DROP TABLE #student
	--select * from #tmp

	----- Indicator11FIIEDueDate ---
	--select c.Indicator11FIIEDueDate,   t.AdjustDay, t.SchooldaysMoved
	--from Compliances  c inner join tmp_3107_sept t on t.student_uid = c.student_uid
	--where t.SchooldaysMoved < 100 and ECIReferral in ( 'No', '')

	--update c
	--set Indicator11FIIEDueDate = t.AdjustDay
	--from Compliances  c inner join tmp_3107_sept t on t.student_uid = c.student_uid
	--where t.SchooldaysMoved < 100
	--and ECIReferral in ( 'No', '')




	---IEP Meeting Due date ---
	  update e
 set e.Indicator11IEPMtgDueDateUpdated = DATEADD(day,30, e.Indicator11FIIEDueDateUpdated)  
 from tmp_3107_sept e


 -- when Actual FIIE date is populated --

  
 --select c.Indicator11ActualFIIEDate,DATEADD(day,30, c.Indicator11ActualFIIEDate)   
 update t
 set Indicator11IEPMtgDueDate_NEW = DATEADD(day,30, c.Indicator11ActualFIIEDate)  
 from tmp_3107_sept t 
 inner join compliances c on c.Student_Uid = t.Student_Uid
  where  c.Indicator11ActualFIIEDate is not null 
  -- t.StudentId = '0815241'


  select c.Indicator11ActualFIIEDate,DATEADD(day,30, c.Indicator11ActualFIIEDate)   , t.Indicator11IEPMtgDueDate_NEW
   from tmp_3107_sept t 
 inner join compliances c on c.Student_Uid = t.Student_Uid
  where  c.Indicator11ActualFIIEDate is not null 
  and t.studentid ='0864163'


 select * from tmp_3107_sept
 where studentid = '0864163'




 select top 10 ProgramSpecialEducationStatusId, * from Enrollments
 where StudentUid = '9C317489-99C3-4606-B141-3C7172A5A55A' and ActiveRecord = 1

 select top 10 * from ProgramStatusTypes


 select * from tmp_3107_sept
 where studentid in ('170626', '224316')


 -- when IEP Meeting Due date is in summer --
 select Indicator11FIIEDueDateUpdated, e.Indicator11IEPMtgDueDateUpdated , dd.BeginningOfFollowingYear, dd.LastDayCurrentYear, dd.BeginningOfFollowingYear, Indicator11IEPMtgDueDate_NEW
 from tmp_3107_sept e 
 inner join Students s on s.uid = e.Student_Uid
inner join Compliances c on c.Student_Uid = e.Student_Uid
inner join DistrictDates dd on dd.DistrictId = e.currentDistrictId
where RowNumber = 1 and   ECIReferral != 'Yes' and e.studentid = '0864163'
and dd.AcademicYear = '2022-23'
and DATEADD(day,30, Indicator11FIIEDueDateUpdated) > dd.LastDayCurrentYear
and DATEADD(day,30,Indicator11FIIEDueDateUpdated) < dd.BeginningOfFollowingYear
and Indicator11FIIEDueDateUpdated  != '06-30-2023' 


update e
set Indicator11IEPMtgDueDate_NEW = dd.BeginningOfFollowingYear
 from tmp_3107_sept e 
 inner join Students s on s.uid = e.Student_Uid
inner join Compliances c on c.Student_Uid = e.Student_Uid
inner join DistrictDates dd on dd.DistrictId = e.currentDistrictId
where RowNumber = 1 and   ECIReferral != 'Yes' 
and DATEADD(day,30, Indicator11FIIEDueDateUpdated) > dd.LastDayCurrentYear
and DATEADD(day,30,Indicator11FIIEDueDateUpdated) < dd.BeginningOfFollowingYear
and dd.AcademicYear = '2022-23'
and Indicator11FIIEDueDateUpdated  != '06-30-2023' 



select * from tmp_3107_sept


-- FIIE Due Date 06-30-2023 --

 select Indicator11IEPMtgDueDateUpdated, DATEADD(day,15,dd.FirstDayCurrentYear)--, e.*
  from tmp_3107_sept e
 inner join districtdates dd on dd.DistrictId = e.CurrentDistrictId
 where  Indicator11FIIEDueDate  = '06-30-2023'
 and Indicator11FIIEDueDate < FirstDayCurrentYear
 and isnull(e.NumberOfAbsences, 0) < 3 
 and studentid = 'TRS10082019'

--and  CurrentDistrictId = 41 
--and e.currentDistrictId = 603


 
 select distinct dd.FirstDayCurrentYear, Indicator11IEPMtgDueDateUpdated, Indicator11IEPMtgDueDateUpdated, DATEADD(day,15,dd.FirstDayCurrentYear), e.*
  from tmp_3107_sept e
 inner join districtdates dd on dd.DistrictId = e.CurrentDistrictId
 where  Indicator11FIIEDueDate  = '06-30-2023'
 and Indicator11FIIEDueDate < FirstDayCurrentYear
 and isnull(e.NumberOfAbsences, 0) < 3
 and AcademicYear = '2023-24'
 order by dd.FirstDayCurrentYear

  (Select dbo.fnAdjustSchoolDays(384, '2023-08-09', 14))



   update e
 set Indicator11IEPMtgDueDate_NEW = (Select dbo.fnAdjustSchoolDays(e.currentDistrictId, dd.FirstDayCurrentYear, 14))
 from tmp_3107_sept e
 inner join districtdates dd on dd.DistrictId = e.CurrentDistrictId
 where  Indicator11FIIEDueDateUpdated  = '06-30-2023' 
 and AcademicYear = '2023-24'
 and e.currentDistrictId = 


 update e 
 set Indicator11IEPMtgDueDateUpdated = (Select dbo.fnAdjustSchoolDays(e.currentDistrictId, dd.FirstDayCurrentYear, 14))
 from tmp_3107_sept e
 inner join districtdates dd on dd.DistrictId = e.CurrentDistrictId
 where  Indicator11FIIEDueDateUpdated  = '06-30-2023'
 --and Indicator11FIIEDueDate < FirstDayCurrentYear
 and isnull(e.NumberOfAbsences, 0) < 3 
 --and e.currentDistrictId = 142
 and dd.AcademicYear = '2023-24'




 update   tmp_3107_sept
 set Indicator11IEPMtgDueDateUpdated = '8/30/2023'
 where  Indicator11FIIEDueDateUpdated  = '06-30-2023'
 and CurrentDistrictId = 384
 and year(Indicator11IEPMtgDueDateUpdated) = 2012


--Absence > 3 --
 update tmp_3107_sept
set Indicator11IEPMtgDueDateUpdated = '9-16-2023'
where Indicator11FIIEDueDateUpdated = '06-30-2023' AND NumberOfAbsences>3
and CurrentDistrictId = 384

 
update t
set Indicator11IEPMtgDueDateUpdated = c.Indicator11IEPMeetingDueDate
from tmp_3107_sept t
inner join Compliances c on c.Student_Uid = t.Student_Uid
where t.Indicator11FIIEDueDateUpdated = '06-30-2023' AND t.NumberOfAbsences>3
and CurrentDistrictId != 384


-- 06/30  AND Abscences >= 3 --
 select t.*,
 (Select dbo.fnAdjustSchoolDays(t.currentDistrictId, t.InitialConsentForEvaluation, (45+t.NumberOfAbsences))) AS Indicator11FIIEDueDate_NEW,
 DATEADD(day,30,(Select dbo.fnAdjustSchoolDays(t.currentDistrictId, t.InitialConsentForEvaluation, (45)))) AS Indicator11IEPMtgDueDate_NEW 
 --into tmp_3107_monday
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_sept t on t.Student_Uid = e.StudentUid
 where  ProgramSpecialEducationStatusId in (3,6)
 --and t.CurrentDistrictId = 384
 --and t.Indicator11FIIEDueDateUpdated = '06-30-2023'
 and t.NumberOfAbsences >= 3
 --and t.StudentId = '0854401'



 select DATEADD(day,30,(Select dbo.fnAdjustSchoolDays(384, '1/3/2023', (45)))) AS Indicator11IEPMtgDueDate_NEW 

 alter table   tmp_3107_sept add Indicator11FIIEDueDate_NEW datetime 
 alter table   tmp_3107_sept add Indicator11IEPMtgDueDate_NEW datetime 

 
 alter table   tmp_3107_monday add Indicator11FIIEDueDate_1020 datetime 
 alter table   tmp_3107_monday add Indicator11IEPMtgDueDate_1020 datetime 



 update t
 set Indicator11FIIEDueDate_NEW = (Select dbo.fnAdjustSchoolDays(t.currentDistrictId, t.InitialConsentForEvaluation, (45+t.NumberOfAbsences))),
 Indicator11IEPMtgDueDate_NEW = DATEADD(day,30,(Select dbo.fnAdjustSchoolDays(t.currentDistrictId, t.InitialConsentForEvaluation, (45))))
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_sept t on t.Student_Uid = e.StudentUid
 where  ProgramSpecialEducationStatusId in (3,6)
 --and t.CurrentDistrictId = 384
 and t.Indicator11FIIEDueDateUpdated = '06-30-2023'
 and t.NumberOfAbsences >= 3


 select  t.*, (Select dbo.fnAdjustSchoolDays(t.currentDistrictId, t.InitialConsentForEvaluation, (45+t.NumberOfAbsences))), DATEADD(day,30,(Select dbo.fnAdjustSchoolDays(t.currentDistrictId, t.InitialConsentForEvaluation, (45))))
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_sept t on t.Student_Uid = e.StudentUid
 where  ProgramSpecialEducationStatusId in (3,6)
 --and t.CurrentDistrictId = 384
 and t.Indicator11FIIEDueDateUpdated = '06-30-2023'
 and t.NumberOfAbsences >= 3



 select t.*, pst.StatusDescription
 from tmp_3107_sept t
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
  inner join programstatustypes pst on pst.id = e.ProgramSpecialEducationStatusId
   where  ProgramSpecialEducationStatusId in (3,6)


   select  * 
   from tmp_3107_monday 


 update tmp_3107_sept
 set Indicator11FIIEDueDate_NEW = Indicator11FIIEDueDateUpdated
 where Indicator11FIIEDueDate_NEW is null

 
 update tmp_3107_sept
 set Indicator11IEPMtgDueDate_NEW = Indicator11IEPMtgDueDateUpdated
 where Indicator11IEPMtgDueDate_NEW is null


-- INITIAL / REFERRAL --
 select distinct t.* ,ProgramSpecialEducationStatusId as Status --, dd2.LastDayCurrentYear,  dd.FirstDayCurrentYear
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_sept t on t.Student_Uid = e.StudentUid
 inner join districtdates dd on dd.DistrictId = t.currentDistrictId
  inner join districtdates dd2 on dd2.DistrictId = t.currentDistrictId
 where   ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6
 and dd.AcademicYear = '2023-24'
 --and month(Indicator11IEPMtgDueDate_NEW) in (5,6,7,8)
 --and year( Indicator11IEPMtgDueDate_NEW) = 2023
 and Indicator11IEPMtgDueDate_NEW < dd.FirstDayCurrentYear
  and dd2.AcademicYear = '2022-23'
 and Indicator11IEPMtgDueDate_NEW > dd2.LastDayCurrentYear
  


update t set Indicator11IEPMtgDueDate_NEW = dd.FirstDayCurrentYear
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_sept t on t.Student_Uid = e.StudentUid
 inner join districtdates dd on dd.DistrictId = t.currentDistrictId
  inner join districtdates dd2 on dd2.DistrictId = t.currentDistrictId
 where   ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6
 and dd.AcademicYear = '2020-19'
 --and month(Indicator11IEPMtgDueDate_NEW) in (5,6,7,8)
 --and year( Indicator11IEPMtgDueDate_NEW) = 2023
 and Indicator11IEPMtgDueDate_NEW < dd.FirstDayCurrentYear
  and dd2.AcademicYear = '2019-20'
 and Indicator11IEPMtgDueDate_NEW > dd2.LastDayCurrentYear
   


select * from districtdates where districtid = 384 and AcademicYear = '2023-24'

drop table #noParentSign

  select distinct fi.StudentUid
  into #noParentSign
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
--inner join tmp_3107_sept t on t.studentid = s.StudentId
where formtypeid = 165  
and f.d.value('(ParentSignatureDate/text())[1]', 'datetime') is not null
and f.d.value('(Date/text())[1]', 'datetime') >= '01/01/2023'


select t.*, c.InitialConsentForEvaluation 
from tmp_3107_sept t
inner join Compliances c on c.Student_Uid = t.student_uid
where student_uid not in (Select student_uid from #noParentSign)

 --- FIIE Locked form -- 

 drop table FIIELockedForm

select   Fi.StudentUid,  d.name as districName,t.CurrentDistrictId as DistrictId ,   
		   f.d.value('(Date/text())[1]', 'datetime')   as [ActualFIIEDate], DateLocked
into FIIELockedForm
from FormInstances fi 
outer apply fi.Data.nodes('Title') f(d)
inner join tmp_3107_sept t on t.Student_Uid = fi.StudentUid
left join Students s (nolock) on s.[Uid] = fi.[StudentUid]
left join Compliances c on c.Student_Uid=fi.StudentUid 	
left join FormTypes ft on ft.Id=fi.FormTypeId
left join Enrollments e on fi.[StudentUid] = e.StudentUid and e.ActiveRecord = 1
join Districts d on e.currentDistrictId = d.Id
where   Locked=1 and  (ft.Name = 'Full and Individual Evaluation' and  ft.PluginType= 'Forms.FIEv2.Title') and( c.ReferralType ='NO' or  c.ReferralType ='' or  c.ReferralType is null )
		and c.InitialConsentForEvaluation is not null and  f.d.value('(Report/text())[1]', 'varchar(max)') ='Full Individual and Initial Evaluation'
		and ProgramSpecialEducationStatusId in (3,6)
--and currentDistrictId <> 267 

drop table FIIELockedForm_AllForms

select  row_number() over(partition by  StudentUid order by ActualFIIEDate desc) as RowNumber, *
into FIIELockedForm_AllForms
from FIIELockedForm

select t.* 
 from tmp_3107_monday t 
 inner join FIIELockedForm_AllForms f on f.StudentUid = t.Student_Uid
  where t.StudentId = '0847002'

 
 select c.Indicator11ActualFIIEDate,DATEADD(day,30, c.Indicator11ActualFIIEDate) , DATEADD(day,30, t.Indicator11FIIEDueDateUpdated) , * 
 from tmp_3107_sept t inner join compliances c on c.Student_Uid = t.Student_Uid
  where t.studentid = '0855744'
  --2023-04-22 00:00:00.000
 
 select t.* , c.Indicator11ActualFIIEDate, c.ReferralType, pst.StatusDescription
 from tmp_3107_sept t  
 inner join compliances c on c.Student_Uid = t.Student_Uid
 inner join ProgramStatusTypes pst on pst.ProgramTypeId = c.BilingualProgramTypeCode
  where t.StudentId = '0729101'



 update t
 set t.Indicator11IEPMtgDueDate_NEW = DATEADD(day,30, f.ActualFIIEDate) 
 from tmp_3107_monday t 
 inner join FIIELockedForm_AllForms f on f.StudentUid = t.Student_Uid


 select DATEADD(day,30, f.ActualFIIEDate) , t.* , f.ActualFIIEDate
 from tmp_3107_monday t 
 inner join FIIELockedForm_AllForms f on f.StudentUid = t.Student_Uid
 where t.studentid in ('88977')

 select * from FIIELockedForm_AllForms where studentuid = '62C68E10-27E8-46B0-BC79-4211DA150F31'


update t
set Indicator11IEPMtgDueDate_NEW = dd.FirstDayCurrentYear  
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_monday t on t.Student_Uid = e.StudentUid
 inner join districtdates dd on dd.DistrictId = t.currentDistrictId
  inner join districtdates dd2 on dd2.DistrictId = t.currentDistrictId
 where   ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6
 and dd.AcademicYear = '2023-24'
 --and month(Indicator11IEPMtgDueDate_NEW) in (5,6,7,8)
 --and year( Indicator11IEPMtgDueDate_NEW) = 2023
 and Indicator11IEPMtgDueDate_NEW < dd.FirstDayCurrentYear
  and dd2.AcademicYear = '2022-23'
 and Indicator11IEPMtgDueDate_NEW > dd2.LastDayCurrentYear
  and t.currentDistrictId = 384


 select Indicator11IEPMtgDueDate_NEW,  dd.FirstDayCurrentYear  , dd2.LastDayCurrentYear
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_sept t on t.Student_Uid = e.StudentUid
 inner join districtdates dd on dd.DistrictId = t.currentDistrictId
  inner join districtdates dd2 on dd2.DistrictId = t.currentDistrictId
 where  t.studentid in ('106045')
 and ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6
 and dd.AcademicYear = '2023-24'    
 --and month(Indicator11IEPMtgDueDate_NEW) in (5,6,7,8)
 --and year( Indicator11IEPMtgDueDate_NEW) = 2023
 and Indicator11IEPMtgDueDate_NEW < dd.FirstDayCurrentYear
  and dd2.AcademicYear = '2022-23'
 and Indicator11IEPMtgDueDate_NEW > dd2.LastDayCurrentYear





 ---SEND TO Steph 10/11/2023 --
  select distinct t.* ,ProgramSpecialEducationStatusId as Status , c.InitialConsentForEvaluation
 from compliances c 
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
 inner join tmp_3107_sept t on t.Student_Uid = e.StudentUid
 --left join #noParentSign p  on p.StudentUid = t.student_uid
  where   ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6
  and c.InitialConsentForEvaluation >= '1/1/2023'
 and t.studentid = '353654'
  and (Indicator11IEPMtgDueDate_NEW is not null
  or Indicator11FIIEDueDate_NEW is not null)
 and t.Student_Uid  not in (  select student_uid from tmp_3107_monday)


 select t.* from tmp_3107_monday t
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
where   ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
and studentid = '88977'

  --and t.student_uid not in (Select studentuid from #noParentSign)

------FINAL SCRIPT----

select  t.* , c.Indicator11FIIEDueDate, t.Indicator11FIIEDueDate_NEW, c.Indicator11IEPMeetingDueDate , t.Indicator11IEPMtgDueDate_NEW
from tmp_3107_sept t
  inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
--where   ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
where t.InitialConsentForEvaluation >= '1/1/2023'
--and t.studentid = 'TGM03232020'
and ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
and (isnull(c.Indicator11FIIEDueDate, '') != t.Indicator11FIIEDueDate_NEW or isnull(c.Indicator11IEPMeetingDueDate, '') != t.Indicator11IEPMtgDueDate_NEW)


select Indicator11FIIEDueDate,Indicator11IEPMeetingDueDate , * from Compliances where Student_Uid = 'A9E8E45B-EB2E-4677-B0DA-8A36DC3649BE'
select  c.Indicator11FIIEDueDate ,  t.Indicator11FIIEDueDate_NEW, c.Indicator11IEPMeetingDueDate , t.Indicator11IEPMtgDueDate_NEW
from tmp_3107_monday t
  inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
where t.InitialConsentForEvaluation >= '1/1/2023'
and ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
and (isnull(c.Indicator11FIIEDueDate, '') != t.Indicator11FIIEDueDate_NEW or isnull(c.Indicator11IEPMeetingDueDate, '') != t.Indicator11IEPMtgDueDate_NEW)



select t.* 
from tmp_3107_monday t
  inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
--where   ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
where t.InitialConsentForEvaluation >= '1/1/2023'
and ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
and (c.Indicator11FIIEDueDate != t.Indicator11FIIEDueDate_NEW or c.Indicator11IEPMeetingDueDate != t.Indicator11IEPMtgDueDate_NEW)


update c
set c.Indicator11FIIEDueDate =  t.Indicator11FIIEDueDate_NEW, c.Indicator11IEPMeetingDueDate = t.Indicator11IEPMtgDueDate_NEW
from tmp_3107_sept t
  inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
where t.InitialConsentForEvaluation >= '1/1/2023'
and ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
and (c.Indicator11FIIEDueDate != t.Indicator11FIIEDueDate_NEW or c.Indicator11IEPMeetingDueDate != t.Indicator11IEPMtgDueDate_NEW)


update c
set c.Indicator11FIIEDueDate =  t.Indicator11FIIEDueDate_NEW, c.Indicator11IEPMeetingDueDate = t.Indicator11IEPMtgDueDate_NEW
from tmp_3107_monday t
  inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
where t.InitialConsentForEvaluation >= '1/1/2023'
and ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
and (c.Indicator11FIIEDueDate != t.Indicator11FIIEDueDate_NEW or c.Indicator11IEPMeetingDueDate != t.Indicator11IEPMtgDueDate_NEW)



---MORE THAN 1 CONSENT FOR EVAL --- 
select s.StudentId,  fi.studentuid, 
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(max)') as TypeOfEvaluation,
f.d.value('(GivePermission/text())[1]', 'varchar(max)') as GivePermission,
f.d.value('(ParentSignatureDate/text())[1]', 'datetime') as ParentSignatureDate,
f.d.value('(Date/text())[1]', 'datetime') as ConsentDate
--into ConsentForEval_3107_Sept
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
where formtypeid = 165  and studentid = '0864163'
and f.d.value('(ParentSignatureDate/text())[1]', 'datetime') >= '01/01/2023'
and f.d.value('(Date/text())[1]', 'datetime') is not null

select * from tmp_3107_sept


select distinct t.student_Uid, f.TypeOfEvaluation,f.ParentSignatureDate, f.ConsentDate
from tmp_3107_sept t
  inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
  inner join ConsentForEval_3107_Sept f on f.studentuid = t.student_uid
--where   ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
where t.InitialConsentForEvaluation >= '1/1/2023'
--and t.studentid = '0833286'
and ProgramSpecialEducationStatusId in (3,6) --Initial:3 , Referral:6 
and (isnull(c.Indicator11FIIEDueDate, '') != t.Indicator11FIIEDueDate_NEW or isnull(c.Indicator11IEPMeetingDueDate, '') != t.Indicator11IEPMtgDueDate_NEW)
group by  t.student_Uid, f.TypeOfEvaluation, f.ParentSignatureDate, f.ConsentDate
having count( t.student_Uid) > 1
order by t.student_Uid


select 
f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(max)') as TypeOfEvaluation_form,
f.d.value('(GivePermission/text())[1]', 'varchar(max)') as GivePermission_form,
f.d.value('(ParentSignatureDate/text())[1]', 'datetime') as ParentSignatureDate_form,
f.d.value('(Date/text())[1]', 'datetime') as ConsentDate_form,
t.*
into ConsentForEval_3107_Oct
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
inner join tmp_3107_sept t on t.student_uid = s.uid
where formtypeid = 165  --and   s.studentid = '0833286'
and f.d.value('(ParentSignatureDate/text())[1]', 'datetime') >= '01/01/2023'
and f.d.value('(Date/text())[1]', 'datetime') is not null
order by t.student_uid


select distinct c.student_uid--, TypeOfEvaluation_form, ParentSignatureDate_form
into #multipleConsentForms
from ConsentForEval_3107_Oct c
group by student_uid
having count(*) > 1



select c.* 
from ConsentForEval_3107_Oct c
inner join #multipleConsentForms m on m.student_uid = c.student_uid
order by c.student_uid


select c.* 
from ConsentForEval_3107_Oct c
inner join ConsentForEval_3107_Oct c2 on c.student_uid = c2.student_uid
inner join #multipleConsentForms m on m.student_uid = c.student_uid
where (c.Indicator11FIIEDueDate_NEW <> c2.Indicator11FIIEDueDate_NEW  or c.Indicator11IEPMtgDueDate_NEW <> c2.Indicator11IEPMtgDueDate_NEW  )
order by c.student_uid


begin tran

 update c
set c.Indicator11FIIEDueDate =  t.Indicator11FIIEDueDate_1020, c.Indicator11IEPMeetingDueDate = t.Indicator11IEPMtgDueDate_1020
from  tmp_3107_sept t 
 inner join Compliances  c  on t.student_uid = c.student_uid
  inner join Enrollments e on e.StudentUid = t.Student_Uid and ActiveRecord = 1
inner join districtdates dd on dd.DistrictId = t.currentDistrictId
 where  ProgramSpecialEducationStatusId in (3,6)
 and Indicator11FIIEDueDate_1020 is not null
 and Indicator11FIIEDueDate_1020 <> Indicator11FIIEDueDate_NEW
 and dd.AcademicYear = '2023-24'
 and t.studentid not in ('721126','0851372')


commit tran