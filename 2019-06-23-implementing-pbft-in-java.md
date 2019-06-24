---
layout: post
title: "Implementing PBFT in Java"
date: 2019-06-23T17:23:35-07:00
---

Following up with my [previous post]() about one of my 
prior projects, I have another post about yet another
project that I've recently finished, 
[`pbft-java`](https://github.com/AgentTroll/pbft-java).

# What is PBFT?

PBFT stands for Practical Byzantine Fault Tolerance. PBFT
is an algorithm developed by Miguel Castro and Barbara
Liskov that allows replicated systems to tolerate what are
called Byzantine faults. Since some readers don't know what
a Byzantine fault is, here is what Wikipedia has to say:

> A Byzantine fault [...] is a condition of a computer 
system, particularly distributed computing systems, where 
components may fail and there is imperfect information on 
whether a component has failed. The term takes its name 
from an allegory, the "Byzantine Generals Problem"

The Wikipedia page on the 
["Two Generals' Problem"](https://en.wikipedia.org/wiki/Two_Generals%27_Problem)
has a good description of what the Byzantine General's
Problem is, but the general gist is that a consensus has
to be made upon a decision or computation where one of the
parties involved may be compromised, may be malicious, or
could be faulty. When applied to computing systems, a set
of replica computers will need to decide on the correct
course of action even though other computers may send 
erroneous data or not even send any data at all.

The PBFT algorithm is described by the paper authored by
Castro and Liskov, which can be read
[here](http://pmg.csail.mit.edu/papers/osdi99.pdf).

# Client Implementation

I personally used a multitude of different sources when
developing this project as an abstraction to the PBFT 
algorithm, and even then, I am still confused on whether or
not I even got everything down correctly.

For simplicity, I will refer to the configured fault 
tolerance to be `f` as in the PBFT paper, the number of
replicas that can have Byzantine faults while still 
allowing a safe consensus to be reached.

The client implementation is very, very simple. Only two
messages need to be implemented, the sending and receiving
capability for one and the other, and the timeout. 

Requests are identified by their timestamp value, which 
count up from 0 instead of using the actual system clock 
since it is possible to send more than one message during 
the time it takes for `System#currentTimeMillis()` to 
update its value.

Once a REQUEST is sent to what is believed to be the 
primary, users will call the `Client#checkTimeout()` method
in a loop, which will check to make sure that a REPLY is 
received within the configured timeout. If it isn't, then a
REQUEST is then multicasted to all replicas.

The client continuously waits for a REPLY message from 
replicas. As soon as it receives the `f + 1`th REPLY 
message that matches a stored REPLY, then the result is
accepted and the timer is stopped.

# Replica Implementation

Replicas are vastly more complicated and have tons of 
moving parts that need to be considered for each message.

In short, what a replica does is wait for REQUEST messages
and then go through a process to ensure that all other 
replicas also agree to go through the same process. Then,
it will send a REPLY message with the computed result. If
the replica waits for too long, it will try to vote out the
primary with a VIEW-CHANGE message in hopes of getting 
things going again.

#### Receiving REQUEST

If the replica already has already responded to a REQUEST
with the same client ID and the same timestamp, then it
means that the operation has already completed and it will
simply resend the cached REPLY for that operation.

When a replica receives a REQUEST message that it didn't
know about before, it will start a timer that will ensure
that things keep moving. If the replica isn't the primary,
then it simply redirects the message to the primary 
instead.

If the replica is a primary, then it will ensure that the
message shouldn't be bufferred. If the number of requests
currently being handled is greater than the configured 
buffer limit, the primary puts it into a FIFO queue to be
executed at a later time.

The primary then sends a PRE-PREPARE to all non-primaries
and relays the request to them, adding the sent message
to its log.

Replicas identify accepted REQUEST messages using the
current view number and the sequence number that the 
primary assigns to it. The primary adds the multicasted
PRE-PREPARE message to a new ticket for that REQUEST.

> In `pbft-java`, I assume that the REQUEST message is 
included with the PRE-PREPARE message to simplify the 
encoding process. Users can decide whether or not to follow
suit, they can always set the REQUEST to null and utilize 
their own thing if they want to follow the an orthodox
implementation.

#### Receiving PRE-PREPARE

When a non-primary receives a PRE-PREPARE, it ensures that
the view number is equal to the view that replica currently
is in, and that the message sequence ID is between the 
specified water marks, otherwise it ignores the message.
The replica then checks to ensure the digest is correct, if
the replica already has a matching ticket (one that has the
same view number and sequence number), then it will also
check to make sure that the new PRE-PREPARE message doesn't
have a digest different from the previous PRE-PREPARE. If
these two conditions aren't met, then the replica also 
ignores the message.

> Digests are `byte[]` arrays in `pbft-java`. Additionally,
ticketing is used because messages could arrive 
out-of-order, so I'm not sure if the PBFT paper specifies
that I should check the `prepared` and `committed-local`
states every single time.

Having accepted the PRE-PREPARE message, the replica then
creates a new ticket. It then adds the PRE-PREPARE message 
to the log, and multicasts a PREPARE message to all known 
replicas, also adding that PREPARE message to the log.

The replica will then attempt to check on the `prepared`
and `committed-local` states, executing the response to 
those states as necessary. More on that below.

#### Receiving PREPARE

When a replica receives a PREPARE, it will also check to
make sure that the view number is equal to the current view
number and the sequence number is within the water marks,
otherwise ignoring the message. It will create a new ticket
if one does not exist already, and append the PREPARE to
the log.

The relevant condition is `prepared`. The ticket will scan
the messages added to the log for that ticket (again, the
same view number and the same sequence number). When it
hits a PRE-PREPARE, it will scan the log to check for
matching PREPARE messages whose digests also match. If
the scan hits the `2f`th matching PREPARE message, then
the `prepared` state becomes true and the replica responds
by multicasting a COMMIT message, adding the COMMIT to the
log.

The replica will then attempt to check on the `prepared`
and `committed-local` states, executing the response to 
those states as necessary.

#### Recieving COMMIT

When a replica receives a COMMIT, it will also check to
make sure that the view number is equal to the current view
number and the sequence number is within the water marks,
otherwise ignoring the message. It will create a new ticket
if one does not exist already, and append the COMMIT to
the log.

The relevant condition here is `committed-local`. If we
know that the ticket has reached the `prepared` phase, we
don't need to rescan to make sure this is true. The ticket
then looks for matching COMMIT messages, and if it reaches
the `2f + 1`th COMMIT, it will then execute the 
operation found from the REQUEST message. A REPLY message 
is sent back to the client with the result of the 
operation, and the ticket is then moved to the cache in 
case the same REQUEST is sent again. The client then stops
the timer for that REQUEST, if available.

The replica will then attempt to check on the `prepared`
and `committed-local` states, executing the response to 
those states as necessary.

If the sequence number is evenly divisible by some
configured number, then the replica will also multicast a
CHECKPOINT message and add it to its log.

#### Receiving CHECKPOINT

When a replica receives a CHECKPOINT, it will add it to its
log. If the log has `2f + 1` CHECKPOINT messages from
itself and other replicas with the same sequence number as
the one that was received, it will then perform a garbage
collection by throwing away cached REPLY messages less than
or equal to the checkpoint, all CHECKPOINT messages below
that checkpoint, and will update the low water mark to the
checkpoint and the high water mark to the checkpoint plus
the configured checkpoint interval.

> `pbft-java` organizes CHECKPOINT messages by the sequence
number, but I *believe* that it should be based on any 
CHECKPOINT with a sequence number greater than the given
checkpoint to make it stable

#### What About View-changes?

Replicas will check the timers for all received REQUESTS in
a loop. If the timer expires, then the replica will skip 
all the other timers and become "disgruntled." It will then
multicast a VIEW-CHANGE message to vote all replicas into
view `v + 1`, where `v` represents the current view number.
The timeout will then double, and the timeout check loop 
continues. If it times out again, the VIEW-CHANGE will then
vote for `v + 2` and the time doubles yet again, and so on.
A disgruntled replica only accepts 3 messages: CHECKPOINT,
VIEW-CHANGE, and NEW-VIEW. All other messages are ignored.

> The PBFT algorithm specifies that the timeout shouldn't 
double, but rather should increase by increments of the 
original timeout, so instead of 1T -> 2T -> 4T, the paper
specifies that it should be 1T -> 2T -> 3T if `T` 
represented the original timeout

#### Receiving VIEW-CHANGE

When the "new primary" (the primary for view `v + 1`)
receives a VIEW-CHANGE message, it will add it to its log.
If there are `2f` VIEW-CHANGE messages in the log from
different replicas, then the new primary will then 
multicast a NEW-VIEW message.

> Technically, a multitude of items aren't supposed to be 
included in the actual NEW-VIEW message, however, again,
for encoding simplicity, `pbft-java` requires that the
NEW-VIEW message includes the full checkpoint proofs as
well as full PRE-PREPARE messages. If a more orthodox
implementation is desired, users are encouraged to add
their own messages to retrieve missing REQUESTs and
CHECKPOINTs.

If the replica isn't the "new primary," it will also add
the message to its log, but if it has `f + 1` VIEW-CHANGE
messages in its log already from different replicas, then
it will "bandwagon" and also multicast a VIEW-CHANGE for
the new view as well.

#### Receiving NEW-VIEW

When a replica receives a NEW-VIEW message is received by a
primary, it will perform a garbage collection by removing
the VIEW-CHANGE messages still in the log and clear all
pending requests from the previous view. If the lowest
proven checkpoint it receives is greater than the current
low water mark, then the checkpoint is upgraded, the proof
is inserted into the log, and a garbage collection is done
as if a checkpoint was proven by CHECKPOINT messages.

The replica then looks through all of the PRE-PREPARE 
messages, multicasting a corresponding PREPARE message
for them once the digest is checked with one generated for
the request. If the operation is `null`, then it is a no-op
and skipped. Both PRE-PREPARE and PREPARE messages are
added to the log.

The replica is then no longer disgruntled, removes all
outstanding timeouts, and then enters the new view.

The new primary that is multicasting the NEW-VIEW message
does all of the above, skipping the portion that handles
the PRE-PREPARE messages and instead adds those 
PRE-PREPARES to the log without sending a PREPARE.

# Conclusion

Most of the details for how I interpreted the PBFT protocol
is laid out here. The finer details of how to structure all
the data structures needed to store the messages and
determine quorum sizes still remain, and my implementation
can be found on GitHub with the link found at the top of
the post. PBFT is sort of like a gateway algorithm, there
are implementations of it like I believe Hyperledger and
other blockchain style applications, but there are other
BFT algorithms as well.

I was initially interested in (P)BFT reading up on, as my
recent post unsurprisingly suggests, about Space(X).
According to [LWN.net](https://lwn.net/Articles/540368/),
replication is used for avionics control on the Dragon
capsules, and the Byzantine Generals' Problem is used to
resolve disagreements between the flight computers, so it
is very cool to see how BFT is applied not only to Earth
applications, but also in space as well. My particular
implementation of BFT probably isn't up-to-par with what
the SpaceX engineers implemented, however. It definitely
wouldn't be launching anything mission critical.

I'll probably go back around to adding new posts in my
"Lessons Learned Debugging" series for another long stretch
until I figure out what other things to talk about.
