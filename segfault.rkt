#lang racket

(require ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/alloc
         "common.rkt"
         racket/runtime-path)

(define-ffi-definer define-libc
  (ffi-lib #f))

(define _fprintf-ptr
  (_cpointer 'fprintf-ptr))

(define-libc fprintf-ptr
  _fprintf-ptr
  #:c-id fprintf)

(define _FILE-ptr
  (_cpointer 'FILE))

(define-libc fopen/write
  (_fun [file : _file]
        [_bytes/nul-terminated = #"w"]
        -> [p : (_or-null _FILE-ptr)]
        -> (if p
               p
               (error 'fopen/write
                      "fopen failed\n  given: ~e"
                      file)))
  #:c-id fopen)

(define-libc fclose
  (_fun _FILE-ptr
        -> [code : _int]
        -> (unless (= 0 code)
             ;; see errno
             (error 'fclose "failed"))))

(define-cstruct _xmlValidCtxt
  ([userData _FILE-ptr] ;; user specific data block 
   [error _fprintf-ptr] ;; the callback in case of errors
   [warning _fprintf-ptr] ;; the callback in case of warning
   [node _pointer] ;; Current parsed Node
   [nodeNr _int] ;; Depth of the parsing stack
   [nodeMax _int] ;; Max depth of the parsing stack
   [nodeTab _pointer] ;; array of nodes
   [finishDtd _uint] ;; finished validating the Dtd ?
   [doc _xmlDocPtr] ;; the document
   [valid _int] ;; temporary validity check result state s
   [vstate _pointer] ;; current state
   [vstateNr _int] ;; Depth of the validation stack
   [vstateMax _int] ;; Max depth of the validation stack
   [vstateTab _pointer] ;; array of validation states
   [am _pointer] ;; the automata
   [state _pointer] ;; used to build the automata
   ))

(define _xmlValidCtxtPtr
  _xmlValidCtxt-pointer)

(define-xml2 xmlFreeValidCtxt
  (_fun _xmlValidCtxtPtr -> _void)
  #:wrap (deallocator))

(define-xml2 xmlNewValidCtxt
  (_fun -> [p : (_or-null _xmlValidCtxtPtr)]
        -> (if p
               p
               (error 'xmlNewValidCtxt
                      "couldn't allocate validation context")))
  #:wrap (allocator xmlFreeValidCtxt))

(define-xml2 xmlValidateDtd
  (_fun _xmlValidCtxtPtr _xmlDocPtr _xmlDtdPtr
        -> [code : _int]
        -> (= 1 code)))

(module+ main
  (require racket/cmdline)
  
  (define-runtime-path rkt-errors.txt-path
    "rkt-errors.txt")

  (define use-error-file? #t)
  (define use-doc-ptr bad-doc)
  
  (command-line
   #:once-any
   [("--bad-doc") "Use an invalid document."
                  (set! use-doc-ptr bad-doc)]
   [("--good-doc") "Use a valid document."
                   (set! use-doc-ptr good-doc)]
   #:once-any
   [("--use-error-file") "Set the xmlValidCtxt to write to \"rkt-errors.txt\"."
                         (set! use-error-file? #t)]
   [("--no-error-file") "Don't mutate the result of xmlNewValidCtxt()"
                        (set! use-error-file? #f)]
   #:args ()
   (define valid-ctxt-ptr
     (xmlNewValidCtxt))

   (when use-error-file?
     (define errors-file-ptr
       (fopen/write rkt-errors.txt-path))
     (set-xmlValidCtxt-userData! valid-ctxt-ptr errors-file-ptr)
     (set-xmlValidCtxt-error! valid-ctxt-ptr fprintf-ptr)
     (set-xmlValidCtxt-warning! valid-ctxt-ptr fprintf-ptr))

   (xmlValidateDtd valid-ctxt-ptr
                   use-doc-ptr
                   example.dtd-ptr)))



