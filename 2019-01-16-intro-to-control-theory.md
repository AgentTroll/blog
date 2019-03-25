---
layout: post
title: "Intro to Control Theory"
date: 2019-01-16T22:16:20-07:00
---

While I don't profess to be an absolute expert at control theory, a lot of the information about the matter
that I've found online appears to be either inaccessible to the average Joe or unhelpful. I've decided to
do a write up about what control theory is from the perspective of an implementor, rather than a theorist.

That being said, control theory is still theory. That is, to understand the concept itself, you must
understand the theory. I do plan on going over the practical use of control theory in code later on in this
post, but I will first begin with theory.

Feel free to drop me a message on Telegram if I've made any errors in my explanation, because I again do not
profess to be an expert at all in the subject.

# The Premise of Control Theory

Control Theory is a branch of Computer Science that deals
with the manipulation of a physical system. When people
talk about Control Theory, they tend to use temperature
control as an example. Another common use of Control Theory
is in robotics, where the physical systems are the moving
parts of the robot such as arms and legs. The need for
Control Theory arises because the state of the environment
changes during the operation of a physical mechanism. In
order to control the distance that a robot moves for
example, one would need to know how powerful the motor is,
the frictional forces that will be experienced, such as
from the surface, from the ball bearings, potentially wind
resistance, etc. By taking all of these factors into
account, one can can calculate parameters such as current
and the time that a motor will need to run to move some
distance. This model, where all the information is
collected beforehand to compute a command that controls
a system is called an *open loop system*.

![Open Loop]({{ site.url }}/blog/img/itct-open-loop.svg)

However, the problem is that it would be impractical to 
have to measure or require a human to input the
potentially large number of different variables that
affect the system. This problem is solved by using a sensor
to measure the actual output of the system (in this case,
the actual distance the wheel of a robot rolls) and then
sending that information back to the software, which then
computes a new set of parameters to compensate for 
overshoot or undershoot of some target. This is called a
*closed-loop system*, because information travels both in
the direction of the system being controlled, and in the
direction of the software controlling that system as well.

![Closed Loop]({{ site.url }}/blog/img/itct-closed-loop.svg)

And while you will still need to understand certain
operating parameters of the physical system, you will not
need to account for every possible factor that will affect
the the physical result of a command.

(As a quick side note, one would use a sensor when dealing
with autonomous systems. When humans are operating a
system, it is the human who takes note of whatever state
the system is currently in, and therefore, a system that
would otherwise be an open-loop becomes a closed-loop
system with human intervention)

# Abstract View of Closed-Loop Systems

Physical systems do not react instantaneously. As such, a
closed-loop system will usually sample and send updates 
over time at fixed intervals.

At the beginning of a procedure, a goal (or target or
setpoint) is defined for a system. This could be rolling a
particular distance for a wheel, or a room heating up to a
particular temperature, or a particular speed at which to
spin an axle, etc, so long as whatever sensor is equipped
on the device is capable of measuring it (e.g. an encoder
or a thermocouple). Then, the *error* is computed by
subtracting the current state of the system from the
setpoint, where error is simply a metric of how far away
the current state of the mechanism is from where the 
setpoint  is. Finally, a command will be sent to compensate
for the error. This will be repeated at a set time interval
until the error becomes, or gets close enough to 0, meaning
that the mechanism has reached its setpoint.

![Abstract Loop]({{ site.url }}/blog/img/itct-abstract-loop.svg)

The process of computing the output based on the error
value is known as PID (sometimes PIDF), where the letters
stand for proportional, integral, derivative, and feed.



`// TODO`
