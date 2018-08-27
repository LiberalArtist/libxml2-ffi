#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/valid.h>
#include <stdio.h>

// cc -Wall -I/usr/include/libxml2 -lxml2 -o validate validate.c

int validate(const xmlChar* dtdPath,
	     const char* outPath,
	     const xmlChar* docStr) {
  xmlValidCtxtPtr ctxt = xmlNewValidCtxt();
  xmlDtdPtr dtd = xmlParseDTD(NULL,dtdPath);
  xmlDocPtr doc = xmlParseDoc(docStr);
  if (NULL == ctxt || NULL == dtd || NULL == doc) {
    fprintf(stderr,"allocation failed\n");
    exit(1);
  }
  FILE* out = fopen(outPath,"w");
  if (NULL == out) {
    fprintf(stderr,"fopen failed\n");
    exit(1);
  }
  ctxt->userData = (void *) out;
  ctxt->error    = (xmlValidityErrorFunc) fprintf;
  ctxt->warning  = (xmlValidityWarningFunc) fprintf;
  int rslt = xmlValidateDtd(ctxt,doc,dtd);
  fclose(out);
  xmlFreeDoc(doc);
  xmlFreeDtd(dtd);
  xmlFreeValidCtxt(ctxt);
  return rslt;
}


int main(int argc, char* argv[]) {
  if (argc != 4) {
    fprintf(stderr,"expected 3 command-line args\n");
    return 1;
  }
  int rslt = validate((xmlChar *) argv[1],
		      argv[2],
		      (xmlChar *) argv[3]);
  if (1 == rslt) {
    printf("valid\n");
    return 0;
  } else {
    printf("NOT valid\n");
    return 1;
  }
}
