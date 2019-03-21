---
layout: post
title: "My Biggest Mistake"
date: 2019-03-20T22:24:50-07:00
---

Quick note, this is NOT clickbait.

I've been around the Bukkit server-modding community for a
while now. Not as long as some people, of course, but still
a pretty long time nevertheless.

![Bukkit Forums Member Since Feb 28, 2013]({{ site.url }}/blog/img/feb-28-2013.png)

In the 6 years I've spent posting thousands of times on
both the Bukkit Forums and the Spigot forums, I look back
and regret one singular thing about myself: being a
self-entitled brat.

# Aggressive At Best, Malicious At Worst

I would say that a large majority of the posts I've made
involved commenting on someone else's code. In many, or
even most of the threads I've posted on, I've found that
my responses tend to assume the worst of intentions.
Here's just [one example](https://bukkit.org/threads/exonrunnable-a-new-runnable.390040/#post-3251252) from late 2015:

![Mistake Exhibit 1]({{ site.url }}/blog/img/mistake-exhibit-1.png)

While I admit that even now I thought that the post to
which I was responding sounded pretentious, that does not
justify an equally aggressive response in return. For a
developer who is not experienced in writing multithreaded
code (the type of developer that tends to be commonly
found more often than not), it is understandable that they
do not understand the performance implications of Timer
as someone like myself (which isn't to say that I am an
expert myself, mind you). In no way was it necessary for me
to interject with "Oh."  and "Oh wow!" and even saying
"BIG performance penalty." Not only did this kind of
response bring me down to the level of the aforementioned
user, it detracted away from the informative aspect of my
post. It made me sound childish and juvenile, when the
value of the advice I gave should have been given greater
emphasis instead of the presentation of my opinion.

Here's a continuation of the same post:

![Mistake Exhibit 2]({{ site.url }}/blog/img/mistake-exhibit-2.png)

Again, for a novice user, it makes sense that they are
making paradigm mistakes, that is simply the nature of
learning programming. The fact that I latched on to their
"stupidity" by saying "Just... What is this? You could quite literally [...]"
rather than simply correcting their error indicates that
my criticism was not constructive by intention. It shows
that I was more concerned with commenting on the developer
rather than the code. It wasn't necessary for me to
add interjections such as "What is this?" and then
leading myself into an example that would probably take up
5 lines rather than the 2 lines that I claimed, assuming
that the same brace style was used as the author (K&R? No
clue honestly what you're supposed to call it lol).

While the rest of the post is pretty flawed, here's a
golden nugget:

![Mistake Exhibit 3]({{ site.url }}/blog/img/mistake-exhibit-3.png)

Goodness, the "WRONG WRONG WRONG WRONG WRONG WRONG WRONG"
was not necessary at all. No information of use was
communicated and it shows again that I was interested less
in the information in the first place, and that I was more
interested in deriding the "stupidity" of the author, when
again, these are rookie mistakes. It is completely
understandable to not be `final`izing your fields and
classes as a novice programmer. The fact that the author
failed to do this indicated a lack of experience rather than
ignorance or stupidity as I have portrayed him/her to be.

Lots of unnecessary information was written that would have
gone over the author's head at the end, not sure what
exactly my intentions were there. I could honestly have
just said "here's a benchmark" and then posted results
(which, as a matter of fact, I had failed to do) and then 
explained the results rather than making further pretentious
and unhelpful comments.

# And Another

The examples of this same pretentious, bratty attitude
continues even farther into the past.

[Here's another](https://bukkit.org/threads/moving-packetplayoutparticles-with-entities.373750/#post-3172379) post.

![Mistake Exhibit 4]({{ site.url }}/blog/img/mistake-exhibit-4.png)

Again, I'm at it again with the long string of repeated
words with the "NONONONONONONONONONONONONONONONOOONONONONONONONONONONONONO."

Once again, adding interjections like this is for yet
another novice mistake is completely unnecessary. Needing
to even consider using this to emphasize a point probably
indicates a lack of imagination on my part. An argument
should ideally stand on its own without needing to have
unnecessary "fluff" such as the long string of "NONONO"
in order to draw attention to it. The fact that I did not
consider this in the writing of my post again goes to
show my lack of consideration of the author's point of
view.

# The Finale

The many thousands of posts I've made number too many to
all have their place in this blog post, so I've selected
one of my most popular posts, the [minigame tutorial](https://bukkit.org/threads/make-a-minigame-plugin.168164/).

![Mistake Exhibit 5]({{ site.url }}/blog/img/mistake-exhibit-5.png)

This is honestly a completely unnecessary comment. The
fact is that this is not even a prime candidate for async
code, so I see no reason for someone to even be considering
using this in an async context. The targeted audience,
intermediate level developers, probably aren't even well
versed in the use of the scheduler anyways (although if
you are an intermediate developer and are skilled in the
use of the Bukkit scheduler, good on you). I think this was
a feeable attempt to assert my own mastery over threading
or something, but doing so made me look insecure and again
detracts from the main point of the post, which should
have been to educate intermediate-level developers on how
to take advantage of OOP in order to create a simple
minigame. It is ironic that I had to include that comment
in there when the post itself contained a number of bugs
pointed out by several users, such as [here](https://bukkit.org/threads/make-a-minigame-plugin.168164/#post-1814525),
[here](https://bukkit.org/threads/make-a-minigame-plugin.168164/page-2#post-1822616),
and [here](https://bukkit.org/threads/make-a-minigame-plugin.168164/page-2#post-1822730).
When I myself am having trouble even writing code that
compiles, others have written their thanks and support,
even after pointing out egregious errors that I have made.
When I posted comments that attack users and had aggressive
undertones, others who might not even be as skilled
developers as I was wrote insightful and friendly comments
instead.

I even had the gall to include this comment prior to
pasting the post source:

![Mistake Exhibit 6]({{ site.url }}/blog/img/mistake-exhibit-6.png)

When the code fails to compile, and the post itself doesn't
even look that good, I told others to source my post for
its *formatting*. I thought so highly of myself, so highly
of the quality of work that I posted, that I even wanted
people to credit me for such a trivial aspect of it, an
aspect that looked terrible anyways. 

# Takeaways

The many examples that I've posted paint me as a person
lacking self-awareness, brash, aggressive, and an
all-around first-class prick. While I'm not a completely
changed person yet, recognizing my toxicity has been
something of a revelation for me, and I continue to work
on actively trying to suppress my propensity for
passive-aggressiveness. These examples fail to do justice
for the amount of appalling comments that I've made, most
notably against the Sponge project, comments that I've not
yet had the opportunity to apologize for.

# Closing Words

One of the things that I've noticed was the fact that many
of my most malicious comments were well-received by people,
garnering several likes, such as in the case of the first
example. While again, the information was laid out
somewhere within the post itself, the lack of comment on
the fact that I was basically bullying the author of the
resource is something that I now find highly discomforting.

The people who have been influenced by my comments have
already been affected, and there's really nothing I can do
about it. I believe that by removing or editing out the
comments I've made, I will have destroyed and hidden 
something that actually happened, and thus those posts will
remain untouched. And while I cannot change what has
already been said, I can help prevent people from making
the same mistake as I did, the mistake of being a complete
self-entitled brat. Again, this is an issue that I continue
to deal with writing comments on the Spigot forums, and
even carefully thinking about my words will not prevent
everything from slipping through. But by sharing my
experience, I hope I can continue to improve.
