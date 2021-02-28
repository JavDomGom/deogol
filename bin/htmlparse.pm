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

# Definition of an HTML tag.  Pretty disgusting.
$tag_regexp  = q{<[\/A-Za-z]([^>"](("[^>"]*")|('[^>']*'))*)*>};

# Definition of an HTML tag name.
$tagname_regexp  = q{^<[A-Za-z0-9\/.-]*};

# Definition of an HTML tag attribute.
$attr_regexp = q{\s*[A-Za-z0-9-.]+=?("[^"]*"|'[^']*'|#?[A-Za-z0-9-.]*%?)};
$attr_regexp = q{\s*[A-Za-z0-9-:.]+=?("[^"]*"|'[^']*'|#?[A-Za-z0-9-:.]*%?)}; 

#############################################################################

sub ParseHTML {
   my $input = $_[0];
   my @taglist = ();
   my @parsed  = ();

   # The following parses through the HTML to separate text from tags.
   # (Note we rely on the fact that Perl's pattern matcher returns the
   #   leftmost match.)

   while ( $input =~ /$tag_regexp/ ) {
      # Split based on the tag regexp
      ($before_tag, $tag, $after_tag) = ($`, $&, $');
      if ($before_tag ne '') { push(@parsed, $before_tag); }
      push(@parsed,$tag);
      push(@taglist,$#parsed);   # add an index to the latest parsed tag
      $input = $after_tag;       # prepare to parse remaining data
   }

   # Once there are no tags left in the source (that is, parsing is done)
   # we push whatever's left onto the end of our parsed list.
   if (defined($after_tag)) { push(@parsed, $after_tag); }

   return (\@parsed,\@taglist);
}

sub ParseElement {
   my $tag         = $_[0];
   my $attributes  =    '';
   my $tagname     =    '';
   my $tagend      =    '';
   my @attributelist =  ();

   # First, split the tag into name and attributes, according to our regexp
   $tag =~ /$tagname_regexp/;
   $tagname = $&;
   $attributes = substr($tag, length($tagname));
   #if (length($attributes)+length($tagname) != length($tag)) { die "!"; }

   # Now parse and separate elements
   @attributelist = ();
   while ( $attributes =~ /$attr_regexp/ and (not $attributes =~ /^\s*>$/)) {
      $attributes = $';           # prepare to parse the rest of the line
      push(@attributelist,$&);    # push this element onto our list
   }
   $tagend = $attributes;
   return $tagname, \@attributelist, $tagend;
}

1;
