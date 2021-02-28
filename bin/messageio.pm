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

#############################################################################

sub ReadMessage {
   my $input='';
   my $binfile=$_[0];
   my $msg_ref=$_[1];
   open(BINFILE, $binfile)  || die("Cannot open $binfile for reading.\n");
   while ( read(BINFILE,$input,1) > 0 ) {
      push(@$msg_ref,ord($input));
   }
   close(BINFILE);
   return $msg_ref;
}

sub WriteMessage {
   my $outfile=$_[0];
   my $msg_ref=$_[1];
   my $packet;
   open(BINFILE, $outfile)  || die("Cannot open $outfile for writing.\n");
   while ( scalar(@$msg_ref) > 0 ) {
      $packet = shift(@$msg_ref);
      print(BINFILE chr($packet));
   }
   close(BINFILE);
   return 1;
}

sub ReadAlphabet {
   my $alphabet='';
   my $alphabet_file=$_[0];

   open(ALPHABET,$alphabet_file);
   while (<ALPHABET>) { $alphabet .= $_; }
   close(ALPHABET);
   return $alphabet;
}

#############################################################################

1;
