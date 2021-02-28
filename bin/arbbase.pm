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

package arbbase;

sub new {
   my $self={};
   bless $self;
   $self->{number}=[0];
   return $self;
}

sub IsEmpty {
   my $self  = shift;
   #my $self->{number}  =  $_[0];
   return (scalar(@{$self->{number}})==1 and $self->{number}[0]==0);
}

# This is a bit of a hack to get around "endian" problems created by the
#  fact that we can't write to files and stdout backwards.  (Well, not
#  efficiently, anyway) and hence can't emulate a stack perfectly.
sub ReverseNumber {
   my $self  = shift;
   my $reverse = {};
   bless $reverse;
   @{$reverse->{number}} = reverse(@{$self->{number}});
   return $reverse;
}

sub MultiplyAdd {
   my $self        = shift;
   my $base        =  $_[0];
   my $m           =  $_[1];
   my $r           =  $_[2];
   my $number_ref  =  $self->{number};
   use integer;
   local($b,$j);

   if (not(defined($number_ref))) {
      die("Undefined reference to number.\n");
   }

   # We treat the case where one multiplies by the base (left shift) specially.
   if ($base==$m) {
      if ( scalar(@{$number_ref})==1 and $number_ref->[0]==0 ) {
         $number_ref->[0] = $r;
      } else {
         push(@{$number_ref}, $r);
      }
      return 1;
   }
   
   for ($j=scalar(@{$number_ref})-1; $j>=0; $j--) {
      $b     = (($number_ref->[$j])*$m + $r) % $base; 
      $r     = (($number_ref->[$j])*$m + $r) / $base; 
      $number_ref->[$j] = $b;

      if ($j==0 and $r>0) {
	      unshift(@{$number_ref}, 0);
	      $j++;
      }
   }
   return 1;
}

# This is basically the grade-school division algorithm:
#   compute the quotient, carry the remainder, etc., etc.
sub DivideRemainder {
   my $self        = shift;
   my $base        =  $_[0];
   my $divisor     =  $_[1];
   my $number_ref  =  $self->{number};
   local($modulus,$j,$q);
   use integer;

   # We treat the case where one divides by the base (right shift) specially.
   if ($base==$divisor) {
      $modulus = pop(@{$number_ref});
      if (scalar(@{$number_ref})==0) { push(@{$number_ref}, 0); }
      return $modulus;
   }
   
   $modulus=0;
   for ($j=0; $j<=scalar(@{$number_ref})-1; $j++) {
      $q = ( $modulus*$base + ($number_ref->[$j]) ) / $divisor;
      $modulus = ( $modulus*$base + ($number_ref->[$j]) ) % $divisor;
      $number_ref->[$j] = $q;
   }
   while (scalar(@{$number_ref})>=2 and $number_ref->[0]==0) {
      shift(@{$number_ref});
   }
   return $modulus;
}

# Print the number presently stored in the reference.
#   (Useful mainly for debugging.)
sub WriteNumber {
   #my $self->{number}  =  $_[0];
   my $self = shift;
   local($string_rep);
   $string_rep='';
   foreach $digit (@{$self->{number}}) {
      $string_rep .= ($digit).' ';
   }  
   return $string_rep;
}

sub GetArrayReference {
   my $self = shift;
   return $self->{number};
}

sub SetArrayReference {
   my $self = shift;
   my $number_ref  =  $_[0];
   $self->{number} = $number_ref;
}

#########################################################################

return 1;
