function cleanupObj = withwarnoff(warningIDs)
   %WITHWARNOFF Temporarily disable warnings
   %
   % WITHWARNOFF('stats:nlinfit:IllConditionedJacobian') disables the warning
   % and reenables it when the calling function exits.
   %
   % cleanupObj = WITHWARNOFF('stats:nlinfit:IllConditionedJacobian') disables
   % the warning and reenables it when cleanupObj is destroyed.
   %
   % See also: withcd

   if ischar(warningIDs)
      warningIDs = {warningIDs};
   end
   assert(iscell(warningIDs));

   % Save the current state of the warnings
   originalWarningState = warning;

   % Create a cleanup object that will be executed when the function is exited
   cleanupObj = onCleanup(@() warning(originalWarningState));

   % Turn off the specified warnings
   for n = 1:numel(warningIDs)
      warning('off', warningIDs{n});
   end
end
