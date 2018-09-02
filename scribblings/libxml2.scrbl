#lang scribble/manual
@title{@tt{libxml2}: Bindings for XML Validation}
@author[(author+email @elem{Philip M@superscript{c}Grath}
                      "philip@philipmcgrath.com"
                      #:obfuscate? #t)]
@defmodule[libxml2]

@(require scribble/example
          (for-label racket
                     xml
                     libxml2))

This package provides a Racket interface to functionality from
the C library @hyperlink["http://xmlsoft.org/" @tt{libxml2}].

Racket already has many mature XML-related libraries implemented
natively in Racket: @racketmodname[libxml2] does not aim to replace them,
nor to implement the entire @tt{libxml2} C API.
Rather, the goal is to use @tt{libxml2} for functionality not
currently available from the native Racket XML libraries,
beginning with validation.

Note that @racketmodname[libxml2] is in an early stage of development:
before relying on this library, please see in particular the notes
on @secref["Safety___Stability"].

@(local-table-of-contents)

@(define libxml2-eval
   ((make-eval-factory '(libxml2 racket/file racket/match)))) 
    

@section{DTD Validation}

The initial goal for @racketmodname[libxml2] is to support
XML validation, beginning with @tech{document type definitions}.

@deftogether[
 (@defproc[(dtd? [v any/c]) boolean?]
   @defproc[(file->dtd [pth path-string?]) dtd?])]{
 A @deftech{DTD object}, recognized by the predicate @racket[dtd?],
 is a Racket value encapsulating an XML @deftech{document type definition},
 which is a formal specification of the structure of an XML document.
 A @tech{DTD object} can be used with functions like @racket[dtd-validate-xml-string]
 to validate an XML document against the encapsulated @tech{document type definition}.

 Currently, the only way to construct a @tech{DTD object} is from a
 stand-alone DTD file using @racket[file->dtd].
 Additional mechanisms may be added in the future.

 @examples[
 #:eval libxml2-eval
 (define dtd-file
   (make-temporary-file))
 (display-lines-to-file
  '("<!ELEMENT example (good)>"
    "<!ELEMENT good (#PCDATA)>")
  #:exists 'truncate/replace
  dtd-file)
 (define example-dtd
   (file->dtd dtd-file))
 example-dtd
 (delete-file dtd-file)
 ]}

@defproc[(dtd-validate-xml-string [dtd dtd?]
                                  [doc string?]
                                  [error-buffer-file (or/c #f path-string?) #f])
         (or/c 'valid
               (and/c string? immutable?))]{
 Parses the string @racket[doc] as XML and validates it
 according to the @tech{DTD object} @racket[dtd].
 If @racket[doc] is both well-formed and valid,
 @racket[dtd-validate-xml-string] returns @racket['valid];
 otherwise, it returns an immutable string containing an error message.

 Internally, @racket[dtd-validate-xml-string] and related functions
 use a file as buffer to collect any error messages from @tt{libxml2}.
 If @racket[error-buffer-file] is provided and is not @racket[#false],
 it will be used as the buffer: it will be created if it does not already
 exist, and any existing contents will likely be overwritten.
 If @racket[error-buffer-file] is @racket[#false] (the default),
 a temporary file will be used.

 @examples[
 #:eval libxml2-eval
 (dtd-validate-xml-string
  example-dtd
  "<example><good>This is a good doc.</good></example>")
 (define buffer-file
   (make-temporary-file))
 (dtd-validate-xml-string
  example-dtd
  (string-append "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                 "<example><good>So is this.</good></example>")
  buffer-file)
 (define (show-string str)
   (let loop ([lst (regexp-split #rx"\n" str)])
     (match lst
       ['() (void)]
       [(cons str lst)
        #:when (<= (string-length str) 60)
        (displayln str (current-error-port))
        (loop lst)]
       [(cons (pregexp #px"^(.{,60})\\s+(.*)$" (list _ a b)) lst)
        (displayln a (current-error-port))
        (loop (cons (string-append "  " b) lst))])))
 (show-string 
  (dtd-validate-xml-string
   example-dtd
   "<ill-formed"
   buffer-file))
 (show-string 
  (dtd-validate-xml-string
   example-dtd
   "<example><bad>This is invalid.</bad></example>"))
 (delete-file buffer-file)       
 ]}

@defproc[(dtd-validate-xexpr [dtd dtd?]
                             [doc xexpr/c]
                             [error-buffer-file (or/c #f path-string?) #f])
         (or/c 'valid
               (and/c string? immutable?))]{
 Like @racket[dtd-validate-xml-string], but validates the
 @tech[#:doc '(lib "xml/xml.scrbl")]{x-expression} @racket[doc].
 Because @racket[doc] is an x-expression, it will always be
 at least well-formed.
 @examples[
 #:eval libxml2-eval
 #:once
 (dtd-validate-xexpr example-dtd
                     '(example (good)))
 (show-string 
  (dtd-validate-xexpr example-dtd
                      '(example (bad))))
 ]}

@defproc[(dtd-validate-xml-file [dtd dtd?]
                                [doc (and/c path-string? file-exists?)]
                                [error-buffer-file (or/c #f path-string?) #f])
         (or/c 'valid
               (and/c string? immutable?))]{
 Like @racket[dtd-validate-xml-string], but validates the XML document
 in the file @racket[doc].
}



@section{Checking Shared Library Availability}

If the @tt{libxml2} shared library cannot be loaded,
the Racket interface defers raising any exception
until a client program attempts to use the foreign
functionality.
In other words, @racket[(require @#,racketmodname[libxml2])]
should not cause an exception, even if attempting
to load the shared library fails.
(Currently, an immediate exception may be raised
if the shared library is loaded, but does not provide
the needed functionality.)

@defproc[(libxml2-available?) boolean?]{
 Returns @racket[#true] if and only if the @tt{libxml2}
 shared library was loaded successfully.
 When @racket[(libxml2-available?)] returns @racket[#false],
 indicating that the shared library could not be loaded,
 most functions provided by @racketmodname[libxml2]
 will raise an exception of the @racket[exn:fail:unsupported:libxml2]
 structure type.
 
 @history[#:added "0.0.1"]
}

@defstruct*[(exn:fail:unsupported:libxml2 exn:fail:unsupported)
            ([who symbol?])
            #:omit-constructor]{
 Raised by functions from this library that depend on
 the @tt{libxml2} shared library when the foreign library
 could not be loaded.
 The @racket[who] field identifies the origin of the exception,
 potentially in terms of the C API or other internal names.

 See also @racket[libxml2-available?].

 @history[#:added "0.0.1"]
}




@section{Usage Notes}

@subsection{Platform Dependencies}
All of this library's functionality depends on having the @tt{libxml2}
shared library available.
It is included by default with Mac OS and is readily available
on GNU/Linux via the system package manager.
For Windows users, there are plans to distribute the necessary libraries
through the Racket package manager, but this has not yet been implemented.


@subsection{Safety & Stability}
The goal for @racketmodname[libxml2] is to provide a safe interface
for Racket clients.
However, this library is still in an early stage of development:
there are likely subtle bugs, and, since @racketmodname[libxml2]
is implemented using
@seclink["intro" #:doc '(lib "scribblings/foreign/foreign.scrbl")]{unsafe}
functionality, these bugs could have bad consequences.
More fundamentally, there may be bugs and
@hyperlink["https://www.cvedetails.com/vulnerability-list/vendor_id-1962/product_id-3311/Xmlsoft-Libxml2.html"]{
 security vulnerabilities} in the underlying @tt{libxml2} shared library.
Please give careful thought to these issues when deciding whether or
how to use @racketmodname[libxml2] in your programs.

In terms of stability, @racketmodname[libxml2] is in an early
stage of development: backwards-compatibility @bold{is not} guaranteed.
However, I have no intention of breaking things gratuitously.
If you use @racketmodname[libxml2] now, I encourage you to be in touch;
I am happy to consult with users about potential changes.




