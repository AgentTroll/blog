---
layout: post
title: "Intro to Control Theory"
date: 2019-01-16T22:16:20-07:00
---

While I don't profess to be an absolute expert at control theory, a lot of the information about the matter
that I've found online appears to be either inaccessible to the average Joe or simply flat-out unhelpful. 
Control Theory is often explained with mechanical controllers that don't really have any application to the
software world, and it has been difficult for me personally to comprehend at all what is going on. In light of
this, I've decided to do a write up about what control theory is from the perspective of an implementor, 
rather than that of a theorist.

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

While I will be referring to the software control of
physical systems, control loops can also be built with
mechanical controls in the place of the software component
as well.

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
stand for proportional, integral, derivative, and
feed-forward. Because PID is the main "controller" of a
mechanism, one often uses the term "PID control" or "PID
loop" to refer to a closed-loop control system. On the
above diagram, PID would be the "Compute output" portion of
the control loop.

When you look up ["PID Controller"](https://en.wikipedia.org/wiki/PID_controller) on Wikipedia, you get
this image here:

![PID equation](https://wikimedia.org/api/rest_v1/media/math/render/svg/cd581e5c8539ce46453574d1188bd9d52a610fe0)

(You will notice that there's only 3 terms, and that I've
dropped the F from PID several times already. I'll get into
why that is later on)

This is a good starting point at which we can start to
implement a PID control loop. All the K values are simply
"gain" constants, which are used to control the power (for
lack of a better word) of the output. These are adjustible
in order to change the order of magnitude of the output, so
for example, a motor that takes an input between -1 m/s and
1 m/s would have smaller gain constants than a motor that
takes input between -10 m/s to 10 m/s.

Each gain constant precedes a value that is proportional to
the instantaneous error, then the accumulated error, then
the rate at which the error is changing.

### The `P` term

The P term is directly proportional to the instantaneous
error. The P term is the most powerful because it responds
to all changes to the value of the error, and the gain
constant for the proportional term is usually tuned first.
Having a P term alone usually leads to erratic output
values in close proximity to the error beacuse the P gain
amplifies the error to the negatives if the mechanism
overshoots, and vice versa.

A typical PID loop with only a P term would look like this:

![P only loop]({{ site.url }}/blog/img/itct-p-only.svg)

I've purposely set the P value too high in order to to
exaggerate the effect I'm referring to. In practice, it is
possible to only use a P term successfully without needing
the other terms to control it for simple mechanisms.

### The `I` term

The I term is related to the accumulated error. The longer
the robot is off target, the more powerful the I term
becomes. The problem with the I term on its own is that it
tends to either overcompensate because the accumulated
error must be reduced by an opposing physical action, which
then overshoots and starts another cycle oscillation.

This can be seen in a I only term loop here:

![I only loop]({{ site.url }}/blog/img/itct-i-only.svg)

The most common type of control loop that I've personally
seen is a PI loop, in which only the P and I terms are
used. It's rare to see a full PID(F) loop because it is
often more work to determine the gain constants than it is
worth the marginal gains produced by adding an extra term.

### The `D` term

The D term is related to the rate at which error changes.
The faster the mechanism moves away from its setpoint, the
more powerful the D term becomes. Unlike the other two
terms, the D term does not respond directly to rate, but
rather the change in rate. Therefore, it is not possible to
have a D only system. The effect of the D term is to
reduce the rate at which the error grows, therefore
flattening the error line. This is useful for more stable
mechanisms that require the output to be adjusted to
reduce the power of the P term.

It's probably easier to see it on a graph. Here's a PD loop
with the D gain set to `0`:

![PD - D = 0]({{ site.url }}/blog/img/itct-pd-0.svg)

Now compare that to a PD loop with the D gain raised
slightly:

![PD - D = 0.6]({{ site.url }}/blog/img/itct-pd-06.svg)

It should be again noted that any combination of PID
controller terms tend to not be used in my experience. The
Wikipedia page has this to say:

> Derivative action is seldom used in practice though – by
one estimate in only 25% of deployed controllers

Although this claim requires citation, it is easy to see
that the D term isn't too significantly useful for the
vast majority of applications where P/I term controllers
are used instead. When the D gain is raised, the D term
tends to "fight" against the other two terms because it
wants to flatten the motion curve, when the other two terms
actually want the curve to get closer to the setpoint:

![PD - D = 0.7]({{ site.url }}/blog/img/itct-pd-07.svg)

### The `F` term

The F term is special because it is often left out of the
"PID" initialism. In part, this is due to the fact that
feed-forward is the application of a constant output,
regardless of the state of the mechanism. The actual
equation for a full PIDF loop looks like the following:

```
u(t) = K_p*e(t) + K_i*integrate(0, t, e(T), T) + K_d*derive(e(t), t) + K_f*SP
```

Where the F term involves the F gain multiplied by the
setpoint.

The purpose of a feed-forward in a PIDF computation is to
provide "stability." The F term acts as kind of a base rate
that pads the output from changes in the environment.

The F term is really only useful for applications where a
rate of something is to remain constant. In attempting to
use the F term to run a PID loop for displacement, you
would get a motion curve that looks something like this:

![PD - D = 0.6]({{ site.url }}/blog/img/itct-pf.svg)

A PID loop would be unable to compensate for the constant
rate provided by the F term.

If a system used only a feed-forward term and had no input
from the other terms, then it would be an open-loop system
because no feedback from the sensor is needed to adjust the
output. Because the F term doesn't respond to any changes
in the environment, it is not included with the other terms
that do require feedback from a sensor.

The other part of the reason why I think that the F term is
dropped is because many systems tend to change quite often.
As a matter of fact, [FRC Programming Done Right](https://frc-pdr.readthedocs.io/en/latest/control/pid_control.html)
has this to say about using the F term:

> Feedforward control is necessary on all but the absolute 
simplest of systems. It’s incredibly difficult to get a 
good response without a feedforward calculation.

In my opinion, this is actually backwards. For simpler,
more predictable systems, it is easier to use an F term
because it is easier to predict and measure the various
different factors that impact the performance of a
specific device. This all goes back to the open-loop and
closed-loop system. The simpler the system is, the easier
it will be to determine the appropriate F gain. This also
means that it is difficult to use for more varied, dynamic
environments you'd typically find PID control loops
running in, which is why PID tends to be referred to
without reference to the F term.

# Implementation

# Implementation For Rate

# Conclusion

`// TODO`
