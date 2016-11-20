# libObjc

#### A version of libApt-pkg that has been written in Objective-C for jailbroken iOS

**Known Bugs:**
- Installation and remove of packages is not yet supported
- May have some restrictions on what repos can be removed (can be modified)
- Currently supports Cydia (will need to be modified to work in sandbox)
- Currently refreshes one source at a time verses all at once (may need to be changed)

**Fixed Bugs:**
- Package files are being miss read. Currently trying to load such a large file will cause it to crash. Attempted to load only the needed part of the file at a time. Some lines are being misses modification to the following should work (APTOFileParser): 

```c
FILE *file = fopen([filename UTF8String], "r");
char buffer[256];
while (fgets(buffer, sizeof(char)*256, file) != NULL){
NSString* line = [NSString stringWithUTF8String:buffer];
NSLog(@"%@",line);
}
```
