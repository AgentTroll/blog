---
layout: post
title: "JDB, But Not That One"
date: 2018-05-11T23:44:35-07:00
---

# But Also, Some Background

I've been working on a school project for my CS Projects class for the past few months. Just a few days ago, I had a great opportunity to actually present it to a school staff meeting. I had mixed feelings about the overall success of my presentation, so instead of working on improving my prepardness for presentations that I might have later, I decided to write a rather unfaithful transcript of it here. I don't fault the staff for being primarily non-technical, but I definitely would have enjoyed presenting to a more seasoned audience in the future.

But enough with my lamenting. Back in September, I had to make a decision on what kind of project I would work on for the rest of the year. Actually, I finished the project last month, so perhaps the rest of the year minus two months. I would have wanted to work on TridentSDK, but that wouldn't have been very good material to present. There's a ton of notable acheivements in TridentSDK that would be difficult to explain relative to an actual Minecraft server, so that got scrapped. My second-choice would be a debugger. I often used the IntelliJ IDEA debugger to work on TridentSDK, so I mean, why not? It really counldn't be that difficult, can it? As it turns out, it really wasn't *that* difficult. I did deal with some interesting bugs, and developing it was difficult at times, but there wasn't anything that I didn't already know, save for the intricacies of the JDI.

By the end of my time developing JDB, I got really lazy and put off working on it a lot. It felt really complete after I solved [the bug involving printing out multiple return values for the same variable](https://github.com/caojohnny/jdb/commit/48483f6211cb5e67f81133b6a050dbc3151ad495). Thanks, laziness. [This was the real planning document](https://github.com/caojohnny/jdb/blob/master/jdb.md) for JDB in the first place. As a matter of fact, I had no clue that there was [already a project](https://docs.oracle.com/javase/7/docs/technotes/tools/windows/jdb.html) in its namesake, but I haven't been aware of it. That's not the real takeaway from planning though, the real takeaway is that I was really ambitious at the start, but ended up with a lot simpler of a program than I had envisioned. In fact, when I took a look at it a few days ago, when I was making my presentation, I realized I basically got to none of the features in the Goals section. Thanks, laziness. Nevertheless, I still think I ended up with a very nifty program that did a lot more than I thought I could do. 

# Slides

As a small side note, Pages sucked for converting slides to images. I used https://www.freepdfconvert.com/pdf-jpg. A few images that I got off the internet got removed from slides 2-3, I was too lazy to cite them and they didn't have anything very useful anyways.

> I've quoted approximately what I said

I'll put some more stuff down below it or what I should have added.

![Slide 1]({{ site.url }}/blog/img/jdb.odp.jpg)

> Hi, I'm Johnny, I've been working on a debugger for the past year. If you don't know what a debugger is, don't worry. I'll get to that in the next slide.

![Slide 2]({{ site.url }}/blog/img/jdb.odp-2.jpg)

> So what exactly is a debugger? What is debugging? What even is a bug in the first place? So a bug is basically an error; it's a mistake made by the programmer when he is writing code. A bug is a glitch, and anomaly, or oversight that results in the program not working correctly. All programs contain bugs. Bugs aren't good. When you're writing software, you don't want bugs. One of the tools that you might use to get rid of bugs (these errors in your code) is by using a debugger. So when a program runs, what the programmer sees on his screen, all the computer code, all of that becomes invisible. You can't see what a program is doing when it runs, you can only see how it affects what the user sees. A debugger helps remove bugs because flaws in the code require you to see the state of the program, and when there is an error, there will be an inconsistency in the program's state.

![Slide 3]({{ site.url }}/blog/img/jdb.odp-3.jpg)

> Now that we have that out of the way, what was I even thinking in the first place, why did I want to create a debugger? I work a lot in the backend, which is basically the behind-the-scenes role of writing software. I write infrastructure, so other people depend on me being right so that everything works. If my programs don't work, everything comes crashing down with it. This was a big inspiration for me because a debugger would give a helping hand in removing bugs and errors from my program. Secondly, many debuggers are included in your text editor, called an IDE. So your debugger is often something that has buttons and stuff, that you click on. What I was looking for was a *CLI*-based debugger, and a CLI is basically a big panel that doesn't have buttons or anything on it, you have to type commands into it for it to do anything. So think of hacker movies and you see some guy typing away at his computer and a bunch of garbage text comes up on the screen and it magically does something - that was what I was looking for, to be able to use commands to control the debugger instead of clicking buttons. This just makes it more efficient to work with than having to move a mouse. Finally, I mean, why not? I needed a project to work on, why not make a debugger?

I had to spend a lot of time here trying to explain basic programming concepts like an IDE and a CLI. I would have liked more time getting into the actual meat of JDB in the first place, but alas, I had to spend my time explaining this to my audience! 

![Slide 4]({{ site.url }}/blog/img/jdb.odp-4.jpg)

> So to demonstrate what my debugger does, I'm going to use it to reverse engineer something, and that something will be a Minecraft server. Now, I chose the Minecraft server becuse it's relatively simple to understand the function of it at its core, and it will really help me explain some of what it does. So what you see here is a function that gets run whenever the server stops, and you will also see a null-check that I have boxed near the bottom of your screen. What this does is it checks the value of the variable. When programming, you want to make sure that your values are initialized, that is that there is *something* at that variable. Sometimes, the variable is null and void; there is nothing stored there. So to demonstrate how my debugger works, what I want to find out is when the server shuts down, is there a value at all at the `v` variable. We know that it is a player list, and I can deduce that it stores players somehow. But what I want to know is even if players don't join the server, will there the `v` variable still be null, void, and have no value, or will there be *something* at that variable when the server shutsdown?

Now admittedly, reverse engineering wasn't a great demonstration of the debugger. My presentation focused very much on explaining the reverse engineering concepts that could have demonstrated better what my debugger does if I had used simple scenarios instead. But alas, I was also inspired to make the debugger because I had a hard time with getting a regular debugger connected to the Minecraft server to debug my plugins. It would also be great if I could demonstrate that JDB works outside of my own custom scenario programs and with other programs as well, but I'm not sure if my audience would have understood the significance of that for me, since I've only ever used the regular IntelliJ IDEA debugger to test code thath it runs intead. I also find it hard to believe that anyone followed along with the "null and void" idea of a value, but that should be expected at this point.

![Slide 5]({{ site.url }}/blog/img/jdb.odp-5.jpg)

> So what I'm doing here is trying to find the line number on which there is this check for the value of `v`. So basically how debuggers work is, as a I said earlier, to stop and halt the program at specific points in the code. So as the code gets read by the computer, as it moves through each line of code, I want to stop the program right before that check and read the value at the `v` variable. This is called a breakpoint, the place where you want the program to just halt for a sec so you can look at the program state. So here, in order to find the line number to put the breakpoint on, I will have to look for where that if check is. I've boxed it at #1 in the bottom left corner of the screen, you can see the ifnull check if you are close enough to the screen. You also might see that there are two other if checks, but I know that instruction #78 is the right one because in the code from the previous slide (scroll back one slide) you can see that there are 3 if checks here, and (scroll to slide #5) and there are 2 if checks above this one and the variable appears here where you can see the method being called where I have underlined by the bottom right. What I've decided to do is actually to pick the instruction at #38, labelled by the #2 box at the top left corner of the screen. This is because in order for the breakpoint to work, I must guarantee that the code is run in the first place, and if I accidentally put it in betwen the if checks, my breakpoint may not run. You can see on the line number table that #32 is located on line 482.

This was an extremely strenuous slide for me because I needed explain all these different concepts like breakpoints and the basic ideas of machine code to laymen.

![Slide 6]({{ site.url }}/blog/img/jdb.odp-6.jpg)

> Here I am going to start the debugger and you can see me using `ba` which means put a breakpoint after line 482 in MinecraftServer.

At this point, my advisor has reminded me that I have 30 seconds left of presentation time. What I should have done was explain also the selection at the bottom and how I select from duplicate class names.

![Slide 7]({{ site.url }}/blog/img/jdb.odp-7.jpg)

> As it turns out, I get an error from the program stopping. This is ironic because there's a bug in my program that I made to get rid of bugs (chuckles)

![Slide 8]({{ site.url }}/blog/img/jdb.odp-8.jpg)

> So, what happened? If you can see here, in my code, I am checking for a 0 and leaving the code. On the previous slide, you can see that 0 is an option, and the no option should be -1. Let's change this to -1 and see what happens.

As I'm under time constraint, I'm unable to explain what the if and the comparison constructs mean.

![Slide 9]({{ site.url }}/blog/img/jdb.odp-9.jpg)

> Alright, so we can put a breakpoint in there, that's good! No errors this time, what happens then, when I stop the server?

Here, I should have reminded my audience of what a breakpoint is and the meaning of what I'm doing, but alas, I was already cutting into meeting time after my presentation.

![Slide 10]({{ site.url }}/blog/img/jdb.odp-10.jpg)

> I can then inspect all the variables in the state of my program, and you can see at the bottom that I've highlighted the value that is located at the `v` variable and it is not null. So what I've found is that even when there are no players in the first place, that there will be a value there.

The value at `v` is present even if there are no players on the server. This is significant because out of this, I've learned that the MinecraftServer initializes this variable without any players on, when it starts off as null by default. Secondly, it is a type of DedicatedPlayerList, which is a type that tells me a lot about how the `v` variable gets handled by the server.

![Slide 11]({{ site.url }}/blog/img/jdb.odp-11.jpg)

> So what exactly did I learn? So I learned a new API, which is a... (pause)
>
> I learned JDI, which is an API, which is in turn something that programmers use to write their apps faster, when I wasn't really familiar with it before. In fact, the rest of this is garbage, it doesn't mean anything to you guys (chuckles). Along the way I also ran into a bunch of issues, such as the one that I just showed you with the off-by-one thing that I fixed by switching the code to -1. I also uh (pause)
>
> I also got a bunch of output whenever I looked through the program state because the console had duplicate entries in it, so I could hardly read the log. This got fixed so I can actually read the console.

At this point, I was already 2 minutes over time and I needed to get done, but my brain was letting me down. I had two long pauses to stop and reconsider, but in my own defense, the API learning part was rather difficult to explain, and it is hard to quantify how difficult it is to work with a spammy console.

![Slide 12]({{ site.url }}/blog/img/jdb.odp-12.jpg)

> Thank you!

Right here, I should probably have talked a little bit more of my project, my project's goals document and the development of it, but again, I'm out of time. I was really ready to present the GitHub it to others, but that will have to wait. Besides, who even cares about GitHub when it's not even that useful to the audience anyways.

# Conclusion

Looking back on it, I would have certainly enjoyed presenting more if I had a more technical audience, and a larger time constraint. The whole presentation took actually about 10 minutes, and if I had more time, I would have gone a lot more in depth. The staff was not an enjoyable audience to speak to for me at least. I'm sure there are certain teachers who were interested in what I was talking about, but even they probably had trouble following what I was talking about. For the teachers themselves, they probably felt like their morning was wasted by what I thought was interesting but was pretty much useless to them. They aren't interested in it, and they have a job to do. Yes, yes, teachers should care about students. But if I was a teacher, I would not have given a single damn about this computer science voodoo magic stuff, I have a staff meeting for crying out loud! I think debugging is an interesting art and science, but if I had more time, I would **definitely** go more in depth with reverse engineering. I think that it is such an interesting thing to do, with not only the mystery of solving problems, but going deeper and deeper with our understanding of a code base, especially one that was meant to be challenging to read such as the Minecraft server has a certain thrill to it. 

You know what else has a certain thrill to it though? Being done with reading this blog post. Until next time.

# Words of Wisdom

I found a piece of gold today in a compilation video:

> It's 2017, I mean we should have a lunar base by now... What the hell is going on?
> - Elon Musk

I think I'm going to start pasting this around like the gospel...
