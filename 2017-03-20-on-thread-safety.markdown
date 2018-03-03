---
layout: post
title: "On Thread Safety"
date: 2017-03-20T18:21:17-07:00
---

<a name="audience"></a>
# [#](#audience) AUDIENCE

A quick warning: I express a lot of liberty in choosing my word choice. I may insert some non-family-friendly/swear/curse words here and there for the entertainment of the reader or to express a strong point. If you are not allowed to read that type of thing, or are uncomfortable consuming them, please stop reading here. I will consider to write a cleaned-up version and post it sometime in the future.

While I attempt to do my best to explain as many of the concepts as possible in layman terms, it may become very difficult to follow along with what I say if you have no prior programming experience. I recommend being a proficient programmer before reading this.

I have also specifically targeted this post to Java. Whether or not what I say applies to other languages or concepts, I do not care nor do I intend to make those connections.

I go from the very basics to some quite high-level topics in this post. If you are a professional dev who has worked in the industry for decades and already know how to write thread-safe code, good for you. I do not intend the beginning few sections to be targeted for you. If you are a beginner, you might find some of the concepts difficult to comprehend. That's OK. If you need a break, go ahead and take one and let the information you've learned sink in.

Finally, I really do try to my best of my ability to avoid making erreneous or overly biased, opininated claims. However, I am a human. I make mistakes. I have opinions. I am not responsible for your losses due to you using what I write to write your own code. Your code is your responsibility. My opinions do not represent those who I am associated with whether they be my (currently nonexistant) employer, my friends, etc. They are my own opinions only. I do not portray myself as superior in skill, age, or whatever in anyway to the reader. If you interpret what I write as so, feel free to stop reading and be a dick to me in retaliation (or politely call me out).

With that said, I do hope that you will learn something out of reading what I have written.

---

<a name="introduction"></a>
# [#](#introduction) INTRODUCTION

- Asynchronous
- Multithreaded
- Scalable
- Parallel
- Concurrent

Heard of these words before?

In case you've been living under a rock for over a (few) decade(s), or you are not a programmer, these are quite important concepts to understand in the modern world of computing. Parallelization is absolutely one of the most important ways that computers have become more and more powerful over the years, and the time has come for people to understand how to build software that truly takes advantage of parallelism rather than processor clock speeds.

> serial programs run on modern computers "waste" potential computing power.

> During the past 20+ years, the trends indicated by ever faster networks, distributed systems, and multi-processor computer architectures (even at the desktop level) clearly show that parallelism is the future of computing.

([Introduction to Parallel Computing, Lawrence Livermore National Labratory](https://computing.llnl.gov/tutorials/parallel_comp/#WhyUse))

> This changeover [from favoring high clock speeds to favoring multicore processors instead] had a profound impact on software performance. Previously, faster hardware speeds translated directly into faster software computation. Afterwards, only software that could take advantage of multiple processors would get this benefit – and not all of them could

([Moore’s Law Goes Multicore, Berkeley Haas School of Business](http://funginstitute.berkeley.edu/wp-content/uploads/2013/12/Neil_Thompson-27s_Moore-27s_Law_Paper_-_Summary.pdf))

It turns out that the benefit that comes from exploiting multiprocessors is a double-edged blade. We find that there is a *minor* difficulty with developing software that is capable of multithreading, that is, ensuring that these applications are **thread-safe**.

(Quick side note: multithreading is an extremely difficult topic to organize and talk about. Ideas jump all over the place and there are many different things that all contribute to fully understanding one big thing, and the little things cannot be organized into different, larger subgroups)

---

<a name="what-is-thread-safety"></a>
# [#](#what-is-thread-safety) WHAT IS THREAD-SAFETY?

When sharing data between threads, it is vitally important to realize that the same assumptions about the ordering of operations cannot be held true for multithreaded programs as they are for single-threaded ones.

> As a small side note, single-threaded programs are not truly single-threaded. While what the programmer does is single-threaded - things like the `main` method - the program as a whole is not. There are threads managed by the JVM in the background, such as the GC thread(s), the JIT thread(s), maybe RMI threads or Ctrl-Break monitor threads if applicable, among others. This means that while there are never truly "single-threaded" programs in the strictest definition of the term, it is important to realise that threads in the JVM sub-system do not interfere or comprimise the thread-safety of a "single-threaded" program. If the programmer does not interact with additional threads other than the main thread which runs the `main` method, **there are no thread-safety issues with the code. In the absence of program-level threads, it is *impossible* for thread-safety to be a problem**.

The idea of making a program thread-safe is the same as making what is arbitrary predictable. The nature of threads is that they run independently of each other. In doing so, it is impossible to determine the timing between operations or the effects of a read or write on a state variable.

> **State**: When I use "state" or "shared state," I refer to data to which a thread might be able to read or write. It is a general term used to describe whatever is made available to threads to access. This may be an instance object that is passed around, a global variable, a class field. For example, I can say that a thread will mutate a state by incrementing it, or a thread can mutate a state by setting its value, because the "state" is the data that the thread is accessing and mutating, or changing in some way. I can also say that a thread will read the state of an object to say that the thread will be able to use the object's getters to obtain the value of its fields.


**While the issues relating to thread-safety are diverse and expansive, most issues can be boiled down to either an ordering or visibility issue.**

The nature of *most* programs is that they must enforce a relationship between its threads in order to calculate a result, to report back the status of an operation, to listen to events, etc... All of these require threads to be dependent on each other, against their independent nature:

If it were possible to isolate visibility issues, then surprising behavior that results from this can be seen in the following diagram of two threads accessing a shared state:

![Visbility]({{ site.url }}/blog/img/Visibility.jpg)

In the absence of adequate synchronization, the above diagram demonstrates how `Thread 1` continued to read a "stale" value of `4` from a shared state, before but also after `Thread 2` has set it to `5`. The effect of writing `5` to the shared variable was therefore not visible to `Thread 1`.

Also consider the following code:

``` java
MutableState state = // ...
Thread t1 = new Thread(() -> {
    state.mutate();
    System.out.println(state.read());
});
Thread t2 = new Thread(() -> {
    state.mutate();
    System.out.println(state.read());
});
t1.start();
t2.start();
```

In the absence of adequate synchronization between threads, there can be no correct assumptions about the order of operations. Recalling that threads are arbitrary and independent, it is entirely possible for `t1` to start AFTER `t2`. It is also possible for `t1` to run as expected before `t2`, but there are no guarantees here. It is even possible for `t1` to `state.mutate()` *simultaneously* with `t2`. To further our visibility example, it is further possible for `t2` to not even see what changes have been made by `t1`. In effect, the results of running these two threads are then arbitrary and indeterminate as well.

This is the heart of thread-safety. Through using tools such as locks, synchronization tools, atomic variables and others, code that is not thread-safe can be tamed and used to exploit modern multiprocessors.

---

<a name="what-causes-threads-to-behave-this-way"></a>
# [#](#what-causes-threads-to-behave-this-way) WHAT CAUSES THREADS TO BEHAVE THIS WAY?

Having some basic idea of what "thread-safety" is, I believe that there is benefit in discussing the nitty gritty details of why threads behave in this "independent" manner. There tends to be a lot of widespread use of mere analogies in order to explain why thread-safety is a problem and this in itself has caused issues on its own, much like how parents might avoid talking about sexual intercourse with their children until they are older.

Going along the same vein with the "messy details" of multithreading, I think now would be a good time to also discuss some drawbacks of writing multithreaded programs:

- They are difficult to write correctly
- They are difficult to test for correctness
- They are difficult to test for performance
- They are difficult to understand multithreaded code
- It is difficult to distribute work and tasks amongst threads
- It is difficult to do resource management - deadlocks, livelocks, starvation
- Coercing system resources to initialize a thread is relatively expensive
- Locking, memory barriers, mutexes and other synchronization primitives add housekeeping overhead
- Ordering and fencing memory access are not free
- Distributing processor time by the thread scheduler comes with overhead
- They sometimes cause degredation in performance due to poor implementaiton
- They are prone to interfering with other threads or other programs

![CPU]({{ site.url }}/blog/img/CPU.jpg)

<!-- TODO -->

Sources used:

- [CPU Cache Flushing Fallacy, Mechanical Sympathy](https://mechanical-sympathy.blogspot.com/2013/02/cpu-cache-flushing-fallacy.html)
- [Memory Barriers/Fences, Mechanical Sympathy](https://mechanical-sympathy.blogspot.com/2011/07/memory-barriersfences.html)
- [Thread scheduling implications in Java, Javamex](http://www.javamex.com/tutorials/threads/thread_scheduling_java.shtml)
- [Context and process switching, Javamex](http://www.javamex.com/tutorials/threads/context_switch.shtml)
- [Multi-core architectures, Carnegie Mellon University](https://www.cs.cmu.edu/~fp/courses/15213-s06/lectures/27-multicore.pdf)
- [Lecture 10: Cache Coherence: Part I, Carnegie Mellon University](https://www.cs.cmu.edu/afs/cs/academic/class/15418-s12/www/lectures/10_coherence.pdf)
- [MESI Cache Coherency Protocol, Trinity College Dublin, the University of Dublin, Ireland](https://www.scss.tcd.ie/Jeremy.Jones/vivio/caches/MESIHelp.htm)
- [Memory Ordering, Portland State University](http://web.cecs.pdx.edu/~alaa/ece587/notes/memory-ordering.pdf)

---

<a name="how-to-write-thread-safe-code"></a>
# [#](#how-to-write-thread-safe-code) HOW TO WRITE THREAD-SAFE CODE?


``` java
@ThreadSafe
public class ThreadNotUnsafe {
    // Add 'volatile'
    private volatile int state = 4;
    
    public void setState(int newState) {
        this.state = newState;
    }
    
    public void getState() {
        return this.state;
    }
}
```

One of the primitives that the Java language gives developers is the `volatile` keyword. This keyword is only applicable to fields. 
