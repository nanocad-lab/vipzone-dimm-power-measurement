import SCPI_34411a
import time
import sys

totalSamples = int(sys.argv[1])
nplc = float(sys.argv[2])
subdir = sys.argv[3]
filename = sys.argv[4]

sampleFreq = 60/nplc
if sampleFreq > 50000:
    sampleFreq = 50000
begin = 1
end = 1

# NESL DMM IP: 172.17.5.236
# ETH SWITCH DMM IP: 192.168.1.2
try:
	begin = 0
	f = open(subdir+"/"+filename+".dat",'w')
	
	print "Configuring DMM..."
	print "Total Samples: " + str(totalSamples)
	print "NPLC: " + str(nplc)
	print "Sample Freq (Hz): " + str(sampleFreq)
	print "Estimated Sampling Duration (s): " + str(totalSamples/sampleFreq)
	
	a34411 = SCPI_34411a.SCPI_34411a("192.168.1.2", 5025, 0.3) # Put DMM IP here
	a34411.setVoltageDC("0.1", "MAX")
	a34411.setVoltageNPLC(str(nplc))
	a34411.setTriggerSource("IMM") 
	a34411.setTriggerCount(str(totalSamples/100))
	a34411.setSampleCount(100)
	a34411.disableAutoZero()
	a34411.disableTrigDelay()
	a34411.disableDisplay()
	a34411.disableCalc()
	a34411.setLANOnly()
	
	print "Sampling data..."
	
	a34411.init()
	time.sleep(totalSamples/sampleFreq+1) # Fill internal memory buffer before fetching
	
	print "Fetching data..."
	v_len = 0
	n = 0
	rawdata = ""
	curr_t = 0

	# Fetch data
	j = 1
	a34411.fetch()
	begin = time.time() # BEGIN TIMING
	while j > 0: # Get the raw ASCII data
		meas,j = a34411.getMeasurements()
		rawdata = rawdata + meas
	end = time.time() # END TIMING
	
	# Process data
	data = rawdata.split(",")
	n = len(data)
	
	# Write data to file
	for i in range(n):
		writestr = str(curr_t) + "," + data[i] + "\n"
		f.write(writestr)
		curr_t += (1.0/sampleFreq)
		
except KeyboardInterrupt:
	print "Termination by user!"
	end = time.time()
finally:
	if end > begin and begin != 0:
		print "Fetch time (s): " + str(end-begin)
		print "Number of samples fetched: " + str(n)
		print "Transfer rate (samples/s): " + str(n / (end-begin))
	a34411.resetAndClear()
	a34411.enableDisplay()
	f.close()
	a34411.shutdown()
