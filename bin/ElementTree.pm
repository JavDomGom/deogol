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

package ElementTree;
use strict;

require 'PermEncode.pm';
require 'arbbase.pm';
require 'htmlparse.pm';

#############################################################################

sub new {
   # Here we go through each element, constructing a tree in memory to
   # hold data about the parsed elements.
   # Simulaneously, we gather data about the number of attributes in each
   # tag, and compute an estimate of how much information we can store.
   my $self                 = {};

   my $container_text       = $_[0];
   my @taglist              = ();
   my @infolist             = ();
   my $tag                  = '';
   my $tagname              = '';
   my $attributelist        = '';
   my $tagend               = '';
   my $info                 = 0;

   $self->{parsed_container} = [];
   $self->{tagindexlist}     = [];
   $self->{tagreflist}       = [];
   $self->{message_capacity} = 0;
   $self->{alph_len}         = 0;
   bless($self);

   $self->{alph_len}         = $_[1];

   #print "we have params 0: ",$_[0];

   ($self->{parsed_container}, $self->{tagindexlist})=&ParseHTML($container_text);
   @taglist = @{$self->{parsed_container}}[@{$self->{tagindexlist}}];

   foreach $tag (@taglist) {
       $attributelist    = [];
       # Separate the string into tagname and attributes
       ($tagname, $attributelist, $tagend) = &ParseElement($tag);

       # Record the amount of information available
       if (scalar(@$attributelist) >= 2) {
           if (defined($infolist[$#$attributelist-1])) {
               $infolist[$#$attributelist-1]++;
           } else {
               $infolist[$#$attributelist-1] = 1;
           }
       }
       # impose lexical order on tag attributes
       # @$attributelist = sort(@$attributelist);

       # We'll put the start and end of the tag at the start and end
       #   of @attributelist, respectively, and store a reference for later.
       unshift(@$attributelist,$tagname);
       push(@$attributelist,$tagend);

       # Save a reference to this array for later
       push(@{$self->{tagreflist}}, $attributelist);
   }

   # Here's how we compute the information (capacity of the container).
   # I thought this might be less susceptible to floating-point errors,
   #    and faster, than the obvious simple addition.
   $info = 0;
   for (my $i=0; $i<=$#infolist; $i++) {
       if (defined($infolist[$i])) {
           $info += $infolist[$i] * log(PermEncode->Factorial($i+2));
       }
   }

   # Technically, we should use POSIX::floor for this.
   # But I don't want to bother with a whole library just for that.
   #print $self->{alph_len}, " is the alphabet length.";
   #print $self->AlphabetLength(), " is the alphabet length.";
   $self->{message_capacity} = int($info/log($self->AlphabetLength()));

   return $self; # \@tagreflist, $message_capacity;
}

sub AssignPermutedTags() {
   my $self  = shift;
   @{$self->{parsed_container}}[@{$self->{tagindexlist}}]
      = $self->Collapse($self->{tagreflist});
}

sub ToString() {
   my $self  = shift;
   return join('',@{$self->{parsed_container}}); 
}

sub GetMessageCapacity() {
   my $self  = shift;
   return $self->{message_capacity};
}

sub AlphabetLength() {
   my $self  = shift;
   return $self->{alph_len};
}

sub Collapse {
#   my $tagreflist          = $_[0];
   my $self                 = shift;
   my @elementlist         = ();
   my $tagname             = '';
   my $attributelist       = '';
   my $tagend              = '';

   while (scalar(@{$self->{tagreflist}})>=1) {
       $attributelist = shift(@{$self->{tagreflist}});
       push(@elementlist, join('',@$attributelist));
   }
   return @elementlist;
}

sub SortAttributes {
   # Puts attributes in lexical order
   #  
   my $self                 = shift;
#//   my $tagreflist          = $_[0];
   my $tagname             = '';
   my $attributelist       = '';
   my $tagend              = '';

   foreach $attributelist (@{$self->{tagreflist}}) {
      $tagname = shift(@$attributelist);
      $tagend  = pop(@$attributelist);

      # impose lexical order on attributes
      @$attributelist = sort(@$attributelist);

      unshift(@$attributelist,$tagname);
      push(@$attributelist,$tagend);
   }
}

sub EncodeMessageInTree {
   my $self                 = shift;
   #my $tagreflist      = $_[0];
   my $number_ref       = $_[0];
   #my $alph_len        = $_[2];
   my $attribute_count = 0;
   my @perm            = ();
   my $tagname         = '';
   my $attributelist   = '';
   my $tagend          = '';
   my $done            = 0;
   my $divisor         = 0;
   my $modulus         = 0;
   my $message = arbbase::new();
   $message->SetArrayReference( $number_ref );

   # Pull our attribute lists back from where we stored it before.
   foreach $attributelist (@{$self->{tagreflist}}) {
      $attribute_count = scalar(@$attributelist)-2;

      $tagname = shift(@$attributelist);
      $tagend  = pop(@$attributelist);

      # Put attributes in lexical order
      @$attributelist = sort(@$attributelist);

      if ($attribute_count >= 2 and (not $done)) {
         $divisor = PermEncode->Factorial( $attribute_count );
         $modulus = $message->DivideRemainder($self->AlphabetLength(),$divisor);

         # So we've obtained the modulus that gives us our encoding.
         # Let's sort by it.
         @perm = PermEncode->GetPermutation($modulus, $attribute_count);

         # We'll use Perl's fancy subscripting to sort it by @perm.  Cool!
         @$attributelist = @$attributelist[@perm];

         # If the whole message is zero, we're done, so flag it.
         if ($message->IsEmpty()) { $done = 1; }
      } else {
        # Otherwise, leave the attributes in lexical order.
      }

      # Now put the start and end back in the attribute list
      unshift(@$attributelist, $tagname);
      push(@$attributelist, $tagend);
   }
   return $done;
}

sub DecodeMessageFromTree {
   my $self                 = shift;
  #$// my $tagreflist            = $_[0];
  #// my $alph_len              = $_[1];
   my $message               = 0;
   my @encoded_message       = ();
   my @sorted_attributelist  = ();
   my $attribute_count       = 0;
   my @perm                  = ();
   my $tagname               = '';
   my $attributelist         = '';
   my $tagend                = '';
   my $modulus               = 0;
   my $divisor               = 0;
   my $done                  = 0;

   foreach $attributelist (@{$self->{tagreflist}}) {
      $attribute_count = scalar(@$attributelist)-2;

      if ( $attribute_count >= 2 ) {
         $tagname = shift(@$attributelist);
         $tagend  = pop(@$attributelist);

         @sorted_attributelist = sort(@$attributelist);
         # figure out what the order was
         @perm=();
         for (my $i=0; $i<$attribute_count; $i++) {
            for (my $j=0; $j<$attribute_count and $#perm+1<=$i; $j++) {
               if ($sorted_attributelist[$j] eq $$attributelist[$i]) {
                   push(@perm,$j);
               }
            }
         }
         $modulus = PermEncode->GetEncoding(@perm);
         push(@encoded_message, $modulus);

         # Now write it back to our master list
         unshift(@$attributelist, $tagname);
         push(@$attributelist, $tagend);
      } else {
         # We can't encode anything in tags with less than 2 elements.
         # So the "encoded value" is zero by convention.
         push(@encoded_message, 0);
      }
   }

   $message = arbbase::new();
   for (my $i=$#encoded_message; $i>=0; $i--) {
      $attributelist = $self->{tagreflist}->[$i];
      $attribute_count = scalar(@$attributelist)-2;
      if ($attribute_count >= 2) {
         $modulus = $encoded_message[$i];
         $divisor = PermEncode->Factorial($attribute_count);
         $message->MultiplyAdd($self->AlphabetLength(), $divisor, $modulus);
      }
   }
   return $message->GetArrayReference();
}

#############################################################################

1;
