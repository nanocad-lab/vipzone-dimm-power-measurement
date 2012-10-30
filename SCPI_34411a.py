import socket
import time
import struct
import string

class SCPI_34411a:
    def __init__(self, host, port, timeout=0.0):
        self.host = host
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((host, port))
        self.s.settimeout(timeout)
        self.resetAndClear()
                	
    def resetAndClear(self):
    	self.s.send("*RST\n")
    	time.sleep(0.1)
        self.s.send("*CLS\n")
        time.sleep(0.1)
    
    def read(self):
    	self.s.send("READ?\n")

    def setVoltageDC(self, limit="AUTO", precision=""):
        if precision == "":
            self.s.send("CONF:VOLT:DC %s\n" %(limit))
            time.sleep(0.1)
        else:
			self.s.send("CONF:VOLT:DC %s,%s\n" %(limit,precision))
			time.sleep(0.1)
		
    def setVoltageNPLC(self, nplc="10"):
		self.s.send("VOLT:DC:NPLC %s\n" %(nplc))
		time.sleep(0.1)
			
    def disableAutoZero(self):
		self.s.send("SENSE:VOLTAGE:DC:ZERO:AUTO OFF\n")
		time.sleep(0.1)
		self.s.send("SENSE:VOLTAGE:DC:NULL OFF\n")
		time.sleep(0.1)
		
    def disableTrigDelay(self):
		self.s.send("TRIG:DELAY:AUTO OFF\n")
		time.sleep(0.1)
		self.s.send("TRIG:DELAY 0\n")
		time.sleep(0.1)
		
    def disableCalc(self):
		self.s.send("CALC:STATE OFF\n")
		
    def setTriggerSource(self, source="AUTO"):
        self.s.send("TRIG:SOURCE %s\n"%(source))
        time.sleep(0.1)
        
    def setLANOnly(self):
    	self.s.send("SYST:COMM:ENAB OFF, GPIB\n")
    	time.sleep(0.1)
    	self.s.send("SYST:COMM:ENAB OFF, USB\n")
    	time.sleep(0.1)
    	self.s.send("SYST:COMM:ENAB OFF, VXI11\n")
    	time.sleep(0.1)
    	self.s.send("SYST:COMM:ENAB OFF, WEB\n")
    	time.sleep(0.1)
    	self.s.send("SYST:COMM:ENAB OFF, TELNET\n")
    	time.sleep(0.1)

    def setTriggerCount(self, count="INF"):
        self.s.send("TRIG:COUNT %s\n"%(count))
        time.sleep(0.1)
       
    def setSampleCount(self, count="1"):
    	self.s.send("SAMPLE:COUNT %s\n" %(count))
        time.sleep(0.1)

    def init(self):
        self.s.send("INIT\n")
        
    def fetch(self):
    	self.s.send("FETCH?\n")
		
    def getMeasurements(self):
    	try:
    		data = self.s.recv(16384) #16KB buffer
    	except socket.timeout:
    		temp = 0
    		return "",0

        return data,len(data)
    
    def disableDisplay(self):
    	self.s.send("DISPLAY OFF\n")
    	time.sleep(0.1)
    
    def enableDisplay(self):
    	self.s.send("DISPLAY ON\n")
    	time.sleep(0.1)
    	
    def shutdown(self):
    	self.s.close()