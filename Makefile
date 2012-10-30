nilibs=-framework nidaqmxbase -framework nidaqmxbaselv
includes=-I../../includes
flags= -O2 -arch i386
cc=gcc

files = sample_daq
      
all : $(files)

% : %.c
	$(cc) $(includes) $(flags) $< $(nilibs) -o $@

clean :
	rm -f $(files)
