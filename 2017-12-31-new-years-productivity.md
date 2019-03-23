---
layout: post
title: "New Years: Productivity"
date: 2017-12-31T00:00:00-07:00
---

Perhaps we can take some time to look at productivity, in spirit of the (Eve of) New Year.

Probably the most ironic thing about productivity is that discussing productivity is unproductive in itself. Sure, it’s great food for thought, but at the same time, let us consider that 1) you will read this and do nothing about it and 2) productivity is subjective. In fact, #1 probably isn’t even your fault; maybe you’ve already fixed whatever issue arose from that facet of productivity, or maybe it doesn’t even apply to you. I’m not saying that you aren’t lazy and stubborn, because you probably are as well. At least something might occur to you that has not before even if you won’t do anything about your own productivity after reading.

# What Does It Mean to Be Productive?

In my view, there are two main types of productivity: problem-solving productivity and programming productivity. The former deals with solving problems and working out bugs, while the latter deals with literally writing out code more quickly. There’s a lot of overlap in terms of “working on a computer” in general, but for the most part, I will be touching on the latter form of productivity. The issue with dealing with the former is that problem-solving is almost purely mental gymnastics; some people “are just better” at solving problems than other people.

I mean, in actuality, I don’t even know that much about productivity, I’m simply distributing my opinion based on my experience. So although I can’t help you in the solving-problems area, I’m sure it’s not the end of the line for you.

There’s lots of debate on who might be a better programmer, the one who is good at problem solving, or the fast programmer. In an ideal world, you’d want someone to be strong in both areas, but there is a sort of division of labor between debuggers and programmers respectively in some cases. While I think that it is an interesting point of discussion, it’s out of scope of what will be covered here.

To further elaborate on our topic of discussion, being “productive” in context means that you are able to edit code efficiently. You are able to put your ideas “onto paper” or out of your head and into an editor quickly. Assuming that you have the problem solved yourself, you’re able to “take action,” that is, you are not simply sitting at your chair staring at your code when you have your ideas down already.

Keep in mind that productivity also depends on the person: there are lots of things (i.e. colors) that are based on preferences, and almost nothing is based on hard data or science. The idea behind productivity is to find what works for *you*. I’m simply here to offer my own preferences and use myself as an example to what facets of productivity might be improved if things were different.

Without further ado…

# Touch-typing

The ultimate limit to how quickly you can write code is your typing speed. You cannot get faster at actually writing code if you can’t type very quickly. While autocomplete is a godsend to those who cannot type as quickly, it still pays to type more quickly and get what little you are typing in the first place done quickly. There are numerous online programs and websites that can help a slow typist, whether it be 10fastfingers or keybr or others. It also helps to type special symbols, such as in Java: `(){}"\^&*+-` and others.

# Monitor Size
There’s also lots of debate on the best size of monitor, the best multi-monitor setup, etc…

However, there is a lot of data that support the idea that humans are terrible multitaskers. The thing is that if you want to write code faster, you must be in your editor as much as possible, that means no browser open with the docs, your StackOverflow question, your GitHub milestone, whatever. If you work sequentially, as in you exclusively process what you have to do, then exclusively work on writing code, and then switching as necessary, you will find that you will be able to work much more quickly than if you looked through, say, the StackOverflow question as you forget key details while within your editor.

That also means that your monitor, and by extension, your **total screen estate** should be kept ot a minimum, while not being too small as to make it difficult or to require effort to read whatever you have written. The way I see it: toss your 2 additional monitors and settle with a single-monitor setup.

Again, for me personally, the best monitor size is around a 24” (a little over 60 cm) diagonal on a 16:10. This way, I can fit a substantial amount of text and therefore be able to navigate more efficiently across larger distances, but at the same time, I do not need to change where I am looking at in order to see the edges of the screen. And yet again, this is not an exact science, but try to look for a monitor that is just large enough for your peripheral vision to process what is at the edge of your screen. If you are completely torn between two screen sizes, I’d go with the smaller screen, because over the long term, you will be focused on what you write anyways rather than anything surrounding it.

To continue adding on to the focus idea, I would also recommend turning off music, at least why you are programming. There are some people who are unsettled by silence, but the fact that you are noticing silence or conversely, the music itself, means that you are not completley focused on the programming task. You probably won’t get rid of your music, and again, I don’t have any hard data to back me up on productivity with or without background noise, but going off the focus logic, it makes more sense to work in silence. Perhaps console yourself with the continous sound from your 100 decibel mechanical keyboard otherwise (just kidding, I do not condone replacing your keyboard with a jet engine).

# Font

The code you write is literally written in the font that you are using, so it pays to use a font that is comfortable to the eye. There are tons and tons of good fonts out there, some meticulously designed, others based more on stylistic preference. I personally use a lot of Monaco, but many people use a less playful font like Menlo or a very blocky monospace. Whatever it is, you should have no trouble reading large amounts of text written in your selected font. You should avoid fonts that are too small or have poor balance although again, preference trumps pretty much everything so just be sure to get yourself a good font.

# Editor

Another productivity-booster is the editor that you use. For me, I use a combination of IntelliJ IDEA/IdeaViM and ViM. What made the difference was that Eclipse was too slow and its auto-completion was nowhere close to IDEA’s in terms of speed or intelligence. IntelliJ actually shows me that over a 3 month period, I had saved 100K characters from being typed, which is an astounding amount of time saved through auto-complete. Again, I’m not saying that you should switch editors, but that is by far one of the most effective productivity-booster for me.

Secondly, ViM and counterparts, the whole idea of avoiding using your mouse is also very effective once you become used to the different mode of navigation. The fact is that using your mouse requires a very precise movement in comparison with the more granular keyboard-based movement that ViM is capable of. To add on to that, you must also remove one hand from the keyboard in order to move the mouse, and then place your hand again on the keyboard, and enough of these actions will eventually add up to a significant amount of time that could be saved remaining in the home position. Although it had/has a steep learning curve for me personally, I think that using IdeaViM has saved me on the magnitude of hours in the past few months from reaching for the mouse. I use ViM for most of my text-editing nowadays and the way I see it, “text-editing has never been better.”

The one thing I have against ViM is that its support for Java is practically non-existant **relative** at least to IntelliJ IDEA. The code completion is not as good and lacking IntelliSense and the more advanced features such as viewing documentation, library source code, Git/Maven wrappers, etc… will kill productivity. Instead of bringing Java to ViM, bring ViM to Java as said somewhere on the Internet.

# Colors

The color palette is also important for productivity. By using a more preferable palette, you will reduce your overall fatigue and increase your endurance for writing code efficiently. Avoid using a harsh, very light, flashy color palette. Many, many developers tend to prefer a high-contrast dark theme for their editors and environment backgrounds, because it makes the text both easy to read and easy on the eyes. These can be found on Google, along with other common “dark” themes such as Solarized. I use a slightly modified Google Code syntax on a grey background, although the contrast is exceedingly poor, it’s just that I haven’t found time to change it in the past, oh, 3 years. You probably won’t change your background either, so I don’t feel exceedingly bad about it myself.

I say contrast is important because although it serves to detriment the general “easy-on-the-eyes” gospel, it will make it much easier to actually see the text. Over time, it’s more typical for eye strain to occur on text that is difficult to see than text that is “a harsh color.” Further, people using programs such as f.lux and redshift will have a difficult time reading the text if there is little contrast, which becomes more compounded as the color temperature decreases.

# Breaks

Sitting at a computer and programming in itself is physically and mentally taxing. It is an absolute necessity to completely stop and take a break once in a while, no matter how close you are to “solving that one bug.” Looking a monitor for extended periods of times is strenuous on the eyes, poor for the back, and wreaks havoc on your hands and shoulders. You must also remain hydrated and satiated, and on top of that, you cannot solve problems effectively while at the same time being distracted by what is on your computer screen. Not only can you improve your productivity but having a self-check once in a while, but you will also become a better problem-solver if you do not continue to attack a problem in the same way you have the past 3 hours you have been sitting in an office chair.

Stand up, stretch, drink some water, give your eyes a break, give your mind some time to relax. Over time, you will lose focus anyways, and giving yourself a break and continue to do something productive and healthy for your body is the absolute least that you can do rather than suffer from over-exerting yourself. I personally take a break whenever I feel the need to go use the restroom, and I immediately drink another cup of water so that I would be guaranteed to need to take a break in the future. What works for a lot of people, not just for software engineers but also students and other places that require long periods of focus is to take a 10-15 minute break every hour.

Indeed, it may seem like a loss and counterproductive - exactly what we are fighting here - but trust me when I say that breaks are necessary to be productive. The hardest part about taking breaks is making sure you get back after treating yourself a bit. If you can at least keep yourself disciplined, then it should be no problem, incorporating breaks into your schedule should slowly, but surely improve your productivity.

# Final Word
I’m sure there are many other factors that I’ve missed which could be vital to productivity, and I acknowledge that “programming productivity” isn’t the entire story. However, with the above noted thoughts on how I improved my own productivity over the years, perhaps the reader might at least have some background on how (yet another) developer works.