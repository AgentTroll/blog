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
@NotThreadSafe
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

This "single-threaded universe" assumption allows for many possible optimizations such as thread-local caching. Since the default is to behave as if other threads don't exist, a thread might cache state values recently read or mutated. Because the caching thread thinks that it is the only thread in existence, it won't consider looking at the caches of other threads, and other threads won't do look at the caching thread either because they have their own caches as well. Threads will continue to read and modify their own cached state variables, which leads to visibility issues. By default, The CPU assumes that its caches are the "source of truth," meaning that if a value from main memory (or RAM) is cached in its multi-level caches, then the CPU will consider the cached value as correct, even if the value in main memory could have been updated by a different thread.

In order to understand why caching is necessary, it may be helpful to look at a diagram of a typical Intel CPU in relation to main memory:

![CPU]({{ site.url }}/blog/img/CPU.jpg)

The primary reason why caching is necessary is because lookups to main memory (or the memory stored in RAM) is several orders of a magnitude slower than lookups to something like a multi-level cache (L1/L2/L3). DRAM memory is slow because it is usually quite large and quite far away from the CPU. On the thread-level, state variables may be cached in either the registers or the multi-level caches, which are both small and localized close to the execution cores, meaning that lookups take significantly less time to transmit data to the execution core. Additionally, SRAM memory used in caches is physically much faster than DRAM memory used for main memory. More SRAM memory isn't used because it is literally expensive as fuck, it costs $5000 USD for a single gigabyte (>100 times the cost per gigabyte of DRAM) and increasing the physical size of the memory storage would also increase the lookup time simply because data travel time increases.

By now, you've seen me write "(shared) state" quite a few times. As was mentioned in the previous section, it is important to note that the entire reason why thread-safety issues even exist is due to *shared states*. **In the absence of shared states, even multithreaded programs are guaranteed to be thread-safe**. If you are NOT sharing data between threads, or if there are no other threads to even share data with, no inconsistencies can be seen.

Because inevitably, a programmer would need to share data in some form or another in their multithreaded programs, CPUs must have a way to ensure that the caches between each execution unit remain coherent. There must be some way for shared states to update their value across caches, and for threads to retrieve values that might have been changed. Many people refer to ensuring shared states are up to date by talking about "cache flushes," whereby the cached state is flushed back to main memory. However, this doesn't make any sense; not only do CPUs not use main memory as a source of truth, it would also make synchronization basically prohibitively expensive because the data would need to cross the memory bus to get back into main memory. Instead, caches are usually kept coherent by policy, meaning that CPUs utilize various protocols (such as the MESIF and MOESI varients of the MESI protocol) that ensure that cached values are kept consistent.

I won't get into the nitty gritty details of how the protocols themselves work, all you need to know is that they work. The more important point is that even with cache coherency protocols in place, inadequately synchronized code may still not work correctly. Execution cores use buffers to store read/write instructions that are sent through the cache coherence protocol. CPUs may be able to use [pipelining](https://cs.stanford.edu/people/eroberts/courses/soco/projects/risc/pipelining/) to keep running instructions as they wait for load requests, for example. In some cases, a CPU may read a "store" instruction from its buffer even though a different value has been stored later on, and would therefore read a stale value. This means that we are still having the visibility problem even with the implementation of cache coherency.

Luckily, CPUs provide *fencing instructions* that insert a "barrier" in the buffer. This means that the contents of buffer up to the point where the fence is inserted needs to be processed before execution can proceed, so values that are waiting to be updated are actually updated prior to whatever the thread needs to do. This ensures that the execution core reads the most up-to-date value from another cache or from main-memory.

The Java language provides a memory model which simplifies these details into various different tools and constructs such as the `volatile` and `synchronized` keywords. It is not necessary to understand all the technical details of what a CPU ends up doing to write thread-safe code. However, by having a little bit more background on what the hardware is doing, programmers can understand the need for adequate synchronization and the significance of ensuring that multithreaded code is safe to run.

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

As previously discussed, the Java language offers many tools to help simplify the process of writing thread-safe code without needing to understand all the hardware details.

#### The `synchronized` Keyword

One such tool is the `synchronized` keyword. All classes extending `Object` (basically classes that you write or are provided by the language excluding primitive types) possess what is known as an "intrinsic lock." You can use a `synchronized` block to acquire the lock and release it when the block ends. The point of a lock is only one thread can "hold" the lock at any given time. This means that if `Thread A` already has the lock and `Thread B` arrives at the `synchronized` block, it will wait until `Thread A` is done before the lock can be acquired by `Thread B`. When more than one thread is waiting, a random thread is selected to acquire the lock once it is released. More on this later.

Consider the `MutableState` class from the previous section. We can utilize the `synchronized` keyword to ensure thread-safety like so:

``` java
@ThreadSafe
class SafeMutableState {
    private int state;

    public synchronized void mutate() { 
        this.state++; 
    }

    public synchronized int read() { 
        return this.state; 
    }
}
```

I previously mentioned that the `synchronized` "block" is used to acquire and release a lock. However, in the above code snippet, I have used it as a method modifier. What's going on? As a matter of fact, using the `synchronized` keyword as a method modifier is equivalent to the following:

``` java
@ThreadSafe
class SafeMutableState {
    private int state;

    public void mutate() { 
        synchronized (this) {
            this.state++; 
        }
    }

    public int read() { 
        synchronized (this) {
            return this.state; 
        }
    }
}
```

A `synchronized` instance method means that it will simply wrap the method code with a `synchronized (this) {}` block. This acquires the intrinsic lock of the Object belonging to that instance of the class.

But what about `static` methods? Since we don't have `this` access, which lock does the `synchronized` block acquire then? In that case, it would acquire the lock belonging to the *class object*. For example, say that there was a `static synchronized` method in `SafeMutableState`. That method would be equivalent to writing `synchronized (SafeMutableState.class) {}`.

By making the methods `synchronized`, we will ensure that only one thread can perform an increment operation at a time using the `mutate()` method. This means that the atomicity issue discussed in the earlier section, where one thread is in the middle of updating the `state` value doesn't complete before another thread reads the value prior to the increment. The `mutate()` operation is therefore *atomic* because the operation completes in its entirety before it is called again. In effect, this means that the `mutate()` method is executed sequentially since each thread must line up if they try to update the `state` value simultaneously. Having threads line up in this way is sometimes referred to as *thread serialization*, (not to be confused with data serialization) because threads are executing serially (sequentially).

However, this doesn't explain why the `read()` method is `synchronized` as well. Reading from a single field or writing to a single field (except in some cases involving the `long` and `double` types, more on this later) is atomic already, so we should have no issues, right? Actually, no, and the answer can even be "it depends." That being said, the *only* safe and definitive way to ensure that `SafeMutableState` is thread-safe is to ensure that the `read()` method is synchronized. The main reason is visibility. A `synchronized` block only guarantees that *all* state values (even those that are not modified with a lock held) that are set BEFORE acquiring the lock are visible to the thread that acquires it. That means that even though we have a `synchronized mutate()` method, that only guarantees that the thread calling the `mutate()` method can see the `state` value. Therefore, in order to guarantee that changes made to the `state` value to be visible to the `read()` method, the `read()` method itself must also be `synchronized`. However, if we recall from the earlier section, the reason why we have visibility issues is because of the store and load buffers on the CPU. Therefore, as long as we have a fence inserted somewhere in our code, then all the most recent values will be available to the CPU already, which means that if we have a `synchronized` or `volatile` somewhere that would produce this fence, then we technically don't even need the `synchronized` (we might not even need to synchronized on the same lock). Using side-effects like this is referred to as *piggybacking*. More on this later. With that, I only conclude that writing your code this way is **dangerous**, fragile, non-portable (especially on CPUs that do not have as strong guarantees about memory fences), and does not comply with the Java Language Specification. Remember, your code is either properly synchronized, or not synchronized at all. You cannot have half of your methods `synchronized`, and the other half not synchronized and expect your code to work correctly. Synchronize, and remember to synchronize on the correct locks to ensure that your code complies with the Java Memory Model.

Wherever your code is being called by multiple threads, a `synchronized` block can be used to ensure atomicity by allowing only a single thread to be executing that to ensure atomicity through thread serialization and that the state values read by that method are up to date.

One technical detail previously mentioned is that threads tend to be non-deterministic. There are many things that control thread timing and when threads run what - the OS thread scheduler and the CPU come to mind. The execution order of threads are arbitrary, and `synchronized` blocks cannot control that. When threads queue to wait for a lock, a random thread is selected when the lock becomes available again. It is possible to ensure FIFO order, but that requires a slightly different tool that I'll be covering in a few sections. That being said, `synchronized` blocks can control reorderings to some extent. The compiler and the JIT may try to reorder certain instructions that work in single-threaded code, but will produce surprising results in multithreaded code. I myself don't actually have any examples of this, but it is worth noting that the `synchronized` block cannot be reordered with other instructions outside the block as an optimization (although again, how this is an optimization I'm not exactly sure). A `synchronized` block acts as a kind of barrier for this, meaning that instructions cannot flow past the `synchronized` block; instructions before can be reordered still, but only as long as those instructions stay before the `synchronized` block. This is the same for instructions after the `synchronized` block and even instructions inside the `synchronized` block as well, so long as those instructions do not move outside of the `synchronized` block, of course. 

#### The `volatile` Keyword

The `volatile` keyword, unlike `synchronized`, is a field modifier. While `synchronized` is designed to give strong guarantees for a block of code, `volatile` gives weaker guarantees for fields. Let's take a look at how it is used:

``` java
@NotThreadSafe
class VolatileMutableState {
    private volatile int state;

    public void mutate() { 
        this.state++; 
    }

    public int read() { 
        return this.state; 
    }
}
```

In case you missed it, I'll highlight again that the above snippet is **not** thread-safe. The only purpose of `volatile` is to ensure that state mutations are visible to other threads. However, because `volatile` has no impact on atomicity, `VolatileMutableState` is not thread-safe. Although the increment operation in `mutate()` will be visible to other threads, that only assumes that another thread doesn't sneak in before the incremented value is set into the state. Remember, an increment operation is actually retrieving the state value and incrementing the local copy before updating the state. We ensure that the retrieval uses the most up-to-date value, and that other threads will see the update in the end, but visibility guarantees do not prevent another thread reading the state value before the update. In order to provide the atomicity guarantee, `synchronized` is needed because it allows for threads finish calling `mutate()` before passing off the lock to another thread.

However, if we don't need to perform any non-atomic operations like an increment (these are usually called *compound operations* because they consist of multiple components) and we only need to hold a certain value, we can change the `VolatileMutableState` to look like this:

``` java
@ThreadSafe
class VolatileStateHolder {
    private volatile int state;

    public void mutate(int newState) {
        this.state = state;
    }

    public int read() {
        return this.state;
    }
}
```

Since we have gotten rid of the atomicity issues, the class is now thread-safe. An additional guarantee that `volatile` provides is ordering, similar to how the `synchronized` keyword works. A volatile read or write acts sort of like a "fence," which means that again, operations that occur before the volatile read or write cannot be reordered to occur after it, and operations after cannot be reordered to occur before the volatile read or write. Instructions can still be reordered, so long as they stay on their side of the fence. Recalling from the earlier section, this fence also works to ensure that reads and writes are completely seen by the CPU in order to provide visibility guarantees.

However, even though `VolatileStateHolder` is thread-safe, that doesn't mean that anyone using it is safe as well. Consider the following use:

``` java
public static final VolatileStateHolder holder = new VolatileStateHolder();

...

// WARNING: NOT THREAD SAFE
int currentState = holder.read();
if (currentState == 0) {
    System.out.println("The holder's state is still 0!")
    holder.mutate(1);
}
```

Can you spot the problem?

In this case, we have moved the atomicity problem we saw in the `VolatileMutableState` into the user code. If multiple threads were running the above snippet, then it is possible for `"The holder's state is still 0!"` to be printed multiple times. Again, notice how the state is retrieved, some operation occurs, and then the state is updated again. In this case, although the final state isn't changing if multiple threads run, we still might not get the desired result. If another thread calls `holder.read()` before the another thread gets to `holder.mutate(1)`, then it will read `0` and re-run the code. In order to solve this problem, we need to synchronize:

``` java
public static final VolatileStateHolder holder = new VolatileStateHolder();

...

synchronized (holder) {
    int currentState = holder.read();
    if (currentState == 0) {
        System.out.println("The holder's state is still 0!")
        holder.mutate(1);
    }
}
```

Now, because we use a lock to prevent other threads from running the code concurrently, we have gotten rid of the atomicity problem. Although you might have written thread-safe classes, the way it is used by users may not be thread-safe.

While we are discussing the `synchronized` keyword for the moment, it is worth learning about what to actually synchronize on. In the previous section, I stated that all `Object`s have intrinsic locks. However, this doesn't mean that you should synchronize on any odd `Object` you have on hand. In general, it is a good idea to reduce the scope of your locks, and prevent outside code from accessing them. Some programming adages suggest that you should avoid the `this` lock, because anyone who constructs your object now has access to it. However, sometimes, it is necessary to allow users to access that lock. For example, synchronized collections obtained from `Collections.synchronizedXYZ(...)` require that users synchronize on the collection if they want to iterate over it. This ensures that the iteration prevents other threads from modifying the collection while you are iterating over it. Because the above example is user code, I decided to synchronize on the `holder` field, because the user would be in control of the scope of `holder`. Giving user code others access to a lock potentially could lead to someone accidentally synchronizing on it when it isn't needed, which will prevent code that actually does need the lock to wait. While this slows down the application, it could also lead to more dire problems such as deadlock. If a class is full of primitive fields or is entirely mutable and `this` is the most obvious choice for a lock, an author will usually use a `private final Object lock = new Object();` and synchronize on that instead. Again, it is important that the same lock is used in order to ensure thread serialization, so a mutable lock is generally a poor idea. It is also possible to synchronize on local variables if it is associated with an object that is shared. So long as the code accessing the shared object uses the same lock, then there should be no issue. The key here is caution and defensive programming.

Back to the topic of `volatile` and having the knowledge of how to use it, what in the world could it be used for? While it is easy to see how a general-purpose/all-around tool like `synchronized` might be used, why would anyone ever use `volatile`? We see in the previous examples that we can use it for states that have a single value set or read by non-compound operations. If we never need to check on the state before we modify the state, then `volatile` is sufficient and no synchronization is needed. Remember, because field assignment and retrieval is atomic (except for `long`s and `double`s), we can use `volatile` to ensure thread-safety by making all changes visible. This is useful for things like loops that run until someone wants the loop to stop:

``` java
public volatile boolean isActive = true;
while (isActive) {
    ...
}

// Another thread might want to stop the loop
isActive = false;
```

Another good use for `volatile` is ensuring that `long` and `double` states are atomically set. Because the Java Memory Model doesn't guarantee that assignments to those types are atomic, marking them `volatile` will ensure that writes to them are atomic (however, this is the only atomicity guaranatee that `volatile` provides for). If you are worried about atomicity in the first place, you probably already need the state values to be visible anyways. Therefore, the fact that `volatile` assignment to `long` and `double` states is also atomic is just a nice side-effect in reality.

One niche use of `volatile` is for single-writer thread models. This means that only one thread does mutations, while all other threads simply read the state. So, while `VolatileMutableState` is not actually thread-safe for multiple mutator threads, if we impose a policy that allows only one thread to ever call `mutate()`, then we have solved the atomicity problem. No other threads can possibly interfere with the increment. We have an external policy that ensures atomicity and we use `volatile` to ensure visibility and ordering. Therefore, the threading model you use can allow you to use non thread-safe classes in a way that is nonetheless thread-safe.

`// TODO`

