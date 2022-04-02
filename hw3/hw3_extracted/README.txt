Configuration:
    Used SEASnet Linux server to run everything (specifically lnxsrv15):
    - Architecture: x86_64
    - CPU op-mode(s): 32-bit, 64-bit
    - Number of CPUs: 4
    - Thread(s) per core: 1
    - CPU Model: Intel(R) Xeon(R) Silver 4116 CPU @ 2.10GHz
    Used javac to compile Pigzj into Java bytecode:
    - javac 17.0.2
    Used java to run Pigzj byte code from javac:
    - openjdk version "17.0.2" 2022-01-18
    - OpenJDK Runtime Environment GraalVM CE 22.0.0.2 (build 17.0.2+8-jvmci-22.0-b05)
    - OpenJDK 64-Bit Server VM GraalVM CE 22.0.0.2 (build 17.0.2+8-jvmci-22.0-b05, mixed mode, sharing)
    Used GraalVM for generating pigzj:
    - GraalVM 22.0.0.2 Java 17 CE (Java Version 17.0.2+8-jvmci-22.0-b05)

GraalVM took 39.0 seconds to build pigzj. It also used 11.99MB of file system space and the CPU load was 3.47.
According to the time command, GraalVM took:
real    0m39.894s
user    2m15.392s
sys     0m2.225s
to build pigzj

According to time, javac took:
real    0m1.047s
user    0m1.713s
sys     0m0.124s
to build Pigzj

The following are benchmark times for gzip, pigz, Pigzj, and pigzj
on default settings, 1 thread, 4 threads, and 8 threads.

Times for on default with /usr/local/cs/jdk-17.0.2/lib/modules:
gzip:
real    0m7.278s
user    0m7.196s
sys     0m0.044s

pigz:
real    0m2.040s
user    0m7.021s
sys     0m0.108s

Pigzj:
real    0m3.503s
user    0m9.302s
sys     0m0.399s

pigzj:
real    0m4.189s
user    0m9.208s
sys     0m0.407s

Times for on one thread with /usr/local/cs/jdk-17.0.2/lib/modules:
gzip:
real    0m7.282s
user    0m7.191s
sys     0m0.053s

real    0m7.292s
user    0m7.180s
sys     0m0.054s

real    0m7.370s
user    0m7.128s
sys     0m0.135s

pigz:
real    0m7.088s
user    0m6.955s
sys     0m0.074s

real    0m7.087s
user    0m6.947s
sys     0m0.074s

real    0m7.152s
user    0m6.881s
sys     0m0.155s

Pigzj:
real    0m8.176s
user    0m14.609s
sys     0m0.530s

real    0m8.043s
user    0m14.509s
sys     0m0.367s

real    0m8.023s
user    0m14.103s
sys     0m0.368s

pigzj:
real    0m8.431s
user    0m14.537s
sys     0m0.421s

real    0m8.178s
user    0m14.430s
sys     0m0.403s

real    0m8.288s
user    0m14.411s
sys     0m0.423s

Times for four threads with /usr/local/cs/jdk-17.0.2/lib/modules:
gzip:
real    0m7.347s
user    0m7.115s
sys     0m0.126s

real    0m7.315s
user    0m7.197s
sys     0m0.057s

real    0m7.321s
user    0m7.163s
sys     0m0.077s

pigz:
real    0m1.995s
user    0m7.017s
sys     0m0.120s

real    0m2.136s
user    0m7.062s
sys     0m0.114s

real    0m2.134s
user    0m7.047s
sys     0m0.113s

Pigzj:
real    0m3.292s
user    0m9.034s
sys     0m0.398s

real    0m3.413s
user    0m9.364s
sys     0m0.402s

real    0m3.543s
user    0m9.088s
sys     0m0.426s

pigzj:
real    0m3.535s
user    0m8.680s
sys     0m0.360s

real    0m3.478s
user    0m8.764s
sys     0m0.348s

real    0m3.879s
user    0m8.982s
sys     0m0.408s

Times for eight threads with /usr/local/cs/jdk-17.0.2/lib/modules:
gzip:
real    0m7.347s
user    0m7.115s
sys     0m0.126s

real    0m7.295s
user    0m7.180s
sys     0m0.062s

real    0m7.305s
user    0m7.178s
sys     0m0.073s

pigz:
real    0m1.995s
user    0m7.017s
sys     0m0.120s

real    0m2.107s
user    0m7.041s
sys     0m0.104s

real    0m2.129s
user    0m7.014s
sys     0m0.123s

Pigzj:
real    0m3.292s
user    0m9.034s
sys     0m0.398s

real    0m3.590s
user    0m9.140s
sys     0m0.453s

real    0m3.623s
user    0m9.320s
sys     0m0.417s

pigzj:
real    0m3.535s
user    0m8.680s
sys     0m0.360s

real    0m4.433s
user    0m8.593s
sys     0m0.457s

real    0m3.832s
user    0m8.377s
sys     0m0.402s

Original size: 126788567
gzip: 43476941
- compression ratio for gzip: 34.3%
pigz: 43351345
- compression ratio for pigz: 34.2%
Pigzj: 44158202
- compression ratio for Pigzj: 34.8%
pigzj: 44214787
- compression ratio for pigzj: 34.9%

As you can see by the times, gzip is slower on a large input when
pigz, pigzj, and Pigzj use multiple threads. In these cases,
pigzj and Pigzj are competitive with pigz in real time.

I used strace to generate traces of system calls executed by the
four programs. The number of calls by pigzj and Pigzj are similar.
pigz has more system calls than gzip. But pigzj and Pigzj have a lot
more system calls than pigz and gzip. This generally explains the
performance difference because the more system calls you have, the
slower your program runs. This can be seen when they all run with
1 thread where pigz is slightly slower than gzip and Pigzj and pigzj
are way slower.

As file size and number of threads scale up, the parallelized programs
(ie, pigz, pigzj, and Pigzj) will run faster. However, since Java
is interpreted and C is compiled straight to machine code, pigz will
run faster than pigzj and Pigzj on average. pigzj and Pigzj will
be competitive but in general shouldn't beat pigz. Also, due to the
large size of the data structures being passed between threads, there
is a larger overhead for pigzj and Pigzj resulting in a longer time.
For small files, it wouldn't make sense to use pigzj for similar reasoning.
Particularly, the overhead of starting threads would cause it to be
slower than gzip. This goes the same for pigzj and Pigzj.

So for pure performance, on large files you should use pigz and on
small files you should use gzip.
