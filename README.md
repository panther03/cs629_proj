note: to use different defines, pass `DEFINES=` to the makefile as follows

```make DualCoreTest DEFINES="-D CACHE_ENABLE" -B```
(`-B` re-executes the rule everytime)

note that if you want to change the flags for the dependencies, you need to run `make clean` so bluespec compiles them again as well