function closenewfigs(figsbefore)
   %CLOSENEWFIGS Delete figures opened since the FIGSBEFORE snapshot.
   %
   %  closenewfigs(figsbefore) deletes every open figure absent from
   %  figsbefore, the handle array a test captured with
   %  findall(0, 'Type', 'figure') during setup. The snapshot and this
   %  call together leave a suite run with zero open figures without
   %  closing figures a user had open before the run.
   %
   % See also: findall

   % delete() skips unsaved-changes prompts and accepts an empty array,
   % so this call is safe headless and when a test opened no figures.
   openfigs = findall(0, 'Type', 'figure');
   delete(openfigs(~ismember(openfigs, figsbefore)))
end
