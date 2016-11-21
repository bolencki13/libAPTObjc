# libObjc

#### A version of libApt-pkg that has been written in Objective-C for jailbroken iOS

**Known Bugs:**
- Installation and remove of packages is not yet supported (not sure how this will work in sandbox unless we can break it or run as root?)
- May have some restrictions on what repos can be removed (can be modified)
- Currently refreshes one source at a time verses all at once (may need to be changed)
- Conflicts are not finished

**Fixed Bugs:**
- Package files are being miss read. Currently trying to load such a large file will cause it to crash. Attempted to load only the needed part of the file at a time. Some lines are being misses modification to the following should work (APTOFileParser): 
- Package dependancies are fixed
- Currently supports Cydia and Works in sandbox
