---
layout: post
title: "What The Fuck Does Guice 'zip file closed' Exception Mean?"
date: 2019-07-18T01:00:15-07:00
---

I've had a lot of time to work with [Guice](https://github.com/google/guice)
when I worked with Skytropia. However, working on a
personal project with more up-to-date versions of Spigot
and Guice, I was met with the strangest possible exception.
But what does it mean? Honestly, I haven't quite figured it
all out myself either.

That being said, the "solution" is deceptively simple and
if you're just here for that, scroll down and skip the
introductory fluff.

# The Setup

Obviously, it would be out of place if I didn't show what
I'm running. Here's the Java/OS info:

```
System Info: Java 11 (OpenJDK 64-Bit Server VM 11.0.3+7) Host:  Linux 4.19.0-5-amd64 (amd64)
```

Now here's the server info:

```
[01:05:37 INFO]: This server is running Paper version git-Paper-133 (MC: 1.14.3) (Implementing API version 1.14.3-R0.1-SNAPSHOT)
[01:05:37 INFO]: Previous version: git-Paper-123 (MC: 1.14.3)
[01:05:37 INFO]: You are 1 version(s) behind
```

And this is my dependencies `pom.xml`:

``` xml
<dependency>
    <groupId>com.google.inject</groupId>
    <artifactId>guice</artifactId>
    <version>4.2.2</version>
    <scope>compile</scope>
    <exclusions>
        <exclusion>
            <groupId>com.google.guava</groupId>
            <artifactId>guava</artifactId>
        </exclusion>
    </exclusions>
</dependency>

<dependency>
    <groupId>com.google.inject.extensions</groupId>
    <artifactId>guice-assistedinject</artifactId>
    <version>4.2.2</version>
    <scope>compile</scope>
</dependency>
```

I am using relocations to move `com.google.inject` to a
different package. It is worth noting that you can get an
equally strange error if you shade Guice in the same
namespace, but that applies to all plugins (and the server
namespace as well, which is why you should NEVER shade
database drivers in a plugin, relocation doesn't work). The
error will obviously look a little bit different, but if I
recall, it should be an `IllegalAccessException` or
something similar. That being said, this post is **not**
on that topic.

# The Error

Now onto the error. This is what I have been tearing my
hair over the last hour:

```
> 2019-07-18 00:30:34,444 Log4j2-TF-1-AsyncLogger[AsyncContext@70dea4e]-1 ERROR An exception occurred processing Appender File com.google.common.util.concurrent.UncheckedExecutionException: java.lang.IllegalStateException: zip file closed
        at com.google.common.cache.LocalCache$Segment.get(LocalCache.java:2217)
        at com.google.common.cache.LocalCache.get(LocalCache.java:4154)
        at com.google.common.cache.LocalCache.getOrLoad(LocalCache.java:4158)
        at com.google.common.cache.LocalCache$LocalLoadingCache.get(LocalCache.java:5147)
        at com.google.common.cache.LocalCache$LocalLoadingCache.getUnchecked(LocalCache.java:5153)
        at com.google.inject.internal.util.StackTraceElements.forMember(StackTraceElements.java:71)
        at com.google.inject.internal.Messages.formatParameter(Messages.java:286)
        at com.google.inject.internal.Messages.formatInjectionPoint(Messages.java:273)
        at com.google.inject.internal.Messages.formatSource(Messages.java:229)
        at com.google.inject.internal.Messages.formatSource(Messages.java:220)
        at com.google.inject.internal.Messages.formatMessages(Messages.java:90)
        at com.google.inject.ConfigurationException.getMessage(ConfigurationException.java:73)
        at org.apache.logging.log4j.core.impl.ThrowableProxy.<init>(ThrowableProxy.java:134)
        at org.apache.logging.log4j.core.impl.ThrowableProxy.<init>(ThrowableProxy.java:122)
        at org.apache.logging.log4j.core.async.RingBufferLogEvent.getThrownProxy(RingBufferLogEvent.java:330)
        at org.apache.logging.log4j.core.pattern.ExtendedThrowablePatternConverter.format(ExtendedThrowablePatternConverter.java:61)
        at org.apache.logging.log4j.core.pattern.PatternFormatter.format(PatternFormatter.java:38)
        at org.apache.logging.log4j.core.layout.PatternLayout$PatternSelectorSerializer.toSerializable(PatternLayout.java:455)
        at org.apache.logging.log4j.core.layout.PatternLayout.toText(PatternLayout.java:232)
        at org.apache.logging.log4j.core.layout.PatternLayout.encode(PatternLayout.java:217)
        at org.apache.logging.log4j.core.layout.PatternLayout.encode(PatternLayout.java:57)
        at org.apache.logging.log4j.core.appender.AbstractOutputStreamAppender.directEncodeEvent(AbstractOutputStreamAppender.java:177)
        at org.apache.logging.log4j.core.appender.AbstractOutputStreamAppender.tryAppend(AbstractOutputStreamAppender.java:170)
        at org.apache.logging.log4j.core.appender.AbstractOutputStreamAppender.append(AbstractOutputStreamAppender.java:161)
        at org.apache.logging.log4j.core.appender.RollingRandomAccessFileAppender.append(RollingRandomAccessFileAppender.java:218)
        at org.apache.logging.log4j.core.config.AppenderControl.tryCallAppender(AppenderControl.java:156)
        at org.apache.logging.log4j.core.config.AppenderControl.callAppender0(AppenderControl.java:129)
        at org.apache.logging.log4j.core.config.AppenderControl.callAppenderPreventRecursion(AppenderControl.java:120)
        at org.apache.logging.log4j.core.config.AppenderControl.callAppender(AppenderControl.java:84)
        at org.apache.logging.log4j.core.config.LoggerConfig.callAppenders(LoggerConfig.java:448)
        at org.apache.logging.log4j.core.config.LoggerConfig.processLogEvent(LoggerConfig.java:433)
        at org.apache.logging.log4j.core.config.LoggerConfig.log(LoggerConfig.java:417)
        at org.apache.logging.log4j.core.config.AwaitCompletionReliabilityStrategy.log(AwaitCompletionReliabilityStrategy.java:79)
        at org.apache.logging.log4j.core.async.AsyncLogger.actualAsyncLog(AsyncLogger.java:337)
        at org.apache.logging.log4j.core.async.RingBufferLogEvent.execute(RingBufferLogEvent.java:161)
        at org.apache.logging.log4j.core.async.RingBufferLogEventHandler.onEvent(RingBufferLogEventHandler.java:45)
        at org.apache.logging.log4j.core.async.RingBufferLogEventHandler.onEvent(RingBufferLogEventHandler.java:29)
        at com.lmax.disruptor.BatchEventProcessor.processEvents(BatchEventProcessor.java:168)
        at com.lmax.disruptor.BatchEventProcessor.run(BatchEventProcessor.java:125)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
        at java.lang.Thread.run(Thread.java:748)
Caused by: java.lang.IllegalStateException: zip file closed
        at java.util.zip.ZipFile.ensureOpen(ZipFile.java:686)
        at java.util.zip.ZipFile.getEntry(ZipFile.java:315)
        at java.util.jar.JarFile.getEntry(JarFile.java:240)
        at java.util.jar.JarFile.getJarEntry(JarFile.java:223)
        at org.bukkit.plugin.java.PluginClassLoader.findClass(PluginClassLoader.java:101)
        at org.bukkit.plugin.java.PluginClassLoader.findClass(PluginClassLoader.java:85)
        at java.lang.ClassLoader.loadClass(ClassLoader.java:424)
        at java.lang.ClassLoader.loadClass(ClassLoader.java:357)
        at com.google.inject.internal.util.StackTraceElements$1.load(StackTraceElements.java:49)
        at com.google.inject.internal.util.StackTraceElements$1.load(StackTraceElements.java:45)
        at com.google.common.cache.LocalCache$LoadingValueReference.loadFuture(LocalCache.java:3716)
        at com.google.common.cache.LocalCache$Segment.loadSync(LocalCache.java:2424)
        at com.google.common.cache.LocalCache$Segment.lockedGetOrLoad(LocalCache.java:2298)
        at com.google.common.cache.LocalCache$Segment.get(LocalCache.java:2211)
        ... 41 more
```

My reaction was immediate. What. The. Fuck.

What is this supposed to even mean? None of this makes any
sense. Why is Guice even in this stacktrace? Where does the
stacktrace even come from? How is the logger looping back
to Guice in the first place? I mean from the looks of it,
it kinda looked like it had something to do with logging,
but there are several things out of place here - it deals
with the class loader, and Guice had something to do with
it. So obviously, the knee-jerk reaction was incorrect.
(I `rm -fR logs/` anyways for good measure, but no dice).

So how am I supposed to fix it?

# Let's Google It

I was actually unable to find anything about this specific
exception. The only thing I could find were questions like
[these](https://stackoverflow.com/q/50693221/3308999) where
they were having issues with the Java version, but that
can't be right because the exceptions don't match up first
of all, and second, I know for a fact that Java 11 works
completely fine since I've used Guice in the past on Java
11 platforms. Finally, I know that assisted inject isn't
the issue either because I literally commented it out in
the `pom.xml` and made the necessary deletions without
effect.

[This](https://stackoverflow.com/q/54174855/3308999) also
came up, but this is another lifeless StackOverflow post
with no answers to it.

# Debugging

Since I know that Guice is part of the problem, I decided
to comment out all the initialization it is doing, from
creating the injector to the usages of
`Injector#getInstance(...)`. Since I was using a newer
Guice version, perhaps simply having the classes in the JAR
or perhaps the relocation could be messing with something?
The answer was no, the exception didn't come up with simply
the files in the JAR. This means that when I'm initializing
something, obviously there was something wrong with either
the way I'm configuring or my constructors, or something
along those lines.

I uncommented `Guice#createInjector(...)` and ran again
with no exception. Good, configuration should probably be
fine as-is unless I forgot something, but I'll have to
start uncommenting the usages of
`Injector#getInstance(...)` to know for sure. As I
uncommented those lines, I finally hit an exception, but
it wasn't the big long meaningless one I pasted above, it
was a readable Guice configuration exception. As it turns
out, I failed to configure a binding for `Plugin`, which I
used in place of the actual main class. However, using
`Plugin` in the first place was a mistake. The particular
class I was working with belonged specifically to the
project and wasn't a utility or anything, so it was
supposed to use the main class rather than a generic
`Plugin`. Since I already had my plugin module correctly
configured, I simply fixed the constructor to take the main
class instead. Ta da, no more exception. In the end, it
turns out that by fixing that configuration exception, the
big meaningless one also went away as well.

# Conclusion

In the end, my best guess is that there is an issue with
loading the classes that are contained in the exception
trace, which led to the large spaghetti exception that I
pasted to be printed out. An exception caused by printing
an exception. I'm not sure why the underlying exception
that I solved was printed in plaintext when I suddenly
commented out a few lines, but by fixing the actual error,
it won't be thrown, and therefore the pasted exception
won't be thrown either. I'm not sure why this even occurs
in the first place, what the problem is with exceptions
that require class loading and such. Perhaps it is needed
to find line numbers or something to display more
debugging information? Perhaps because it ends up having
to resolve classes through `PluginClassLoader`, and the JAR
file has already been read, it can't read from the closed
JAR stream? I honestly can only speculate. That being said,
it is ironic that something which may have originally been
intended to expedite the debugging process actually
hindered it in this case. Go figure.

I'm working on getting the project out as soon as I can.
This is simply a quick post I decided to write in case
anyone else also runs into this issue.

# Quick update 2019-07-21 23:47

I figured out that it has something to do with unchecked
exceptions being thrown; if you wrap all of your code
that uses `Injector#getInstance(...)` with a try-catch
block and print with `Exception#printStackTrace()` instead,
you can print the actual exception. Since
`#getInstance(...)` should only be used in a few entry
points, it should be relatively straightforward (if it
is being used literally everywhere, you've probably missed
the point of Guice...).

