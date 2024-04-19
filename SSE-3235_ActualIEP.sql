  update c
  set  c.ActualIEPMeetingDate = null, DeterminedEligible12 = null
   from SSE_3086 s inner join Compliances c on c.Student_Uid = s.StudentUid
  where    c.ActualIEPMeetingDate is not  null
  

  update c
  set Indicator11ActualIEPMeetingDate = s.ActualIEPMeetingDate
  from SSE_3086 s inner join Compliances c on c.Student_Uid = s.StudentUid
  where isnull(s.ActualIEPMeetingDate, '') != isnull(c.Indicator11ActualIEPMeetingDate , '')
