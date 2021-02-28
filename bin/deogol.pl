#!/usr/bin/perl -w
#
# This file is part of Deogol.
#
# Deogol is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Deogol is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Deogol; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#############################################################################

use strict;
use Getopt::Long;

my $DEOGOL_BINDIR = '../bin';

push(@INC, $DEOGOL_BINDIR);
require messageio;
require ElementTree;

#############################################################################

my $alph_len         = 256;
my $usage_str = "Usage: $0 message_file < html_container > modified_container";

my $arg_capacity   = 0;
my $arg_compress   = 0;
my $arg_container  ='-';
my $arg_encode     = 1;
my $arg_filter     = '';
my $arg_message    = 0;
my $arg_msgsize    = 0;
my $arg_noise      = 0;
my $arg_size       = 0;
my $arg_text       = 0;

my @bin_t2b        = ('bin2text.pl -f', 'text2bin.pl -f');

&GetOptions('capacity|c'    => \$arg_capacity,
            'container=s'   => \$arg_container,
            'encode|e'      => \$arg_encode,
            'decode|d'      => sub { $arg_encode=0 },
            'filter|f=s'    => \$arg_filter,
            'size|s'        => \$arg_msgsize,
            'message=s'     => \$arg_message,
            'noise|random'  => \$arg_noise);


my @commandlist      = ();
my $cmd              = '';
my $message_file     = '';
my $message_capacity = '';
my $container_text   = '';

my $elementtree      = '';
my $message          = []; #ref array

my $message_length   = '';

if (not($arg_message)) {
   if (scalar(@ARGV) > 0) {
       $arg_message = $ARGV[0];
   } elsif (not($arg_noise) and not($arg_capacity)) {
       die($usage_str.".\n");
   }
}

# If the user is only checking the message size, he doesn't care about the
# container capacity, UNLESS the message is pure noise, in which the message
# size must be equal to capacity.
if (not($arg_msgsize) or ($arg_noise)) {
   if ($arg_container =~ m{^http://}) {
      die("Sorry, URLs not supported yet.  Container must be a filename.\n");
   } else {
      # We read in the input, line by line, and throw it into a string
      open(CONTAINER,$arg_container)
                    || die("Cannot open $arg_container for reading.\n");
      while (<CONTAINER>) { $container_text .= $_; }
      close(CONTAINER);
   }

   # Parse the input into tags and text
   $elementtree = ElementTree::new($container_text, $alph_len);
   $message_capacity = $elementtree->GetMessageCapacity();

#############################################################################
   if ($arg_capacity) {
       print "Container capacity: $message_capacity\n";
       exit;
   }

   if (not $arg_encode) {
       $message = $elementtree->DecodeMessageFromTree();
   }
}
####################################################################


# Here, we figure out just what filters will be run on the data before
# it's written or read.
if ($arg_text) {
   $cmd = $bin_t2b[ $arg_encode ];
   push(@commandlist, $cmd);
}
if ($arg_filter)   { push(@commandlist, $arg_filter); }

# Having determined what filters we're using, we pipe the actual
# input file into the first program, and then pipe the output through
# the rest.  Or, if no filters are being used, just pass the filename.
if ($arg_encode) {
   if ((scalar(@commandlist) > 0) and ($arg_message eq '-')) {
      $message_file = join(' | ',@commandlist).' |';
   } elsif ((scalar(@commandlist) > 0)) {
      $message_file = shift(@commandlist)." < $arg_message | ";
      if (scalar(@commandlist) > 0) {
         $message_file .= join(' | ',@commandlist).' |';
      }
   } else {
      $message_file = $arg_message;
   }
} else {
   @commandlist = reverse(@commandlist);
   if ((scalar(@commandlist) > 0) and ($arg_message eq '-')) {
      $message_file = '| '.join(' | ',@commandlist);
   } elsif (scalar(@commandlist) > 0) {
      $message_file = '| '.join(' | ',@commandlist)." > $arg_message";
   } else {
      $message_file = "> $arg_message";
   }
}

#############################################################################

if ($arg_encode) {
   if ( not($arg_noise) ) {
      # Here we open the file, run it through whatever filter
      # we're using, and pass the output byte-by-byte into @$message.
      &ReadMessage($message_file, $message);
   } else {
      # Here we generate a random message.
      # (Well, as random as Perl is capable of, anyway).
      for (my $i=0;  $i<$message_capacity;  $i++) {
         push(@$message,rand(256));
      }
   }
}
$message_length = scalar(@$message);

if ($arg_msgsize) {
   print "$message_length\n";
   exit;
} elsif ($arg_encode and ($message_length > $message_capacity)) {
   die "Error: Container capacity exceeded.",
       "$message_length $message_capacity.\n";
}

#############################################################################
# Finally, we go through the tags to make the appropriate substitutions.

if ($arg_encode) {
   my $success = $elementtree->EncodeMessageInTree($message);
   if ( $success ) {
      # Replace the elements in the document with their counterparts
      # with attributes permuted.
      $elementtree->AssignPermutedTags();
      print $elementtree->ToString();
   } else {
      # This shouldn't happen; the condition should be caught before
      # encoding the message in the HTML document.
      die "Error: Container capacity has been exhausted; message is too big.\n";
   }
} else {
   &WriteMessage($message_file, $message);
}
