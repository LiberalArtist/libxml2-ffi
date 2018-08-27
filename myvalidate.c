#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/valid.h>
#include <stdio.h>

// cc -Wall -I/usr/include/libxml2 -lxml2 -shared -o libmyvalidate.so myvalidate.c

unsigned int my_validate(const xmlDtdPtr dtd,
			 const xmlChar* docStr,
			 const char* outPath) {
    if (NULL == dtd || NULL == outPath || NULL == docStr) {
	return 2;
    }
    const xmlValidCtxtPtr ctxt = xmlNewValidCtxt();
    if (NULL == ctxt) {
	return 2;
    }
    const xmlDocPtr doc = xmlParseDoc(docStr);
    if (NULL == doc) {
	xmlFreeValidCtxt(ctxt);
	return 2;
    }
    FILE* out = fopen(outPath,"w");
    if (NULL == out) {
	xmlFreeDoc(doc);
	xmlFreeValidCtxt(ctxt);
	return 2;
    }
    ctxt->userData = (void *) out;
    ctxt->error    = (xmlValidityErrorFunc) fprintf;
    ctxt->warning  = (xmlValidityWarningFunc) fprintf;
    const int rslt = xmlValidateDtd(ctxt,doc,dtd);
    fclose(out);
    xmlFreeDoc(doc);
    xmlFreeValidCtxt(ctxt);
    if (1 == rslt) {
	return 0;
    } else {
	return 1;
    }
}


