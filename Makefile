LDFLAGS = -I/usr/include/opencv -lopencv_cudabgsegm -lopencv_cudaobjdetect -lopencv_cudastereo -lopencv_shape -lopencv_stitching -lopencv_cudafeatures2d -lopencv_superres -lopencv_cudacodec -lopencv_videostab -lopencv_cudaoptflow -lopencv_cudalegacy -lopencv_calib3d -lopencv_features2d -lopencv_objdetect -lopencv_highgui -lopencv_videoio -lopencv_photo -lopencv_imgcodecs -lopencv_cudawarping -lopencv_cudaimgproc -lopencv_cudafilters -lopencv_video -lopencv_ml -lopencv_imgproc -lopencv_flann -lopencv_cudaarithm -lopencv_core -lopencv_cudev


#build: shortSampleCpu_v2 shortSampleCpu_v3 shortSampleGpu_v3 ThreshSliders_v3 ThreshSliders_g3
build: ThreshSliders_v3 ThreshSliders_g3
#######################     CPU       ############################
shortSampleCpu_v2.o: shortSampleCpu_v2.cpp
	g++ -std=c++11 -c shortSampleCpu_v2.cpp -o shortSampleCpu_v2.o

shortSampleCpu_v2: shortSampleCpu_v2.o
	g++ -std=c++11 shortSampleCpu_v2.o -o shortSampleCpu_v2 $(LDFLAGS)

shortSampleCpu_v3.o: shortSampleCpu_v3.cpp
	g++ -std=c++11 -c shortSampleCpu_v3.cpp -o shortSampleCpu_v3.o

shortSampleCpu_v3: shortSampleCpu_v3.o
	g++ -std=c++11 shortSampleCpu_v3.o -o shortSampleCpu_v3 $(LDFLAGS)

ThreshSliders_v3.o: ThreshSliders_v3.cpp
	g++ -std=c++11 -c ThreshSliders_v3.cpp -o ThreshSliders_v3.o

ThreshSliders_v3: ThreshSliders_v3.o
	g++ -std=c++11 ThreshSliders_v3.o -o ThreshSliders_v3 $(LDFLAGS)

#######################     CUDA       ############################
CUDAFLAGS= -std=c++11 -m64 -gencode arch=compute_62,code=compute_62
LIBS= -lpthread -lcudart -lcublas
LIBDIRS=-L/usr/local/cuda-8.0/lib64
INCDIRS=-I/usr/local/cuda-8.0/include

## opencv2 gpu does not compile because it was uninstalled missing opencv2/gpu/gpu.hpp
shortSampleGpu_v2.o: shortSampleGpu_v2.cu
	nvcc -ccbin g++ $(CUDAFLAGS) $(INCDIRS) -c shortSampleGpu_v2.cu -o shortSampleGpu_v2.o 

shortSampleGpu_v2: shortSampleGpu_v2.o
	nvcc -ccbin g++ $(CUDAFLAGS) shortSampleGpu_v2.o -o shortSampleGpu_v2  $(LIBDIRS) $(LIBS) $(LDFLAGS)

shortSampleGpu_v3.o: shortSampleGpu_v3.cu
	nvcc -ccbin g++ $(CUDAFLAGS) $(INCDIRS) -c shortSampleGpu_v3.cu -o shortSampleGpu_v3.o

shortSampleGpu_v3: shortSampleGpu_v3.o
	nvcc -ccbin g++ $(CUDAFLAGS) shortSampleGpu_v3.o -o shortSampleGpu_v3 $(LIBDIRS) $(LIBS) $(LDFLAGS)

ThreshSliders_g3.o: ThreshSliders_g3.cu
	nvcc -ccbin g++ $(CUDAFLAGS) $(INCDIRS) -c ThreshSliders_g3.cu -o ThreshSliders_g3.o

ThreshSliders_g3: ThreshSliders_g3.o
	nvcc -ccbin g++ $(CUDAFLAGS) ThreshSliders_g3.o -o ThreshSliders_g3 $(LIBDIRS) $(LIBS) $(LDFLAGS)

########################    CLEAN   ################################
clean:
	-rm -f shortSampleCpu_v2.o
	-rm -f shortSampleCpu_v2
	-rm -f shortSampleCpu_v3.o
	-rm -f shortSampleCpu_v3
	-rm -f shortSampleGpu_v2.o
	-rm -f shortSampleGpu_v2
	-rm -f shortSampleGpu_v3.o
	-rm -f shortSampleGpu_v3
	-rm -f ThreshSliders_v3.o
	-rm -f ThreshSliders_v3
	
