---
layout: post
title: "Lessons Learned Debugging: Part 3"
date: 2019-06-03T18:48:55-07:00
---

Been another while since I've last written something, so
here goes for another post in the series.

# Keep method line counts to 30 lines or less

As a general rule of thumb, your methods should probably
never, ever exceed 30 SLOC. As a matter of fact, this is
one of the rules from the "The Power of Ten" article I've
been referencing at the end of every post in this series:

> Rule: No function should be longer than what can be 
printed on a single sheet of paper in a standard reference 
format with one line per statement and one line per
declaration. Typically, this means no more than about 60 
lines of code per function.
> 
> Rationale: Each function should be a logical unit in the 
code that is understandable and verifiable as a unit. It is 
much harder to understand a logical unit that spans 
multiple screens on a computer display or multiple pages 
when printed. Excessively long functions are often a sign 
of poorly structured code. 

While this rule does say that you can use a maximum of 60
lines per method, I myself recommend using 30 lines. "The
Power of Ten" primarily refers to C code, which usually
more verbose than Java is since it requires more 
low-level instructions to do the same thing that the Java
library might provide in a single line. The fact that 
engineers at NASA can launch satellites into space and 
control robots on another planet from right here on Earth
means that you probably can accomplish whatever end-goal
you have in mind without writing any methods exceeding 30
lines of code.

# Rationale Points

Not all of the points in the rationale make much sense for
us Java developers, however, there same principles still
apply.

#### It Helps Reduce Clutter

One of the reasons you should do this piggybacks off of the
Part 1 post - keeping your methods below a certain number
of lines helps reduce mental clutter. You can only see a
limited amount of logic before you'll need to scroll, which
means that you will hide some of the context outside of the
viewport. By keeping the number of SLOC in a method to a 
minimum, you will have a much easier time reviewing your
code as you go along because you know that it is doing one
specific thing. You will boost your productivity because
you aren't bogged down with which variables you have
initialized and what other logic you need to implement, you
instead focus on the one purpose the method has.


#### Keeping Your Methods Short Is Good Design

The second reason is because it is simply good design.
Methods should do exactly one thing and one thing only.
Joshua Bloch (author of *Effective Java*, former Google 
Software engineer, current professor at CMU) says that
API designers (which applies here as well) should adhere
to the "Principle of Least Astonishment" 
([How To Design A Good API and Why it Matters](https://youtu.be/heh4OeB9A-c?t=2910)).
This means that when you read the method name, you should
never be surprised by what the method is going to do, i.e.
the method should perform exactly the function it was
designed to do and nothing more. Too often, I will see
novice developers write methods with a generic name that
is doing too much, especially listener methods which are
like super-methods with the utter amount of logic that
needs to be performed for a method that is named something
entirely generic such that you cannot actually *tell* what
is going on.

#### Splitting Up Your Methods Encourages Documentation

Finally, the third reason is that method names can be used
as documentation. If you're doing a little bit of work that
needs to be explained, you can extract that portion of code
to a method with a descriptive name rather than adding a
comment. For example, I myself am guilty of violating this
lesson a few odd times, one of them involving the code
needed to parse an item lore. The code looks a little bit
like this:

``` java
public void parseLore(ItemMeta meta) {
    ...

    List<String> newLore = new ArrayList<>();
    for (Enchantment ench : this.enchantments) {
        String enchName = ench.getName();
        newLore.add(enchName);
    }

    if (newLore.size() > 15) {
        Collections.sort(newLore);
        newLore = newLore.sublist(0, 15);
    } 

    ...
}
```

While this snippet looks succinct in its current form,
this portion of code is embedded within dozens of lines of
code above and below. In Java, method calls are essentially
free (or at least so insignificant that if you aren't an
engineer working at Oracle it isn't worth optimizing), and
you don't even need to use a method more than once to have
a method. It costs next to nothing to add another method to
improve readability, reduce clutter, and to document the
code. The improved code would look something like so:

``` java
public void parseLore(ItemMeta meta) {
    ...

    List<String> newLore = this.parseAndTrimLore();

    ...
}

private void parseAndTrimLore() {
    List<String> newLore = new ArrayList<>();
    for (Enchantment ench : this.enchantments) {
        String enchName = ench.getName();
        newLore.add(enchName);
    }

    if (newLore.size() > 15) {
        Collections.sort(newLore);
        newLore = newLore.sublist(0, 15);
    } 

    return newLore;
}
```

Now, while reading through `#parseLore(ItemMeta)`, you
immediately know what 9 odd lines of code are doing without
having to read over it. As an added bonus, you can focus on 
getting the high-level logic of the `#parseLore(ItemMeta)` 
method down right, before moving on to debugging 
lower-level methods such as `#parseAndTrimLore()`.

While this isn't to say that comments are always bad or
they are always a code smell, but a certain [programming
mantra](https://blog.codinghorror.com/coding-without-comments/) 
reasons that commenting is a poor practice because it acts
as a crutch or as an excuse for writing code that isn't
understandable. If you focus on writing your code so that
it is easily understandable, you will reduce the amount of
bugs in your code because you are forced to slow down and
think through all the moving parts of your code. It will be
easier for yourself as well as other developers to do code
review, because your code is declarative and the intentions
of the developer are more clear. As the article author puts
it:

> if your feel your code is too complex to understand 
without comments, your code is probably just bad

# In Practice

It is important to note that as is with many rules, there
are exceptions to the rule, both the 30 SLOC limit as well
as getting rid of all your comments. I personally comment
my code all the time, but if I'm breaking 30 SLOC, I better
have a damn good reason for doing so. Otherwise, it is a
good idea to split a super-method into smaller methods.
In the future, if I ever refactor my code or if I need to
modify my super-method to not do something, I can just use
the existing sub-methods, or remove a call to a sub-method
respectively without modifying existing code. This helps
improve extensibility and productivity in the long run,
even if it takes a bit longer now to extract portions
of your code into a different method.

Many IDEs will probably have a linter, or if you aren't
running checkstyle or something, you can use SonarQube or
something of the like attached to your CI pipeline to do
checks on the SLOC of your methods. IntelliJ IDEA's linter
settings for method length is this particular entry here:

![IDEA Settings Menu]({{ site.url }}/blog/img/lld-idea-settings.png)

It's usually helpful to include along with it lambda length
as well, probably 15-20 lines for lambdas is a little too
much (at that point, pull the lambda entire lambda into a
method, or split the lambda logic into methods).

# Conclusion

This is very similar to the 
[Part 1]({{ site.url }}/blog/2019/03/20/lessons-learned-debugging-part-1.html)
reasoning in terms of keeping your code short and
organized. The effect of making changing your programming
practices is enormous, and in time, you will start to spend
less time debugging your code. Remember that the majority
of development time is debugging, not actually writing 
anything. If you are saving debugging time and instead
writing your code a little more slowly, but getting it 
right the first time, you are saving a significant amount
of time and costs down the road.

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

While these tips are not necessarily rules that are
responsible for keeping people alive, incorporating the
same philosophy into your programming repertoire will help
you in the long run.

