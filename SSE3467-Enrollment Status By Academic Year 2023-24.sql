 
	declare @UserId int = 1
	,@DistrictIds varchar(max) = '674'
	--,@CampusIds varchar(max)
	--,@CaseManagerId int
	--,@Grades varchar(max) = ''
	--,@StudentUid uniqueidentifier
	,@StartDate  datetime = '6/1/2023'
	,@EndDate  datetime = '5/31/2024'
	,@EnrollmentStatuses varchar(max) = ''
	,@IncludePreStartRecords bit = 1
 
	Declare 
		@UserId_Internal int
		,@DistrictIds_Internal varchar(max)
		--,@CampusIds_Internal varchar(max)
		--,@CaseManagerId_Internal int
		--,@Grades_Internal varchar(max) = ''
		--,@StudentUid_Internal varchar(max)
		,@StartDate_Internal  datetime
		,@EndDate_Internal  datetime
		,@EnrollmentStatuses_Internal varchar(max)
		,@IncludePreStartRecords_Internal bit

	select
		@UserId_Internal = @UserId
		,@DistrictIds_Internal = @DistrictIds
		--,@CampusIds_Internal = @CampusIds
		--,@CaseManagerId_Internal = @CaseManagerId
		--,@Grades_Internal = @Grades
		--,@StudentUid_Internal = @StudentUid
		,@StartDate_Internal = @StartDate
		,@EndDate_Internal = @EndDate
		,@EnrollmentStatuses_Internal = @EnrollmentStatuses
		,@IncludePreStartRecords_Internal = @IncludePreStartRecords

	declare @Campuses table (Id int)
	declare @DistrictCount int
	declare @StudentGrades table (grade varchar(2))
	declare @Statuses table (Id varchar(255))
	declare @Districts table (Id int)

	--insert into @Campuses(Id)
	--SELECT cast(Id as int) FROM dbo.fnUtilitySplitParameter(@CampusIds_Internal, ',')

	insert into @Districts(Id)
	SELECT distinct cmp.District_Id from Campuses cmp
	join @Campuses c
		on c.id = cmp.id

	insert into @Statuses(Id)
	SELECT CAST(REPLACE(Id, 'Special Education-', '') AS VARCHAR(255)) FROM dbo.fnUtilitySplitParameter(@EnrollmentStatuses_Internal, ',')

	select * from @Statuses

	select @DistrictCount = count(distinct c.District_Id)
	from @Campuses cp
	join Campuses c
		on c.id = cp.id
	
	--insert into @StudentGrades(grade)
	--SELECT Id FROM dbo.fnUtilitySplitParameter(@Grades_Internal, ',')

    IF object_id('tempdb..#StudentSelection') IS NOT NULL DROP TABLE #StudentSelection
	IF object_id('tempdb..#C163Ids') IS NOT NULL DROP TABLE #C163Ids

	create table #StudentSelection (StudentUid uniqueidentifier primary key)
	
	--declare @RosterDistrict table(DistrictId int, Active bit)

	--insert into @RosterDistrict(DistrictId, Active)
	--select
	--	d.id
	--	,case 
	--		when count(ur.studentuid) > 0 then 1
	--		else 0
	--		end
	--from @Districts d
	--left join UserRosters ur
	--	on d.Id = ur.DistrictId
	--	and ur.UserId = @UserId_Internal
	--group by
	--	d.id

    insert into #StudentSelection (StudentUid)
    select distinct
			e.StudentUid
            from enrollments e (nolock)
            --join @Campuses cl
            --        on cl.id = e.CurrentCampusId
            --join @StudentGrades sg
            --        on sg.grade = e.CurrentGrade
			join Districts d
				on d.Id = e.CurrentDistrictId
			--left join UserRosters ur
			--	on ur.StudentUid = e.StudentUid
			--	and ur.DistrictId = d.id
				--and ur.UserId = @UserId_Internal
			--join @RosterDistrict rd
			--	on rd.DistrictId = d.id
            where
                e.ActiveRecord = 1
				--and d.id = @DistrictIds_Internal
				-- limit by user roster if needed
				--and 
				--(
				--	(rd.Active = 1 AND ur.StudentUid is not null)
				--	or
				--	(rd.Active = 0 AND ur.StudentUid is null)
				--)
                --and (@CaseManagerId_Internal = 0 or e.CaseManager = @CaseManagerId_Internal)
                --and (@StudentUid_Internal = '00000000-0000-0000-0000-000000000000' or e.StudentUid = @StudentUid_Internal)

	--select * from #StudentSelection

	create table #C163Ids (Id int, StudentUID varchar(255))
	--select @StartDate_Internal, @EndDate_Internal


	 
	if @StartDate_Internal != @EndDate_Internal
		begin
			insert into #C163Ids
			select distinct 
				c.Id
				, c.StudentUID
			from compliance163 c
			join #StudentSelection ss
				on ss.StudentUid = c.StudentUid
			where (c.ServicesStartDate BETWEEN @StartDate_Internal AND @EndDate_Internal)
		end

		--select * from #C163Ids

	;with Ordered163s
	as
	(
		select
			c.Id
			,c.StudentUID
			,ROW_NUMBER() over (partition by c.studentuid order by c.servicesstartdate desc, c.datecreated desc) as rownum
		from compliance163 c
		join #StudentSelection ss
			on ss.StudentUid = c.StudentUid
		where c.ServicesStartDate <= @StartDate_Internal
		and @IncludePreStartRecords_Internal = 1
	)
	insert into #C163Ids (Id, StudentUID)
	select
		Id
		,StudentUID
	from Ordered163s
	where rownum = 1

	--drop table  SSE_3467_2

	select distinct
		s.[Uid]
		,s.StudentId as [StudentId]
		,s.LastName
		,s.FirstName
		,s.MI
		,d.Name as DistrictName
		,cmp.[StateBldgCode] as CampusId
		,c163.[Grade] as [Grade]
		 
		,cast(c163.[ServicesStartDate] as date) as [ServicesStartDate]
		,Coalesce(c163.[EnrollmentStatus], '') as [EnrollmentStatus]
		,cast(c163.[IEPDate] as date) as [IEPDate]
		,case when coalesce(c163.[IsAnnualIEP], 0) = 1
				then 'Y'
				else 'N' end --todo
				as [IsAnnualIEP]
		,cast(c163.[FIEDate] as date) as [FIEDate]

		, c.InitialConsentForEvaluation as SPP11_InitialConsentForEvaluation
		, c.Indicator11ActualFIIEDate as SPP11_ActualFIIEDate		 
		, c.Indicator11ActualIEPMeetingDate as SPP11_ActualIEPMeetingDate
		--, IEP Meeting spp11

		, c.ECIReferralDate as SPP12_Referral
		, c.InitialConsentForEvaluation2 as SPP12_InitialConsentForEvaluation
		, c.ActualFIIEDate as SPP12_ActualFIIEDate
		, c.ActualIEPMeetingDate as SPP12_ActualIEPMeetingDate
		--, IEP Meeting spp12
		INTO  SSE_3467_2
	from #C163Ids Ids
	join Students s
		on s.uid = Ids.StudentUID
		inner join SSE_3467 sse on sse.uid = s.Uid
	join Compliance163 c163
		on c163.id = Ids.Id
	join Enrollments e
		on e.studentuid = s.[uid]
		and activerecord = 1
	join campuses cmp
		on cmp.id = c163.[CurrentCampusId]
	join districts d
		on d.id = cmp.District_Id
	--join @Statuses stat
	--	on stat.Id = c163.EnrollmentStatus
	--	or c163.EnrollmentStatus = ''
	join ActualIEP_AllForms_SSE_3467_ALL a on a.studentUid = e.StudentUid
	left join compliances c on c.Student_Uid = s.Uid
	order by s.LastName
			, s.FirstName
			, s.MI
			, s.[uid]

	IF object_id('tempdb..#StudentSelection') IS NOT NULL DROP TABLE #StudentSelection
	IF object_id('tempdb..#C163Ids') IS NOT NULL DROP TABLE #C163Ids



	
	--select * from SSE_3467 
	--select * from SSE_3467_2 