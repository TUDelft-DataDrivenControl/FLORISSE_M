.. _background:

Background
============
Today, wind turbines that are part of a wind farm do not take neighbouring turbines into account when determining their control settings. This results in greedy control, where each turbine tries to align itself with the dominant wind direction and optimize its energy production using generator torque control and pitch control. During operation, each turbine creates a volume of slow-moving turbulent air behind its rotor, which is called a wake.

FLORIS tries to model the dominant wake characteristics such as position and intensity, FLORIS also estimates how wakes interact with eachoter. The goal is to use FLORIS to find optimal control setpoint for wind turbines. The goal is to move from individually optimized turbines to optimizing the energy production of an entire wind farm.

The originial FLORIS model used multiple zones to model the wake velocity :cite:`Gebraad2014` and implemented the wake deflection model as described in :cite:`Jimenez2009`. However there is quite some interest in this type of optimization and these type of models from the wind reseacrh community. Because of that reason FLORIS has been made modular, making it relatively straightforward to implement new wake models. One such implemented model comes from :cite:`Bastankhah2016`.

There is also a python version of FLORIS but because of the wide spread use of matlab in the academic community the choice was made to also keep the originial matlab implementation up to date.

The aim is to provide a model that is easy to extend and straightforward to use in optimization algorithms. Currently there are several use cases for FLORIS:

- Find optimal control settings for a set of wind turbines
- Find optimal positions for wind turbines that will be placed in a new wind farm
- Estimate the wind strength and direction in a wind farm

Another aim is to make tuning the model parameters of a model implemented in FLORIS as straightforward as possible.

More information on how these options are implemented and how the model is structured can be found on the :ref:`architecture` page.

.. bibliography:: FLORIS.bib
	:filter: docname in docnames
