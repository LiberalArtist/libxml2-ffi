#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/valid.h>
#include <stdio.h>

// cc -Wall -I/usr/include/libxml2 -lxml2 -shared -o libmyvalidate.so myvalidate.c

unsigned int my_validate(const xmlDtdPtr dtd,
			 const xmlDocPtr doc,
			 const char* outPath) {
    const xmlValidCtxtPtr ctxt = xmlNewValidCtxt();
    if (NULL == dtd ||
	NULL == doc ||
	NULL == outPath ||
	NULL == ctxt) {
	return 2;
    }
    FILE* out = fopen(outPath,"w");
    if (NULL == out) {
	xmlFreeValidCtxt(ctxt);
	return 2;
    }
    ctxt->userData = (void *) out;
    ctxt->error    = (xmlValidityErrorFunc) fprintf;
    ctxt->warning  = (xmlValidityWarningFunc) fprintf;
    const int rslt = xmlValidateDtd(ctxt,doc,dtd);
    fclose(out);
    xmlFreeValidCtxt(ctxt);
    if (1 == rslt) {
	return 0;
    } else {
	return 1;
    }
}


