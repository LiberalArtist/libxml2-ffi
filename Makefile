all: libmyvalidate.so

validate: validate.c
	cc -Wall -I/usr/include/libxml2 -lxml2 -o validate validate.c

libmyvalidate.so: myvalidate.c
	cc -Wall -I/usr/include/libxml2 -lxml2 -shared -o libmyvalidate.so myvalidate.c

