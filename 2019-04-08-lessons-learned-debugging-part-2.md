---
layout: post
title: "Lessons Learned Debugging: Part 2"
date: 2019-04-08T22:03:10-07:00
---

One of the recurring problems that will cause you headaches
is the throwing of exceptions where you *don't want them to
be thrown*. Among these exceptions, one of the most elusive
is `ConcurrentModificationException`.

# What is `ConcurrentModificationException`?

A `ConcurrentModificationException`, or a CME, as I will
refer to it from here on out, is caused by a change, or a
modification, to a collection while iterating over it.
The most common example of this happening is through
something like this:

``` java
List<String> stringList = ...
for (String string : stringList) {
    stringList.remove(string);
}
```

The reason you cannot do this is because it will cause the
Iterator to lose track of where it is. For example, in a
collection with 10 elements, if you remove the 3rd item and
the iterator is on the 4th element, what is the iterator
supposed to do? Is it supposed to now be on the 5th element
because everything shifts down? Are you supposed to stay on
the same 4th element and shift with the removal of the
item? It's easier just to avoid the consistency issues and
throw an exception instead. We will get into how to get
around this later.

A for-each loop is simply syntax sugar over an `Iterator`.
In an `ArrayList`, the call to `Iterator#next()` checks to
ensure that `modCount` has not changed, where `modCount` is
an `int` that changes whenever the `ArrayList` has a
modification (such as through the usage of `#add(...)`
or `#remove(...)`). From the [ArrayList source](https://hg.openjdk.java.net/jdk8/jdk8/jdk/file/tip/src/share/classes/java/util/ArrayList.java#l884):

``` java
final void checkForComodification() {
    if (modCount != expectedModCount)
        throw new ConcurrentModificationException();
}
```

`expectedModCount` is the value of `modCount` when the
iterator is constructed, or when the for-loop begins. A CME
is so serious of an exception because often, one can get
away without throwing the exception during testing. If a
collection contains only one element, the `modCount` will
change after `Itr#checkForComodification()` has been
called, and no CME will be thrown. This is an issue because
one might populate a collection with only a single element
for the purposes of testing. It may be only one player,
because you are the only one testing the plugin, or it may
be only one object that you are storing to make sure that
something works. This is something that tends to slip into
production because it appears to work during testing.

As a reminder, this can happen with any collection except
those that are thread-safe, so a `HashSet`, a `LinkedList`,
and `HashMap` are all succeptible to throwing a CME if you
iterate and modify at the same time.

# Be Wary of Iteration and Unforeseen Side-Effects

One way to avoid making mistakes is to reuse paradigms that
are well understood, and that is known to already work. On
the opposite end, it is also imperative to recognize
certain paradigms that have a tendency to fail. Iteration
through Collections is one of those paradigms that you
should be on the lookout for. The simplicity of loops and
the monotony of perhaps writing them hundreds if not
thousands of times over can lower one's guard against them.

The trick is to proceed with caution when writing loops.
Ensure that you are truly only reading from them, and never
modifying the collection in the process.

There are a few important exceptions to this where you are
completely safe from CME:

    1. You are using an indexed loop. If you remove
    something, you are in control of the loop index, so
    it's up to you to correct for the index of any item
    shifting (if you are not using an indexed removal,
    that is).
    2. You are using a thread-safe collection. Iterators
    provided by those classes are only weakly-consistent,
    and it can potentially take time for modifications to
    show up. If you are simply throwing away elements,
    there's really nothing to worry about.
    3. If you are using a safe method of modifying the
    collection such as through `Iterator#remove()` or
    using `#removeIf(...)`.

You will also need to be cautious of side-effects of
methods called in the loop. For example, the following
snippet of code will throw a CME:

``` java
Inventory inventory;
for (HumanEntity viewer : inventory.getViewers()) {
    viewer.closeInventory();
}
```

Upon initial inspection, it looks completely safe, it
doesn't appear to be modifying the collection returned by
`Inventory#getViewers()`. However, this is another reason
why CMEs are so insidious. `HumanEntity#closeInventory()`
interally removes the viewer from the `#getViewers()`
collection, and so by closing the inventory, it will modify
the collection while you are still in a loop. This is only
one example from the Bukkit API, but I'm sure there are
more, I've just never personally had to deal with them.

In this case, where you are not able to change the
`#closeInventory()` method because it is written in the
API, you would make a copy of that collection and then
iterate over it:

``` java
Inventory inventory;
for (HumanEntity viewer : new ArrayList<>(inventory.getViewers())) {
    viewer.closeInventory();
}
```

This works because the new collection is a different
`ArrayList` and therefore uses a different iterator than
the actual collection of viewers. We can remove items from
the actual collection without affecting the elements in the
copy, and therefore no CME is thrown.

It is tempting to use a workaround to creating an entirely
new deep copy of the collection, such as by using
`Collections#unmodifiableCollection(...)`, or even by using
Google Guava's `Iterables.concat(...)` to "hack" in a new
iterator. However, the problem is that both of these are
non-solutions because they *still depend on the underlying
iterator*. You MUST create a new collection in order for
this to work.

# Other Solutions

Instances such as the Inventory example don't come up too
often, and sometimes you just need to run some unrelated
code to process the removed elements, or even just remove
a few elements from a loop outright.

Nowadays, the most effective solution would be to use the
`#removeIf(...)` method:

``` java
List<String> list = // ...
list.removeIf(string -> string.startsWith("remove-me"));
```

You can even use this to process the elements that should
be removed if you so wish:

``` java
List<String> list = // ...
Consumer<String> removeListener = // ...

list.removeIf(string -> {
    if (string.startsWith("remove-me")) {
        removeListener.accept(string);
        return true;
    }

    return false;
});
```

For those of us stuck on Java 7, or for reasons I might not
have forseen, you can use `Iterator#remove()` in order to
do the same thing:

``` java
List<String> list = // ...

Iterator<String> it = list.iterator();
while (it.hasNext()) {
    String string = it.next();
    if (string.startsWith("remove-me")) {
        it.remove();
    }
}
```

This will also allow you to only partially iterate by using
`break` if you so desire. A shortened form that scopes the
iterator for only a single loop will look like this:

``` java
List<String> list = // ...

for (Iterator<String> it = list.iterator(); it.hasNext(); ) {
    String string = it.next();
    if (string.startsWith("remove-me")) {
        it.remove();
    }
}
```

All of these code snippets will have the same effect of
removing `String`s starting with `remove-me`, so choose
whatever one you see fit. Once again, these will not work
if methods you are calling have the side effect of removing
the element from the collection anyways, such as 
demonstrated in the previous section, so you will be stuck
with having to deep-copy the entire collection for that.

(I'm not sure why the API designers decided not to produce
a copy of the collection there. In the modern age of
Java 8, I would have personally returned a `Stream`, but
that luxury didn't when `Inventory` was designed. In fact,
there should be no reason really why the returned 
collection is mutable, at the very least, it needs to be
unmodifiable because other cleanup procedures need to be
run for someone to actually stop "viewing" an inventory.
Perhaps this could be a PR or something to return a
deep-copy as a defensive programming measure)

# Conclusion

There are solutions to CME, but it is up to the programmer
to actually be vigilant, and to never let their guard down
in spite of the appearance of simplicity of a loop. You
must train yourself to recognize and check yourself when
you are writing loops, because a CME might also slip past
during testing as I've discussed before. This paradigm is
the second lesson in this series of posts.

I leave with the following wisdom from [The Power of Ten](http://spinroot.com/gerard/pdf/P10.pdf):

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
