proc piOpts() =
  --cpu:arm
  --os:linux
  --arm.linux.gcc.exe:"arm-linux-musleabihf-gcc"
  --arm.linux.gcc.linkerexe:"arm-linux-musleabihf-gcc"

task debug, "build project in debug mode":
  --define:debug
  #--debugger:native
  piOpts()
  setCommand "c", "main.nim"

task release, "build project in release mode":
  --define:release
  piOpts()
  setCommand "c", "main.nim"

task upload, "upload to rpizero":
  exec "scp main root@10.0.1.98:"

task x86, "build project for x86, debug":
  --define:debug
  setCommand "cpp", "piclock.nim"

task ws, "build webserver":
  --gc:arc
  --threads:on
  setCommand "c", "wsclock.nim"
