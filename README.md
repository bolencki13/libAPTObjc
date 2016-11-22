# libObjc

#### A version of libApt-pkg that has been written in Objective-C for jailbroken iOS

**Known Bugs:**
- Installation and remove of packages is not yet supported (not sure how this will work in sandbox unless we can break it or run as root?)
- Sandboxing has lead to a new version being installed will overwrite source.list resetting a persons source list (possibly only a simulator bug?)

**Fixed Bugs:**
- Package files are being miss read. Currently trying to load such a large file will cause it to crash. Attempted to load only the needed part of the file at a time. Some lines are being misses modification to the following should work (APTOFileParser): 
- Package dependancies are fixed
- Package conflicts are fixed
- Currently supports Cydia and Works in sandbox
- Somewhat optomized for speed. Refreshes all sources at the same time. Refreshes all package lists at the same time
