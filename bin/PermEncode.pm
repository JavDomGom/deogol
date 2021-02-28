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

package PermEncode;

sub Factorial {
   my $self = shift;
   my $number = $_[0];
   my $returnValue = 1;
   for(my $i = 2; $i <= $number; $i++) {
     $returnValue *= $i;
   }
   return $returnValue;
}

#############################################################################
#
# Takes a pair of integers (i,n), where 0 <= i < n!, and returns
#   the ith permutation (of the form (a_1 .. a_n) where a_i in 1..n) in the
#   standard lexical ordering.
sub GetPermutation {
   use integer;
   my $self = shift;
   local($n,@perm,@ordering,$i,$permindex, $nf, $quotient);
   ($permindex,$n) = @_;
   @perm = ();
   @ordering = (0..$n-1);
   $nf = $self->Factorial($n);

   for ($i=0;$i<$n;$i++) {
      $nf = $nf / ($n-$i);
      $quotient = $permindex / $nf;
      $permindex = $permindex % $nf; #($n-$i);
      push(@perm, $ordering[$quotient] );
      splice(@ordering, $quotient, 1);
   }
   return @perm;
}

#############################################################################
#
# Takes a permutation (of the form (a_1 .. a_n) where a_i in 1..n) and
#   returns its index in the standard lexical ordering.
sub GetEncoding {
   local($n,@perm,@ordering,$i,$j,$permindex);
   my $self = shift;
   ($n,@perm) = ($#_+1, @_);
   @ordering = (0..$n-1);
   $permindex = 0;

   for ($i=0;$i<$n-1;$i++) {
      $permindex += ($ordering[$perm[$i]])* $self->Factorial($n-($i+1));
      for ($j=$perm[$i]+1; $j<$n ; $j++) {
         $ordering[$j]--;
      }
      splice(@ordering,$n);
   }
   return $permindex;
}

1;
