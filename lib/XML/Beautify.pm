package XML::Beautify;
#require 5.6.0;
require 5.005;
$XML::Beautify::VERSION = 0.01;

use strict;
#use warnings;
use Log::AndError;
use Log::AndError::Constants qw(:all);
use XML::Parser::Expat;

##############################################################################
## Variables
##############################################################################
my($ref_self, $cleanXMLstr, $level, $noChar, $last_handle);
my %Deflt = (
	'INDENT_STR' => "\t",
	'ORIG_INDENT' => -1,
);

##############################################################################
## Documentation
##############################################################################

=head1 NAME

XML::Beautify - Beautifies XML output from XML::Writer.

=head1 SYNOPSIS

	B<WARNING:> This is Alpha Software. Plenty is subject to change.
	use XML::Beautify;
	$obj_ref = XML::Beautify->new();
	$cleanXML = $obj_ref->beautify(\$XMLstr);

=head1 DESCRIPTION

Beautifies XML output from XML::Writer and formats any old XML to be human readable.

=head1 METHODS

=cut

DESTROY {
my $self = shift;
}

# NO EXPORTS NEEDED 
# We're a good little module.
@XML::Beautify::ISA = qw(Log::AndError);
##############################################################################
## constructor
##############################################################################
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless($self, $class);

# This loads $self up with all of the default options.
	foreach my $nomen (keys(%Deflt)){
		$self->{$nomen} = $Deflt{$nomen};
	}
# This overwrites any default values in $self with stuff passed in.
	my %Cfg = @_;
    @{$self}{keys(%Cfg)} = values(%Cfg);
	$self->service_name('XML-Beautify');
	$self->debug_level($self->{'DEBUG'});
return($self);
}


##############################################################################
# Application subroutines 
##############################################################################

#################################################################################
sub beautify {
=pod

=head2 beautify()

C<Brown::Feeds::Entity::beutify()>

=over 2

=item Usage:

	$obj_ref->beautify(\$XML);

=item Purpose:

Parses the output of 

=item Returns:

($ok, $error) where $ok is 1 on success. $error is a diagnostic error message.

=back

=cut
my $self = shift;
$self->logger(DEBUG3, 'beautify('.join(',',@_).')'); 
my ($ref_XMLstr) = ($_[0]);
$self->error(-1, 'OK');

my $expat = XML::Parser::Expat->new(
								ParseParamEnt => undef,
								NoExpand => 1,
							);
$expat->setHandlers(
	'Doctype' => \&_doctype,
	'XMLDecl' => \&_decl,
	'Start' => \&_start,
	'End' => \&_end,
	'Char' => \&_char, # null????
	'Proc' => \&_proc, 
	'Comment' => \&_comment,
	'CdataStart' => \&_cDataStart,
	'CdataEnd' => \&_cDataEnd,
	'Default' => \&_default,
	'Unparsed' => \&_unparsed,
	'Notation' => \&_notation,
	'ExternEnt' => \&_extEnt,
	'Entity' => \&_ent,
	'Element' => \&_element,
	'Attlist' => \&_attriblist,
);

###HERE Need to find a better way to handle this and not use static globals.
($ref_self, $cleanXMLstr, $level, $noChar, $last_handle) = ($self, undef, $self->orig_indent, undef, undef);
###HERE Using these
#context
#Returns a list of element names that represent open elements, with the last one being the innermost. Inside start and end tag handlers, this will be the tag of the parent element. 

#current_element
#Returns the name of the innermost currently opened element. Inside start or end handlers, returns the parent of the element associated with those tags. 

#in_element(NAME)
#Returns true if NAME is equal to the name of the innermost currently opened element. If namespace processing is being used and you want to check against a name that may be in a namespace, then use the generate_ns_name method to create the NAME argument. 


$expat->parse($$ref_XMLstr);

###HERE Need to find a better way to handle this and not use static globals.
# Reset the values
($ref_self, $level, $noChar, $last_handle) = ($self, $self->orig_indent, undef, undef);
$expat->release();
$self->logger(DEBUG3, 'RETURN[beautify()]: '.$self->error_code().'/'.$self->error_msg()); 
wantarray ? return($self->error(), $cleanXMLstr) : return($cleanXMLstr);
}

##############################################################################
sub indent_str {
=pod

=head2 indent_str()

C<XML::Beautify::indent_str()>

=over 2

=item Usage:

	$indent_str = $obj_ref->indent_str();  # To retrieve the current value
        or
    $obj_ref->indent_str("\t"); # To set a new value

=item Purpose:

Sets or gets the indent str. 

=item Returns:

($indent_str) if set.

=back

=cut
my $self = shift;
$self->logger(DEBUG3, 'indent_str('.join(',',@_).')');
$self->error(-1, 'OK');
my $key = 'INDENT_STR';
   	if(!$self->{$key}){
		$self->{$key} = $Deflt{$key};
	}
	if(@_){ 
		$self->{$key} = $_[0]; 
	}

$self->logger(DEBUG3, 'RETURN[indent_str()]: '.$self->error_code().'/'.$self->error_msg()); 
return($self->{$key});
}


##############################################################################
sub orig_indent {
=pod

=head2 orig_indent()

C<XML::Beautify::orig_indent()>

=over 2

=item Usage:

	$indent_str = $obj_ref->orig_indent();  # To retrieve the current value
        or
    $obj_ref->orig_indent("\t"); # To set a new value

=item Purpose:

Sets or gets the original value for the indent incrementer. B<NB:> Beware of setting this.

=item Returns:

($indent_str) if set.

=back

=cut
my $self = shift;
$self->logger(DEBUG3, 'orig_indent('.join(',',@_).')');
$self->error(-1, 'OK');
my $key = 'ORIG_INDENT';
   	if(!$self->{$key}){
		$self->{$key} = $Deflt{$key};
	}
	if(@_){ 
		$self->{$key} = $_[0]; 
	}

$self->logger(DEBUG3, 'RETURN[orig_indent()]: '.$self->error_code().'/'.$self->error_msg()); 
return($self->{$key});
}


#################################################################################
## Private Methods
#################################################################################
sub append_str {
my $self = shift;
$self->logger(DEBUG3, 'append_str('.join(',',@_).')'); 
$self->error(-1, 'OK');
my($line) = ($_[0]);

$cleanXMLstr .= $line;

$self->logger(DEBUG3, 'RETURN[append_str()]: '.$self->error_code().'/'.$self->error_msg()); 
}

sub _doctype{
#Doctype (Parser, Name, Sysid, Pubid, Internal)
#This handler is called for DOCTYPE declarations. Name is the document type name. Sysid is the system id of the document type, if it was provided, otherwise it's undefined. Pubid is the public id of the document type, which will be undefined if no public id was given. Internal is the internal subset, given as a string. If there was no internal subset, it will be undefined. Internal will contain all whitespace, comments, processing instructions, and declarations seen in the internal subset. The declarations will be there whether or not they have been processed by another handler (except for unparsed entities processed by the Unparsed handler). However, comments and processing instructions will not appear if they've been processed by their respective handlers. 
$ref_self->logger(DEBUG3, '_doc('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser, $name, $sysid, $pubid, $internal) = @_;

	$ref_self->append_str($parser->original_string."\n");
$last_handle = '_doctype';
$ref_self->logger(DEBUG3, 'RETURN[_doc()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _decl{
#XMLDecl (Parser, Version, Encoding, Standalone)
#This handler is called for xml declarations. Version is a string containg the version. Encoding is either undefined or contains an encoding string. Standalone will be either true, false, or undefined if the standalone attribute is yes, no, or not made respectively. 
$ref_self->logger(DEBUG3, '_decl('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser, $ver, $encoding, $standalone) = @_;

	$ref_self->append_str($parser->original_string."\n");

$last_handle = '_decl';
$ref_self->logger(DEBUG3, 'RETURN[_decl()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _start{
#Start (Parser, Element [, Attr, Val [,...]])
#This event is generated when an XML start tag is recognized. Parser is an XML::Parser::Expat instance. Element is the name of the XML element that is opened with the start tag. The Attr & Val pairs are generated for each attribute in the start tag. 
$ref_self->logger(DEBUG3, '_start('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser, $element) = ($_[0], $_[1]);

	$ref_self->append_str("\n") if($last_handle eq '_start');
	$level++; #increment the level counter
	my $line = $parser->original_string();
	$line =~ s/^\w//gio;
	my $indent = $ref_self->indent_str x $level;
###HERE Try putting all data on the line with the Start Tag and then not 
#	$ref_self->append_str($indent.$parser->original_string."\n");
	$ref_self->append_str($indent.$line);
	$noChar = 1; # Set this so _end() can tell if there was any data and indent appropriately

$last_handle = '_start';
$ref_self->logger(DEBUG3, 'RETURN[_start()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _end{
#End (Parser, Element)
#This event is generated when an XML end tag is recognized. Note that an XML empty tag (<foo/>) generates both a start and an end event. 
#There is always a lower level start and end handler installed that wrap the corresponding callbacks. This is to handle the context mechanism. A consequence of this is that the default handler (see below) will not see a start tag or end tag unless the default_current method is called.
$ref_self->logger(DEBUG3, '_end('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser, $element) = ($_[0], $_[1]);

###HERE Put something in _start() and _char() that can tell if any data came through in between the tags
	my $line = $parser->original_string();
	$line =~ s/^\w//gio;
	my $indent = '';
	unless($noChar || ($last_handle eq '_char')){
		$indent = $ref_self->indent_str x $level;
	}
	$ref_self->append_str($indent.$line."\n");
	$level--; # decrement the level counter

$last_handle = '_end';
$ref_self->logger(DEBUG3, 'RETURN[_end()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _char{
#Char (Parser, String)
#This event is generated when non-markup is recognized. The non-markup sequence of characters is in String. A single non-markup sequence of characters may generate multiple calls to this handler. Whatever the encoding of the string in the original document, this is given to the handler in UTF-8. 
$ref_self->logger(DEBUG3, '_char('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser, $string) = ($_[0], $_[1]);

	$ref_self->append_str($parser->original_string);#."\n"
	$noChar = 0; # Tells _end() that some data was present

$last_handle = '_char';
$ref_self->logger(DEBUG3, 'RETURN[_char()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _proc{
#Proc (Parser, Target, Data)
#This event is generated when a processing instruction is recognized. 
$ref_self->logger(DEBUG3, '_proc('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser, $string) = ($_[0], $_[1]);

	$ref_self->append_str($parser->original_string);

$last_handle = '_proc';
$ref_self->logger(DEBUG3, 'RETURN[_proc()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _comment{
#Comment (Parser, String)
#This event is generated when a comment is recognized. 
$ref_self->logger(DEBUG3, '_comment('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser, $string) = ($_[0], $_[1]);

	my $line = $parser->original_string();
	$line =~ s/^\w//gio;
	#my $indent = $ref_self->indent_str x $level;
	$ref_self->append_str($line);

$last_handle = '_comment';
$ref_self->logger(DEBUG3, 'RETURN[_comment()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _cDataStart{
#CdataStart (Parser)
#This is called at the start of a CDATA section. 
$ref_self->logger(DEBUG3, '_cDataStart('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser) = ($_[0]);
	$ref_self->append_str($parser->original_string."\n");
$last_handle = '_cDataStart';
$ref_self->logger(DEBUG3, 'RETURN[_cDataStart()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _cDataEnd{
#CdataEnd (Parser)
#This is called at the end of a CDATA section. 
$ref_self->logger(DEBUG3, '_cDataEnd('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser) = ($_[0]);
	$ref_self->append_str($parser->original_string."\n");
$last_handle = '_cDataEnd';
$ref_self->logger(DEBUG3, 'RETURN[_cDataEnd()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _default{
#Default (Parser, String)
#This is called for any characters that don't have a registered handler. This includes both characters that are part of markup for which no events are generated (markup declarations) and characters that could generate events, but for which no handler has been registered. 
#Whatever the encoding in the original document, the string is returned to the handler in UTF-8.
$ref_self->logger(DEBUG3, '_default('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser, $str) = ($_[0], $_[1]);

	$ref_self->append_str($parser->original_string."\n");

$last_handle = '_default';
$ref_self->logger(DEBUG3, 'RETURN[_default()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _unparsed{
#Unparsed (Parser, Entity, Base, Sysid, Pubid, Notation)
#This is called for a declaration of an unparsed entity. Entity is the name of the entity. Base is the base to be used for resolving a relative URI. Sysid is the system id. Pubid is the public id. Notation is the notation name. Base and Pubid may be undefined. 
$ref_self->logger(DEBUG3, '_unparsed('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser) = ($_[0]);

	$ref_self->append_str($parser->original_string);

$last_handle = '_unparsed';
$ref_self->logger(DEBUG3, 'RETURN[_unparsed()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _notation{
#Notation (Parser, Notation, Base, Sysid, Pubid)
#This is called for a declaration of notation. Notation is the notation name. Base is the base to be used for resolving a relative URI. Sysid is the system id. Pubid is the public id. Base, Sysid, and Pubid may all be undefined. 
$ref_self->logger(DEBUG3, '_notation('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser) = ($_[0]);

	$ref_self->append_str($parser->original_string);

$last_handle = '_notation';
$ref_self->logger(DEBUG3, 'RETURN[_notation()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _extEnt{
#ExternEnt (Parser, Base, Sysid, Pubid)
#This is called when an external entity is referenced. Base is the base to be used for resolving a relative URI. Sysid is the system id. Pubid is the public id. Base, and Pubid may be undefined. 
#This handler should either return a string, which represents the contents of the external entity, or return an open filehandle that can be read to obtain the contents of the external entity, or return undef, which indicates the external entity couldn't be found and will generate a parse error.
#If an open filehandle is returned, it must be returned as either a glob (*FOO) or as a reference to a glob (e.g. an instance of IO::Handle). The parser will close the filehandle after using it.
$ref_self->logger(DEBUG3, '_extEnt('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser) = ($_[0]);

	$ref_self->append_str($parser->original_string);

$last_handle = '_extEnt';
$ref_self->logger(DEBUG3, 'RETURN[_extEnt()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _ent{
#Entity (Parser, Name, Val, Sysid, Pubid, Ndata)
#This is called when an entity is declared. For internal entities, the Val parameter will contain the value and the remaining three parameters will be undefined. For external entities, the Val parameter will be undefined, the Sysid parameter will have the system id, the Pubid parameter will have the public id if it was provided (it will be undefined otherwise), the Ndata parameter will contain the notation for unparsed entities. If this is a parameter entity declaration, then a '%' will be prefixed to the name. 
#Note that this handler and the Unparsed handler above overlap. If both are set, then this handler will not be called for unparsed entities.
$ref_self->logger(DEBUG3, '_ent('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser) = ($_[0]);

	$ref_self->append_str($parser->original_string);

$last_handle = '_ent';
$ref_self->logger(DEBUG3, 'RETURN[_ent()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _element{
#Element (Parser, Name, Model)
#The element handler is called when an element declaration is found. Name is the element name, and Model is the content model as a string. 
$ref_self->logger(DEBUG3, '_element('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser) = ($_[0]);

	$ref_self->append_str($parser->original_string);

$last_handle = '_element';
$ref_self->logger(DEBUG3, 'RETURN[_element()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

sub _attriblist{
#Attlist (Parser, Elname, Attname, Type, Default, Fixed)
#This handler is called for each attribute in an ATTLIST declaration. So an ATTLIST declaration that has multiple attributes will generate multiple calls to this handler. The Elname parameter is the name of the element with which the attribute is being associated. The Attname parameter is the name of the attribute. Type is the attribute type, given as a string. Default is the default value, which will either be ``#REQUIRED'', ``#IMPLIED'' or a quoted string (i.e. the returned string will begin and end with a quote character). If Fixed is true, then this is a fixed attribute. 
$ref_self->logger(DEBUG3, '_attriblist('.join(',',@_).')'); 
$ref_self->error(-1, 'OK');
my($parser) = ($_[0]);

	$ref_self->append_str($parser->original_string);

$last_handle = '_attriblist';
$ref_self->logger(DEBUG3, 'RETURN[_attriblist()]: '.$ref_self->error_code().'/'.$ref_self->error_msg()); 
}

#################################################################################
# WIP subs
#################################################################################

#################################################################################


=head1 HISTORY

=head2 Ver 0.01 - 1/16/02

=over 1

=item *

Born on Date.

=back

=head1 TODO

=over 1

=item *

=back

=head1 AUTHOR

=over 1

Thomas Bolioli <Thomas_Bolioli@alumni.adelphi.edu>

=back

=head1 COPYRIGHT

Copyright (c) 2001 Thomas Bolioli. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 1

=item *

Log::AndError

=item *

Log::AndError::Constants

=cut


1;
