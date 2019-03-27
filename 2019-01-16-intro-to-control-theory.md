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
takes input between -10 m/s to 10 m/s. A user provides
these constants to the PID controller in advance. It takes
some degree of testing to figure out the best combination
of gain values, a topic which is out of scope of this
discussion of the PID equation for the time being.

Each gain constant precedes a value that is proportional to
the instantaneous error, then the accumulated error, then
the rate at which the error is changing.

# PID Under The Magnifying Glass

The PID formula from the previous section takes all 3
terms and adds them together to produce the final output
value.

The error values that go into a PID controller are almost
always some form of distance or displacement. For example,
this could be the distance a robot is from a target, or the
number of degrees off a desired temperature. However, error
can also be a rate in, such as the current rate of a pump 
compared to the desired rate of a pump. The concept for 
both of them are exactly the same, however, and the PID 
computation shouldn't need to change so long as they are 
using distinct PID controllers. Either way, the bottom line
is that PID is simply a way to derive an output value based
on the input values. The behavior of the mechanism ends up 
being the same one way or another anyways, so don't fret if
you're worried about the rate being a derivative of
distance - it doesn't matter. The end result is that you
want to obtain an output that gets you to where you want to
go, or to a rate at which you want to go at.

The output of a PID controller is always a rate. It doesn't
really make any sense to output a distance or displacement
value, because physical systems can control rate in order
to affect the distance from a setpoint. For example, a PID
controller can output a greater value to increase the speed
at which a wheel turns, or decrease the temperature of a
heating element to reduce the speed at which heat is
distrubuted into a room.

#### The `P` term

The P term looks like the following:

```
K_p*e(t)
```

Meaning that it is derived from the proportional gain
constant multiplied by the most recently recorded error.

The P term is the most powerful because it responds to all 
changes to the value of the error, and the gain constant 
for the proportional term is usually tuned first. Having a 
P term alone usually leads to erratic output values in 
close proximity to the error beacuse the P gain amplifies 
the error to the negatives if the mechanism overshoots, and
vice versa.

A motion curve is typically used in robotics to show the
distanced travelled by a robot over time. I've used a
motion curve below to show the response to a PID loop
controlling the state of a system, where state can be a
temperature or a volume or a distance.

A system with an overly large P value looks like the 
following:

![P unstable loop]({{ site.url }}/blog/img/itct-p-unstable.svg)

It is often possible to acheive reasonably good results
using just the P term. One can adjuts the P gain until a
decent motion curve is produced, leaving all other gains
to 0. This is simply called a "P controller" or "P loop."

#### The `I` term

The I term looks like the following:

```
K_i*integrate(0, t, e(T), T)
```

Meaning that it is derived from multiplying the integral
gain by the accumulated error from time 0 to the current
time.

Because the I term is related to the accumulated error, the
longer the robot is off target, the more powerful the I 
term becomes. The problem with the I term on its own is 
that it tends to overcompensate because the accumulated 
error must be reduced by an opposing physical action, which 
then overshoots and starts another oscillation cycle.

This can be seen in a I only term loop here:

![I only loop]({{ site.url }}/blog/img/itct-i-only.svg)

The most common type of control loop that I've personally
seen is a PI loop, in which only the P and I terms are
used. It's rare to see a full PID(F) loop because it is
often more work to redetermine the gain constants than it 
is worth the marginal gains produced by adding an extra 
term.

For example, consider the following P only loop, which
demonstrates the ability of a single P term to produce
relatively decent results:

![P stable]({{ site.url }}/blog/img/itct-p-stable.svg)

An I term can be introduced to make a PI controller. This
will smooth out the motion curve when it reaches the
setpoint, and prevent a quick decceleration. You can see,
however, that there is some degree of overshoot when an I
term is introduced:

![PI]({{ site.url }}/blog/img/itct-pi.svg)

According to [PID Theory Explained](http://www.ni.com/en-us/innovations/white-papers/06/pid-theory-explained.html):

> Some amount of overshoot is always necessary for a fast 
system so that it could respond to changes immediately

#### The `D` term

The D term looks like the following:

```
K_d*derive(e(t), t)
```

Meaning that it is derived from the product of the
derivative gain and the instantaneous rate of change for 
the error.

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

Now, compare that to a PD loop with the D gain raised
slightly:

![PD - D = 0.6]({{ site.url }}/blog/img/itct-pd-06.svg)

The D term is problematic sometimes because setting the D
gain to to high of a value will cause the output to
oscillate extremely rapidly. This can also happen when
there are a lot of environmental disturbances that cause
the D term to overreact:

![PD - D = massive]({{ site.url }}/blog/img/itct-pd-massive.svg)

In my experience, I tend to see controllers using mostly
P and I terms, but usually no D term. The Wikipedia page
has this to say:

> Derivative action is seldom used in practice though – by
one estimate in only 25% of deployed controllers

Although this claim requires citation, it is easy to see
that the D term isn't too significantly useful for the
vast majority of applications where PI term controllers
are used instead. When the D gain is raised, the D term
tends to "fight" against the other two terms because it
wants to flatten the motion curve, when the other two terms
actually want the curve to get closer to the setpoint:

![PD - D = 0.7]({{ site.url }}/blog/img/itct-pd-07.svg)

When the D term is used, it tends to be used in a full PID
loop to control the I term overshoot. PD loops are also
found in the wild, but again, anything with a D term tends
to be quite rare compared to P and PI loops.

#### The `F` term

The F term is special because it is often left out of the
"PID" initialism. In part, this is due to the fact that
feed-forward is the application of a constant output,
regardless of the state of the mechanism. The actual
equation for a full PIDF loop looks like the following:

```
u(t) = K_p*e(t) + K_i*integrate(0, t, e(T), T) + K_d*derive(e(t), t) + K_f*SP
```

Where the F term is derived from the product of the
feed-forward gain and the current setpoint.

The purpose of a feed-forward in a PIDF computation is to
provide "stability." The F term acts as kind of a base rate
that pads the output from changes in the environment.
Because the F term doesn't respond to feedback from a
sensor (see the derivation of the F term), it is doesn't
truly belong with the other P, I, and D terms that do
depend on sensor feedback.

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

The F term also is only really useful for constant-rate
mechanisms (i.e. those that use difference in rate as the
error value rather than difference in displacement as is
customoary). Becase the F term cannot respond to
environmental changes, having a pre-defined F term in order
to drive a mechanism and using the other terms to control
error to that predefined rate is the most useful
application of the F term that I can personally see.

# Implementation

The derivation of the PID(F) formula is actually more 
daunting than the implementation in code.

We can imagine the PID loop as looking something like this:

``` java
PidfController controller = // ...

// Begin the loop by setting a target
controller.setSetpoint(setpoint);

while (true) {
    // Set the last state recorded by a sensor
    controller.setLastState(state);

    // If the error is 0, the PID procedure is done
    if (controller.computeError() == 0) {
        break;
    }

    // Compute the output
    double output = controller.computePidf();

    // Send output to the mechanism
    mechanism.setOutput(output);

    // Wait a constant time interval before repeating 
    Thread.sleep(INTERVAL);
}
```

(Once again, it should be noted that often a PID(F)
controller stops once the error is close enough to 0, in
general it's a poor idea to directly compare floating point
numbers anyways, so you probably get the idea)

To write the `PidfController`, the easiest step is to 
firstly define our gain and interval constants:

``` java
static final double INTERVAL;

double pGain;
double iGain;
double dGain;
double fGain;
```

The next portion would be to implement a way to calculate
error. We will need a way to define the setpoint to which
the PID(F) controller is to travel to, and then a way to
define the last state recorded by a sensor:

``` java
double setpoint;
double lastState;

// Called by a user to set the setpoint
public void setSetpoint(double setpoint) {
    this.setpoint = setpoint;
}

// Called by a sensor to set the state of the system
public void setLastState(double lastState) {
    this.lastState = lastState;
}

public double computeError() {
    return this.setpoint - this.lastState;
}
```

Now that we have our gain constants a way to compute the 
current error, we can now head to computing each term.

Proportional:

``` java
double computeProportional() {
    double error = this.computeError();
    return this.pGain * error;
}
```

For integral, we need to hold the amount of error that has
accummulated since the PID loop began. This can be acheived
by using a variable to hold the error multiplied by the
interval time each time the loop runs:

``` java
double accumulatedError;

double computeIntegral() {
    double error = this.computeError();
    this.accumulatedError += error * INTERVAL;

    return this.iGain * this.accumulatedError;
}
```

For derivative, since the rate of change of the error is
instantaneous, we can simply use the slope formula for the
last recorded error and the current error taken over the
interval time:

``` java
double lastError;

double computeDerivative() {
    double error = this.computeError();
    double derivative = (error - this.lastError) / INTERVAL;

    this.lastError = error;

    return this.dGain * derivative;
}
```

For feed-forward, it is the gain multiplied by setpoint:

``` java
double computeFeedforward() {
    return this.fGain * this.setpoint;
}
```

Finally, tying everything together:

``` java
double computePidf() {
    return this.computeProportional()
            + this.computeDerivative()
            + this.computeIntegral()
            + this.computeFeedforward();
}
```

And then cleanup our code and write it all into a coherent
class:

``` java
public class PidfController {
    private static final double INTERVAL = 0.5;

    private final double pGain;
    private final double iGain;
    private final double dGain;
    private final double fGain;

    private double setpoint;
    private double lastState;

    private double accumulatedError;
    private double lastError;

    public PidfController(double pGain, double iGain, double dGain, double fGain) {
        this.pGain = pGain;
        this.iGain = iGain;
        this.dGain = dGain;
        this.fGain = fGain;
    }

    public void setSetpoint(double setpoint) {
        this.setpoint = setpoint;
    }

    public void setLastState(double lastState) {
        this.lastState = lastState;
    }

    public double computeError() {
        return this.setpoint - this.lastState;
    }

    private double computeProportional() {
        double error = this.computeError();
        return this.pGain * error;
    }

    private double computeIntegral() {
        double error = this.computeError();
        this.accumulatedError += error * INTERVAL;

        return this.iGain * this.accumulatedError;
    }

    private double computeDerivative() {
        double error = this.computeError();
        double derivative = (error - this.lastError) / INTERVAL;

        this.lastError = error;

        return this.dGain * derivative;
    }

    private double computeFeedforward() {
        return this.fGain * this.setpoint;
    }

    public double computePidf() {
        return this.computeProportional()
                + this.computeDerivative()
                + this.computeIntegral()
                + this.computeFeedforward();
    }
}
```

Users should change the `INTERVAL` time as they see 
appropriate.

It should be noted that all the gain values can even be
changed during the PID loop, and so it is not necessary for
them to be `final`. The `INTERVAL` time doesn't even need
to be constant, so long as one takes into account the time
that elapses between each iteration of the PID loop. That
being said, this is simply just the bare-bones minimum
code, and it is up to the implementor to determine if those
features are needed.

As far as units go, it is not necessarily required to have
a consistent unit conversion. A PIDF loop simply outputs
the rate as it relates to the gain constants and the error
value. It is up to users to determine if any consistency is
really required here.

# Conclusion

Control Theory and control engineering are broad topics
that I've only briefly touched over in this blog post. With
a better understanding of the theory and implementation of
PID control, one can build more precise physical mechanisms
such as robots, temperature controls, pumps, etc.

I've done my best to speak on general terms so that the
concepts can be applied to the widest selection of
scenarios possible. Sometimes, that has made it more 
difficult to undestand what I'm talking about, but I hope
that giving several real world examples to demonstrate a
single concept has made it easier to grasp.

Again, I will reiterate that I'm by no means an expert in
the field of Control Theory. Feel free to contact me for
corrections, but I'm definitely not the right person to ask
if you need clarification, as I've done my best already to 
try and clarify everything up front.

For FRC Robots, you definitely want to use `PIDController`
over the hand-rolled implementation I have here, by the
way.

I probably won't be doing any more posts about robotics
unless some extenuating circumstance forces me to.

