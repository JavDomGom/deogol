# Deogol
An HTML steganography tool.

# Status

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-brightgreen.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Release](https://img.shields.io/badge/release-v0.11b-brightgreen)](https://github.com/JavDomGom/deogol/releases/latest)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/JavDomGom/deogol)
![Contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)


# What is Deogol?

Deogol is a commandline program implementing basic steganography on HTML files. It is written in Perl and is distributed under the GNU General Public License v3.

# News

## March 11, 2003

Version 0.11 released; minor changes in design of modules.

## July 31, 2003

Deogol is mentioned in a paper by [gray-world.net](http://gray-world.net/): [[English version](http://gray-world.net/projects/papers/covert_paper.txt)] [[version française](http://gray-world.net/projects/papers/covert_paper_fr.txt)]

## September 13, 2006

Version 0.11a released; updated URLs in man page and other text documentation.

## February 28, 2021

Version 0.11b released; I contacted Stephen Forrest to propose a small improvement, but got no response, so I decided to upload the code with my proposal to this repository. `DEOGOL_BINDIR` variable is modified so that the main program can run smoothly without the need for the user to make modifications to the code. I've also dusted a bit and updated the documentation in this README file, making it available to the community so they can contribute more current methods.

# What is steganography?

In modern parlance, [steganography](https://en.wikipedia.org/wiki/Steganography) is defined as *"hiding a secret message within a larger one in such a way that others can not discern the presence or contents of the hidden message"*.

As a concept, it's not confined to the computer world; an example of a "real-world" application of steganography is invisible ink. However, with the massive growth in the quantity of available and alterable information accessible through computers, the number of practical steganographic techniques increased immensely.

Note that steganography is distinct from cryptography: steganography seeks to hide a message in such a way that it will not be discovered; cryptography seeks to encode a message in such a way that it may be discovered but not decoded.

# What does Deogol do?

Deogol embeds a small message into an HTML container file without increasing its size or changing the non-tag text of the file. An HTML container file produced by Deogol (containing an embedded secret message) will be indistinguishable by a browser from the original HTML file used to produce it.

# How does it work?

## Basic idea

An HTML file consists of text interspersed with tags, which have the form:

```html
<tagname attribute1=value1 attribute2=value2 ... >
```

What the tags actually mean and do is left to the browser to handle, and is unimportant for our purposes. The key idea is that the attributes can have arbitrary order within the tag. Let's take a simple example of this:

```html
<IMG SRC="steve.jpg" ALT="Picture of Steve">
```

Here we have a simple command to display a JPEG file, or the text "Picture of Steve" if the file steve.jpg cannot be displayed for some reason. The above tag puts the SRC attribute before ALT, but it could just as easily have been:

```html
<IMG ALT="Picture of Steve" SRC="steve.jpg">
```

So we have two equally valid ways of expressing the same HTML tag. When designing a webpage, we can pick one or the other at our whim. However, we can also pick some convention for associating one or the other of the tags with a piece of information, say 0 or 1. Then, if we embed an HTML file with one or the other of these two equivalent tags, we can say we're using this file as a "carrier" for our one-bit
message.

## Generalization

That's the basic idea. You can argue that one bit is not very much, which is quite true. But consider this example:

```html
<TD NOWRAP ROWSPAN=1 COLSPAN=4 ALIGN=left VALIGN=top HEIGHT=40 WIDTH=40 id=col1>
```

This tag has 8 attributes. Some high-school math tells us that the number of possible distinct permutations of these attributes is 8!=40320. This means that there are 40320 tags equivalent to this one, but with attributes permuted. Thus, by choosing a particular tag of the 40320 possible in a container document, we can record log\[2\](8!) ?= 15.3 bits, or slightly less than 2 bytes.

At first glance this seems pretty unimpressive, considering we could record 80 bytes directly in the space it took us to express the tag. But that's true only if the information is in plain sight; our system of tag-encoding is tags is not foolproof, but is at least obscure. And, as the above example shows, the content-to-noise ratio of the container does considerably increase as the average number of attributes per tag increases.

## Across a document

We've seen the idea for a single tag; how does Deogol operate on a document? First, it ignores but preserves all non-tag content and any tags with 0 or 1 attributes (as these tags cannot contain any information).

It then converts the message to be encoded into a large number M, and proceeds through the container file one tag at a time. On encountering a tag with n elements, it computes M' = M div n! and p = M mod n!. The number p is a number between 0 and n!-1, which Deogol then transforms into a permutation. It then permutes the current tag according to the this ordering, and outputs the new tag. The number M is then updated with the new, strictly smaller number M', and the process continues.

Finally, either the message is completely transcribed, which happens when M=0, or the container is exhausted. (Deogol checks for the latter case and issues a warning if the container is too small.)

# The importance of preserving size

The other appealing fact is that each of the alternate expressions of the tag are the same length. A common approach of steganographic tools for the computer is inserting information in places where it doesn't matter. Examples:

* Embedding whitespace in HTML files. Whitespace doesn't show up to people viewing the file with a Web browser, so it doesn't change the rendered content.
* Inserting information in a UNIX file after the end-of-file character. This is allowed, and the extra data will not be noticed by most programs.

The problem with each of these approaches is that they offer easily-testable clues. It's simple to write a program to search for excessive whitespace in HTML documents on the web, and simple to write a program to test for data after the EOF character. Both approaches result in "unusual" files.

On the other hand, an HTML file produced by Deogol is a simple, unremarkable HTML file. Upon closer inspection, there may seem to be a rather unusual convention for ordering tags inside, but this is probably a comparatively difficult thing to test for.

# Examples of using Deogol

The following examples illustrate the basic use of Deogol. They assume    some basic knowledge of UNIX syntax on the part of the reader; note that Deogol is not restricted to UNIX platforms: it will run anywhere Perl does.

Lines below starting with $ indicate commandline input under UNIX or GNU/Linux.

## Preliminaries

First, grab a large HTML file with a lot of tags. (News sites are generally good for this.) Save this HTML file locally as container.html. Test its size with:

```bash
~$ deogol.pl -c < container.HTML
```

Deogol will print "Container capacity:" followed by the capacity in bytes. For the following examples to work, this value must be at least 25.

## Example 1

In this example we create a message, encode it, then decode it and check that the encoded message is correct.

Create a short message, and check its size:

```bash
~$ echo "Hello, world!" > message1.txt
~$ deogol.pl --size message1.txt
14
```

Having confirmed this message is less than the container capacity, embed this message into the HTML container:

```bash
~$ deogol.pl message1.txt < container.html > full_container_1.html
```

So now we've generated our HTML container with an embedded message. Look at it in your browser, or in a text editor, to see if you can see any differences from the original container.html.

Now extract the encoded message from the container to a file:

```bash
~$ deogol.pl -d message1-decoded.txt < full_container_1.html
~$ cat message1-decoded.txt
Hello, world!
```

We see that the encoded message was what we expected.

## Example 2

In this example we write a message, compress it to save space, and then encode it in our container file. Then we decode and decompress it, and check the result.

Enter the following to create a message file:

```bash
~$ echo aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa > message2.txt
```

First, we shall check the message size with Deogol:

```bash
~$ deogol.pl --s message2.txt
40
```

So message2.txt is a file with 40 characters. This may be too much for our container size, so we'll use the compression utility gzip to compress it. (We'll assume the recepient knows to decompress the file before reading it.)

```bash
~$ deogol.pl message2.txt --size --filter="gzip -f"
25
```

Thus, after filtering our message through gzip, we see that our (admittedly contrived) example is just big enough to fit it 40 characters. So we go ahead with encoding:

```bash
~$ deogol.pl message2.txt --filter="gzip -f" < container.html > full_container_2.html
```

No complaints. So the file full_container_2.html is correctly generated. Again, look at it in your browser, or in a text editor, to see if you can see any differences from the original container.html file.

We'd like to decode now to see if it worked correctly. To do this correctly, we'll need to invert the gzip compression, using gunzip:

```bash
~$ deogol.pl -d message2_decoded.txt --filter="gunzip -f" < full_container_2.html
~$ cat message2_decoded.txt
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
```

So we get back the expected answer.

# More about Deogol

More information on Deogol's commandline parameters may be found in the accompanying man page.

For the most recent code and documentation, including an up-to-date version of this file, consult the [Deogol webpage](https://hord.ca/projects/deogol/).

# Contact

Deogol was written by [Stephen Forrest](https://hord.ca/contact/) and is now maintained by the community through this repository or anyone else who wants to contribute their own version.
