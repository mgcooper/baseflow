function tests = test_nonnansegements
   %TEST_NONNANSEGEMENTS Test the nonnansegments private function.
   %
   % The toolbox nonnansegments is the matfunclib version, which handles
   % leading and trailing nans. A version that assumes trimmed input
   % errors on edge nans, so the four edge-nan tests fail on that version.
   % They check the segment starts, ends, and lengths that the intended
   % behavior defines. An all-nan vector has no segments, so
   % nonnansegments returns empty columns for any nmin. The file name keeps
   % the 'nonnansegements' spelling.
   tests = functiontests(localfunctions);
end

function setupOnce(testCase)
   % The function is private, so reach it once through privatefunction.
   testCase.TestData.nonnansegments = ...
      baseflow.privatefunction('nonnansegments');

   % Several tests share these two input vectors, so name them once.
   testCase.TestData.fullvector = [0, 1, 2, 3];
   testCase.TestData.leftnanvector = [nan, 1, 2, 3];

   % Segment start, end, and length for fullvector and leftnanvector. The
   % single-vector tests and the cell and matrix tests share them.
   testCase.TestData.fullsegment = {1; 4; 4};
   testCase.TestData.leftnansegment = {2; 4; 3};
end

function verifysegments(testCase, x, S_expected, E_expected, L_expected, ...
      varargin)
   % Shared check: compare all three outputs with the expected values. An
   % optional trailing nmin argument passes through to nonnansegments.
   nonnansegments = testCase.TestData.nonnansegments;
   [S, E, L] = nonnansegments(x, varargin{:});
   returned = {S, E, L};
   expected = {S_expected, E_expected, L_expected};
   testCase.verifyEqual(returned, expected)
end

function test_noNans(testCase)
   % A full vector is one segment.
   x = testCase.TestData.fullvector;
   S_expected = testCase.TestData.fullsegment{1};
   E_expected = testCase.TestData.fullsegment{2};
   L_expected = testCase.TestData.fullsegment{3};
   verifysegments(testCase, x, S_expected, E_expected, L_expected)
end

function test_interiorNans(testCase)
   % Interior nans split the vector into two segments.
   x = [0, 1, 2, 3, nan, nan, nan, 1, 2, 3, 4];
   S_expected = [1; 8];
   E_expected = [4; 11];
   L_expected = [4; 4];
   verifysegments(testCase, x, S_expected, E_expected, L_expected)
end

function test_leftEdgeNan(testCase)
   % A leading nan shifts the segment start.
   x = testCase.TestData.leftnanvector;
   S_expected = testCase.TestData.leftnansegment{1};
   E_expected = testCase.TestData.leftnansegment{2};
   L_expected = testCase.TestData.leftnansegment{3};
   verifysegments(testCase, x, S_expected, E_expected, L_expected)
end

function test_rightEdgeNan(testCase)
   % A trailing nan ends the segment early.
   x = [1, 2, 3, nan];
   S_expected = 1;
   E_expected = 3;
   L_expected = 3;
   verifysegments(testCase, x, S_expected, E_expected, L_expected)
end

function test_bothEdgeNans(testCase)
   % Nans on both edges bound one interior segment.
   x = [nan, 1, 2, 3, nan];
   S_expected = 2;
   E_expected = 4;
   L_expected = 3;
   verifysegments(testCase, x, S_expected, E_expected, L_expected)
end

function test_edgeAndInteriorNans(testCase)
   % Edge and interior nans together produce two interior segments.
   x = [nan, 1, 2, 3, nan, nan, nan, 1, 2, 3, nan];
   S_expected = [2; 8];
   E_expected = [4; 10];
   L_expected = [3; 3];
   verifysegments(testCase, x, S_expected, E_expected, L_expected)
end

function test_allNanVector(testCase)
   % An all-nan vector returns empty column outputs with the default nmin
   % and with nmin = 0, which keeps every segment.
   x = [nan, nan, nan];
   S_expected = zeros(0, 1);
   E_expected = zeros(0, 1);
   L_expected = zeros(0, 1);
   verifysegments(testCase, x, S_expected, E_expected, L_expected)
   verifysegments(testCase, x, S_expected, E_expected, L_expected, 0)
end

function test_minimumLength(testCase)
   % nonnansegments removes segments shorter than nmin. Longer segments
   % keep their original indices.
   x = [nan, 1, nan, 2, 3, 4, nan];
   nmin = 2;
   S_expected = 4;
   E_expected = 6;
   L_expected = 3;
   verifysegments(testCase, x, S_expected, E_expected, L_expected, nmin)
end

function test_cellInput(testCase)
   % A cell array of vectors returns cell outputs, one per element.
   nonnansegments = testCase.TestData.nonnansegments;
   x = {testCase.TestData.fullvector, testCase.TestData.leftnanvector};
   [S, E, L] = nonnansegments(x);
   returned = {S{1}, E{1}, L{1}, S{2}, E{2}, L{2}};
   expected = [testCase.TestData.fullsegment', ...
      testCase.TestData.leftnansegment'];
   testCase.verifyEqual(returned, expected)
end

function test_matrixInput(testCase)
   % A matrix returns per-column cell outputs.
   nonnansegments = testCase.TestData.nonnansegments;
   x = [testCase.TestData.fullvector', testCase.TestData.leftnanvector'];
   [S, E, L] = nonnansegments(x);
   returned = {S{1}, E{1}, L{1}, S{2}, E{2}, L{2}};
   expected = [testCase.TestData.fullsegment', ...
      testCase.TestData.leftnansegment'];
   testCase.verifyEqual(returned, expected)
end
