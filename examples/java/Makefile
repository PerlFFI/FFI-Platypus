GCJ=gcj
CXX=g++
CFLAGS=-fPIC
LDFLAGS=-shared
RM=rm -f

libexample.so: between.o Example.o
	$(GCJ) $(LDFLAGS) -o libexample.so between.o Example.o

between.o: between.cpp
	$(CXX) $(CFLAGS) -c -o between.o between.cpp

Example.o: Example.java
	$(GCJ) $(CFLAGS) -c -o Example.o Example.java

clean:
	$(RM) *.o *.so
