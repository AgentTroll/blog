---
layout: post
title: "Lessons Learned Debugging: Part 1"
date: 2019-03-20T22:27:00-07:00
---

This is going to be among the first in a blog series that
detail some of my work while at Intermissum to reduce
bugginess. Not only did I personally run into many
hardships in order to write better production-quality
plugins, this series will present me with new challenges in
the form of figuring out what to share, what not to share,
as well as what I am not *allowed* to share.

# Splitting Up Your Code

The first lesson, while it may seem obvious to some, is to
always split up your code. What I used to do was place a
large majority of my code in the main class, reasoning that
the more I can keep in the main class, the less classes and
therefore the less complexity I will have to deal with.
There are often [memes](https://github.com/EnterpriseQualityCoding/FizzBuzzEnterpriseEdition) 
that stigmatize complexity or "enterprise" design in a 
negative light. While monolithic codebases such as the
Spring framework with sprawling abstractions for each and
every possible purpose might add credit to this stigma,
using abstractions and creating purpose-built classes can
improve your code quality and productivity vastly.

Some of the many advantages to splitting up your code
include:

  - Less mental overhead to keep track of where specific
  code segments are in your file
  - It is easier to navigate classes that have a purpose
  rather than through a file that has many purposes
  - It will be easier to browse and evaluate what the
  plugin is doing

All of these will contribute to less buggy code, because
you will be less mentally fatigued by housekeeping while
you are writing the code, as well as being able to more
quickly debug and walk through the call trace in a logical
fashion. Splitting up my code in a sensible way was far and
away one of the most effective steps I took in reducing the
bugginess of my code.

# Drawbacks?

You will feel like you are less productive initially if you
are not used to the workflow. You are going to feel like
creating new files is such a pain, how you need to set
everything up, how writing more pragmatic and clean code
takes up so much space and isn't as elegant as what you
would have figured out when writing code that fits into a
single class.

You will feel like you're creating classes all the time and
not writing enough code. You will feel like there's so much
boilerplate, and the gains you are making are marginal.
But I implore you to trust me on this one. You are clearing
out mental clutter. You are making less mistakes, because
you are taking time to really understand the code and how
it all fits into the big picture. You are slowing down when
you write code, so you have less bugs down the line to have
to fix. I cannot stress enough that this is something that
has been tried and tested dozens upon dozens of times, and
that I myself have found success in being more watchful
over my tendency to write spaghetti code.

You will thank yourself in the future, when you have to
look back over your code, because it is so much easier to
understand. You will see that you have gotten better at
recognizing the responsibility of each component of your
code. You will become a better engineer, because you will
have gotten closer to *designing* your code rather than
simply *writing* your code. These are skills that you build
up by changing poor programming practices, so it pays to
really evaluate yourself now.

# Conclusion

There you go, that's tip #1 done. These are meant to be
simple, short, and practical. If you've been disappointed,
then hopefully the next one will offer some insight you
yourself have missed.

I leave with the following wisdom from [The Power of Ten](http://spinroot.com/gerard/pdf/P10.pdf):

> If the rules seem Draconian at first, bear in mind that
they are meant to make it possible to check code where very
literally your life may depend on its correctness: code 
that is used to control the airplane that you fly on, the 
nuclear powerplant a few miles from where you live, or the 
spacecraft that carries astronauts into orbit. The rules 
act like the seat-belt in your car: initially they are 
perhaps a little uncomfortable, but after a while their use
becomes second-nature and not using them becomes 
unimaginable. 

While these tips are not necessarily rules that are
responsible for keeping people alive, incorporating the
same philosophy into your programming repertoire will help
you in the long run.
