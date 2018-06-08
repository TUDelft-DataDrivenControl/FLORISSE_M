Classes
=========

Here the software classes will be documented. i.e. The comments in the code and the available methods and such things.


FLORIS Class
---------------
This is the handle class definition. It shows inheritance and member functions.

.. automodule:: FLORISSE_M.coreFunctions

.. autoclass:: floris
	:show-inheritance:
	:members:

Turbines
-----------

These are the turbines that are currently implemented in FLORIS. The first class is the turbine_prototype superclass, the actual turbines pass this class the relevant information to create a functioning turbine handle.

.. automodule:: FLORISSE_M.turbineDefinitions

.. autoclass:: turbine_type
	:show-inheritance:
	:members:

.. automodule:: FLORISSE_M.turbineDefinitions.dtu10mw

.. autofunction:: dtu10mw()

.. automodule:: FLORISSE_M.turbineDefinitions.mwt12

.. autofunction:: mwt12()

.. automodule:: FLORISSE_M.turbineDefinitions.nrel5mw

.. autofunction:: nrel5mw()

.. automodule:: FLORISSE_M.turbineDefinitions.TUM_G1

.. autofunction:: tum_g1()

AddedTurbulenceModels
-------------------------

This page documents the models which describe the amount of added turbulence in a wake

.. automodule:: FLORISSE_M.submodelDefinitions.addedTurbulence

.. autoclass:: added_ti_interface
	:show-inheritance:
	:members:
	
.. autoclass:: crespo_hernandez
	:show-inheritance:
	:members:

Deflection Models
----------------------

This page documents the deflection models that are currently implemented in FLORIS. The first class is the interface superclass, The actual deflection objects have to implement the function defined in the deflection interface.

.. automodule:: FLORISSE_M.submodelDefinitions.wakeDeflection


.. autoclass:: deflection_interface
	:members:
	:show-inheritance:


.. autoclass:: jimenez_deflection
	:members:
	:show-inheritance:


.. autoclass:: rans_deficit_deflection
	:members:
	:show-inheritance:

SummationModels
------------------

This page documents the wake summation models

.. automodule:: FLORISSE_M.submodelDefinitions.wakeSummation

.. autofunction:: quadratic_ambient_velocity()

.. autofunction:: quadratic_rotor_velocity()

Velocity Models
-------------------

This page documents the wake velocity models that are currently implemented in FLORIS. The first class is the interface superclass, The actual velocity objects have to implement the functions defined in the velocity interface.

.. automodule:: FLORISSE_M.submodelDefinitions.wakeVelocity


.. autoclass:: velocity_interface
	:members:
	:show-inheritance:

.. autoclass:: self_similar_gaussian_velocity
	:members:
	:show-inheritance:

.. autoclass:: zoned_velocity
	:members:
	:show-inheritance:

.. autoclass:: jensen_gaussian_velocity
	:members:
	:show-inheritance:

.. autoclass:: larsen_velocity
	:members:
	:show-inheritance:

Ambient Flow Classes
-----------------------

This page documents the classes that make ambient flow objects which are currently implemented in FLORIS. The first class is the interface superclass, The actual ambient flow objects have to implement the function and properties defined in the ambient flow interface.

.. automodule:: FLORISSE_M.helperObjects


.. autoclass:: ambient_inflow_interface
	:members:
	:show-inheritance:

.. autoclass:: ambient_inflow_uniform
	:show-inheritance:

.. autoclass:: ambient_inflow_log
	:members: Href
	:show-inheritance:

.. bibliography:: FLORIS.bib
	:filter: docname in docnames
