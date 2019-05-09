#! /usr/bin/env python3

import os, sys
import re
#import collections

# In P4_16 grammark.mdk file, all top level things in a P4_16 program
# are generated from the grammar symbol `declaration`:

#declaration
#    : constantDeclaration
#    | externDeclaration
#    | actionDeclaration
#    | parserDeclaration
#    | typeDeclaration
#    | controlDeclaration
#    | instantiation
#    | errorDeclaration
#    | matchKindDeclaration
#    | functionDeclaration
#    ;

# There are a bunch of comments below giving brief grammar
# descriptions of all of these things, sometimes going a level or two
# "deeper" in the grammar in order to get to some recognizable
# language syntax for the construct.

# I will create some strings to use within this program to name each
# of these things, and they will also be used as parts of file names
# for auto-generated P4_16+v1model architecture test programs to run
# through the compiler and see whether it gives an error message when
# two of these top level things have the same name, or not.


#constantDeclaration
#    : optAnnotations CONST typeRef name '=' initializer ';'
#    ;

#'constantDeclaration',

#externDeclaration
#    : optAnnotations EXTERN nonTypeName optTypeParameters '{' methodPrototypes '}'
#    | optAnnotations EXTERN functionPrototype ';'
#    ;

# I will use a separate name for an extern function declaration,
# vs. an extern object declaration, since I like to think of those as
# different kinds of objects, even though the grammar uses the same
# non-terminal symbol for both.

#'externObjectDeclaration',
#'externFunctionDeclaration',

#actionDeclaration
#    : optAnnotations ACTION name '(' parameterList ')' blockStatement
#    ;

#'actionDeclaration',

#parserDeclaration
#    : parserTypeDeclaration optConstructorParameters
#      /* no type parameters allowed in the parserTypeDeclaration */
#      '{' parserLocalElements parserStates '}'
#    ;

#'parserDeclaration',

#typeDeclaration
#    : derivedTypeDeclaration
#    | typedefDeclaration
#    | parserTypeDeclaration ';'
#    | controlTypeDeclaration ';'
#    | packageTypeDeclaration ';'
#    ;

# Keep going a little deeper in the grammar ...

#derivedTypeDeclaration
#    : headerTypeDeclaration
#    | headerUnionDeclaration
#    | structTypeDeclaration
#    | enumDeclaration
#    ;

# Keep going a little deeper in the grammar ...

#headerTypeDeclaration
#    : optAnnotations HEADER name '{' structFieldList '}'
#    ;

#'headerTypeDeclaration',

#headerUnionDeclaration
#    : optAnnotations HEADER_UNION name '{' structFieldList '}'
#    ;

#'headerUnionDeclaration',

#structTypeDeclaration
#    : optAnnotations STRUCT name '{' structFieldList '}'
#    ;

#'structTypeDeclaration',

#enumDeclaration
#    : optAnnotations ENUM name '{' identifierList '}'
#    | optAnnotations ENUM BIT '<' INTEGER '>' name '{' specifiedIdentifierList '}'
#    ;

# I will use a separate name for a regular enum type declaration vs. a
# serializable enum type declaration, just in case the compiler treats
# them differently as far as name conflicts go.

#'enumDeclaration',
#'serializableEnumDeclaration',

#typedefDeclaration
#    : optAnnotations TYPEDEF typeRef name ';'
#    | optAnnotations TYPEDEF derivedTypeDeclaration name ';'
#    | optAnnotations TYPE typeRef name ';'
#    | optAnnotations TYPE derivedTypeDeclaration name ';'
#    ;

# I will use separate names for a typedef vs. a type declaration here,
# to create different test cass for each independently.

#'typedefDeclaration',
#'typeDeclaration',

#parserTypeDeclaration
#    : optAnnotations PARSER name optTypeParameters '(' parameterList ')'
#    ;

#'parserTypeDeclaration',

#controlTypeDeclaration
#    : optAnnotations CONTROL name optTypeParameters
#      '(' parameterList ')'
#    ;

#'controlTypedeclaration',

#packageTypeDeclaration
#    : optAnnotations PACKAGE name optTypeParameters
#      '(' parameterList ')'
#    ;

#'packageTypeDeclaration',

#controlDeclaration
#    : controlTypeDeclaration optConstructorParameters
#      /* no type parameters allowed in controlTypeDeclaration */
#      '{' controlLocalDeclarations APPLY controlBody '}'
#    ;

#'controlDeclaration',

#instantiation
#    : typeRef '(' argumentList ')' name ';'
#    | annotations typeRef '(' argumentList ')' name ';'
#    ;

# I will create separate cass for instantiating each of a parser,
# control, package, and extern object, to check whether the compiler
# treats these any differently as far as top level name conflicts go.

#'parserInstantiation',
#'controlInstantiation',
#'packageInstantiation',
#'externObjectInstantiation',

#errorDeclaration
#    : ERROR '{' identifierList '}'
#    ;

# I will leave this out for now, since all error names are qualified
# by "error.", and so they cannot conflict with the name of some other
# top level thing.  Or at least, it would be much stranger if the
# compiler gave such a conflict.

#'errorDeclaration',

#matchKindDeclaration
#    : MATCH_KIND '{' identifierList '}'
#    ;

#'matchKindDeclaration',

#functionDeclaration
#    : functionPrototype blockStatement
#    ;

#'functionDeclaration'

p4_16_thing_kinds = {
    'constantDeclaration':
    {'template': 'const bit<8> {} = 5;'},
    'typedefDeclaration':
    {'template': 'typedef bit<8> {};'},
    'typeDeclaration':
    {'template': 'type bit<8> {};'},
    #'errorDeclaration':
    'matchKindDeclaration':
    {'template': 'match_kind {{ {} }}'},
    'headerTypeDeclaration':
    {'template': 'header {} {{ bit<8> f1; }}'},
    'headerUnionDeclaration':
    {'template': 'header hu1_t {{ bit<8> huf1; }}  header hu2_t {{ bit<16> huf2; }}  header_union {} {{ hu1_t hu1; hu2_t hu2; }}'},
    'structTypeDeclaration':
    {'template': 'struct {} {{ bit<8> f1; bit<16> f2; }}'},
    'enumDeclaration':
    {'template': 'enum {} {{ ENUM_CASE1, ENUM_CASE2 }}'},
    'serializableEnumDeclaration':
    {'template': 'enum bit<8> {} {{ ENUM_CASE1=3, ENUM_CASE2=12 }}'},

    'functionDeclaration':
    {'template': 'bit<8> {} (in bit<8> x) {{ return (x << 3); }}'},
    'actionDeclaration':
    {'template': 'action {} (in bit<8> x, out bit<8> y) {{ y = (x >> 2); }}'},
    'externFunctionDeclaration':
    {'template': 'extern bit<8> {} (in bit<8> x);'},

    'externObjectDeclaration':
    {'template': 'extern {} {{ bit<8> methodbar (in bit<8> x); }}'},
    'parserTypeDeclaration':
    {'template': 'parser {} (packet_in pkt);'},
    'controlTypedeclaration':
    {'template': 'control {} (in bit<8> x, out bit<8> y);'},
    'packageTypeDeclaration':
    {'template': 'package {} ();'},

#instantiation
#    : typeRef '(' argumentList ')' name ';'
#    | annotations typeRef '(' argumentList ')' name ';'
#    ;
    'externObjectInstantiation':
    {'template': 'extern MyCksum16 {{ MyCksum16(); bit<16> get<D>(in D data); }}  MyCksum16() {};'},
    'parserDeclaration':
    {'template': 'parser {} (packet_in pkt) {{ state start {{ transition accept; }} }}'},
    'controlDeclaration':
    {'template': 'control {} (in bit<8> x, out bit<8> y) {{ apply {{ y = x + 7; }} }}'},

    'parserInstantiation':
    {'template': 'parser myParser1 (packet_in pkt) {{ state start {{ transition accept; }} }}   myParser1() {};'},
    'controlInstantiation':
    {'template': 'control myControl1 (in bit<8> x, out bit<8> y) {{ apply {{ y = x + 7; }} }}    myControl1() {};'},

    # TBD
    #'packageInstantiation':
    #{'template': ''},
}

thing_name = 'foo';

for kind1 in p4_16_thing_kinds:
    template1 = p4_16_thing_kinds[kind1]['template']
    for kind2 in p4_16_thing_kinds:
        template2 = p4_16_thing_kinds[kind2]['template']
        assert isinstance(template1, str)
        assert isinstance(template2, str)
        fname = 'nameconflict-{}-{}.p4'.format(kind1, kind2);
        #print()
        #print('// {}'.format(fname))
        #print(template1.format(thing_name))
        #print(template2.format(thing_name))
        with open(fname, 'w') as f:
            print('#include <core.p4>', file=f)
            print('#include <v1model.p4>', file=f)
            print('// {}'.format(fname), file=f)
            print(template1.format(thing_name), file=f)
            print(template2.format(thing_name), file=f)
            print("""
struct headers_t { }
struct metadata_t { }
parser parserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta, inout standard_metadata_t stdmeta) { state start { transition accept; } }
control verifyChecksum(inout headers_t hdr, inout metadata_t meta) { apply { } }
control ingressImpl(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t stdmeta) { apply { } }
control egressImpl(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t stdmeta) { apply { } }
control updateChecksum(inout headers_t hdr, inout metadata_t meta) { apply { } }
control deparserImpl(packet_out packet, in headers_t hdr) { apply { } }
V1Switch(parserImpl(), verifyChecksum(), ingressImpl(), egressImpl(), updateChecksum(), deparserImpl()) main;
            """, file=f)
