CC = gcc
CFLAGS = -Ofast -march=native -fopenmp -mcmodel=large -fno-PIC
#CFLAGS = -O0 -g -march=native -fopenmp -mcmodel=large -fno-PIC
CFLAGS_MILAN = -DSTREAM_ARRAY_SIZE=260000000
CFLAGS_GH200 = -DSTREAM_ARRAY_SIZE=240000000 -DCUSTOM_ALLOC
CFLAGS_MI300A = -DSTREAM_ARRAY_SIZE=195000000

FC = gfortran
FFLAGS = -O2 -fopenmp

all: stream_f.exe stream_c.exe

stream_f.exe: stream.f mysecond.o
	$(CC) $(CFLAGS) -c mysecond.c
	$(FC) $(FFLAGS) -c stream.f
	$(FC) $(FFLAGS) stream.o mysecond.o -o stream_f.exe

stream_c.milan: stream.c
	$(CC) $(CFLAGS) $(CFLAGS_MILAN) -DNTIMES=200 -DSTREAM_TYPE=double stream.c -o $@

stream_c.gh200: stream.c
	$(CC) $(CFLAGS) $(CFLAGS_GH200) -DNTIMES=200 -DSTREAM_TYPE=double stream.c -o $@

stream_c.mi300a: stream.c
	$(CC) $(CFLAGS) $(CFLAGS_MI300A) -DNTIMES=200 -DSTREAM_TYPE=double stream.c -o $@

stream_c.exe: stream.c
	$(CC) $(CFLAGS) $(CFLAGS_MILAN) -DNTIMES=200 -DSTREAM_TYPE=double stream.c -o stream_c.exe

clean:
	rm -f stream_f.exe stream_c.* *.o

# an example of a more complex build line for the Intel icc compiler
stream.icc: stream.c
	icc -O3 -xCORE-AVX2 -ffreestanding -qopenmp -DSTREAM_ARRAY_SIZE=80000000 -DNTIMES=20 stream.c -o stream.omp.AVX2.80M.20x.icc
