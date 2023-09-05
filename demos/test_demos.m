function tests = test_demos
   %TEST_DEMOS Test 
   % Note: to run this, replace:
   % clearvars, close all, clc 
   % with:
   % clearvars -except testCase demoFiles 
   tests = functiontests(localfunctions);
end

function test_rundemos(testCase)

   % Get the list of .m demo files in the demos/mfiles folder
   demopath = bfra.privatefunction('demopath');
   cd(demopath('mfiles'))

   demoFiles = dir(fullfile(demopath('mfiles'), '*.m'));
   demoFiles = string(fullfile({demoFiles.folder}, {demoFiles.name}).');

   % Loop through each demo file and run it
   for file = demoFiles(:)'
      try
         run(file)
         success = true;
      catch
         success = false;
      end
      % Assert that the demo was successful
      testCase.verifyThat(success, matlab.unittest.constraints.IsTrue);
   end
end