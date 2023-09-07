function test_withcd
   %TEST_WITHCD Test withcd.
   tests = functiontests(localfunctions);
end


function testWithCd(testCase)

   thispath = fileparts(mfilename('fullpath'));
   gotopath = fileparts(fileparts(thispath));
   
   obj = withcd(gotopath); %#ok<*NASGU> 
   
   hi = pwd(); 
   
   testCase.verifyEqual(hi, gotopath, 'withcd failed to reach top level project path')   
   
   % !touch test.txt
   
   %assert(isfile(fullfile(gotopath, 'test.txt')))
%    verifyTrue(testCase, isfile(fullfile(gotopath, 'test.txt')))
% 
%    if isfile(fullfile(gotopath, 'test.txt'))
%       delete(fullfile(gotopath, 'test.txt'))
%    end
end