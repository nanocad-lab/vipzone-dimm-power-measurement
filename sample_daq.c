#include "NIDAQmxBase.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define MIN -0.200
#define MAX 0.200
#define CHAN_NAME_BUFF_SIZE 256
#define ERR_BUFF_SIZE 256 
#define DATA_BUFF_LEN 1000
#define N_CHAN 8
#define DATA_BUFF_SIZE DATA_BUFF_LEN * N_CHAN
#define INPUT_BUFF_CHAN_LEN 100000
#define INPUT_BUFF_SIZE INPUT_BUFF_CHAN_LEN * N_CHAN
#define DAQmxErrChk(functionCall) { if( DAQmxFailed(error=(functionCall)) ) { errorHandler(error, errBuff, ERR_BUFF_SIZE, taskHandle); } }

//Call after each DAQmxBase API call to check for errors
int errorHandler(int32 error, char *errBuff, int32 size, TaskHandle taskHandle) {
    DAQmxBaseGetExtendedErrorInfo(errBuff, size);        
    printf ("DAQmxBase Error %d: %s\n", (int)error, errBuff);
	 if(taskHandle != 0) {
    	DAQmxBaseStopTask(taskHandle);
    	DAQmxBaseClearTask(taskHandle);
    }
    exit(1);
}
		
int main(int argc, char *argv[])
{
    //Task parameters
    int32       error = 0;
    TaskHandle  taskHandle = 0;
    char        errBuff[ERR_BUFF_SIZE] = {'\0'};
    
    time_t      startTime = 0;
    bool32      done = 0;

    //Channel parameters
    char        chan[] = "Dev1/ai0:7"; //differential channels

    //Timing parameters
    char        clockSource[] = "OnboardClock";
    float64     sampleRate = 0.0;

	 float64		 minValue[N_CHAN] = {0};
	 float64		 avg[N_CHAN] = {0};

    //Data read parameters
    float64     data[DATA_BUFF_SIZE];
    int32       pointsToRead = DATA_BUFF_SIZE;
    int32       pointsRead = 0;
	 float64		 duration = 0;
	 int64   	 targetNumSamples = 0;
	 float64		 timestep = 0;
	 int64		 iter = 1;
    float64     timeout = 10;
    int64       totalRead = 0;
	 int32		 row, col = 0;

	 int32		 i = 0;
    
    //Parse input
    if (argc != 3) {
    	fprintf(stderr, "Syntax: sample_daq [SAMPLE_RATE_PER_CHANNEL] [DURATION]\n");
    	return 1;
    }
    
    sampleRate = atof(argv[1]); //Get sample rate
    if (sampleRate < 1.0 || sampleRate > 250000.00) {
    	fprintf(stderr, "Illegal sample rate\n");
    	return 1;
    }
    fprintf(stderr, "Sample rate: %f Hz\n", sampleRate);
    
    duration = atof(argv[2]); //Get duration
    if (duration <= 0) {
    	fprintf(stderr, "Illegal duration\n");
    	return 1;
    }
    fprintf(stderr, "Duration: %f s\n", duration);

	 targetNumSamples = (int)(sampleRate * duration);
	 fprintf(stderr, "Target number of samples: %ld\n", (long)targetNumSamples);

	 timestep = duration / targetNumSamples;

    //Configure DAQ driver
	 fprintf(stderr, "Configuring DAQ...\n");
	 DAQmxErrChk(DAQmxBaseResetDevice("Dev1"));
    DAQmxErrChk (DAQmxBaseCreateTask("dimm_voltage_x8", &taskHandle)); //Create the task
    DAQmxErrChk (DAQmxBaseCreateAIVoltageChan(taskHandle, chan, NULL, DAQmx_Val_Diff, MIN, MAX, DAQmx_Val_Volts, NULL)); //Configure channels for voltage measurement
    DAQmxErrChk (DAQmxBaseCfgSampClkTiming(taskHandle, clockSource, sampleRate, DAQmx_Val_Rising, DAQmx_Val_FiniteSamps, targetNumSamples)); //Configure sample timing
    DAQmxErrChk (DAQmxBaseCfgInputBuffer(taskHandle, INPUT_BUFF_SIZE)); //Configure input buffer size

	 fprintf(stderr, "Starting DAQ sampling...\n");
	 //fprintf(stdout, "Time (s),Chan 1,Chan 2,Chan 3,Chan 4,Chan 5,Chan 6,Chan 7,Chan 8,\n");
    DAQmxErrChk (DAQmxBaseStartTask(taskHandle)); //Start sampling

    //Mark start time
	 startTime = time(NULL);
    
	 //Stream DAQ data to stdout
	 do {
        DAQmxErrChk (DAQmxBaseReadAnalogF64(taskHandle, pointsToRead, timeout, DAQmx_Val_GroupByScanNumber, data, DATA_BUFF_SIZE, &pointsRead, NULL)); //Read an interleaved batch of samples 
        totalRead += pointsRead;

		  //If we got data...
		  if (pointsRead > 0) {
			  fprintf(stderr, "Acquired %ld samples. Total %ld\n", (long)pointsRead, (long)totalRead);
			 
			  //Iterate over rows in the buffer
			  for (row = 0; row < pointsRead; ++row) {
				  //Print time stamp
				  fprintf(stdout, "%f,", iter*timestep); 

				  //Iterate over columns (channels) in the buffer
				  for (col = 0; col < N_CHAN; ++col) {
					   if (data[row*N_CHAN + col] < minValue[col]) //Find min value per channel
							minValue[col] = data[row*N_CHAN + col];
						avg[col] += data[row*N_CHAN + col]; //Add term to avg computation
						fprintf(stdout, "%f,", data[row*N_CHAN + col]); //Print voltage data
				  }
				  fprintf(stdout, "\n");
				  ++iter; //For timesteps
			  }
		  }
    }
	 while (totalRead < targetNumSamples); //Read until we have the target num of samples/channel
    
	 //fprintf(stderr, "\nAcquired %lu total samples. Total time elapsed = %d s\n", totalRead, time(NULL)-startTime);
	 fprintf(stderr, "\nAcquired %ld total samples.\n", (long)totalRead);
	
	 //Report avg and min values per channel
/*	 for (i = 0; i < N_CHAN; i++) {
		 avg[i] /= totalRead;
		 fprintf(stderr, "Avg[%d]: %f W, Min[%d]: %f W\n", i+1, avg[i]*1.5/0.02, i+1, minValue[i]*1.5/0.02);
		 if (minValue[i] < 0)
			 fprintf(stderr, "Saw negative chan %d\n", i+1);
	 }*/

	 //Clean up
	 if(taskHandle != 0) {
    	DAQmxBaseStopTask(taskHandle);
    	DAQmxBaseClearTask(taskHandle);
    }

    return 0;
}
