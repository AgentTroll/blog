---
layout: post
title: "TLE - Tracking Satellites in Space"
date: 2019-06-22T17:23:35-07:00
---

This is about my [`fate`](https://github.com/AgentTroll/fate)
project, something I finished in August of last year. I've
been on a long journey with some other Java-related
projects more recently, but I'd simply like the chance to
go back to one of my most significant C projects I've ever
written. I think it would also be a good chance to revisit
what I learned in the process of writing `fate` as well,
because Tim Dodd of Everyday Astronaut posted a [video
recently](https://youtu.be/kB-GKvdydho) that had some
discussion about inclination and azimuth, and despite
wrangling with that for weeks to understand how it worked,
I still had to pause the video and think through what he
had said.

# High-level Overview

The project is actually very simple on the surface, if you
have the most recent TLE (more specifically 3LE) data, then
you can input that into the command line and every second,
some output will be printed to show you above what point
the satellite is as well as where to point a telescope or
your eyes to find the object in the sky.

# What is TLE?

TLE stands for two-line element set. You'll actually notice
that I use 3LE, which stands for 3-line element set, and it
is *exactly* the same, save for the fact that a 3LE set has
an additional line at the top that states the name of the
satellite. This is what a 3LE set looks like:

```
0 ISS (ZARYA)
1 25544U 98067A   19174.05036204  .00001525  00000-0  33398-4 0  9995
2 25544  51.6442 332.2030 0008185  74.7737  30.3832 15.51219884176168
```

A TLE set would just be the same thing but with the line 
starting with `0` removed. For the purposes of
making things easier to understand, I'll primarily refer
to both 3LE and TLE as just TLE.

The [Wikipedia page](https://en.wikipedia.org/wiki/Two-line_element_set)
for TLE sets is actually surprisingly helpful and
informative. The main gist is that TLE is a way of
communicating the position and motion of a satellite
orbiting the Earth in as few numbers as possible. TLE sets 
are readily available from [SpaceTrack.org's TLE search
page](https://www.space-track.org/#/tle), and you can look
for satellites in the [satellite catalog](https://www.space-track.org/#/catalog).
The U.S. Air Force 18th Space Control Squadron produces
the TLE data sets by using a variety of sensing techniques
and calculating the TLE set data for publication on the
SpaceTrack website.

Here are some additional reading items you might find
helpful:

  - [FAQ page](https://www.space-track.org/documentation#/faq)
  - [TLE format](https://www.space-track.org/documentation#tle)
  - [Terminology](https://www.space-track.org/documentation#legend)

# Decoding TLE

It's all well and good that we have the data in TLE format,
but how can that data be translated into usable numbers
that show us where to point a telescope for example?

The first step is to refer to 
[SpaceTrack Report #3](https://www.celestrak.com/NORAD/documentation/spacetrk.pdf).
I'll let the author(s) summarize:

> The NORAD element sets [TLE sets] are “mean” values 
obtained by removing periodic variations in a particular
way. In order to obtain good predictions, these periodic
variations must be reconstructed (by the prediction model)
in exactly the same way they were removed by NORAD. Hence, 
inputting NORAD element sets into a different model (even 
though the model may be more accurate or even a numerical 
integrator) will result in degraded predictions. The NORAD 
element sets must be used with one of the models described 
in this report in order to retain maximum prediction 
accuracy

Essentially, the report lays out the mathematical models
for reconstructing the orbit of a particular satellite
from the data given by the TLE data set. Now there are
5 different models that the report lays out, SGP, SGP4/8
and SDP4/8. These are collectively known as "simplified
perturbation models" and take into account atmospheric
drag, gravitational drag caused by the Earth's oblate 
shape, the Earth's spin, and various other factors in order
to predict the motion of the satellite over time.

Since my primary goal was to figure out the position of
the International Space Station, I selected SGP4. As far as
I am aware, SGP4 and SDP4 are the most commonly used
models, this can be checked with the `MEAN_ELEMENT_THEORY`
entry for each satellite entry's OMM data.

Translating all of the formulae into working C code was
not super challenging. There is even working FORTRAN that
I referred to whenever I was having trouble figuring out
what the intent of a formula was. However, there are quite
a few variable values that are missing as well as this
part:

> Solve Kepler’s equation for (E + ω)

and the changes made to the model with a perigee at
different distances, which really confused me. That being
said, combined with looking at the FORTRAN listings on
SpaceTrack Report #3 as well as with the LizardTail website
[source](https://www.lizard-tail.com/isana/tle/lib/sgp4.js)
and the 
[Revisiting Spacetrack Report #3](https://www.celestrak.com/publications/AIAA/2006-6753/AIAA-2006-6753.pdf)
code listings in the appendix, I was able to reconstruct
the entire mathematical model in C code with most of the
constants updated to the modern values. I don't think it is
entirely perfect, but the numbers it produces look pretty
correct to me nonetheless.

Now if you ask me, I'd say that the finer details of the
model itself aren't actually that important. I can't say 
for sure what the purpose of each and every calculation is.
Again, the model takes into account the many different
variables that affect the gravitational pull and drag
experienced by a satellite, but that is as far as the 
extent of my knowledge about the perturbation models goes.

(Apologies to those readers who may have clicked on this to
get an understanding of how the perturbation models work,
that's simply something I never even needed to know to
implement the model in code. If anyone does understand, I'd
love to learn)

# Conversion Between Coordinate Systems

Now having implemented the SGP4 model, you might think that
we can now extract the data we need. Not so. The SGP4 model
produces 2 vectors, specifying the position and velocity
(meters per second) of the satellite. `fate` actually 
provides an additional 2 vectors called "unit orientation 
vectors." These are used  to derive the position and 
velocity vectors. 

The problem is that the reference frame for the
position vector uses the ECI coordinate grid, which means
that we get 3 values in X, Y, and Z. This doesn't help me,
because all I want to know is latitude and longitude to the
ISS.

I won't go into specifics, but these three articles are
extremely informative and detailed, and even an idiot like
myself was able to understand what is being discussed. I
highly recommend reading the entirety of the following:

  - [Orbital Coordinate Systems, Part I](https://www.celestrak.com/columns/v02n01/)
  - [Orbital Coordinate Systems, Part II](https://www.celestrak.com/columns/v02n02/)
  - [Orbital Coordinate Systems, Part III](https://www.celestrak.com/columns/v02n03/)

As far as the high-level overview goes, it is worth taking
a look at what ECI really is. ECI stands for 
"Earth-centered inertial," Earth-centered meaning that the
origin is at the center of the Earth and inertial meaning 
that it doesn't move with the rotation of the Earth itself.

Calculating the look angle in azimuth rotation from true
north and inclination angle from the horizon is relatively
complex because you need to turn yourr own latitude and 
longitude into ECI coordinates as well and utilize some 
trigonometry to determine the angle created between the 
coordinates. Not so hard, right? Unfortunately, the
complication comes from the fact that standard longitude
and latitude considers the Earth as an oblate spheroid, 
while ECI considers the Earth as a perfect sphere. Further,
the Earth also spins, which means that your position 
changes relative to the ECI coordinate system, which is 
aligned with the ecliptic plane (this would be the plane 
that the Equator would cross if the Earth wasn't tilted). 
In order to calculate everything, the current time is 
taken, and then converted to a single Julian date. This is
then converted to Greenwich Mean Sidereal Time (GMST), 
which allows one to calculate the current rotation of the 
Earth without the fluctuations in a solar day. Armed with 
this information, we can then convert from the standard 
"geodetic" latitude and longitude into a "geocentric" 
latitude and longitude, and from there, trigonometry is 
used to obtain the ECI coordinates of the observer.
[The implementation](https://github.com/AgentTroll/fate/blob/70311dab1664ffa3278c4af0e3f8f96f859f9efc/eci.c#L12-L22)
actually then looks deceptively simple.

Calculating the position of the satellite above the Earth
(called the sub-point) is a bit more simple. Essentially, 
We need to reverse the process and convert ECI into 
geodetic coordinates, but since we already have the ECI
coordinates, only simple trig is needed once we've factored
in the GMST to figure out the longitude is because the fact
that the Earth is oblate only affects latitude, longitude
runs parallel to the oblateness so no modification is
necessary. To calculate geodetic latitude, we first 
calculate the geocentric latitude, which is rather straight
forward trig. We then run a transformation which moves the
angle closer and closer to geodetic latitude, until the
diffence in improvement to the value becomes smaller than
is worth calculating. This value is then close enough to
the geodetic latitude to accept.

# Conclusion

This has only been a high-level overview of the
calculations needed to convert the available data into a
usable format, and then converting that format into
something that is understandable, like geodetic latitude
and longitude, and the look angles. I myself don't even
know all of the specifics. Working on this project was a
fascinating insight into the work done by astrophysicists
and mission planners to determine how to get satellites and
rockets into the correct orbits, and not only that, but to
track them and create models for the orbital mechanics that
affect the motion of the satellites through space.

Not only do I not usually talk about the C language, but I
didn't really go into any specifics of it in this 
particular blog post. That being said, I did talk a little
bit about astronomy and space, which are both topics that
I'm very curious to learn more about. I'm sure that every
one of us watched a rocket launch, watched Neil Armstrong
take humanity's first steps on another planet, or simply
read the news about the Opportunity rover. I'm absolutely
certain that others have been inspired by spaceflight and 
can relate to wanting to advance space exploration in the
future, if not the present.

I, for one, certainly would like to.
