---
layout: post
title: "On Thread Safety"
date: 2017-03-20T18:21:17-07:00
---

<a name="audience"></a>
# [#](#audience) AUDIENCE

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

Before beginning, it is worth mentioning that multithreading is an extremely difficult topic to organize and talk about. Ideas jump all over the place and there are many different things that all contribute to fully understanding one big thing. I had the same experience when I was first learning about multithreading, and what I found helped me was to keep going through, because often as I learn a bit more about different topics, I strengthen my understanding of topics that I previous didn't understand fully. Take some time to digest and comprehend the ideas once you've finished rather than attempting to piece everything together as you go along.

---

<a name="what-is-thread-safety"></a>
# [#](#what-is-thread-safety) WHAT IS THREAD-SAFETY?

Thread-safety is a problem arising from when program state is shared between threads.

> **State**: state refers to variables, basically as a general term to describe anything that holds a value. Fields, global variables, and others are considered to be part of the "program state," or the various different values that need to be passed around and set in a program.

The concept of a "shared state," or state that is accessible and modifiable (mutable) by many threads is the root of thread-safety problems. A thread-safe program therefore eliminates the problems introduced by accessing that shared state from different threads.

If your program is not thread-safe, insidious and perhaps even catastrophic bugs can arise. Thread-safety issues are difficult to understand because the result of certain operations are counterintuitive on initial inspection.

#### Visibility Issues

Consider the following sequence of events from two threads that are reading and mutating the same shared state:

![Visbility]({{ site.url }}/blog/img/Visibility.jpg)

In the absence of adequate synchronization, the above diagram demonstrates how `Thread 1` continues to read `4` from a shared state, even after `Thread 2` has set it to `5`. The value read by `Thread 1` might have been cached. Another possibility is that the new value set by `Thread 2` might have been cached where only `Thread 2` can see it, and therefore `Thread 1` continues to read the value from memory when it should be reading from `Thread 2`'s cache instead. This is a visibility issue because without the necessary synchronization, it is possible that threads simply don't even see changes made to a shared state.

#### Ordering Issues

Consider the following snippet of code:

``` java
class MutableState {
    private int state;
    public void mutate() { this.state++; }
    public int read() { return this.state; }
}

MutableState state = new MutableState();
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

In the absence of synchronization to dictate the execution order between threads, there are no guarantees about who or even what runs first. It is entirely possible for `t1` to start AFTER `t2`. It is also possible for `t1` to run as expected before `t2`, but there are no guarantees here. It is even possible for `t1` to `state.mutate()` *simultaneously* with `t2`. Referring back to our visibility example, it is possible for `t2` to not even see what changes have been made by `t1`.

This time diagram shows an entirely possible execution ordering between the two threads:

![Race Condition Time Diagram]({{ site.url }}/blog/img/ots-race-condition.svg)

And the output for the two threads are then as follows:

```
2
2
```

What is often difficult for novice developers to think about is potential for operations to occur out of order. In the above diagram, although `t1` was `start`ed first, the scheduler might actually begin execiting `t2` before anything even starts in `t1`. This is an ordering issue because threads are not run in an expected order.

#### Atomicity Issues

Atomic, from the Greek word *atomos* meaning "indivisible" refers to a property of an operation whereby it will execute in its entirety (or not execute at all) without being interrupted by another operation.

A common way to illustrate an atomicity issue is through the `++` operator. A `++` can be mistakenly seen as an atomic operation because it only takes up one line, however, that is not actually true. A `++` clumps together 3 operations:

``` java
int previous = state;
previous = previous + 1;
state = previous;
```

Which means that it is possible for a different thread that increments the same state to interrupt the increment operation of another thread.

If we waited for 2 threads increment the state once, then we would expect the `main` thread to print out `2` in the end. However, because the `++` operation isn't atomic, the following scenario might occur:

![Race Condition Time Diagram 2]({{ site.url }}/blog/img/ots-race-condition-2.svg)

In this case, the output may well be `1`, but that doesn't even consider visibility issues. Factoring in visibility issues, you might even print out a `0` because the `main` thread reads the initial value of the state from its cache.

---

<a name="what-causes-threads-to-behave-this-way"></a>
# [#](#what-causes-threads-to-behave-this-way) WHAT CAUSES THREADS TO BEHAVE THIS WAY?

Having some basic idea of what "thread-safety" is and the problems caused by programs that are not thread-safe, I believe that there is benefit in discussing the nitty gritty details of why threads behave in this "independent" manner. There tends to be a lot of widespread use of mere analogies in order to explain why thread-safety is a problem and this in itself has caused issues on its own.

Going along the same vein as with the "messy details" of multithreading, now is a good time to also discuss some drawbacks of writing multithreaded programs:

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

Multithreading isn't a magic sauce you can simply add to make your program run faster. It requires a ground-up design approach, a careful analysis of cost-benefit, as well as an actual evaluation of the possible performance gain you can get out of multithreading. As discussed before, the costs associated with multithreading derives from the fact that they act independently. As Java Concurrency in Practice puts it, threads are like mini-programs. Your internet browser isn't going to care about what your terminal is doing as they are both independent programs. Like programs, threads, by default, don't care about what other threads are up to either.

A thread will intrinsically behave as if it were the only thread running on the entire system because this is the most useful and performant default *most* of the time. Many Java programs are relatively simple and require only one thread to run the `main(String[] args)` method.

> It is worth nothing that essentially no Java programs are actually "single-threaded" in the strictest sense of the word. The JVM always runs a few threads to perform GC, JIT optimizations, perhaps RMI and Ctrl-Break monitoring as well depending on the environment. A Java program is usually only referred to as "multithreaded" only if the program code itself is actually creating new threads.

This "single-threaded universe" assumption allows for many possible optimizations such as thread-local caching. Since the default is to behave as if other threads don't exist, a thread might cache state values recently read or mutated. Because the caching thread thinks that it is the only thread, it won't consider looking at the caches of other threads, and other threads won't do look at the caching thread either because they have their own caches as well. Threads will continue to read and modify their own cached state variables, which leads to visibility issues.

On many systems, what is referred to as "memory" or "main memory" is the "source of truth." Whatever value is stored in the machine DRAM memory is the "correct" value for whatever state is being read or written to. In order to understand why caching is necessary, it may be helpful to look at a diagram of a typical Intel CPU in relation to main memory:

![CPU]({{ site.url }}/blog/img/CPU.jpg)

The primary reason why caching is necessary is because lookups to main memory is several orders of a magnitude slower than lookups to something like a multi-level cache (L1/L2/L3). DRAM memory is slow because it is usually quite large and quite far away from the CPU. On the thread-level, state variables may be cached in either the registers or the multi-level caches, which are both small and localized close to the execution cores, meaning that lookups take significantly less time to transmit data to the execution core. Additionally, SRAM memory used in caches is physically much faster than DRAM memory used for main memory. More SRAM memory isn't used because it is expensive as fuck, $5000 USD for a single gigabyte (so literally >100 times the cost of DRAM), and increasing the physical size of the memory storage would increase the lookup time simply because data travel time increases.

<!-- TODO -->

By now, you've seen me write "(shared) state" quite a few times. As was mentioned in the previous section, it is important to note that the entire reason why thread-safety issues even exist is due to *shared states*. **In the absence of shared states, even multithreaded programs are guaranteed to be thread-safe**. If you are NOT sharing data between threads, or if there are no other threads to even share data with, no inconsistencies can be seen.

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
public class ThreadSafe {
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
