

select top 10 * from students
where StudentId = '257482'


select top 10 Indicator11TSDSParentalConsentDate , InitialConsentForEvaluation , DateUpdated,* 
from compliances
where Student_Uid in ( 'D5B3DB53-E45D-4327-BEF7-E6CD70159206', 'C031584C-3041-4AB7-80DA-2D82381547F7')

--2023-04-27 09:56:20.877



--- CODE FIX ---

SELECT *
FROM   sys.procedures
WHERE  Object_definition(object_id) LIKE '%#Indicator11TSDSParentalConsentDate%'



----DATA FIX ---


-- InitialConsentForEvaluation is null on PC OR consent form
select * from districts where name like '%spring branch%'



truncate table t3118

insert into t3118 ([Student_Uid], [CurrentDistrictId], [InitialConsentForEvaluation], [Indicator11TSDSParentalConsentDate])
select c.Student_Uid , e.CurrentDistrictId, c.InitialConsentForEvaluation, c.Indicator11TSDSParentalConsentDate 
--into t3118
from compliances c
 inner join Enrollments e on e.StudentUid = c.Student_Uid and ActiveRecord = 1
where isnull(e.ProgramSpecialEducationStatusId, 0) not in (3,6) --Initial:3 , Referral:6
and  InitialConsentForEvaluation is null 
and Indicator11TSDSParentalConsentDate is not null
--and c.Student_Uid in ( 'D5B3DB53-E45D-4327-BEF7-E6CD70159206', 'C031584C-3041-4AB7-80DA-2D82381547F7')



insert into t3118 ([Student_Uid], [CurrentDistrictId], [InitialConsentForEvaluation], [Indicator11TSDSParentalConsentDate])
 select fi.studentuid , e.currentDistrictId, f.d.value('(Date/text())[1]', 'datetime'), c.[Indicator11TSDSParentalConsentDate]
from forminstances fi
outer apply fi.Data.nodes('ConsentforEvaluation') f(d)
inner join students s on s.Uid = fi.StudentUid
inner join Enrollments e on e.StudentUid = s.Uid and e.ActiveRecord = 1
inner join compliances c on c.Student_Uid = fi.StudentUid
where formtypeid = 165  
--and f.d.value('(ParentSignatureDate/text())[1]', 'datetime') is not null
and f.d.value('(Date/text())[1]', 'datetime') is null --consentdate
and f.d.value('(TypeOfEvaluation/text())[1]', 'varchar(max)') = 'Initial'
and c.Indicator11TSDSParentalConsentDate is not null
and isnull(e.ProgramSpecialEducationStatusId,0) not in (3,6) --Initial:3 , Referral:6
--and c.Student_Uid in ( 'D5B3DB53-E45D-4327-BEF7-E6CD70159206', 'C031584C-3041-4AB7-80DA-2D82381547F7')


 


select  * 
from t3118 t 
where CurrentDistrictId = 698
and Student_Uid in ( 'D5B3DB53-E45D-4327-BEF7-E6CD70159206', 'C031584C-3041-4AB7-80DA-2D82381547F7')


Spring Branch: 2199
Total: 81049

---FINAL SCRIPT--

update c
set [Indicator11TSDSParentalConsentDate] = null
from t3118 t 
inner join compliances c on c.Student_Uid = t.student_uid