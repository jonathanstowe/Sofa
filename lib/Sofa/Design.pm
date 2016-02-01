
use v6.c;

use JSON::Name;
use JSON::Class;

use Sofa::Document::Wrapper;

class Sofa::Design does JSON::Class does Sofa::Document::Wrapper {

    class View does JSON::Class {
        has Str $.map     is json-skip-null;
        has Str $.reduce  is json-skip-null;
    }

    # Need to skip-null this so don't populate it with
    # a null
    has Str  $.name       is json-skip-null;

    has Str  $.language = "javascript";
    has View %.views;
    has Str  %.lists;
    has Str  %.shows;
    has Str  %.updates;
    has Str  %.filters;

    has Str  @.rewrites;
    has Str  $.validate-doc-update  is json-name('validate_doc_update') is json-skip-null;

    method to-json() {
        if !$!sofa_document_id.defined  && $!name.defined {
            $!sofa_document_id = '_design/' ~ $!name;
        }
        elsif $!sofa_document_id.defined && !$!name.defined {
            $!name = $!sofa_document_id.split('/')[1];
        }
        self.Sofa::Document::Wrapper::to-json();
    }

    method name() {
        if !$!name.defined && $!sofa_document_id.defined {
            $!name = $!sofa_document_id.split('/')[1];
        }
        $!name;
    }

    method id-or-name() returns Str {
        $!sofa_document_id // '_design/' ~ $!name;
    }
}

# vim: expandtab shiftwidth=4 ft=perl6
