---
layout: post
title: "Lessons Learned Debugging: Part 4"
date: 2019-06-17T23:26:40-07:00
---

I'm bored, let's write another blog post, see if I can
turn my boredom into something helpful for other
people.

# Avoid Using Hardcoded Strings

While this may be controversial, it is my opinion that
production-quality code should never have magic String
values, or you should at least never use quotes if you are
not assigning a constant.

A magic String is a raw `"string value"` that you pass
directly to a a method for example. They are called "magic"
because the `"string value"` magically makes the code work.
It may not be entirely clear what the purpose of the String 
is, or why the String has the value that it does when you
are doing code review.

Firstly, production-quality code should essentially have no
errors due to a misspelled String constant. String 
constants, especially ones that are long or used multiple
times are commonly misspelled. If you extract magic Strings
into a constant, you can reuse the constant multiple times
so long as you ensure that the original assigned constant
is spelled correctly. Pulling Strings into a constant
forces you to slow down and focus on the task of writing
the constant itself, which reduces the chance of making
spelling mistakes. It is incredibly disappointing when the
project has a few spelling errors here and there that make
the development cycle that much longer to fix for a rather
trivial issue that can be entirely avoided.

Secondly, always using `static final` constants forces you
to place them at the top of the file, which means that it
is easier for you to look over each String and review the
spelling, capitalization, etc. You can go over all your
Strings at once if you have them in a single class holding
all constants, so code review is extremely easy.

Finally, using constants allows you to make your code 
easier to understand and extensible. By having named 
constants take the place of magic Strings, the constant
name can be used to document the purpose of the code. For
example, examine the following code:

``` java
sendMessage("reply", message);
```

What do you think the `"reply"` String does? Now examine
the code when the magic String value is replaced with a
constant:

``` java
private static final String REPLY_FORMAT_CFG_KEY = "reply";

...

sendMessage(REPLY_FORMAT_CFG_KEY, message);
```

Now when you read over the code, you understand that the
String is actually a configuration key that specifies the
format for a reply message. Constant names give context and
help programmers avoid mistakes by identifying the purpose
of the value, which will help avoid copy-paste errors. If
you wanted to change the String in the future, you will be 
able to easily find the constant and change all the uses of
that particular constant as well.

As always, rules do have exceptions, and there are places
where a constant name is probably extra work. I myself
don't even use constants that often for Strings, even 
though I should definitely do it more. For example, when
I am writing a configuration file wrapper, I will probably
forgo with the constants, since configuration keys are
pretty unique, their usage is pretty clear, I know myself
and my peers probably can tell the intent of the String,
and I'm only using it once, in the wrapper file itself.
That being said, I do make copy-paste mistakes as well as
mispell the config key names sometimes, both issues that
I could avoid by always using constants instead of using a
magic String value.

In short, it may seem like extra work, but having a policy
to reduce the usage of magic Strings, and as a matter of
fact, magic values in general (numbers are even more 
difficult to guess the purpose of), will reduce the chance
of making mistakes in this area as well. You get out what
you put in, in a way.

# Conclusion

I usually put a few ending thoughts here, but there's not
really much to end on today.

As is customary, I leave with the following wisdom from 
[The Power of Ten](http://spinroot.com/gerard/pdf/P10.pdf):

> If the rules seem Draconian at first, bear in mind that
they are meant to make it possible to check code where very
literally your life may depend on its correctness: code 
that is used to control the airplane that you fly on, the 
nuclear power plant a few miles from where you live, or the 
spacecraft that carries astronauts into orbit. The rules 
act like the seat-belt in your car: initially they are 
perhaps a little uncomfortable, but after a while their use
becomes second-nature and not using them becomes 
unimaginable. 

I've been doing a little but of Bukkit stuff, a little bit
of Java-general stuff here and there, I might do a 
C-related post later on. I've never really talked about my
interest in astronomy so a little bit about how my
[`fate`](https://github.com/AgentTroll/fate) works would be
a good start.

I've also recently finished my 
[`pbft-java`](https://github.com/AgentTroll/pbft-java)
project as well, and I'm eager to talk about the different
decisions I made over the course of the project.
