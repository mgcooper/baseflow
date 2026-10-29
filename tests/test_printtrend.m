function tests = test_printtrend
   %TEST_PRINTTREND Test the total change baseflow.printtrend reports.
   %
   % printtrend fits a trend per year and reports the total change over
   % the record, which is the trend times the years the record spans.
   tests = functiontests(localfunctions);
end

function test_totalChangeSpansTheRecord(testCase)
   % A monthly series that rises one unit per year from January 2000 to
   % December 2009 spans 9.92 years, so its total change is 9.92 rather
   % than the sample count, 120.
   Time = (datetime(2000,1,1):calmonths(1):datetime(2009,12,1))';
   Data = timetable(Time, years(Time - Time(1)), 'VariableNames', {'Qb'});
   expected = sprintf('dQb = %.3f', years(Time(end) - Time(1)));

   returned = evalc('baseflow.printtrend(Data);');

   testCase.verifySubstring(returned, expected)
end
