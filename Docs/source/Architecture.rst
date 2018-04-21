Architecture
===============

Matlab supports object oriented programming and it is used in the FLORIS package. The mathworks website has `a quick primer on objects <https://nl.mathworks.com/company/newsletters/articles/introduction-to-object-oriented-programming-in-matlab.html>`_. As you will quickly notice the matlab objects all inherit from handle, the reason for that is explained `here <https://nl.mathworks.com/help/matlab/matlab_oop/comparing-handle-and-value-classes.html>`_
FLORIS is based on several papers. Below is an image showing a draft of the current architecture:


.. image:: Images/DrawIODiagrams/FLORIS_top_level.png
   :width: 100 %
   :alt: Diagram of FLORIS
   :align: center

Every top level block in this diagram corresponds to a folder in the FLORIS source code.


.. automodule:: FLORISSE_M

.. :mod:`coreFunctions` is a really cool module.

FLORIS Class
---------------
This is the handle class definition. It shows inheritance and memebr functions.

.. autoclass:: floris
	:show-inheritance:
	:members:


.. More text here

.. And a heading
.. ---------------


.. and some more text
